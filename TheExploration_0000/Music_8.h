#pragma once


static float clampFloat(float v, float lo, float hi) {
    return (v < lo) ? lo : (v > hi) ? hi : v;
}

constexpr int SCALE_NOTES = 7;
static const double cMajorScale[SCALE_NOTES] = {
    261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88
};
static const double aMinorScale[SCALE_NOTES] = {
    220.00, 246.94, 277.18, 293.66, 329.63, 369.99, 415.30
};

static uint32_t lcgState = 1;
static float nextNoiseFloat() {
    lcgState = 1664525u * lcgState + 1013904223u;
    return float(((lcgState >> 16) & 0xFFFF) / 65535.0 * 2.0 - 1.0);
}

// Enhanced multi-tap delay buffer with stereo separation
constexpr int ECHO_BUFFER_SIZE = 48000; // doubled for more room
static float delayBufferL[ECHO_BUFFER_SIZE] = { 0 };
static float delayBufferR[ECHO_BUFFER_SIZE] = { 0 };
static int writeIndex = 0;

// Simple 1-pole filter state
struct OnePole {
    float a0, b1;
    float z1;
    OnePole() : a0(1.0f), b1(0.0f), z1(0.0f) {}
    inline float process(float x) {
        float y = a0 * x + b1 * z1;
        z1 = y;
        return y;
    }
    inline void setLowpass(float cutoffFreq, unsigned sampleRate) {
        float x = expf(-2.0f * 3.14159265358979323846f * cutoffFreq / float(sampleRate));
        b1 = x;
        a0 = 1.0f - x;
    }
    inline void setHighpass(float cutoffFreq, unsigned sampleRate) {
        float x = expf(-2.0f * 3.14159265358979323846f * cutoffFreq / float(sampleRate));
        b1 = -x;
        a0 = (1.0f + x) * 0.5f;
    }
};

// Per-voice envelope generator (simple exponential)
struct Envelope {
    float value;
    float decay; // between 0 and 1
    bool active;
    Envelope() : value(0.0f), decay(0.9995f), active(false) {}
    inline void trigger(float initial = 1.0f, float decayRate = 0.9995f) {
        value = initial;
        decay = decayRate;
        active = true;
    }
    inline float process() {
        if (!active) return 0.0f;
        float out = value;
        value *= decay;
        if (value < 0.001f) { active = false; value = 0.0f; }
        return out;
    }
};



