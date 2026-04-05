#pragma once

#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <ctime>
#include <atomic>


// -----------------------------------------------------------------------------
// Basic utilities
// -----------------------------------------------------------------------------
static float clampFloat(float v, float lo, float hi) {
    return (v < lo) ? lo : (v > hi) ? hi : v;
}

// Linear congruential generator for smooth noise
static uint32_t lcgState = 1;
static float nextNoiseFloat() {
    lcgState = 1664525u * lcgState + 1013904223u;
    return float(((lcgState >> 16) & 0xFFFF) / 65535.0 * 2.0 - 1.0);
}

// -----------------------------------------------------------------------------
// Scales (for bright, "spacey" chords and melodies)
// -----------------------------------------------------------------------------
constexpr int SCALE_NOTES = 8;
static const double ionianScale[SCALE_NOTES] = {
    261.63, // C4
    293.66, // D4
    329.63, // E4
    349.23, // F4
    392.00, // G4
    440.00, // A4
    493.88, // B4
    523.25  // C5
};
static const double lydianScale[SCALE_NOTES] = {
    261.63, // C4
    293.66, // D4
    329.63, // E4
    369.99, // F#4 (Lydian characteristic)
    392.00, // G4
    440.00, // A4
    493.88, // B4
    523.25  // C5
};

// -----------------------------------------------------------------------------
// A simple one-pole filter (can be lowpass or highpass)
// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
// Envelope generator (simple exponential decay)
// -----------------------------------------------------------------------------
struct Envelope {
    float value;
    float decay;
    bool active;
    Envelope() : value(0.0f), decay(0.995f), active(false) {}
    inline void trigger(float initial = 1.0f, float decayRate = 0.995f) {
        value = initial;
        decay = decayRate;
        active = true;
    }
    inline float process() {
        if (!active) return 0.0f;
        float out = value;
        value *= decay;
        if (value < 0.001f) {
            active = false;
            value = 0.0f;
        }
        return out;
    }
};

// -----------------------------------------------------------------------------
// Global atomic player position (to be updated by game logic elsewhere)
// -----------------------------------------------------------------------------
extern std::atomic<float> g_playerPosX;
extern std::atomic<float> g_playerPosY;
extern std::atomic<float> g_playerPosZ;

// -----------------------------------------------------------------------------
// Reverb buffer for a spacious “cosmic” feel
// -----------------------------------------------------------------------------
constexpr int REVERB_BUFFER_SIZE = 96000; // 2 seconds @ 48kHz
static float reverbBufferL[REVERB_BUFFER_SIZE] = { 0 };
static float reverbBufferR[REVERB_BUFFER_SIZE] = { 0 };
static int reverbWriteIndex = 0;

