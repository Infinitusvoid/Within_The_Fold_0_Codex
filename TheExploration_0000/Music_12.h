#pragma once


static float clampFloat(float v, float lo, float hi) {
    return (v < lo) ? lo : (v > hi) ? hi : v;
}

constexpr int SCALE_NOTES = 8;
// Expanded C minor scale with octave for more melodic variety
static const double cMinorScale[SCALE_NOTES] = {
    261.63, 293.66, 311.13, 349.23, 392.00, 415.30, 466.16, 523.25
};

static uint32_t lcgState = 1;
static float nextNoiseFloat() {
    lcgState = 1664525u * lcgState + 1013904223u;
    return float(((lcgState >> 16) & 0xFFFF) / 65535.0 * 2.0 - 1.0);
}


// Reverb/delay buffer (2 seconds at 48kHz)
constexpr int REVERB_BUFFER_SIZE = 96000;
static float reverbBufferL[REVERB_BUFFER_SIZE] = { 0 };
static float reverbBufferR[REVERB_BUFFER_SIZE] = { 0 };
static int reverbWriteIndex = 0;

// Simple 1-pole filter
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

// Simple exponential envelope
struct Envelope {
    float value;
    float decay;
    bool active;
    Envelope() : value(0.0f), decay(0.999f), active(false) {}
    inline void trigger(float initial = 1.0f, float decayRate = 0.999f) {
        value = initial;
        decay = decayRate;
        active = true;
    }
    inline float process() {
        if (!active) return 0.0f;
        float out = value;
        value *= decay;
        if (value < 0.0005f) {
            active = false;
            value = 0.0f;
        }
        return out;
    }
};

