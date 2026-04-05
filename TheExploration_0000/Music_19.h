#pragma once

#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <ctime>
#include <atomic>
#include "miniaudio.h"

// If you prefer M_PI, uncomment the next line instead of defining PI yourself:
// #define _USE_MATH_DEFINES

//==============================================================================
// Simple PI constants (in case M_PI isn’t available)
static constexpr double PI = 3.14159265358979323846;
static constexpr double TWO_PI = 2.0 * PI;

//==============================================================================
// Utility: clamp a float between lo and hi
static float clampFloat(float v, float lo, float hi) {
    return (v < lo) ? lo : (v > hi) ? hi : v;
}

// A bright “space” pentatonic major scale (5 notes) and a shimmering Dorian mode
constexpr int SPACE_SCALE_NOTES = 5;
static const double spacePentatonic[SPACE_SCALE_NOTES] = {
    261.63, 329.63, 392.00, 523.25, 659.25  // C, E, G, C5, E5
};
constexpr int DORIAN_NOTES = 7;
static const double dorianScale[DORIAN_NOTES] = {
    293.66, 329.63, 349.23, 392.00, 440.00, 493.88, 523.25  // D Dorian
};

// Simple LCG noise for randomness
static uint32_t lcgState = 1;
static float nextNoiseFloat() {
    lcgState = 1664525u * lcgState + 1013904223u;
    return float(((lcgState >> 16) & 0xFFFF) / 65535.0 * 2.0 - 1.0);
}

//==============================================================================
// Reverb buffer for a cosmic echo effect
constexpr int REVERB_BUFFER_SIZE = 96000; // ~2 seconds @ 48kHz
static float reverbBufferL[REVERB_BUFFER_SIZE] = { 0 };
static float reverbBufferR[REVERB_BUFFER_SIZE] = { 0 };
static int reverbWriteIndex = 0;

// One-pole filter: lowpass or highpass
struct OnePole {
    float a0, b1, z1;
    OnePole() : a0(1.0f), b1(0.0f), z1(0.0f) {}
    inline float process(float x) {
        float y = a0 * x + b1 * z1;
        z1 = y;
        return y;
    }
    inline void setLowpass(float cutoffFreq, unsigned sampleRate) {
        float x = expf(-2.0f * float(PI) * cutoffFreq / float(sampleRate));
        b1 = x;
        a0 = 1.0f - x;
    }
    inline void setHighpass(float cutoffFreq, unsigned sampleRate) {
        float x = expf(-2.0f * float(PI) * cutoffFreq / float(sampleRate));
        b1 = -x;
        a0 = (1.0f + x) * 0.5f;
    }
};