// -----------------------------------------------------------------------------
// Audio callback: “Space Synth” variation reacting to player position
// -----------------------------------------------------------------------------
void audio_callback(ma_device* /*device*/, void* pOutput, const void* /*pInput*/, ma_uint32 frameCount) {
    float* out = static_cast<float*>(pOutput);

    // Read player position
    float px = g_playerPosX.load(std::memory_order_relaxed);
    float py = g_playerPosY.load(std::memory_order_relaxed);
    float pz = g_playerPosZ.load(std::memory_order_relaxed);

    // Persistent state across calls
    static double phaseLead = 0.0;
    static double phaseBass = 0.0;
    static double stepCounter = 0.0;
    static double chordTimeAcc = 0.0;
    static int chordIndex = 0;
    static double chordEnv = 0.0;
    static double chordPhase[3] = { 0.0, 0.0, 0.0 };
    static double lfoPhase1 = 0.0;
    static double lfoPhase2 = 0.0;

    // Drum envelopes
    static Envelope kickEnv;
    static Envelope snareEnv;
    static Envelope hatEnv;
    static double kickPhase = 0.0;

    // Simple noise-based “space shimmer” envelopes
    struct Shimmer {
        bool active;
        double phase;
        double freq;
        double env;
    };
    static Shimmer shimmers[3] = {};

    // Filters
    static OnePole chordLPF_L, chordLPF_R;
    static OnePole leadLPF_L, leadLPF_R;
    static OnePole bassLPF_L, bassLPF_R;
    static OnePole shimmerLPF;
    static OnePole windHPF_L, windHPF_R;

    // Spatial pan LFO
    static double spatialPanPhase = 0.0;

    const double PI = 3.14159265358979323846;
    const double TWO_PI = 2.0 * PI;
    const unsigned SAMPLE_RATE = AUDIO_SAMPLE_RATE;

    // Loop over each sample
    for (ma_uint32 i = 0; i < frameCount; ++i) {
        // --- LFO updates ---
        spatialPanPhase += 0.005 / SAMPLE_RATE;
        if (spatialPanPhase >= 1.0) spatialPanPhase -= 1.0;
        lfoPhase1 += 0.02 / SAMPLE_RATE;
        if (lfoPhase1 >= 1.0) lfoPhase1 -= 1.0;
        lfoPhase2 += 0.03 / SAMPLE_RATE;
        if (lfoPhase2 >= 1.0) lfoPhase2 -= 1.0;

        // --- Spatial factors from player Z (depth) and X (left-right) ---
        float depthFactor = clampFloat(pz * 0.3f + 0.7f, 0.2f, 1.0f);   // 0.2–1.0
        float widthFactor = clampFloat(px * 0.4f + 0.6f, 0.1f, 1.0f);   // 0.1–1.0

        // --- Tempo modulation by player Y (height) ---
        double tempoBase = 0.8;
        double tempoVar = 0.4 * sin(py * 2.0 + TWO_PI * lfoPhase1);
        double tempoFactor = clampFloat(float(tempoBase + tempoVar), 0.3f, 2.0f);

        // --- Chord progression every 1.2 seconds real time, sped by tempoFactor ---
        chordTimeAcc += tempoFactor / SAMPLE_RATE;
        if (chordTimeAcc >= 1.2) {
            chordTimeAcc -= 1.2;
            chordIndex = (chordIndex + 1) % 4;
            chordEnv = 1.0; // reset chord envelope
        }
        chordEnv *= 0.9975; // smooth decay over time

        // --- Determine current scale (Ionian when above ground, Lydian when below) ---
        const double* currentScale = (py > 0.0f) ? ionianScale : lydianScale;
        // Pick root of chord based on chordIndex
        int rootIdx = (chordIndex * 2) % SCALE_NOTES; // cycles: C, E, G, B…
        double freqRoot = currentScale[rootIdx] * 0.5;                          // one octave down for spacey bass
        double freqThird = currentScale[(rootIdx + 2) % SCALE_NOTES] * 0.5;     // major third
        double freqSeventh = currentScale[(rootIdx + 6) % SCALE_NOTES] * 0.5;   // major seventh for dreamy color

        // --- Update chord oscillator phases ---
        chordPhase[0] += freqRoot * (1.0 + 0.03 * sin(py * 3.0 + TWO_PI * lfoPhase1)) / SAMPLE_RATE;
        chordPhase[1] += freqThird * (1.0 + 0.03 * sin(pz * 2.5 + TWO_PI * lfoPhase2)) / SAMPLE_RATE;
        chordPhase[2] += freqSeventh * (1.0 + 0.03 * sin(px * 3.5 + TWO_PI * lfoPhase1)) / SAMPLE_RATE;
        for (int k = 0; k < 3; ++k) {
            if (chordPhase[k] >= 1.0) chordPhase[k] -= 1.0;
        }
        // Mix three partials, scaled by chordEnv
        float rawChord = (sin(chordPhase[0] * TWO_PI) +
            sin(chordPhase[1] * TWO_PI) +
            sin(chordPhase[2] * TWO_PI)) / 3.0f
            * float(chordEnv);

        // --- Apply a gentle lowpass filter on chords, cutoff modulated by position X/Z ---
        float cutoffChord = 400.0f + float(0.4 + 0.6 * sin(px * 1.5 + TWO_PI * lfoPhase1)) * 1500.0f * depthFactor;
        chordLPF_L.setLowpass(cutoffChord, SAMPLE_RATE);
        chordLPF_R.setLowpass(cutoffChord * (1.05f + 0.1f * sin(pz * 2.0)), SAMPLE_RATE);
        float sampleChordL = chordLPF_L.process(rawChord * 0.5f * depthFactor);
        float sampleChordR = chordLPF_R.process(rawChord * 0.5f * depthFactor);

        // --- Bass synth: sine wave with slight FM from LFO and player Y ---
        double bassMod = 0.2 * sin(py * TWO_PI * lfoPhase2);
        double freqBass = freqRoot * (0.35 + 0.3 * sin(py * 4.5 + TWO_PI * lfoPhase1));
        phaseBass += clampFloat(float(freqBass * (1.0 + bassMod)), 30.0f, 120.0f) / SAMPLE_RATE;
        if (phaseBass >= 1.0) phaseBass -= 1.0;
        float rawBass = sin(phaseBass * TWO_PI);
        float cutoffBass = 80.0f + float(0.5 + 0.5 * cos(py * 3.0 + TWO_PI * lfoPhase2)) * 400.0f;
        bassLPF_L.setLowpass(cutoffBass, SAMPLE_RATE);
        bassLPF_R.setLowpass(cutoffBass * 1.02f, SAMPLE_RATE);
        float sampleBassL = bassLPF_L.process(rawBass * 0.7f) * 0.6f * depthFactor;
        float sampleBassR = bassLPF_R.process(rawBass * 0.7f) * 0.6f * depthFactor;

        // --- Lead melody: sawtooth-like PWM synth, notes step by stepCounter, reacts to position X/Z ---
        stepCounter += tempoFactor * 1.2 / SAMPLE_RATE;
        if (stepCounter >= SCALE_NOTES) stepCounter -= SCALE_NOTES;
        int noteIndex = static_cast<int>(floor(stepCounter + (pz * 0.2))) % SCALE_NOTES;
        double freqLead = currentScale[noteIndex] *
            (1.0 + 0.08 * sin(TWO_PI * lfoPhase2) + 0.05 * cos(px * 5.0));
        phaseLead += freqLead / SAMPLE_RATE;
        if (phaseLead >= 1.0) phaseLead -= 1.0;
        // wavetable: mix sine and square to get brighter “space” feel
        float saw = float((phaseLead * 2.0 - 1.0));
        float square = (phaseLead < 0.5) ? 1.0f : -1.0f;
        float rawLead = 0.6f * saw + 0.4f * square;
        // Lowpass on lead for cohesion
        float cutoffLead = 600.0f + float(0.5 + 0.5 * sin(py * 2.5 + TWO_PI * lfoPhase1)) * 1200.0f;
        leadLPF_L.setLowpass(cutoffLead, SAMPLE_RATE);
        leadLPF_R.setLowpass(cutoffLead * 1.03f, SAMPLE_RATE);
        // Pan lead left-right based on sin(spatialPanPhase + px)
        float leadPan = 0.5f + 0.5f * cos(TWO_PI * spatialPanPhase + px * 1.2f);
        float sampleLeadL = leadLPF_L.process(rawLead) * (1.0f - leadPan) * 0.35f * widthFactor;
        float sampleLeadR = leadLPF_R.process(rawLead) * leadPan * 0.35f * widthFactor;

        // --- Shimmer bells: occasional bright bursts of filtered noise + sine glissandi ---
        float sampleShimmerL = 0.0f, sampleShimmerR = 0.0f;
        if (nextNoiseFloat() > (0.998f - pz * 0.015f)) {
            // Trigger a new shimmer voice
            for (int s = 0; s < 3; ++s) {
                if (!shimmers[s].active) {
                    shimmers[s].active = true;
                    shimmers[s].freq = 800.0 + (rand() % 200);
                    shimmers[s].phase = 0.0;
                    shimmers[s].env = 1.0;
                    break;
                }
            }
        }
        for (int s = 0; s < 3; ++s) {
            if (shimmers[s].active) {
                shimmers[s].phase += shimmers[s].freq / SAMPLE_RATE;
                if (shimmers[s].phase >= 1.0) shimmers[s].phase -= 1.0;
                // Mix sine and filtered noise
                float bellTone = sin(shimmers[s].phase * TWO_PI) * float(shimmers[s].env);
                float noise = nextNoiseFloat() * float(shimmers[s].env) * 0.3f;
                // Filter shimmer noise to be “icy”
                shimmerLPF.setHighpass(1500.0f, SAMPLE_RATE);
                float filteredNoise = shimmerLPF.process(noise);
                float mix = (bellTone + filteredNoise) * 0.4f;
                // Pan randomly between L/R for depth
                float pan = 0.4f + 0.6f * (nextNoiseFloat() * 0.5f + 0.5f);
                sampleShimmerL += mix * (1.0f - pan);
                sampleShimmerR += mix * pan;
                // Decay envelope
                shimmers[s].env *= 0.992;
                if (shimmers[s].env < 0.002) {
                    shimmers[s].active = false;
                    shimmers[s].env = 0.0;
                }
            }
        }

        // --- “Cosmic wind” layer: filtered Brownian noise modulated by player Z ---
        float rawWind = nextNoiseFloat() * 0.2f * (0.5f + 0.5f * sin(pz * 2.0f + TWO_PI * lfoPhase1));
        float windWet = rawWind * 0.5f * depthFactor;
        float cutoffWindL = 300.0f + float(0.5 + 0.5 * cos(py * 2.5 + TWO_PI * lfoPhase2)) * 300.0f;
        float cutoffWindR = 300.0f + float(0.5 + 0.5 * sin(px * 2.5 + TWO_PI * lfoPhase1)) * 350.0f;
        windHPF_L.setHighpass(cutoffWindL, SAMPLE_RATE);
        windHPF_R.setHighpass(cutoffWindR, SAMPLE_RATE);
        float sampleWindL = windHPF_L.process(windWet) * 0.5f;
        float sampleWindR = windHPF_R.process(windWet) * 0.5f;

        // --- Rhythm sequencing: playful, brighter beats based on distance traveled ---
        static float prevPx = px, prevPy = py, prevPz = pz;
        static float distAccum = 0.0f;
        float dx = px - prevPx;
        float dy = py - prevPy;
        float dz = pz - prevPz;
        float traveled = sqrtf(dx * dx + dy * dy + dz * dz);
        distAccum += traveled;
        prevPx = px;
        prevPy = py;
        prevPz = pz;

        static bool drumPattern = false;
        static double barPhase = 0.0;
        static int prevBeatStep = -1;
        if (distAccum >= 3.0f) {
            distAccum -= 3.0f;
            drumPattern = !drumPattern;
            barPhase = 0.0;
            prevBeatStep = -1;
        }
        barPhase += tempoFactor * 1.0 / SAMPLE_RATE;
        if (barPhase >= 4.0) {
            barPhase -= 4.0;
            prevBeatStep = -1;
        }
        int beatStep = static_cast<int>(floor(barPhase)) % 4;
        if (beatStep != prevBeatStep) {
            prevBeatStep = beatStep;
            // On-beat: kick; off-beat: snare or hat
            if (!drumPattern) {
                if (beatStep == 0) kickEnv.trigger(1.0f, 0.993f);
                if (beatStep == 2) snareEnv.trigger(1.0f, 0.985f);
                hatEnv.trigger(0.5f, 0.95f);
            }
            else {
                if (beatStep == 0 || beatStep == 2) kickEnv.trigger(1.0f, 0.991f);
                if (beatStep == 1 || beatStep == 3) snareEnv.trigger(1.0f, 0.982f);
                hatEnv.trigger(0.4f, 0.93f);
            }
        }
        // Eighth-note hats if pattern is toggled
        double eighthPhase = (barPhase - floor(barPhase)) * 2.0;
        if (drumPattern && eighthPhase < (tempoFactor / SAMPLE_RATE)) {
            hatEnv.trigger(0.3f, 0.92f);
        }

        // --- Percussion synthesis ---
        float sampleKickL = 0.0f, sampleKickR = 0.0f;
        float sampleSnareL = 0.0f, sampleSnareR = 0.0f;
        float sampleHatL = 0.0f, sampleHatR = 0.0f;

        // Kick: low sine thump
        if (kickEnv.active) {
            kickPhase += 60.0 / SAMPLE_RATE;
            if (kickPhase >= 1.0) kickPhase -= 1.0;
            float k = sin(kickPhase * TWO_PI) * kickEnv.process();
            sampleKickL += k * 0.8f * depthFactor;
            sampleKickR += k * 0.8f * depthFactor;
        }
        // Snare: noise + bandpass
        if (snareEnv.active) {
            float noise = nextNoiseFloat() * snareEnv.process();
            snareEnv.decay = clampFloat(snareEnv.decay, 0.97f, 0.995f);
            OnePole snareBP;
            snareBP.setHighpass(1200.0f, SAMPLE_RATE);
            float s = snareBP.process(noise) * 0.6f * depthFactor;
            sampleSnareL += s;
            sampleSnareR += s;
        }
        // Hi-hat: filtered noise clicks
        if (hatEnv.active) {
            float noise = nextNoiseFloat() * hatEnv.process() * 0.4f;
            OnePole hatHPF;
            hatHPF.setHighpass(8000.0f, SAMPLE_RATE);
            float hh = hatHPF.process(noise);
            if ((i & 1) == 0) sampleHatL += hh * 0.4f;
            else             sampleHatR += hh * 0.4f;
        }

        // --- Mix dry signals ---
        float mixL_dry =
            sampleChordL +
            sampleBassL +
            sampleLeadL +
            sampleShimmerL +
            sampleWindL +
            sampleKickL +
            sampleSnareL +
            sampleHatL;

        float mixR_dry =
            sampleChordR +
            sampleBassR +
            sampleLeadR +
            sampleShimmerR +
            sampleWindR +
            sampleKickR +
            sampleSnareR +
            sampleHatR;

        // --- Multi-tap reverb for “cosmic expanse” ---
        int tapOffsets[4] = {
            int(0.08 * SAMPLE_RATE),  // 80ms
            int(0.18 * SAMPLE_RATE),  // 180ms
            int(0.35 * SAMPLE_RATE),  // 350ms
            int(0.65 * SAMPLE_RATE)   // 650ms
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
        float fbMixL = mixL_dry + revL * 0.5f;
        float fbMixR = mixR_dry + revR * 0.5f;
        reverbBufferL[reverbWriteIndex] = clampFloat(fbMixL, -1.0f, 1.0f);
        reverbBufferR[reverbWriteIndex] = clampFloat(fbMixR, -1.0f, 1.0f);
        reverbWriteIndex = (reverbWriteIndex + 1) % REVERB_BUFFER_SIZE;

        float outL_dryrev = clampFloat(mixL_dry + revL * 0.4f, -1.0f, 1.0f);
        float outR_dryrev = clampFloat(mixR_dry + revR * 0.4f, -1.0f, 1.0f);

        // --- Final stereo width and rotation based on player X/Z ---
        float width = clampFloat(px * 0.6f + 0.4f, 0.1f, 1.0f);  // 0.1–1.0
        float mid = (outL_dryrev + outR_dryrev) * 0.5f;
        float side = (outR_dryrev - outL_dryrev) * 0.5f * width;
        float rot = float(0.5f + 0.5f * sin(TWO_PI * spatialPanPhase + pz * 0.3f));
        float finalL = clampFloat(mid - side * rot, -1.0f, 1.0f);
        float finalR = clampFloat(mid + side * rot, -1.0f, 1.0f);

        // Output interleaved stereo
        out[2 * i] = finalL;
        out[2 * i + 1] = finalR;
    }
}

// -----------------------------------------------------------------------------
// Seed random number generator once at program start
// -----------------------------------------------------------------------------
void seedNoiseGenerator() {
    srand(static_cast<unsigned>(time(nullptr)));
}
