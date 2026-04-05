#pragma once

#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <ctime>
#include <atomic>
#include "miniaudio.h"

//--------------------------------------------------------------------------------------------------
// Helper functions and constants
//--------------------------------------------------------------------------------------------------

static float clampFloat(float v, float lo, float hi) {
    return (v < lo) ? lo : (v > hi) ? hi : v;
}

constexpr int SCALE_NOTES = 7;
// Cosmic Lydian scale (joyful, spacey feel)
static const double cosmicScale[SCALE_NOTES] = {
    261.63, // C4
    293.66, // D4
    329.63, // E4
    349.23, // F#4 (Lydian raised fourth)
    392.00, // G4
    440.00, // A4
    493.88  // B4
};

// Simple linear congruential generator for noise
static uint32_t lcgState = 1;
static float nextNoiseFloat() {
    lcgState = 1664525u * lcgState + 1013904223u;
    return float(((lcgState >> 16) & 0xFFFF) / 65535.0 * 2.0 - 1.0);
}

//--------------------------------------------------------------------------------------------------
// One-pole filter (used for lowpass/highpass)
//--------------------------------------------------------------------------------------------------
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

//--------------------------------------------------------------------------------------------------
// Simple envelope generator (exponential decay)
//--------------------------------------------------------------------------------------------------
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

//--------------------------------------------------------------------------------------------------
// Global player position (to be updated by game loop)
//--------------------------------------------------------------------------------------------------
extern std::atomic<float> g_playerPosX;
extern std::atomic<float> g_playerPosY;
extern std::atomic<float> g_playerPosZ;

//--------------------------------------------------------------------------------------------------
// Delay buffer for spacious reverb/delay
//--------------------------------------------------------------------------------------------------
constexpr int DELAY_BUFFER_SIZE = 96000; // 2 seconds at 48kHz
static float delayBufferL[DELAY_BUFFER_SIZE] = { 0 };
static float delayBufferR[DELAY_BUFFER_SIZE] = { 0 };
static int delayWriteIndex = 0;

//--------------------------------------------------------------------------------------------------
// Seed noise generator once at startup
//--------------------------------------------------------------------------------------------------
inline void seedNoiseGenerator() {
    srand(static_cast<unsigned>(time(nullptr)));
    lcgState = rand();
}