// Audio callback
void audio_callback(ma_device* /*device*/, void* pOutput, const void* /*pInput*/, ma_uint32 frameCount) {
    float* out = static_cast<float*>(pOutput);

    // Listener position
    float px = g_playerPosX.load(std::memory_order_relaxed);
    float py = g_playerPosY.load(std::memory_order_relaxed);
    float pz = g_playerPosZ.load(std::memory_order_relaxed);

    // Persistent state variables
    static double phaseKick = 0.0;
    static double phaseBass = 0.0;
    static double phaseStab = 0.0;
    static double phaseHat = 0.0;
    static double lfoPhase = 0.0;
    static double hatAcc = 0.0;
    static double kickAcc = 0.0;
    static double stabAcc = 0.0;
    static double bassAcc = 0.0;

    // -- NEW: Complex evolving melody --
    static double melodyLFO = 0.0;
    static double melodyPhase[4] = { 0.0, 0.0, 0.0, 0.0 };
    static int melodyPatternIndices[4] = { 0, 2, 4, 6 }; // starting indices in scale
    static Envelope melodyEnv[4]; // one envelope per voice
    static bool melodyTrig[4] = { false, false, false, false };
    static double patternAcc = 0.0;
    static int patternStep = 0;

    static Envelope kickEnv;
    static Envelope stabEnv;
    static Envelope snareEnv;
    static Envelope hatEnv;

    // Filters
    static OnePole stabLPF_L, stabLPF_R;
    static OnePole bassLPF_L, bassLPF_R;
    static OnePole snareHPF_L, snareHPF_R;
    static OnePole hatHPF_L, hatHPF_R;
    static OnePole melodyLPF_L[4], melodyLPF_R[4];
    static OnePole ambientHPF_L, ambientHPF_R;

    // Spatial LFOs for moving sources
    static double spatialLFO1 = 0.0;
    static double spatialLFO2 = 0.0;

    const double PI = 3.14159265358979323846;
    const double TWO_PI = 2.0 * PI;
    const unsigned SAMPLE_RATE = AUDIO_SAMPLE_RATE;

    for (ma_uint32 i = 0; i < frameCount; ++i) {
        // 1) Update global LFOs
        lfoPhase += 0.05 / SAMPLE_RATE;
        if (lfoPhase >= 1.0) lfoPhase -= 1.0;
        spatialLFO1 += 0.02 / SAMPLE_RATE;
        if (spatialLFO1 >= 1.0) spatialLFO1 -= 1.0;
        spatialLFO2 += 0.03 / SAMPLE_RATE;
        if (spatialLFO2 >= 1.0) spatialLFO2 -= 1.0;
        melodyLFO += 0.15 / SAMPLE_RATE;
        if (melodyLFO >= 1.0) melodyLFO -= 1.0;

        // 2) Techno Kick: 4-on-the-floor at 125 BPM
        kickAcc += 125.0 / 60.0 / SAMPLE_RATE;
        if (kickAcc >= 1.0) {
            kickAcc -= 1.0;
            kickEnv.trigger(1.0f, 0.995f);
        }

        // 3) Hi-Hat at 16th notes
        hatAcc += 125.0 / 60.0 * 4.0 / SAMPLE_RATE;
        if (hatAcc >= 1.0) {
            hatAcc -= 1.0;
            hatEnv.trigger(0.3f, 0.92f);
        }

        // 4) Bassline: 4-step pattern per bar (bar = 0.48s at 125 BPM)
        bassAcc += 125.0 / 60.0 / SAMPLE_RATE;
        if (bassAcc >= 0.25) {
            bassAcc -= 0.25;
            // Trigger nothing here; continuous bass wave
        }

        // 5) Stab/Clap on 2 & 4
        stabAcc += 125.0 / 60.0 / SAMPLE_RATE;
        if (stabAcc >= 0.5) {
            stabAcc -= 0.5;
            stabEnv.trigger(0.8f, 0.990f);
            snareEnv.trigger(1.0f, 0.985f);
        }

        // 6) New: Melodic pattern sequencing
        // Use melodyLFO to drive a 8-step pattern (each step = 0.125)
        patternAcc += 125.0 / 60.0 * 8.0 / SAMPLE_RATE; // 8 triggers per bar
        if (patternAcc >= 1.0) {
            patternAcc -= 1.0;
            patternStep = (patternStep + 1) % 8;
            // For four simultaneous voices, trigger on certain steps
            for (int v = 0; v < 4; ++v) {
                // Simple Euclidean pattern: voice v plays on pattern steps where (step + offset) % (v+2) == 0
                if ((patternStep + v) % (v + 2) == 0) {
                    melodyTrig[v] = true;
                }
            }
        }

        // 7) Generate Kick (sine burst)
        float sampleKick = 0.0f;
        if (kickEnv.active) {
            phaseKick += 60.0 / SAMPLE_RATE;
            if (phaseKick >= 1.0) phaseKick -= 1.0;
            sampleKick = sin(phaseKick * TWO_PI) * kickEnv.process() * 0.9f;
        }

        // 8) Generate Snare/Clap (filtered noise)
        float sampleSnare = 0.0f;
        if (snareEnv.active) {
            float noise = nextNoiseFloat() * snareEnv.process();
            snareHPF_L.setHighpass(2000.0f, SAMPLE_RATE);
            float s = snareHPF_L.process(noise);
            sampleSnare = s * 0.6f;
        }

        // 9) Generate Hi-Hat (filtered noise)
        float sampleHat = 0.0f;
        if (hatEnv.active) {
            float noise = nextNoiseFloat() * hatEnv.process();
            hatHPF_L.setHighpass(8000.0f, SAMPLE_RATE);
            float h = hatHPF_L.process(noise);
            sampleHat = h * 0.4f;
        }

        // 10) Generate Bassline (sawtooth/square hybrid)
        static int bassStep = 0;
        if (bassAcc < 0.0001) {
            bassStep = (bassStep + 1) % 4;
        }
        double bassFreqs[4] = { 110.0, 130.81, 98.0, 146.83 }; // C2, C#2, B1, D2
        double freqBass = bassFreqs[bassStep];
        phaseBass += freqBass / SAMPLE_RATE;
        if (phaseBass >= 1.0) phaseBass -= 1.0;
        float rawBass = (sin(phaseBass * TWO_PI) > 0.0f) ? 1.0f : -1.0f; // square
        // Mix with a saw component
        double phaseSaw = fmod(phaseBass * 2.0, 1.0);
        float sawBass = float(phaseSaw * 2.0 - 1.0);
        float mixedBass = rawBass * 0.5f + sawBass * 0.5f;
        bassLPF_L.setLowpass(500.0f, SAMPLE_RATE);
        float sampleBass = bassLPF_L.process(mixedBass * 0.7f);

        // 11) Generate Stab (saw pulse)
        float sampleStab = 0.0f;
        if (stabEnv.active) {
            double stabFreq = 440.0 * (1.0 + 0.2 * sin(lfoPhase * TWO_PI)); // modulate tune
            phaseStab += stabFreq / SAMPLE_RATE;
            if (phaseStab >= 1.0) phaseStab -= 1.0;
            float saw = float((phaseStab * 2.0 - 1.0));
            stabLPF_L.setLowpass(2000.0f, SAMPLE_RATE);
            sampleStab = stabLPF_L.process(saw) * stabEnv.process() * 0.5f;
        }

        // 12) Generate Complex Melody (4 voices)
        float sampleMelodyL = 0.0f, sampleMelodyR = 0.0f;
        for (int v = 0; v < 4; ++v) {
            if (melodyTrig[v]) {
                // Choose a random interval shift based on position
                int shift = int(floor(py * 2.0f)) % SCALE_NOTES;
                if (shift < 0) shift += SCALE_NOTES;
                melodyPatternIndices[v] = (melodyPatternIndices[v] + shift + 1) % SCALE_NOTES;
                melodyEnv[v].trigger(1.0f, 0.995f);
                melodyTrig[v] = false;
            }
            if (melodyEnv[v].active) {
                double freqMel = cMinorScale[melodyPatternIndices[v]] * (1.0 + 0.1 * sin(pz * 5.0));
                melodyPhase[v] += freqMel / SAMPLE_RATE;
                if (melodyPhase[v] >= 1.0) melodyPhase[v] -= 1.0;
                // Triangle wave for voice v
                float tri = float(2.0f * fabsf(float(melodyPhase[v] * 2.0 - 1.0f)) - 1.0f);
                // Pan each voice differently in 3D (use spatialLFO1+v offset)
                float panPos = 0.5f + 0.5f * sinf(float((spatialLFO1 + v * 0.25) * TWO_PI + px));
                // Lowpass for smoothing
                melodyLPF_L[v].setLowpass(1500.0f + float(500.0 * sin(v + lfoPhase * TWO_PI)), SAMPLE_RATE);
                melodyLPF_R[v].setLowpass(1500.0f + float(500.0 * cos(v + lfoPhase * TWO_PI)), SAMPLE_RATE);
                float voiceSample = tri * melodyEnv[v].process() * 0.4f;
                float vl = melodyLPF_L[v].process(voiceSample) * (1.0f - panPos);
                float vr = melodyLPF_R[v].process(voiceSample) * panPos;
                sampleMelodyL += vl;
                sampleMelodyR += vr;
            }
        }

        // 13) Ambient “Space Dust” layer (high-passed noise)
        float rawDust = nextNoiseFloat() * 0.15f;
        float cutoffDust = 2000.0f + float(0.5 + 0.5 * sin(lfoPhase * TWO_PI)) * 2000.0f;
        ambientHPF_L.setHighpass(cutoffDust, SAMPLE_RATE);
        float sampleDust = ambientHPF_L.process(rawDust);
        // Position dust overhead (pz+5)
        auto computePanAtten = [&](float sx, float sy, float sz, float input) {
            float dx = sx - px;
            float dy = sy - py;
            float dz = sz - pz;
            float dist = sqrtf(dx * dx + dy * dy + dz * dz);
            float atten = 1.0f / (1.0f + dist * 0.5f);
            float angle = atan2f(dy, dx);
            float pan = 0.5f * (1.0f + sinf(angle));
            float l = input * atten * (1.0f - pan);
            float r = input * atten * pan;
            return std::pair<float, float>(l, r);
            };
        float dustX = px;
        float dustY = py;
        float dustZ = pz + 5.0f;
        auto dustLR = computePanAtten(dustX, dustY, dustZ, sampleDust);

        // 14) Spatial positions for each techno element
        // Kick centered slightly in front
        float kickX = px;
        float kickY = py;
        float kickZ = pz + 1.0f;
        // Snare moves in same circle as before
        float snareX = px + 2.0f * float(cos(spatialLFO1 * TWO_PI));
        float snareY = py + 2.0f * float(sin(spatialLFO1 * TWO_PI));
        float snareZ = pz + 1.5f;
        // Hi-hat opposite circle
        float hatX = px + 2.0f * float(cos((spatialLFO1 + 0.5) * TWO_PI));
        float hatY = py + 2.0f * float(sin((spatialLFO1 + 0.5) * TWO_PI));
        float hatZ = pz + 1.5f;
        // Bass rotates on X
        float bassX = px + 3.0f * float(cos(spatialLFO2 * TWO_PI));
        float bassY = py;
        float bassZ = pz + 2.0f;
        // Stab moves in Y
        float stabX = px;
        float stabY = py + 3.0f * float(cos((spatialLFO2 + 0.25) * TWO_PI));
        float stabZ = pz + 2.5f;
        // Melody voices each orbit differently
        float melX[4], melY[4], melZ[4];
        for (int v = 0; v < 4; ++v) {
            melX[v] = px + 2.5f * float(cos((spatialLFO2 + v * 0.25) * TWO_PI));
            melY[v] = py + 2.5f * float(sin((spatialLFO2 + v * 0.25) * TWO_PI));
            melZ[v] = pz + 2.5f + 0.5f * v; // spread in Z
        }

        // 15) Mix and spatialize each dry source
        auto kickLR = computePanAtten(kickX, kickY, kickZ, sampleKick);
        auto snareLR = computePanAtten(snareX, snareY, snareZ, sampleSnare);
        auto hatLR = computePanAtten(hatX, hatY, hatZ, sampleHat);
        auto bassLR = computePanAtten(bassX, bassY, bassZ, sampleBass);
        auto stabLR = computePanAtten(stabX, stabY, stabZ, sampleStab);

        float mixL_dry = kickLR.first + snareLR.first + hatLR.first +
            bassLR.first + stabLR.first +
            dustLR.first + sampleMelodyL;
        float mixR_dry = kickLR.second + snareLR.second + hatLR.second +
            bassLR.second + stabLR.second +
            dustLR.second + sampleMelodyR;

        // 16) 3D Reverb / Multi-tap delay
        int tapOffsets[4] = {
            int(0.1 * SAMPLE_RATE),  // 100ms
            int(0.23 * SAMPLE_RATE), // 230ms
            int(0.47 * SAMPLE_RATE), // 470ms
            int(0.85 * SAMPLE_RATE)  // 850ms
        };
        float revL = 0.0f, revR = 0.0f;
        for (int t = 0; t < 4; ++t) {
            int readIndex = (reverbWriteIndex + REVERB_BUFFER_SIZE - tapOffsets[t]) % REVERB_BUFFER_SIZE;
            float dL = reverbBufferL[readIndex];
            float dR = reverbBufferR[readIndex];
            float gain = (t == 0) ? 0.4f : (t == 1) ? 0.3f : (t == 2) ? 0.2f : 0.1f;
            revL += dL * gain;
            revR += dR * gain;
        }
        float fbMixL = mixL_dry + revL * 0.3f;
        float fbMixR = mixR_dry + revR * 0.3f;
        reverbBufferL[reverbWriteIndex] = clampFloat(fbMixL, -1.0f, 1.0f);
        reverbBufferR[reverbWriteIndex] = clampFloat(fbMixR, -1.0f, 1.0f);
        reverbWriteIndex = (reverbWriteIndex + 1) % REVERB_BUFFER_SIZE;

        float outL = clampFloat(mixL_dry + revL * 0.2f, -1.0f, 1.0f);
        float outR = clampFloat(mixR_dry + revR * 0.2f, -1.0f, 1.0f);

        // 17) Final stereo width adjustment based on listener Z
        float width = clampFloat(1.0f - pz * 0.2f, 0.5f, 1.0f);
        float mid = (outL + outR) * 0.5f;
        float side = (outR - outL) * 0.5f * width;
        float finalL = clampFloat(mid - side, -1.0f, 1.0f);
        float finalR = clampFloat(mid + side, -1.0f, 1.0f);

        out[2 * i] = finalL;
        out[2 * i + 1] = finalR;
    }
}

// Seed RNG once at start
void seedNoiseGenerator() {
    srand(static_cast<unsigned>(time(nullptr)));
}
