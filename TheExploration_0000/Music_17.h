#pragma once

#pragma once

#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <ctime>
#include <atomic>
#include "miniaudio.h" // (Or your preferred low-latency audio API)

// Utility: clamp a float between lo and hi
static float clampFloat(float v, float lo, float hi) {
    return (v < lo) ? lo : (v > hi) ? hi : v;
}

// Scales: Lydian (bright) and Ionian (major) for a joyful feel
constexpr int SCALE_NOTES = 7;
static const double lydianScale[SCALE_NOTES] = {
    261.63, // C4
    293.66, // D4
    329.63, // E4
    349.23, // F4
    392.00, // G4
    440.00, // A4
    493.88  // B4
};
static const double ionianScale[SCALE_NOTES] = {
    261.63, // C4
    293.66, // D4
    329.63, // E4
    349.23, // F4
    392.00, // G4
    440.00, // A4
    493.88  // B4
};

// Linear congruential noise generator for random events
static uint32_t lcgState = 1;
static float nextNoiseFloat() {
    lcgState = 1664525u * lcgState + 1013904223u;
    return float(((lcgState >> 16) & 0xFFFF) / 65535.0 * 2.0 - 1.0);
}

// Reverb buffer (multi-tap) for spacious ambience
constexpr int REVERB_BUFFER_SIZE = 96000; // 2 seconds at 48kHz
static float reverbBufferL[REVERB_BUFFER_SIZE] = { 0 };
static float reverbBufferR[REVERB_BUFFER_SIZE] = { 0 };
static int reverbWriteIndex = 0;