// Audio callback
void audio_callback(ma_device* /*device*/, void* pOutput, const void* /*pInput*/, ma_uint32 frameCount) {
    float* out = static_cast<float*>(pOutput);

    float px = g_playerPosX.load(std::memory_order_relaxed);
    float py = g_playerPosY.load(std::memory_order_relaxed);
    float pz = g_playerPosZ.load(std::memory_order_relaxed);

    // Persistent state variables
    static double phaseLead = 0.0;
    static double phaseBass = 0.0;
    static double beatAcc = 0.0;
    static double lfoMainPhase = 0.0;
    static double stepCounter = 0.0;
    static double chordTimeAcc = 0.0;
    static int chordIndex = 0;
    static double chordEnv = 0.0;
    static double chordPhase[3] = { 0.0, 0.0, 0.0 };
    static double windLFOPhase = 0.0;
    static float prevWindIn = 0.0f;
    static float prevWindOut = 0.0f;
    static bool melActive = false;
    static double melPhase = 0.0;
    static double melEnv = 0.0;
    static double melFreq = 0.0;

    // NEW: Drum voices
    static Envelope kickEnv, snareEnv, hatEnv;
    static double kickPhase = 0.0;
    static double snarePhase = 0.0;

    // NEW: FM bell voices
    struct FMBell { bool active; double carrierPhase, modPhase, carrierFreq, modFreq, env; };
    static FMBell bells[4] = {};

    // NEW: Filters
    static OnePole chordLPF_L, chordLPF_R;
    static OnePole windHPF_L, windHPF_R;
    static OnePole hatHPF_L, hatHPF_R;

    const double PI = 3.14159265358979323846;
    const double TWO_PI = 2.0 * PI;
    const unsigned SAMPLE_RATE = AUDIO_SAMPLE_RATE;

    // Pre-compute filter cutoff LFOs based on player X and Y
    double filterLFO1 = 0.5 + 0.5 * sin(px * 2.0 + lfoMainPhase * TWO_PI); // 0-1
    double filterLFO2 = 0.5 + 0.5 * cos(py * 3.0 + lfoMainPhase * TWO_PI);

    // Choose scale dynamically: if playerY > 0, use C major; else A minor
    const double* currentScale = (py > 0.0f) ? cMajorScale : aMinorScale;

    for (ma_uint32 i = 0; i < frameCount; ++i) {
        // 1) Update LFO phases
        lfoMainPhase += 0.1 / SAMPLE_RATE;
        if (lfoMainPhase >= 1.0) lfoMainPhase -= 1.0;

        windLFOPhase += 0.05 / SAMPLE_RATE;
        if (windLFOPhase >= 1.0) windLFOPhase -= 1.0;

        // 2) Spatial factors
        float spatialDepth = clampFloat(pz * 0.5f + 0.5f, 0.1f, 1.0f);
        float spatialWidth = clampFloat(px * 0.5f + 0.5f, 0.1f, 1.0f);

        // 3) Dynamic tempo
        double tempoFactor = 0.5 + 0.5 * sin(px * 3.0);
        tempoFactor = clampFloat(tempoFactor, 0.2f, 2.0f);

        // 4) Chord progression (every 1.5s instead of 2s)
        chordTimeAcc += tempoFactor / SAMPLE_RATE;
        if (chordTimeAcc >= 1.5) {
            chordTimeAcc -= 1.5;
            chordIndex = (chordIndex + 1) % 4; // now 4-chord cycle
            chordEnv = 1.0;
        }
        chordEnv *= 0.9992; // slightly faster decay

        // 5) Determine chord roots: (C, F, G, Am)
        int rootIdx;
        switch (chordIndex) {
        case 0: rootIdx = 0; break;   // C
        case 1: rootIdx = 3; break;   // F
        case 2: rootIdx = 4; break;   // G
        case 3: rootIdx = 5; break;   // A minor (using C major scale as basis)
        default: rootIdx = 0; break;
        }
        double freqRoot = currentScale[rootIdx] * 0.5;
        double freqThird = currentScale[(rootIdx + 2) % SCALE_NOTES] * 0.5;
        double freqFifth = currentScale[(rootIdx + 4) % SCALE_NOTES] * 0.5;

        // 6) Update chord phases with spatial modulation
        chordPhase[0] += freqRoot * (1.0 + 0.02 * sin(py * 4.0)) / SAMPLE_RATE;
        chordPhase[1] += freqThird * (1.0 + 0.02 * sin(pz * 4.0)) / SAMPLE_RATE;
        chordPhase[2] += freqFifth * (1.0 + 0.02 * sin(px * 4.0)) / SAMPLE_RATE;
        for (int k = 0; k < 3; ++k) {
            if (chordPhase[k] >= 1.0) chordPhase[k] -= 1.0;
        }
        float rawChord = (sin(chordPhase[0] * TWO_PI) +
            sin(chordPhase[1] * TWO_PI) +
            sin(chordPhase[2] * TWO_PI)) / 3.0f * chordEnv;

        // 7) Chord filter cutoff (low-pass) modulated by filterLFO1
        float cutoffChord = 200.0f + float(filterLFO1) * 3000.0f; // 200Hz to ~3200Hz
        chordLPF_L.setLowpass(cutoffChord, SAMPLE_RATE);
        chordLPF_R.setLowpass(cutoffChord * (1.0f + 0.1f * sin(px * 5.0f)), SAMPLE_RATE);
        float sampleChordL = chordLPF_L.process(rawChord * 0.6f * spatialDepth);
        float sampleChordR = chordLPF_R.process(rawChord * 0.6f * spatialDepth);

        // 8) Bass follows chord root with Y modulation & lowpass
        double freqBass = freqRoot * 0.4 * (1.0 + 0.3 * sin(py * 6.0));
        phaseBass += clampFloat(freqBass, 40.0f, 120.0f) / SAMPLE_RATE;
        if (phaseBass >= 1.0) phaseBass -= 1.0;
        float rawBass = sin(phaseBass * TWO_PI);
        // Lowpass bass lightly
        static OnePole bassLPF_L, bassLPF_R;
        float cutoffBass = 100.0f + float(filterLFO2) * 800.0f; // 100Hz to ~900Hz
        bassLPF_L.setLowpass(cutoffBass, SAMPLE_RATE);
        bassLPF_R.setLowpass(cutoffBass * 1.1f, SAMPLE_RATE);
        float sampleBassL = 0.5f * bassLPF_L.process(rawBass * 0.8f);
        float sampleBassR = 0.5f * bassLPF_R.process(rawBass * 0.8f);

        // 9) Lead melody (stepping) with PWM-like modulation
        stepCounter += tempoFactor * 1.2 / SAMPLE_RATE;
        if (stepCounter >= SCALE_NOTES) stepCounter -= SCALE_NOTES;
        int noteIndex = static_cast<int>(floor(stepCounter)) % SCALE_NOTES;
        double freqLead = currentScale[noteIndex] * (1.0 + 0.1 * sin(lfoMainPhase * TWO_PI) + 0.05 * sin(pz * 10.0));
        phaseLead += freqLead / SAMPLE_RATE;
        if (phaseLead >= 1.0) phaseLead -= 1.0;
        float rawLead = sin(phaseLead * TWO_PI);
        // PWM effect: mix with 90-degree phase-shifted sine
        float pwm = sin((phaseLead + 0.25) * TWO_PI);
        float sampleLead = rawLead * 0.6f + pwm * 0.4f;

        // Pan lead between L/R by px
        float leadPan = 0.5f + 0.5f * sin(px * 6.0f);
        float sampleLeadL = sampleLead * (1.0f - leadPan) * 0.5f;
        float sampleLeadR = sampleLead * leadPan * 0.5f;

        // 10) Random melodic ornaments (FM-bells occasionally)
        float sampleOrnamentL = 0.0f, sampleOrnamentR = 0.0f;
        // existing "melActive" sine-ornament
        if (!melActive) {
            if (nextNoiseFloat() > (0.995f - pz * 0.015f)) {
                melActive = true;
                int idx = rand() % SCALE_NOTES;
                melFreq = currentScale[idx] * (2.0 + (rand() % 2));
                melPhase = 0.0;
                melEnv = 1.0;
            }
        }
        if (melActive) {
            melPhase += melFreq / SAMPLE_RATE;
            if (melPhase >= 1.0) melPhase -= 1.0;
            float tone = sin(melPhase * TWO_PI) * float(melEnv);
            melEnv *= 0.990;
            if (melEnv < 0.001) melActive = false;
            // pan based on px
            sampleOrnamentL += tone * 0.3f * (1.0f - leadPan);
            sampleOrnamentR += tone * 0.3f * leadPan;
        }
        // NEW: FM-bell trigger occasionally
        if (nextNoiseFloat() > (0.9995f - pz * 0.02f)) {
            // find inactive bell slot
            for (int b = 0; b < 4; ++b) {
                if (!bells[b].active) {
                    bells[b].active = true;
                    bells[b].carrierFreq = 440.0 + (rand() % 6 - 3) * 20.0; // around A4 ± 60Hz
                    bells[b].modFreq = bells[b].carrierFreq * 2.0;
                    bells[b].carrierPhase = 0.0;
                    bells[b].modPhase = 0.0;
                    bells[b].env = 1.0;
                    break;
                }
            }
        }
        for (int b = 0; b < 4; ++b) {
            if (bells[b].active) {
                bells[b].modPhase += bells[b].modFreq / SAMPLE_RATE;
                if (bells[b].modPhase >= 1.0) bells[b].modPhase -= 1.0;
                double modulator = sin(bells[b].modPhase * TWO_PI) * 50.0;
                bells[b].carrierPhase += (bells[b].carrierFreq + modulator) / SAMPLE_RATE;
                if (bells[b].carrierPhase >= 1.0) bells[b].carrierPhase -= 1.0;
                float bellSample = float(sin(bells[b].carrierPhase * TWO_PI) * bells[b].env);
                bells[b].env *= 0.995;
                if (bells[b].env < 0.001) { bells[b].active = false; bells[b].env = 0.0; }
                // spread them stereo randomly
                float pan = float(0.3 + 0.7 * (nextNoiseFloat() * 0.5f + 0.5f));
                sampleOrnamentL += bellSample * (1.0f - pan) * 0.2f;
                sampleOrnamentR += bellSample * pan * 0.2f;
            }
        }

        // 11) Percussive elements
        float sampleKickL = 0.0f, sampleKickR = 0.0f;
        float sampleSnareL = 0.0f, sampleSnareR = 0.0f;
        float sampleHatL = 0.0f, sampleHatR = 0.0f;

        // Kick: sine buzz + envelope
        if (!kickEnv.active) {
            if (nextNoiseFloat() > (0.995f - spatialWidth * 0.002f)) {
                kickEnv.trigger(1.0f, 0.995f);
                kickPhase = 0.0;
            }
        }
        if (kickEnv.active) {
            kickPhase += 60.0 / SAMPLE_RATE; // 60Hz fundamental
            if (kickPhase >= 1.0) kickPhase -= 1.0;
            float k = sin(kickPhase * TWO_PI) * kickEnv.process();
            sampleKickL += k * 0.8f;
            sampleKickR += k * 0.8f;
        }

        // Snare: filtered noise burst
        if (!snareEnv.active) {
            if (nextNoiseFloat() > (0.996f - pz * 0.003f)) {
                snareEnv.trigger(1.0f, 0.99f);
            }
        }
        if (snareEnv.active) {
            float noise = nextNoiseFloat() * snareEnv.process();
            // high-pass filter for snare "crack"
            static OnePole snareHPF_L, snareHPF_R;
            snareHPF_L.setHighpass(2000.0f, SAMPLE_RATE);
            snareHPF_R.setHighpass(2000.0f, SAMPLE_RATE);
            float s = snareHPF_L.process(noise);
            sampleSnareL += s * 0.5f;
            sampleSnareR += s * 0.5f;
        }

        // Hi-Hat: rapid noise bursts
        if (!hatEnv.active) {
            if (nextNoiseFloat() > (0.997f - spatialWidth * 0.004f)) {
                hatEnv.trigger(1.0f, 0.98f);
            }
        }
        if (hatEnv.active) {
            float noise = nextNoiseFloat() * hatEnv.process() * 0.3f;
            // band-limited by high-pass
            hatHPF_L.setHighpass(8000.0f, SAMPLE_RATE);
            hatHPF_R.setHighpass(8000.0f, SAMPLE_RATE);
            float hh = hatHPF_L.process(noise);
            // pan hard L/R alternating
            if ((i & 1) == 0) {
                sampleHatL += hh;
            }
            else {
                sampleHatR += hh;
            }
        }

        // 12) Atmospheric wind layer (with high-pass)
        float rawWind = nextNoiseFloat() * 0.3f;
        float windOut = rawWind - prevWindIn + 0.98f * prevWindOut;
        prevWindIn = rawWind;
        prevWindOut = windOut;
        double windLFO = 0.5 + 0.5 * sin(windLFOPhase * TWO_PI);
        float windWet = windOut * float(windLFO) * 0.4f;
        windHPF_L.setHighpass(300.0f + float(filterLFO2) * 500.0f, SAMPLE_RATE);
        windHPF_R.setHighpass(300.0f + float(filterLFO2) * 600.0f, SAMPLE_RATE);
        float sampleWindL = windHPF_L.process(windWet);
        float sampleWindR = windHPF_R.process(windWet);

        // 13) Granular shaker: very fast noise grain bursts
        float shaker = 0.0f;
        if (nextNoiseFloat() > 0.999f) {
            shaker = nextNoiseFloat() * 0.2f;
        }
        // simple envelope
        static float shakerEnv = 0.0f;
        shakerEnv = shaker > 0.0f ? 1.0f : shakerEnv * 0.97f;
        float sampleShaker = shaker * shakerEnv;
        // pan near center
        float sampleShakerL = sampleShaker * 0.6f;
        float sampleShakerR = sampleShaker * 0.6f;

        // 14) Mix all dry signals
        float mixL_dry =
            sampleChordL +
            sampleBassL +
            sampleLeadL +
            sampleOrnamentL +
            sampleKickL +
            sampleSnareL +
            sampleHatL +
            sampleWindL +
            sampleShakerL;

        float mixR_dry =
            sampleChordR +
            sampleBassR +
            sampleLeadR +
            sampleOrnamentR +
            sampleKickR +
            sampleSnareR +
            sampleHatR +
            sampleWindR +
            sampleShakerR;

        // 15) Multi-Tap Delay (2 taps) for reverb-like tail
        int tapOffset1 = int(0.05 * SAMPLE_RATE);  // 50ms
        int tapOffset2 = int(0.12 * SAMPLE_RATE);  // 120ms
        int readIndex1 = (writeIndex + ECHO_BUFFER_SIZE - tapOffset1) % ECHO_BUFFER_SIZE;
        int readIndex2 = (writeIndex + ECHO_BUFFER_SIZE - tapOffset2) % ECHO_BUFFER_SIZE;

        float delayL1 = delayBufferL[readIndex1];
        float delayL2 = delayBufferL[readIndex2];
        float delayR1 = delayBufferR[readIndex1];
        float delayR2 = delayBufferR[readIndex2];

        // Write combined feedback + dry into buffer
        float fbMixL = mixL_dry + delayL1 * 0.5f + delayL2 * 0.3f;
        float fbMixR = mixR_dry + delayR1 * 0.5f + delayR2 * 0.3f;
        delayBufferL[writeIndex] = clampFloat(fbMixL, -1.0f, 1.0f);
        delayBufferR[writeIndex] = clampFloat(fbMixR, -1.0f, 1.0f);
        writeIndex = (writeIndex + 1) % ECHO_BUFFER_SIZE;

        // Final output is dry + scaled delayed taps for spaciousness
        float outL = clampFloat(mixL_dry + delayL1 * 0.4f + delayL2 * 0.2f, -1.0f, 1.0f);
        float outR = clampFloat(mixR_dry + delayR1 * 0.4f + delayR2 * 0.2f, -1.0f, 1.0f);

        // 16) Final cross-stereo width adjustment based on player X
        float width = clampFloat(px * 0.8f + 0.2f, 0.0f, 1.0f);
        float mid = (outL + outR) * 0.5f;
        float side = (outR - outL) * 0.5f * width;
        out[2 * i] = clampFloat(mid - side, -1.0f, 1.0f);
        out[2 * i + 1] = clampFloat(mid + side, -1.0f, 1.0f);
    }
}

// Call once at initialization to seed RNG
void seedNoiseGenerator() {
    srand(static_cast<unsigned>(time(nullptr)));
}
