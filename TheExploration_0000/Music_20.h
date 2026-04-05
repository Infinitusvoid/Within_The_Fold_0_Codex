#pragma once

#pragma once

#include <cmath>
#include <cstdint>
#include <atomic>
#include <cstdlib>
#include <ctime>
#include "miniaudio.h"  // Assume miniaudio or similar is used for AUDIO_SAMPLE_RATE

//-------------------------------------------------------------------------------------------------
// Utility functions & constants
//-------------------------------------------------------------------------------------------------
static float clampFloat(float v, float lo, float hi) {
    return (v < lo) ? lo : (v > hi) ? hi : v;
}

constexpr int SCALE_NOTES = 8;
// Use a dreamy Lydian?like scale for a more "spacey" feel
static const double lydianScale[SCALE_NOTES] = {
    261.63, // C4
    293.66, // D4
    329.63, // E4
    369.99, // F#4 (raised 4th for Lydian)
    392.00, // G4
    440.00, // A4
    493.88, // B4
    523.25  // C5
};

// Basic linear congruential generator for noise
static uint32_t lcgState = 1;
static float nextNoiseFloat() {
    lcgState = 1664525u * lcgState + 1013904223u;
    return float(((lcgState >> 16) & 0xFFFF) / 65535.0 * 2.0 - 1.0);
}

//-------------------------------------------------------------------------------------------------
// Simple 1?pole filter
//-------------------------------------------------------------------------------------------------
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