// Simple exponential envelope
struct Envelope {
    float value;
    float decay;
    bool active;
    Envelope() : value(0.0f), decay(0.998f), active(false) {}
    inline void trigger(float initial = 1.0f, float decayRate = 0.998f) {
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

//==============================================================================
// Global atomic player position (set these from your game loop):
extern std::atomic<float> g_playerPosX;
extern std::atomic<float> g_playerPosY;
extern std::atomic<float> g_playerPosZ;

// Seed the noise generator once at startup
inline void seedNoiseGenerator() {
    srand(static_cast<unsigned>(time(nullptr)));
    lcgState = rand();
}

//==============================================================================
// Audio callback: “Space Synth” procedural music reacting to player position
void audio_callback(ma_device* /*device*/, void* pOutput, const void* /*pInput*/, ma_uint32 frameCount) {
    float* out = static_cast<float*>(pOutput);

    // Read player position (assumed in [-1, +1] or similar)
    float px = g_playerPosX.load(std::memory_order_relaxed);
    float py = g_playerPosY.load(std::memory_order_relaxed);
    float pz = g_playerPosZ.load(std::memory_order_relaxed);

    // Persistent state between calls
    static double phaseArp = 0.0;
    static double phasePad[4] = { 0.0, 0.0, 0.0, 0.0 };
    static double phaseLead = 0.0;
    static double lfoSlow = 0.0;
    static double lfoFast = 0.0;
    static Envelope arpEnv;
    static Envelope padEnv;
    static Envelope leadEnv;

    // Filters for various layers
    static OnePole  arpLPF_L, arpLPF_R;
    static OnePole  padLPF_L, padLPF_R;
    static OnePole  leadHPF_L, leadHPF_R;
    static OnePole  hatHPF_L, hatHPF_R;      // ?? Declare the hi?hat filters here
    static OnePole  reverbLPF_L, reverbLPF_R;

    const unsigned SAMPLE_RATE = AUDIO_SAMPLE_RATE;

    // React to player movement: trigger new envelopes every ~3 units of movement
    static float prevPx = px, prevPy = py, prevPz = pz;
    static float distAccum = 0.0f;
    {
        float dx = px - prevPx;
        float dy = py - prevPy;
        float dz = pz - prevPz;
        float traveled = sqrtf(dx * dx + dy * dy + dz * dz);
        distAccum += traveled;
        prevPx = px; prevPy = py; prevPz = pz;
        if (distAccum >= 3.0f) {
            distAccum -= 3.0f;
            arpEnv.trigger(1.0f, clampFloat(0.995f - 0.0005f * fabs(pz), 0.98f, 0.998f));
            padEnv.trigger(1.0f, clampFloat(0.999f - 0.0002f * fabs(py), 0.995f, 0.9995f));
            leadEnv.trigger(1.0f, 0.995f);
        }
    }

    // Main sample loop
    for (ma_uint32 i = 0; i < frameCount; ++i) {
        // 1) Update LFOs
        lfoSlow += 0.005 + 0.005 * px;
        if (lfoSlow >= 1.0) lfoSlow -= 1.0;
        lfoFast += 0.02 + 0.01 * py;
        if (lfoFast >= 1.0) lfoFast -= 1.0;

        // 2) Depth-based filter
        float filterDepth = clampFloat((pz + 1.0f) * 0.5f, 0.1f, 1.0f);
        float tempoMod = 0.5f + 0.5f * sin(px * 2.0f);

        // 3) Arpeggio (pentatonic, 4 notes/sec base)
        double arpRate = 4.0 * tempoMod;
        phaseArp += arpRate / SAMPLE_RATE;
        if (phaseArp >= SPACE_SCALE_NOTES) phaseArp -= SPACE_SCALE_NOTES;
        int arpIndex = static_cast<int>(floor(phaseArp)) % SPACE_SCALE_NOTES;
        double freqArp = spacePentatonic[arpIndex] * (1.0 + 0.2 * sin(lfoFast * TWO_PI));
        static double arpPhase = 0.0;
        arpPhase += freqArp / SAMPLE_RATE;
        if (arpPhase >= 1.0) arpPhase -= 1.0;
        float rawArp = float(sin(arpPhase * TWO_PI));
        float arpGain = arpEnv.process() * 0.6f;
        float arpFilteredL, arpFilteredR;
        {
            float cutoff = 400.0f + filterDepth * 2000.0f;
            arpLPF_L.setLowpass(cutoff * (1.0f + 0.1f * sin(lfoSlow * TWO_PI)), SAMPLE_RATE);
            arpLPF_R.setLowpass(cutoff * (1.0f - 0.1f * sin(lfoSlow * TWO_PI)), SAMPLE_RATE);
            arpFilteredL = arpLPF_L.process(rawArp * arpGain);
            arpFilteredR = arpLPF_R.process(rawArp * arpGain);
        }

        // 4) Pad (4 detuned saws in Dorian)
        float padSumL = 0.0f, padSumR = 0.0f;
        if (padEnv.active) {
            float padLevel = padEnv.process();
            double detune[4] = { -0.02, 0.0, 0.02, 0.04 };
            for (int p = 0; p < 4; ++p) {
                double base = dorianScale[0] * (1.0 + detune[p]);
                phasePad[p] += base / SAMPLE_RATE;
                if (phasePad[p] >= 1.0) phasePad[p] -= 1.0;
                float saw = float((phasePad[p] * 2.0 - 1.0));
                padSumL += saw * (0.15f * padLevel);
                padSumR += saw * (0.15f * padLevel);
            }
            float padCut = 200.0f + filterDepth * 1500.0f + 200.0f * sin(lfoSlow * TWO_PI);
            padLPF_L.setLowpass(padCut, SAMPLE_RATE);
            padLPF_R.setLowpass(padCut * 1.05f, SAMPLE_RATE);
            padSumL = padLPF_L.process(padSumL * 0.8f);
            padSumR = padLPF_R.process(padSumR * 0.8f);
        }

        // 5) Lead (sine, occasional Dorian note)
        float leadSampleL = 0.0f, leadSampleR = 0.0f;
        if (leadEnv.active) {
            double envLevel = leadEnv.process();
            static double prevLeadFreq = dorianScale[2];
            if (i == 0 && nextNoiseFloat() > 0.98f) {
                int idx = rand() % DORIAN_NOTES;
                prevLeadFreq = dorianScale[idx];
            }
            double currLeadFreq = prevLeadFreq * (1.0 + 0.1 * sin(lfoFast * TWO_PI));
            phaseLead += currLeadFreq / SAMPLE_RATE;
            if (phaseLead >= 1.0) phaseLead -= 1.0;
            float rawLead = float(sin(phaseLead * TWO_PI)) * float(envLevel);
            // High?pass for brightness
            leadHPF_L.setHighpass(500.0f + 200.0f * sin(lfoSlow * TWO_PI), SAMPLE_RATE);
            leadHPF_R.setHighpass(500.0f + 200.0f * cos(lfoSlow * TWO_PI), SAMPLE_RATE);
            float hl = leadHPF_L.process(rawLead * 0.7f);
            float hr = leadHPF_R.process(rawLead * 0.7f);
            // Pan by Y position
            float pan = 0.5f + 0.5f * py;
            leadSampleL = hl * (1.0f - pan);
            leadSampleR = hr * pan;
        }

        // 6) Cosmic “sparkle” noise bursts
        float sparkleL = 0.0f, sparkleR = 0.0f;
        if (nextNoiseFloat() > (0.9995f - filterDepth * 0.0002f)) {
            float burst = nextNoiseFloat() * 0.2f;
            float sparkleEnv = 1.0f;
            sparkleEnv *= 0.96f;
            sparkleL = burst * sparkleEnv * 0.5f;
            sparkleR = burst * sparkleEnv * 0.5f;
        }

        // 7) Mix dry layers
        float mixL_dry = arpFilteredL + padSumL + leadSampleL + sparkleL;
        float mixR_dry = arpFilteredR + padSumR + leadSampleR + sparkleR;

        // 8) Multi?tap cosmic reverb
        float revL = 0.0f, revR = 0.0f;
        {
            int tapOffsets[4] = {
                int(0.12 * SAMPLE_RATE),  // 120ms
                int(0.25 * SAMPLE_RATE),  // 250ms
                int(0.5 * SAMPLE_RATE),  // 500ms
                int(0.9 * SAMPLE_RATE)   // 900ms
            };
            float gains[4] = { 0.6f, 0.4f, 0.25f, 0.15f };
            for (int t = 0; t < 4; ++t) {
                int readIdx = (reverbWriteIndex + REVERB_BUFFER_SIZE - tapOffsets[t]) % REVERB_BUFFER_SIZE;
                float dL = reverbBufferL[readIdx];
                float dR = reverbBufferR[readIdx];
                revL += dL * gains[t];
                revR += dR * gains[t];
            }
            float fbL = mixL_dry + revL * (0.35f + 0.1f * sin(lfoSlow * TWO_PI));
            float fbR = mixR_dry + revR * (0.35f + 0.1f * cos(lfoSlow * TWO_PI));
            reverbBufferL[reverbWriteIndex] = clampFloat(fbL, -1.0f, 1.0f);
            reverbBufferR[reverbWriteIndex] = clampFloat(fbR, -1.0f, 1.0f);
            reverbWriteIndex = (reverbWriteIndex + 1) % REVERB_BUFFER_SIZE;
        }
        float outL = clampFloat(mixL_dry + revL * 0.3f, -1.0f, 1.0f);
        float outR = clampFloat(mixR_dry + revR * 0.3f, -1.0f, 1.0f);

        // 9) Final stereo?width (based on player X)
        float width = clampFloat(px * 0.8f + 0.2f, 0.0f, 1.0f);
        float mid = 0.5f * (outL + outR);
        float side = 0.5f * (outR - outL) * width;
        float rotate = 0.5f + 0.5f * sin(lfoFast * TWO_PI);
        float finalL = clampFloat(mid - side * rotate, -1.0f, 1.0f);
        float finalR = clampFloat(mid + side * rotate, -1.0f, 1.0f);

        out[2 * i] = finalL;
        out[2 * i + 1] = finalR;
    }
}
