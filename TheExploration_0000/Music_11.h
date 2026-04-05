#pragma once

#pragma once

#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <ctime>
#include <atomic>
#include "miniaudio.h" // assume you have this

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


// Delay buffer for multi-tap ambient reverb
constexpr int REVERB_BUFFER_SIZE = 96000; // 2 seconds at 48kHz
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

// Envelope generator
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

    float px = g_playerPosX.load(std::memory_order_relaxed);
    float py = g_playerPosY.load(std::memory_order_relaxed);
    float pz = g_playerPosZ.load(std::memory_order_relaxed);

    // Persistent state
    static double phaseLead = 0.0;
    static double phaseBass = 0.0;
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

    // Drum voices
    static Envelope kickEnv;
    static Envelope snareEnv;
    static Envelope hatEnv;
    static double kickPhase = 0.0;

    // FM bells
    struct FMBell { bool active; double carrierPhase, modPhase, carrierFreq, modFreq, env; };
    static FMBell bells[4] = {};

    // Filters (declare once)
    static OnePole chordLPF_L;
    static OnePole chordLPF_R;
    static OnePole windHPF_L;
    static OnePole windHPF_R;
    static OnePole bassLPF_L;
    static OnePole bassLPF_R;
    static OnePole snareHPF_L;
    static OnePole snareHPF_R;
    static OnePole hatHPF_L;
    static OnePole hatHPF_R;
    static OnePole padLPF_L;
    static OnePole padLPF_R;
    static OnePole brrLPF;    // lowpass for brr
    static OnePole brrHPF;    // highpass for brr

    // Brr LFO
    static double brrLFOPhase = 0.0;
    static double brrPanPhase = 0.0;

    // Rhythm sequencing
    static double barPhase = 0.0;
    static int prevBeatStep = -1;
    static bool rhythmPattern = false;

    // Distance-based section change
    static float prevPx = px, prevPy = py, prevPz = pz;
    static float distAccum = 0.0f;

    // Spatial pan
    static double spatialPanPhase = 0.0;

    // Ambient pad voices (4 detuned saw waves)
    static double padPhase[4] = { 0.0, 0.0, 0.0, 0.0 };
    static double padEnv = 0.0;
    static double padEnvDecay = 0.9998;

    const double PI = 3.14159265358979323846;
    const double TWO_PI = 2.0 * PI;
    const unsigned SAMPLE_RATE = AUDIO_SAMPLE_RATE;

    // Compute travel distance
    float dx = px - prevPx;
    float dy = py - prevPy;
    float dz = pz - prevPz;
    float traveled = sqrtf(dx * dx + dy * dy + dz * dz);
    distAccum += traveled;
    prevPx = px;
    prevPy = py;
    prevPz = pz;

    // Every 4 meters, toggle rhythm and trigger pad envelope
    if (distAccum >= 4.0f) {
        distAccum -= 4.0f;
        rhythmPattern = !rhythmPattern;
        barPhase = 0.0;
        prevBeatStep = -1;
        chordIndex = (chordIndex + 1) % 4;
        chordEnv = 1.0;
        padEnv = 1.0; // trigger pad in new section
    }

    for (ma_uint32 i = 0; i < frameCount; ++i) {
        // 1) LFO updates
        spatialPanPhase += 0.015 / SAMPLE_RATE;
        if (spatialPanPhase >= 1.0) spatialPanPhase -= 1.0;
        windLFOPhase += 0.04 / SAMPLE_RATE;
        if (windLFOPhase >= 1.0) windLFOPhase -= 1.0;
        brrLFOPhase += 0.1 / SAMPLE_RATE; // slower flutter for brr amplitude
        if (brrLFOPhase >= 1.0) brrLFOPhase -= 1.0;
        brrPanPhase += 0.08 / SAMPLE_RATE; // swirling pan for brr
        if (brrPanPhase >= 1.0) brrPanPhase -= 1.0;

        // 2) Spatial factors
        float spatialDepth = clampFloat(pz * 0.5f + 0.5f, 0.1f, 1.0f);
        float spatialWidth = clampFloat(px * 0.5f + 0.5f, 0.1f, 1.0f);

        // 3) Tempo factor
        double tempoFactor = 0.6 + 0.4 * sin(px * 2.5);
        tempoFactor = clampFloat(tempoFactor, 0.2f, 2.0f);

        // 4) Chord progression every 1.5s
        chordTimeAcc += tempoFactor / SAMPLE_RATE;
        if (chordTimeAcc >= 1.5) {
            chordTimeAcc -= 1.5;
            chordIndex = (chordIndex + 1) % 4;
            chordEnv = 1.0;
        }
        chordEnv *= 0.9985;

        // 5) Chord frequencies
        int rootIdx;
        switch (chordIndex) {
        case 0: rootIdx = 0; break;
        case 1: rootIdx = 3; break;
        case 2: rootIdx = 4; break;
        case 3: rootIdx = 5; break;
        default: rootIdx = 0; break;
        }
        const double* currentScale = (py > 0.0f) ? cMajorScale : aMinorScale;
        double freqRoot = currentScale[rootIdx] * 0.5;
        double freqThird = currentScale[(rootIdx + 2) % SCALE_NOTES] * 0.5;
        double freqFifth = currentScale[(rootIdx + 4) % SCALE_NOTES] * 0.5;

        // 6) Update chord phases
        chordPhase[0] += freqRoot * (1.0 + 0.02 * sin(py * 3.5)) / SAMPLE_RATE;
        chordPhase[1] += freqThird * (1.0 + 0.02 * sin(pz * 3.5)) / SAMPLE_RATE;
        chordPhase[2] += freqFifth * (1.0 + 0.02 * sin(px * 3.5)) / SAMPLE_RATE;
        for (int k = 0; k < 3; ++k) {
            if (chordPhase[k] >= 1.0) chordPhase[k] -= 1.0;
        }
        float rawChord = (sin(chordPhase[0] * TWO_PI) +
            sin(chordPhase[1] * TWO_PI) +
            sin(chordPhase[2] * TWO_PI)) / 3.0f * chordEnv;

        // 7) Chord filter
        double filterLFO1 = 0.5 + 0.5 * sin(px * 2.0 + spatialPanPhase * TWO_PI);
        float cutoffChord = 300.0f + float(filterLFO1) * 2400.0f;
        chordLPF_L.setLowpass(cutoffChord, SAMPLE_RATE);
        chordLPF_R.setLowpass(cutoffChord * (1.0f + 0.1f * sin(px * 4.0f)), SAMPLE_RATE);
        float sampleChordL = chordLPF_L.process(rawChord * 0.65f * spatialDepth);
        float sampleChordR = chordLPF_R.process(rawChord * 0.65f * spatialDepth);

        // 8) Bass
        double filterLFO2 = 0.5 + 0.5 * cos(py * 2.5 + spatialPanPhase * TWO_PI);
        double freqBass = freqRoot * 0.4 * (1.0 + 0.3 * sin(py * 5.5));
        phaseBass += clampFloat(freqBass, 40.0f, 140.0f) / SAMPLE_RATE;
        if (phaseBass >= 1.0) phaseBass -= 1.0;
        float rawBass = sin(phaseBass * TWO_PI);
        float cutoffBass = 100.0f + float(filterLFO2) * 900.0f;
        bassLPF_L.setLowpass(cutoffBass, SAMPLE_RATE);
        bassLPF_R.setLowpass(cutoffBass * 1.05f, SAMPLE_RATE);
        float sampleBassL = 0.6f * bassLPF_L.process(rawBass * 0.8f);
        float sampleBassR = 0.6f * bassLPF_R.process(rawBass * 0.8f);

        // 9) Lead melody
        stepCounter += tempoFactor * 1.1 / SAMPLE_RATE;
        if (stepCounter >= SCALE_NOTES) stepCounter -= SCALE_NOTES;
        int noteIndex = static_cast<int>(floor(stepCounter)) % SCALE_NOTES;
        double freqLead = currentScale[noteIndex] *
            (1.0 + 0.1 * sin(spatialPanPhase * TWO_PI) + 0.05 * sin(pz * 9.0));
        phaseLead += freqLead / SAMPLE_RATE;
        if (phaseLead >= 1.0) phaseLead -= 1.0;
        float rawLead = sin(phaseLead * TWO_PI);
        float pwm = sin((phaseLead + 0.25) * TWO_PI);
        float sampleLead = rawLead * 0.5f + pwm * 0.5f;
        float leadPan = 0.5f + 0.5f * cos(spatialPanPhase * TWO_PI + px * 1.5f);
        float sampleLeadL = sampleLead * (1.0f - leadPan) * 0.5f;
        float sampleLeadR = sampleLead * leadPan * 0.5f;

        // 10) FM bells
        float sampleOrnamentL = 0.0f, sampleOrnamentR = 0.0f;
        if (!melActive) {
            if (nextNoiseFloat() > (0.995f - pz * 0.02f)) {
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
            melEnv *= 0.989;
            if (melEnv < 0.001) melActive = false;
            float pan = 0.5f + 0.5f * sin(spatialPanPhase * TWO_PI * 1.2f);
            sampleOrnamentL += tone * 0.3f * (1.0f - pan);
            sampleOrnamentR += tone * 0.3f * pan;
        }
        if (nextNoiseFloat() > (0.9993f - pz * 0.025f)) {
            for (int b = 0; b < 4; ++b) {
                if (!bells[b].active) {
                    bells[b].active = true;
                    bells[b].carrierFreq = 440.0 + (rand() % 6 - 3) * 25.0;
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
                double modulator = sin(bells[b].modPhase * TWO_PI) * 60.0;
                bells[b].carrierPhase += (bells[b].carrierFreq + modulator) / SAMPLE_RATE;
                if (bells[b].carrierPhase >= 1.0) bells[b].carrierPhase -= 1.0;
                float bellSample = float(sin(bells[b].carrierPhase * TWO_PI) * bells[b].env);
                bells[b].env *= 0.994;
                if (bells[b].env < 0.001) { bells[b].active = false; bells[b].env = 0.0f; }
                float pan = 0.3f + 0.7f * (nextNoiseFloat() * 0.5f + 0.5f);
                sampleOrnamentL += bellSample * (1.0f - pan) * 0.2f;
                sampleOrnamentR += bellSample * pan * 0.2f;
            }
        }

        // 11) Ambient pad layer
        float samplePadL = 0.0f, samplePadR = 0.0f;
        if (padEnv > 0.0001) {
            padEnv *= padEnvDecay;
            double detuneAmounts[4] = { -0.01, 0.0, 0.01, 0.02 };
            for (int p = 0; p < 4; ++p) {
                double baseFreq = freqRoot * (1.0 + detuneAmounts[p]);
                padPhase[p] += baseFreq / SAMPLE_RATE;
                if (padPhase[p] >= 1.0) padPhase[p] -= 1.0;
                float saw = float((padPhase[p] * 2.0 - 1.0));
                samplePadL += saw * 0.15f * float(padEnv);
                samplePadR += saw * 0.15f * float(padEnv);
            }
            float padCutoff = 200.0f + float(0.5 + 0.5 * cos(spatialPanPhase * TWO_PI)) * 1000.0f;
            padLPF_L.setLowpass(padCutoff, SAMPLE_RATE);
            padLPF_R.setLowpass(padCutoff * 1.05f, SAMPLE_RATE);
            samplePadL = padLPF_L.process(samplePadL * 0.8f);
            samplePadR = padLPF_R.process(samplePadR * 0.8f);
        }

        // 12) New “Brr” layer: playful constant texture
        // Generate raw noise
        float rawBrr = nextNoiseFloat() * 0.2f;
        // Band-limit to mid-high frequencies (bandpass ~400–1200Hz)
        brrLPF.setLowpass(1200.0f, SAMPLE_RATE);
        float brrLow = brrLPF.process(rawBrr);
        brrHPF.setHighpass(400.0f, SAMPLE_RATE);
        float brrBand = brrHPF.process(brrLow);
        // Modulate amplitude with LFO for a “brrr” flutter
        float brrAmp = 0.3f * float(0.5 + 0.5 * sin(brrLFOPhase * TWO_PI));
        float brrSample = brrBand * brrAmp;
        // Spatial swirl pan for brr
        float brrPan = 0.5f + 0.5f * sin(brrPanPhase * TWO_PI);
        float sampleBrrL = brrSample * (1.0f - brrPan) * 0.4f;
        float sampleBrrR = brrSample * brrPan * 0.4f;

        // 13) Rhythm sequencing (4-beat bar)
        barPhase += tempoFactor / SAMPLE_RATE;
        if (barPhase >= 4.0) {
            barPhase -= 4.0;
            prevBeatStep = -1;
        }
        int beatStep = static_cast<int>(floor(barPhase)) % 4;
        if (beatStep != prevBeatStep) {
            prevBeatStep = beatStep;
            if (!rhythmPattern) {
                if (beatStep == 0) kickEnv.trigger(1.0f, 0.994f);
                if (beatStep == 2) snareEnv.trigger(1.0f, 0.988f);
                hatEnv.trigger(0.5f, 0.96f);
            }
            else {
                if (beatStep == 0 || beatStep == 2) kickEnv.trigger(1.0f, 0.991f);
                if (beatStep == 1 || beatStep == 3) snareEnv.trigger(1.0f, 0.982f);
                hatEnv.trigger(0.4f, 0.94f);
            }
        }
        float eighthPhase = (barPhase - floor(barPhase)) * 2.0f;
        if (rhythmPattern && eighthPhase < (tempoFactor / SAMPLE_RATE)) {
            hatEnv.trigger(0.3f, 0.92f);
        }

        // 14) Percussion synthesis
        float sampleKickL = 0.0f, sampleKickR = 0.0f;
        float sampleSnareL = 0.0f, sampleSnareR = 0.0f;
        float sampleHatL = 0.0f, sampleHatR = 0.0f;

        if (kickEnv.active) {
            kickPhase += 55.0 / SAMPLE_RATE;
            if (kickPhase >= 1.0) kickPhase -= 1.0;
            float k = sin(kickPhase * TWO_PI) * kickEnv.process();
            sampleKickL += k * 0.9f;
            sampleKickR += k * 0.9f;
        }

        if (snareEnv.active) {
            float noise = nextNoiseFloat() * snareEnv.process();
            snareHPF_L.setHighpass(1800.0f, SAMPLE_RATE);
            snareHPF_R.setHighpass(1800.0f, SAMPLE_RATE);
            float s = snareHPF_L.process(noise);
            sampleSnareL += s * 0.6f;
            sampleSnareR += s * 0.6f;
        }

        if (hatEnv.active) {
            float noise = nextNoiseFloat() * hatEnv.process() * 0.3f;
            hatHPF_L.setHighpass(9000.0f, SAMPLE_RATE);
            hatHPF_R.setHighpass(9000.0f, SAMPLE_RATE);
            float hh = hatHPF_L.process(noise);
            if ((i & 1) == 0) sampleHatL += hh * 0.5f;
            else             sampleHatR += hh * 0.5f;
        }

        // 15) Atmospheric wind
        float rawWind = nextNoiseFloat() * 0.25f;
        float windOut = rawWind - prevWindIn + 0.97f * prevWindOut;
        prevWindIn = rawWind;
        prevWindOut = windOut;
        double windLFO = 0.5 + 0.5 * sin(windLFOPhase * TWO_PI);
        float windWet = windOut * float(windLFO) * 0.3f;
        float cutoffWindL = 300.0f + float(filterLFO2) * 400.0f;
        float cutoffWindR = 300.0f + float(filterLFO2) * 450.0f;
        windHPF_L.setHighpass(cutoffWindL, SAMPLE_RATE);
        windHPF_R.setHighpass(cutoffWindR, SAMPLE_RATE);
        float sampleWindL = windHPF_L.process(windWet);
        float sampleWindR = windHPF_R.process(windWet);

        // 16) Granular shaker
        float shaker = 0.0f;
        if (nextNoiseFloat() > 0.9985f) {
            shaker = nextNoiseFloat() * 0.15f;
        }
        static float shakerEnv = 0.0f;
        shakerEnv = shaker > 0.0f ? 1.0f : shakerEnv * 0.95f;
        float sampleShaker = shaker * shakerEnv;
        float sampleShakerL = sampleShaker * 0.5f;
        float sampleShakerR = sampleShaker * 0.5f;

        // 17) Mix dry signals
        float mixL_dry =
            sampleChordL +
            sampleBassL +
            sampleLeadL +
            sampleOrnamentL +
            samplePadL +
            sampleKickL +
            sampleSnareL +
            sampleHatL +
            sampleWindL +
            sampleShakerL +
            sampleBrrL;  // include brr left

        float mixR_dry =
            sampleChordR +
            sampleBassR +
            sampleLeadR +
            sampleOrnamentR +
            samplePadR +
            sampleKickR +
            sampleSnareR +
            sampleHatR +
            sampleWindR +
            sampleShakerR +
            sampleBrrR;  // include brr right

        // 18) Multi-tap ambient reverb (4 taps)
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
            float gain = (t == 0) ? 0.5f : (t == 1) ? 0.35f : (t == 2) ? 0.2f : 0.1f;
            revL += dL * gain;
            revR += dR * gain;
        }
        float fbMixL = mixL_dry + revL * 0.4f;
        float fbMixR = mixR_dry + revR * 0.4f;
        reverbBufferL[reverbWriteIndex] = clampFloat(fbMixL, -1.0f, 1.0f);
        reverbBufferR[reverbWriteIndex] = clampFloat(fbMixR, -1.0f, 1.0f);
        reverbWriteIndex = (reverbWriteIndex + 1) % REVERB_BUFFER_SIZE;

        float outL = clampFloat(mixL_dry + revL * 0.3f, -1.0f, 1.0f);
        float outR = clampFloat(mixR_dry + revR * 0.3f, -1.0f, 1.0f);

        // 19) Final spatial stereo width and rotation
        float width = clampFloat(px * 0.7f + 0.3f, 0.0f, 1.0f);
        float mid = (outL + outR) * 0.5f;
        float side = (outR - outL) * 0.5f * width;
        float rot = float(0.5f + 0.5f * sin(spatialPanPhase * TWO_PI));
        float finalL = clampFloat(mid - side * rot, -1.0f, 1.0f);
        float finalR = clampFloat(mid + side * rot, -1.0f, 1.0f);

        out[2 * i] = finalL;
        out[2 * i + 1] = finalR;
    }
}

// Seed RNG once at start
void seedNoiseGenerator() {
    srand(static_cast<unsigned>(time(nullptr)));
}