//--------------------------------------------------------------------------------------------------
// Audio callback implementing a space-synth procedural generator
//--------------------------------------------------------------------------------------------------
void audio_callback(ma_device* /*device*/, void* pOutput, const void* /*pInput*/, ma_uint32 frameCount) {
    float* out = static_cast<float*>(pOutput);

    // Read player position (range assumed roughly -1..+1 for each axis)
    float px = g_playerPosX.load(std::memory_order_relaxed);
    float py = g_playerPosY.load(std::memory_order_relaxed);
    float pz = g_playerPosZ.load(std::memory_order_relaxed);

    //--------------------------------------------------------------------------------------------------
    // Persistent state variables
    //--------------------------------------------------------------------------------------------------
    static double phaseArp = 0.0;
    static double phasePad[4] = { 0.0, 0.0, 0.0, 0.0 };
    static double padEnv = 0.0;
    static double padEnvDecay = 0.9997;

    static double phaseLead = 0.0;
    static double leadEnv = 0.0;
    static bool leadActive = false;

    static double phaseDrone = 0.0;

    static double lfoPhase1 = 0.0;
    static double lfoPhase2 = 0.0;
    static double lfoPhase3 = 0.0;

    static Envelope arpEnv;
    static Envelope droneEnv;

    // Filters
    static OnePole padLPF_L;
    static OnePole padLPF_R;
    static OnePole leadLPF_L;
    static OnePole leadLPF_R;
    static OnePole droneHPF_L;
    static OnePole droneHPF_R;

    // Delay/feedback for cosmic echoes
    static OnePole delayLPF;

    //--------------------------------------------------------------------------------------------------
    // Constants
    //--------------------------------------------------------------------------------------------------
    const double PI = 3.14159265358979323846;
    const double TWO_PI = 2.0 * PI;
    const unsigned SAMPLE_RATE = AUDIO_SAMPLE_RATE;

    //--------------------------------------------------------------------------------------------------
    // Compute travel-based section changes
    //--------------------------------------------------------------------------------------------------
    static float prevPx = px, prevPy = py, prevPz = pz;
    static float distAccum = 0.0f;
    float dx = px - prevPx;
    float dy = py - prevPy;
    float dz = pz - prevPz;
    float traveled = sqrtf(dx * dx + dy * dy + dz * dz);
    distAccum += traveled;
    prevPx = px; prevPy = py; prevPz = pz;

    // Every 3 units traveled, trigger pad swell and arp envelope
    if (distAccum >= 3.0f) {
        distAccum -= 3.0f;
        padEnv = 1.0;
        arpEnv.trigger(1.0f, 0.995f);
    }

    for (ma_uint32 i = 0; i < frameCount; ++i) {
        //----------------------------------------------------------------------------------------------
        // 1) LFO updates (for filter mod, pan, etc.)
        //----------------------------------------------------------------------------------------------
        lfoPhase1 += 0.005 + 0.002 * pz; // slow wander influenced by depth
        if (lfoPhase1 >= 1.0) lfoPhase1 -= 1.0;

        lfoPhase2 += 0.01 + 0.003 * px; // mod influenced by x
        if (lfoPhase2 >= 1.0) lfoPhase2 -= 1.0;

        lfoPhase3 += 0.008 + 0.002 * py; // mod influenced by y
        if (lfoPhase3 >= 1.0) lfoPhase3 -= 1.0;

        //----------------------------------------------------------------------------------------------
        // 2) Dynamic tempo factor (slower when deep, faster when near surface)
        //----------------------------------------------------------------------------------------------
        double tempoFactor = 0.5 + 0.5 * (1.0 - fabs(pz)); // pz near 0 => max tempo, near ±1 => min
        tempoFactor = clampFloat(tempoFactor, 0.2f, 1.2f);

        //----------------------------------------------------------------------------------------------
        // 3) ARPEGGIATOR (cosmic pluck) – cycles through cosmicScale
        //----------------------------------------------------------------------------------------------
        phaseArp += (tempoFactor * 2.0 + 0.5 * sin(pz * 5.0)) / SAMPLE_RATE;
        if (phaseArp >= SCALE_NOTES) phaseArp -= SCALE_NOTES;
        int arpIndex = static_cast<int>(floor(phaseArp)) % SCALE_NOTES;
        double arpFreq = cosmicScale[arpIndex] * (1.0 + 0.1 * sin(lfoPhase2 * TWO_PI));
        double arpPhaseInc = arpFreq / SAMPLE_RATE;
        static double arpPhase = 0.0;
        arpPhase += arpPhaseInc;
        if (arpPhase >= 1.0) arpPhase -= 1.0;
        float rawArp = sin(arpPhase * TWO_PI) * arpEnv.process() * 0.7f;

        // Pan arp by x position
        float arpPan = 0.5f + 0.5f * sin(lfoPhase1 * TWO_PI + px * 2.0f);
        float sampleArpL = rawArp * (1.0f - arpPan);
        float sampleArpR = rawArp * arpPan;

        //----------------------------------------------------------------------------------------------
        // 4) PAD LAYER (detuned saws with slow envelope)
        //----------------------------------------------------------------------------------------------
        float samplePadL = 0.0f;
        float samplePadR = 0.0f;
        if (padEnv > 0.0001) {
            padEnv *= padEnvDecay;
            double baseFreq = cosmicScale[0] * 0.25 * (1.0 + 0.1 * sin(lfoPhase3 * TWO_PI));
            double detunes[4] = { -0.02, 0.0, 0.02, 0.03 };
            for (int p = 0; p < 4; ++p) {
                phasePad[p] += (baseFreq * (1.0 + detunes[p])) / SAMPLE_RATE;
                if (phasePad[p] >= 1.0) phasePad[p] -= 1.0;
                float saw = float((phasePad[p] * 2.0 - 1.0));
                samplePadL += saw * 0.3f * float(padEnv);
                samplePadR += saw * 0.3f * float(padEnv);
            }
            // Filter pad with LFO-modulated cutoff
            float padCutoff = 200.0f + float(0.5 + 0.5 * cos(lfoPhase2 * TWO_PI)) * 1200.0f * clampFloat(py + 0.5f, 0.1f, 1.0f);
            padLPF_L.setLowpass(padCutoff, SAMPLE_RATE);
            padLPF_R.setLowpass(padCutoff * 1.05f, SAMPLE_RATE);
            samplePadL = padLPF_L.process(samplePadL * 0.8f);
            samplePadR = padLPF_R.process(samplePadR * 0.8f);
        }

        //----------------------------------------------------------------------------------------------
        // 5) LEAD SYNTH (spacey sine with subtle FM shimmer)
        //----------------------------------------------------------------------------------------------
        if (!leadActive) {
            // Occasionally trigger a lead note based on z-depth
            if (nextNoiseFloat() > (0.995f - pz * 0.02f)) {
                leadActive = true;
                leadEnv = 1.0;
            }
        }
        float sampleLeadL = 0.0f, sampleLeadR = 0.0f;
        if (leadActive) {
            // Choose a random note from cosmicScale when triggered
            static double leadNoteFreq = cosmicScale[rand() % SCALE_NOTES] * (1.0 + (rand() % 3) * 0.5);
            phaseLead += leadNoteFreq / SAMPLE_RATE;
            if (phaseLead >= 1.0) phaseLead -= 1.0;
            float tone = sin(phaseLead * TWO_PI);
            leadEnv *= 0.992f;
            if (leadEnv < 0.001f) {
                leadActive = false;
                leadEnv = 0.0;
            }
            // Subtle FM mod: modulate tone amplitude
            float fmMod = sin(phaseLead * 3.0 * TWO_PI) * 0.2f;
            float rawLead = tone * (leadEnv * (1.0f + fmMod));
            // Pan lead by y position
            float leadPan = 0.5f + 0.5f * cos(lfoPhase3 * TWO_PI + py * 2.0f);
            sampleLeadL = rawLead * (1.0f - leadPan) * 0.6f;
            sampleLeadR = rawLead * leadPan * 0.6f;

            // Filter lead for brightness variation
            float leadCutoff = 500.0f + float(0.5 + 0.5 * sin(lfoPhase1 * TWO_PI)) * 2000.0f * clampFloat(fabs(px), 0.2f, 1.0f);
            leadLPF_L.setLowpass(leadCutoff, SAMPLE_RATE);
            leadLPF_R.setLowpass(leadCutoff * 1.02f, SAMPLE_RATE);
            sampleLeadL = leadLPF_L.process(sampleLeadL);
            sampleLeadR = leadLPF_R.process(sampleLeadR);
        }

        //----------------------------------------------------------------------------------------------
        // 6) DRONE LAYER (subtle low rumble reacting to height)
        //----------------------------------------------------------------------------------------------
        double droneFreq = 55.0 + pz * 30.0; // deeper when deeper in z
        phaseDrone += droneFreq / SAMPLE_RATE;
        if (phaseDrone >= 1.0) phaseDrone -= 1.0;
        float rawDrone = sin(phaseDrone * TWO_PI) * 0.2f;
        // Very gentle envelope
        if (!droneEnv.active && nextNoiseFloat() > 0.9995f) {
            droneEnv.trigger(0.8f, 0.999f);
        }
        float droneOut = rawDrone * droneEnv.process();
        // High-pass filter to remove subsonic rumble
        droneHPF_L.setHighpass(60.0f, SAMPLE_RATE);
        droneHPF_R.setHighpass(60.0f, SAMPLE_RATE);
        float sampleDroneL = droneHPF_L.process(droneOut);
        float sampleDroneR = droneHPF_R.process(droneOut);

        //----------------------------------------------------------------------------------------------
        // 7) “Stellar Dust” shimmer – random chime-like grains
        //----------------------------------------------------------------------------------------------
        float sampleDustL = 0.0f, sampleDustR = 0.0f;
        if (nextNoiseFloat() > 0.997f) {
            // small grain bursts
            float grainFreq = cosmicScale[rand() % SCALE_NOTES] * (1.0 + float(nextNoiseFloat()) * 0.5f);
            double grainPhase = 0.0;
            float grainEnv = 1.0f;
            for (int g = 0; g < 5; ++g) {
                // Synthesize 5 rapid blips
                grainPhase += grainFreq / SAMPLE_RATE;
                if (grainPhase >= 1.0) grainPhase -= 1.0;
                float blip = sin(grainPhase * TWO_PI) * grainEnv;
                grainEnv *= 0.90f;
                // Random pan
                float pan = 0.5f + 0.5f * nextNoiseFloat();
                sampleDustL += blip * (1.0f - pan) * 0.3f;
                sampleDustR += blip * pan * 0.3f;
            }
        }

        //----------------------------------------------------------------------------------------------
        // 8) MIX DRY SIGNALS
        //----------------------------------------------------------------------------------------------
        float mixL_dry =
            samplePadL +
            sampleArpL +
            sampleLeadL +
            sampleDroneL +
            sampleDustL;

        float mixR_dry =
            samplePadR +
            sampleArpR +
            sampleLeadR +
            sampleDroneR +
            sampleDustR;

        //----------------------------------------------------------------------------------------------
        // 9) COSMIC DELAY / ECHO (multi-tap)
        //----------------------------------------------------------------------------------------------
        // Use three taps with time based on z-depth
        float delayTime1 = 0.2f + clampFloat(pz * 0.1f, 0.0f, 0.3f); // 200-500ms
        float delayTime2 = 0.4f + clampFloat(py * 0.2f, -0.1f, 0.2f); // 300-600ms
        float delayTime3 = 0.7f - clampFloat(px * 0.15f, -0.1f, 0.3f); // 400-800ms

        int tap1 = int(delayTime1 * SAMPLE_RATE);
        int tap2 = int(delayTime2 * SAMPLE_RATE);
        int tap3 = int(delayTime3 * SAMPLE_RATE);

        float echoL = 0.0f, echoR = 0.0f;
        int idx1 = (delayWriteIndex + DELAY_BUFFER_SIZE - tap1) % DELAY_BUFFER_SIZE;
        int idx2 = (delayWriteIndex + DELAY_BUFFER_SIZE - tap2) % DELAY_BUFFER_SIZE;
        int idx3 = (delayWriteIndex + DELAY_BUFFER_SIZE - tap3) % DELAY_BUFFER_SIZE;
        echoL += delayBufferL[idx1] * 0.5f;
        echoR += delayBufferR[idx1] * 0.5f;
        echoL += delayBufferL[idx2] * 0.3f;
        echoR += delayBufferR[idx2] * 0.3f;
        echoL += delayBufferL[idx3] * 0.2f;
        echoR += delayBufferR[idx3] * 0.2f;

        float fbMixL = mixL_dry + echoL * 0.6f;
        float fbMixR = mixR_dry + echoR * 0.6f;
        delayLPF.setLowpass(1200.0f + float(0.5f + 0.5f * sin(lfoPhase1 * TWO_PI)) * 1000.0f, SAMPLE_RATE);
        float writeL = delayLPF.process(fbMixL);
        float writeR = delayLPF.process(fbMixR);
        delayBufferL[delayWriteIndex] = clampFloat(writeL, -1.0f, 1.0f);
        delayBufferR[delayWriteIndex] = clampFloat(writeR, -1.0f, 1.0f);
        delayWriteIndex = (delayWriteIndex + 1) % DELAY_BUFFER_SIZE;

        float outL = clampFloat(mixL_dry + echoL * 0.5f, -1.0f, 1.0f);
        float outR = clampFloat(mixR_dry + echoR * 0.5f, -1.0f, 1.0f);

        //----------------------------------------------------------------------------------------------
        // 10) FINAL SPATIAL WIDTH & ROTATION (spacey stereo motion based on position)
        //----------------------------------------------------------------------------------------------
        float width = clampFloat(0.5f + px * 0.5f, 0.0f, 1.0f);
        float mid = (outL + outR) * 0.5f;
        float side = (outR - outL) * 0.5f * width;
        float rot = float(0.5f + 0.5f * sin(lfoPhase3 * TWO_PI + pz * 2.0f));
        float finalL = clampFloat(mid - side * rot, -1.0f, 1.0f);
        float finalR = clampFloat(mid + side * rot, -1.0f, 1.0f);

        out[2 * i] = finalL;
        out[2 * i + 1] = finalR;
    }
}