// One-pole filter for simple lowpass/highpass
struct OnePole {
    float a0 = 1.0f, b1 = 0.0f, z1 = 0.0f;
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

// Simple decay envelope
struct Envelope {
    float value = 0.0f;
    float decay = 0.999f;
    bool active = false;
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

// Global atomics for player position (to be updated elsewhere)
extern std::atomic<float> g_playerPosX;
extern std::atomic<float> g_playerPosY;
extern std::atomic<float> g_playerPosZ;

// Seed RNG at startup
inline void seedNoiseGenerator() {
    srand(static_cast<unsigned>(time(nullptr)));
}

// Audio callback: "space synth" that reacts to player position
void audio_callback(ma_device* /*device*/, void* pOutput, const void* /*pInput*/, ma_uint32 frameCount) {
    float* out = static_cast<float*>(pOutput);

    // Read player position in [-1, 1]
    float px = g_playerPosX.load(std::memory_order_relaxed);
    float py = g_playerPosY.load(std::memory_order_relaxed);
    float pz = g_playerPosZ.load(std::memory_order_relaxed);

    // Persistent state
    static double phaseLead = 0.0;
    static double phasePad[4] = { 0.0, 0.0, 0.0, 0.0 }; // <<< corrected name
    static double padEnv = 0.0;
    static double padEnvDecay = 0.9995;
    static double lfoPhase = 0.0;
    static double chordPhase[3] = { 0.0, 0.0, 0.0 };
    static double chordEnv = 0.0;
    static int chordIndex = 0;
    static double chordTimeAcc = 0.0;
    static double arpCounter = 0.0;

    // Filters
    static OnePole chordLPF_L, chordLPF_R;
    static OnePole leadLPF_L, leadLPF_R;
    static OnePole padLPF_L, padLPF_R;
    static OnePole brrLPF, brrHPF;

    // Shimmer (delay-based feedback) buffer
    static float shimmerBuffer[REVERB_BUFFER_SIZE] = { 0 };
    static int shimmerIndex = 0;

    const double PI = 3.14159265358979323846;
    const double TWO_PI = 2.0 * PI;
    const unsigned SAMPLE_RATE = AUDIO_SAMPLE_RATE;

    // Track previous Y to trigger pad env on upward motion
    static float prevPy = py;

    for (ma_uint32 i = 0; i < frameCount; ++i) {
        // 1) LFO for modulation
        lfoPhase += 0.003 + 0.002 * pz;
        if (lfoPhase >= 1.0) lfoPhase -= 1.0;

        // 2) Chord progression every 2s, speed modulated by Y-position
        chordTimeAcc += (1.0 + 0.5 * py) / SAMPLE_RATE;
        if (chordTimeAcc >= 2.0) {
            chordTimeAcc -= 2.0;
            chordIndex = (chordIndex + 1) % 4;
            chordEnv = 1.0;
        }
        chordEnv *= 0.999;

        // Choose scale: Lydian if py>0, Ionian otherwise
        const double* currentScale = (py > 0.0f) ? lydianScale : ionianScale;

        // Chord root indices
        int rootOffsets[4] = { 0, 2, 3, 5 };
        int rootIdx = rootOffsets[chordIndex] % SCALE_NOTES;
        double freqRoot = currentScale[rootIdx] * 0.5;
        double freqThird = currentScale[(rootIdx + 2) % SCALE_NOTES] * 0.5;
        double freqFifth = currentScale[(rootIdx + 4) % SCALE_NOTES] * 0.5;

        // 3) Update chord voices
        chordPhase[0] += freqRoot * (1.0 + 0.1 * sin(pz * 2.0)) / SAMPLE_RATE;
        chordPhase[1] += freqThird * (1.0 + 0.1 * sin(px * 2.0)) / SAMPLE_RATE;
        chordPhase[2] += freqFifth * (1.0 + 0.1 * sin(py * 2.0)) / SAMPLE_RATE;
        for (int k = 0; k < 3; ++k) {
            if (chordPhase[k] >= 1.0) chordPhase[k] -= 1.0;
        }
        float rawChord = (sin(chordPhase[0] * TWO_PI) +
            sin(chordPhase[1] * TWO_PI) +
            sin(chordPhase[2] * TWO_PI)) / 3.0f
            * float(chordEnv);

        // 4) Filter chords for warmth (cutoff moves with X-position)
        float filterMod = 0.5f + 0.5f * sin(lfoPhase * TWO_PI);
        float cutoffChord = 200.0f + filterMod * 2000.0f + px * 500.0f;
        chordLPF_L.setLowpass(cutoffChord, SAMPLE_RATE);
        chordLPF_R.setLowpass(cutoffChord * 1.1f, SAMPLE_RATE);
        float sampleChordL = chordLPF_L.process(rawChord * 0.6f);
        float sampleChordR = chordLPF_R.process(rawChord * 0.6f);

        // 5) Pad layer: four detuned saws (“cosmic pad”)
        float samplePadL = 0.0f, samplePadR = 0.0f;
        if (padEnv > 0.0001) {
            padEnv *= padEnvDecay;
            double detunes[4] = { -0.015, 0.0, 0.015, 0.03 };
            for (int p = 0; p < 4; ++p) {
                double baseFreq = freqRoot * (1.0 + detunes[p]);
                phasePad[p] += baseFreq / SAMPLE_RATE;   // <<< using phasePad[]
                if (phasePad[p] >= 1.0) phasePad[p] -= 1.0;
                float saw = float((phasePad[p] * 2.0 - 1.0));
                samplePadL += saw * 0.2f * float(padEnv);
                samplePadR += saw * 0.2f * float(padEnv);
            }
            float padCutoff = 100.0f + float(0.3 + 0.7 * cos(lfoPhase * TWO_PI)) * 1200.0f;
            padLPF_L.setLowpass(padCutoff, SAMPLE_RATE);
            padLPF_R.setLowpass(padCutoff * 1.05f, SAMPLE_RATE);
            samplePadL = padLPF_L.process(samplePadL * 0.7f);
            samplePadR = padLPF_R.process(samplePadR * 0.7f);
        }

        // Trigger pad envelope whenever player moves upward
        if (py - prevPy > 0.01f) {
            padEnv = 1.0;
        }
        prevPy = py;

        // 6) Arpeggiated lead: sine + triangle, speed ? Z-position
        double stepRate = 4.0 + 4.0 * pz;
        arpCounter += stepRate / SAMPLE_RATE;
        if (arpCounter >= SCALE_NOTES) arpCounter -= SCALE_NOTES;
        int arpIdx = static_cast<int>(floor(arpCounter)) % SCALE_NOTES;
        double freqLead = currentScale[arpIdx] * (1.0 + 0.05 * sin(lfoPhase * TWO_PI));
        phaseLead += freqLead / SAMPLE_RATE;
        if (phaseLead >= 1.0) phaseLead -= 1.0;

        float rawLead = sin(phaseLead * TWO_PI);
        float tri = float(2.0 * fabs((phaseLead * 2.0 - floor(phaseLead * 2.0 + 0.5))) - 1.0);
        float sampleLead = rawLead * 0.6f + tri * 0.4f;

        // Pan lead by X-position
        float leadPan = 0.5f + 0.5f * px;
        float sampleLeadL = sampleLead * (1.0f - leadPan) * 0.5f;
        float sampleLeadR = sampleLead * leadPan * 0.5f;

        // Light lowpass on lead for “space shimmer”
        float cutoffLead = 500.0f + float(0.5 + 0.5 * sin(pz * 3.0)) * 2000.0f;
        leadLPF_L.setLowpass(cutoffLead, SAMPLE_RATE);
        leadLPF_R.setLowpass(cutoffLead * 1.05f, SAMPLE_RATE);
        sampleLeadL = leadLPF_L.process(sampleLeadL);
        sampleLeadR = leadLPF_R.process(sampleLeadR);

        // 7) “Brr” noise layer (cosmic static)
        float rawBrr = nextNoiseFloat() * 0.3f;
        brrLPF.setLowpass(1200.0f + py * 300.0f, SAMPLE_RATE);
        float brrLow = brrLPF.process(rawBrr);
        brrHPF.setHighpass(400.0f, SAMPLE_RATE);
        float brrBand = brrHPF.process(brrLow);
        float brrAmp = 0.3f * float(0.5 + 0.5 * sin(lfoPhase * TWO_PI * 1.5));
        float brrSample = brrBand * brrAmp;
        float swirlPan = 0.5f + 0.5f * sin(lfoPhase * TWO_PI + px * 1.0f);
        float sampleBrrL = brrSample * (1.0f - swirlPan) * 0.3f;
        float sampleBrrR = brrSample * swirlPan * 0.3f;

        // 8) Mix dry signals
        float mixL_dry =
            sampleChordL +
            samplePadL +
            sampleLeadL +
            sampleBrrL;
        float mixR_dry =
            sampleChordR +
            samplePadR +
            sampleLeadR +
            sampleBrrR;

        // 9) Shimmer feedback: small delay with high-freq emphasis
        float shimmerInL = mixL_dry;
        float shimmerInR = mixR_dry;
        float shimmerOutL = shimmerBuffer
            [(shimmerIndex + REVERB_BUFFER_SIZE - int(0.2f * SAMPLE_RATE)) % REVERB_BUFFER_SIZE];
        float shimmerOutR = shimmerBuffer
            [(shimmerIndex + REVERB_BUFFER_SIZE - int(0.2f * SAMPLE_RATE) + 1) % REVERB_BUFFER_SIZE];
        float shimmerFeedL = shimmerInL + shimmerOutL * 0.5f;
        float shimmerFeedR = shimmerInR + shimmerOutR * 0.5f;
        chordLPF_L.setLowpass(3000.0f, SAMPLE_RATE);
        shimmerFeedL = chordLPF_L.process(shimmerFeedL);
        chordLPF_R.setLowpass(3000.0f, SAMPLE_RATE);
        shimmerFeedR = chordLPF_R.process(shimmerFeedR);
        shimmerBuffer[shimmerIndex] = shimmerFeedL;
        shimmerBuffer[(shimmerIndex + 1) % REVERB_BUFFER_SIZE] = shimmerFeedR;
        shimmerIndex = (shimmerIndex + 2) % REVERB_BUFFER_SIZE;

        float shimmerL = shimmerOutL * 0.3f;
        float shimmerR = shimmerOutR * 0.3f;

        // 10) Multi-tap reverb (4 taps)
        int tapOffsets[4] = {
            int(0.08 * SAMPLE_RATE),  // 80ms
            int(0.18 * SAMPLE_RATE),  // 180ms
            int(0.38 * SAMPLE_RATE),  // 380ms
            int(0.75 * SAMPLE_RATE)   // 750ms
        };
        float revL = 0.0f, revR = 0.0f;
        for (int t = 0; t < 4; ++t) {
            int readIndex = (reverbWriteIndex + REVERB_BUFFER_SIZE - tapOffsets[t]) % REVERB_BUFFER_SIZE;
            float dL = reverbBufferL[readIndex];
            float dR = reverbBufferR[readIndex];
            float gain = (t == 0) ? 0.5f : (t == 1) ? 0.35f : (t == 2) ? 0.2f : 0.1f;
            revL += dL * gain;
            revR += dR * gain;
        }
        float fbMixL = mixL_dry + shimmerL + revL * 0.4f;
        float fbMixR = mixR_dry + shimmerR + revR * 0.4f;
        reverbBufferL[reverbWriteIndex] = clampFloat(fbMixL, -1.0f, 1.0f);
        reverbBufferR[reverbWriteIndex] = clampFloat(fbMixR, -1.0f, 1.0f);
        reverbWriteIndex = (reverbWriteIndex + 1) % REVERB_BUFFER_SIZE;

        float outL = clampFloat(mixL_dry + shimmerL + revL * 0.3f, -1.0f, 1.0f);
        float outR = clampFloat(mixR_dry + shimmerR + revR * 0.3f, -1.0f, 1.0f);

        // 11) Final stereo width + rotation (width ? |px|)
        float width = clampFloat(fabs(px) * 0.8f + 0.2f, 0.0f, 1.0f);
        float mid = (outL + outR) * 0.5f;
        float side = (outR - outL) * 0.5f * width;
        float rot = float(0.5f + 0.5f * sin(lfoPhase * TWO_PI + py * 1.5f));
        float finalL = clampFloat(mid - side * rot, -1.0f, 1.0f);
        float finalR = clampFloat(mid + side * rot, -1.0f, 1.0f);

        out[2 * i] = finalL;
        out[2 * i + 1] = finalR;
    }
}