//-------------------------------------------------------------------------------------------------
// Envelope generator (simple exponential decay)
//-------------------------------------------------------------------------------------------------
struct Envelope {
    float value;
    float decay;
    bool active;
    Envelope() : value(0.0f), decay(0.999f), active(false) {}
    inline void trigger(float initial = 1.0f, float decayRate = 0.995f) {
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

//-------------------------------------------------------------------------------------------------
// Audio callback: Space?Synth Procedural Music reacting to player position
//-------------------------------------------------------------------------------------------------
void audio_callback(ma_device* /*device*/, void* pOutput, const void* /*pInput*/, ma_uint32 frameCount) {
    float* out = static_cast<float*>(pOutput);

    // Read player position (normalized in some game world space; expected in [-1, +1])
    float px = g_playerPosX.load(std::memory_order_relaxed);
    float py = g_playerPosY.load(std::memory_order_relaxed);
    float pz = g_playerPosZ.load(std::memory_order_relaxed);

    //-------------------------------------------------------------------------------------------------
    // Persistent state across calls
    //-------------------------------------------------------------------------------------------------
    static double phaseLead = 0.0;
    static double phasePad[4] = { 0.0, 0.0, 0.0, 0.0 };
    static double padEnv = 0.0;
    static double padEnvDecay = 0.9995;
    static double arpPhase = 0.0;
    static double arpEnv = 0.0;
    static int arpStep = 0;
    static double arcLFOPhase = 0.0;
    static double shimmerLFOPhase = 0.0;

    // Filter objects
    static OnePole leadLPF_L, leadLPF_R;
    static OnePole padLPF_L, padLPF_R;
    static OnePole envLPF;
    static OnePole shimmerHPF_L, shimmerHPF_R;

    // Reverb buffer for a lush “spacey” ambiance (multi?tap)
    constexpr int REVERB_BUFFER_SIZE = 96000; // 2 seconds @ 48kHz
    static float reverbBufferL[REVERB_BUFFER_SIZE] = { 0 };
    static float reverbBufferR[REVERB_BUFFER_SIZE] = { 0 };
    static int reverbWriteIndex = 0;

    const double PI = 3.14159265358979323846;
    const double TWO_PI = 2.0 * PI;
    const unsigned SAMPLE_RATE = AUDIO_SAMPLE_RATE;

    //-------------------------------------------------------------------------------------------------
    // Setup spatial and tempo factors based on player position
    //-------------------------------------------------------------------------------------------------
    // Use Z?axis (pz) to control “depth” ? more distant (pz??1) becomes sparser, closer (pz?+1) becomes denser
    float depthFactor = clampFloat((pz + 1.0f) * 0.5f, 0.1f, 1.0f);
    // X?axis (px) influences stereo width and LFO rates
    float widthFactor = clampFloat((px + 1.0f) * 0.5f, 0.2f, 1.0f);
    // Y?axis (py) sways tempo between 0.5× and 1.5×
    double tempoFactor = 1.0 + 0.5 * sin(py * 3.14);

    //-------------------------------------------------------------------------------------------------
    // Reactive chord/arpeggio progression: every ~2 seconds adjusted by tempo
    //-------------------------------------------------------------------------------------------------
    static double chordTimer = 0.0;
    static int chordRootIndex = 0;
    chordTimer += tempoFactor / SAMPLE_RATE;
    if (chordTimer >= 2.0) {
        chordTimer -= 2.0;
        chordRootIndex = (chordRootIndex + 1) % 4;
        // Trigger new pad envelope
        padEnv = 1.0;
    }
    padEnv *= padEnvDecay;

    //-------------------------------------------------------------------------------------------------
    // Audio generation per sample
    //-------------------------------------------------------------------------------------------------
    for (ma_uint32 i = 0; i < frameCount; ++i) {
        // --- Update LFOs for shimmer & arc modulation ---
        arcLFOPhase += 0.02 * (0.5 + 0.5 * px) / SAMPLE_RATE; // slow pan swirl
        if (arcLFOPhase >= 1.0) arcLFOPhase -= 1.0;
        shimmerLFOPhase += 0.05 * depthFactor / SAMPLE_RATE; // shimmer rate increases as you move “forward”
        if (shimmerLFOPhase >= 1.0) shimmerLFOPhase -= 1.0;

        // --- Determine root freq from Lydian scale ---
        int rootIdx = (chordRootIndex * 2) % SCALE_NOTES; // move by 2 steps each chord
        double freqRoot = lydianScale[rootIdx];
        double freqThird = lydianScale[(rootIdx + 2) % SCALE_NOTES];
        double freqFifth = lydianScale[(rootIdx + 4) % SCALE_NOTES];

        // --- Generate a swirling “lead” synth voice ---
        // Lead pitch glides slightly with player’s Y?position
        double leadFreq = freqRoot * (1.0 + 0.1 * sin(py * 5.0));
        phaseLead += leadFreq * tempoFactor / SAMPLE_RATE;
        if (phaseLead >= 1.0) phaseLead -= 1.0;
        float rawLead = sin(phaseLead * TWO_PI);

        // Apply a bandpassed shimmer shimmer for “cosmic” feel
        float shimmerCutoff = 2000.0f + 1000.0f * float(0.5 + 0.5 * sin(shimmerLFOPhase * TWO_PI));
        shimmerHPF_L.setHighpass(shimmerCutoff, SAMPLE_RATE);
        shimmerHPF_R.setHighpass(shimmerCutoff * 1.05f, SAMPLE_RATE);
        float shimmerL = shimmerHPF_L.process(rawLead * 0.4f);
        float shimmerR = shimmerHPF_R.process(rawLead * 0.4f);

        // Lowpass the main lead and pan left?right based on arcLFO + px
        leadLPF_L.setLowpass(800.0f + 1200.0f * depthFactor, SAMPLE_RATE);
        leadLPF_R.setLowpass((800.0f + 1200.0f * depthFactor) * 1.1f, SAMPLE_RATE);
        float leadL = leadLPF_L.process(rawLead * 0.7f) * (1.0f - widthFactor * float(0.5 + 0.5 * sin(arcLFOPhase * TWO_PI)));
        float leadR = leadLPF_R.process(rawLead * 0.7f) * (widthFactor * float(0.5 + 0.5 * sin(arcLFOPhase * TWO_PI)));

        // --- Arpeggio “sparkles” that react to player's motion speed ---
        static float prevPx = px, prevPy = py, prevPz = pz;
        float dx = px - prevPx, dy = py - prevPy, dz = pz - prevPz;
        float speed = sqrtf(dx * dx + dy * dy + dz * dz) * 10.0f; // amplify
        prevPx = px; prevPy = py; prevPz = pz;
        // Faster motion = more frequent arpeggio triggers
        if (nextNoiseFloat() > 0.998f - clampFloat(speed, 0.0f, 0.2f)) {
            arpEnv = 1.0;
            arpStep = (arpStep + 1) % SCALE_NOTES;
            arpPhase = 0.0;
        }
        float arpL = 0.0f, arpR = 0.0f;
        if (arpEnv > 0.001f) {
            double arpFreq = lydianScale[arpStep] * (1.0 + 0.05 * sin(py * 7.0));
            arpPhase += arpFreq * tempoFactor / SAMPLE_RATE;
            if (arpPhase >= 1.0) arpPhase -= 1.0;
            float tone = sin(arpPhase * TWO_PI) * float(arpEnv);
            arpEnv *= 0.993;
            float pan = 0.5f + 0.5f * sin(arcLFOPhase * TWO_PI * 1.5f + px * 2.0f);
            arpL = tone * (1.0f - pan) * 0.3f;
            arpR = tone * pan * 0.3f;
        }

        // --- Lush “pad” layer: 4 detuned saw waves per voice ---
        float padL = 0.0f, padR = 0.0f;
        if (padEnv > 0.001) {
            padEnv *= padEnvDecay;
            double detune[4] = { -0.015, -0.005, 0.005, 0.015 };
            for (int v = 0; v < 4; ++v) {
                double base = freqRoot * (1.0 + detune[v]);
                phasePad[v] += base * (0.25 * tempoFactor) / SAMPLE_RATE;
                if (phasePad[v] >= 1.0) phasePad[v] -= 1.0;
                float saw = float((phasePad[v] * 2.0) - 1.0);
                padL += saw * 0.2f * float(padEnv);
                padR += saw * 0.2f * float(padEnv);
            }
            float padCutoff = 300.0f + 1200.0f * depthFactor;
            padLPF_L.setLowpass(padCutoff, SAMPLE_RATE);
            padLPF_R.setLowpass(padCutoff * 1.05f, SAMPLE_RATE);
            padL = padLPF_L.process(padL * 0.8f);
            padR = padLPF_R.process(padR * 0.8f);
        }

        // --- Cosmic “wind” noise layer (filtered and panned slowly) ---
        float rawWind = nextNoiseFloat() * 0.3f * depthFactor;
        float windCutHP = 200.0f + 800.0f * (0.5f + 0.5f * sin(py * 4.0f));
        float windCutLP = 3000.0f - 2000.0f * (0.5f + 0.5f * sin(pz * 4.0f));
        envLPF.setHighpass(windCutHP, SAMPLE_RATE);
        float windHi = envLPF.process(rawWind);
        envLPF.setLowpass(windCutLP, SAMPLE_RATE);
        float windBand = envLPF.process(windHi);
        float windPan = 0.5f + 0.5f * sin(arcLFOPhase * TWO_PI * 0.7f + pz * 2.0f);
        float windL = windBand * (1.0f - windPan) * 0.4f;
        float windR = windBand * windPan * 0.4f;

        // --- Mix dry signals per channel ---
        float mixL_dry = leadL + shimmerL + arpL + padL + windL;
        float mixR_dry = leadR + shimmerR + arpR + padR + windR;

        // --- Multi?tap “space reverb” for cosmic atmosphere ---
        int taps[4] = {
            int(0.12 * SAMPLE_RATE), // 120ms
            int(0.28 * SAMPLE_RATE), // 280ms
            int(0.5 * SAMPLE_RATE), // 500ms
            int(0.9 * SAMPLE_RATE)  // 900ms
        };
        float revL = 0.0f, revR = 0.0f;
        for (int t = 0; t < 4; ++t) {
            int readIdx = (reverbWriteIndex + REVERB_BUFFER_SIZE - taps[t]) % REVERB_BUFFER_SIZE;
            float dL = reverbBufferL[readIdx];
            float dR = reverbBufferR[readIdx];
            float gain = (t == 0) ? 0.6f : (t == 1) ? 0.4f : (t == 2) ? 0.25f : 0.15f;
            revL += dL * gain * depthFactor;
            revR += dR * gain * depthFactor;
        }
        float fbL = mixL_dry + revL * 0.5f;
        float fbR = mixR_dry + revR * 0.5f;
        reverbBufferL[reverbWriteIndex] = clampFloat(fbL, -1.0f, 1.0f);
        reverbBufferR[reverbWriteIndex] = clampFloat(fbR, -1.0f, 1.0f);
        reverbWriteIndex = (reverbWriteIndex + 1) % REVERB_BUFFER_SIZE;

        float outL = clampFloat(mixL_dry + revL * 0.4f, -1.0f, 1.0f);
        float outR = clampFloat(mixR_dry + revR * 0.4f, -1.0f, 1.0f);

        // --- Final stereo width based on X?axis position ---
        float mid = (outL + outR) * 0.5f;
        float side = (outR - outL) * 0.5f * widthFactor;
        float panRot = float(0.5f + 0.5f * sin(arcLFOPhase * TWO_PI));
        float finalL = clampFloat(mid - side * panRot, -1.0f, 1.0f);
        float finalR = clampFloat(mid + side * panRot, -1.0f, 1.0f);

        // --- Write to output buffer ---
        out[2 * i] = finalL;
        out[2 * i + 1] = finalR;
    }
}

// Call once at initialization
void seedNoiseGenerator() {
    srand(static_cast<unsigned>(time(nullptr)));
}
