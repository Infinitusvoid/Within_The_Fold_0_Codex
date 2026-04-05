#pragma once 


#include <cmath>
#include <ctime>
#include <cstdlib>

// (2) -- Utility clamp function & scale data
static float clampFloat(float v, float lo, float hi) {
    return (v < lo) ? lo : (v > hi) ? hi : v;
}

constexpr int SCALE_NOTES = 7;
static const double cMajorScale[SCALE_NOTES] = {
    261.63,  // C4
    293.66,  // D4
    329.63,  // E4
    349.23,  // F4
    392.00,  // G4
    440.00,  // A4
    493.88   // B4
};

// (3) -- File-scope LCG state for noise
static uint32_t lcgState = 1;
static float nextNoiseFloat() {
    // Linear-congruential generator -> [-1..+1]
    lcgState = 1664525u * lcgState + 1013904223u;
    return float(((lcgState >> 16) & 0xFFFF) / 65535.0 * 2.0 - 1.0);
}

// (4) -- PAD / ECHO state (moved to file scope so that echoIndex is always known)
static float  echoBuffer[24000];    // ~0.5 seconds at 48 kHz
static int    echoIndex = 0;

// (5) -- The audio callback itself
void audio_callback(ma_device* /*device*/, void* pOutput, const void* /*pInput*/, ma_uint32 frameCount) {
    float* out = static_cast<float*>(pOutput);

    // Read player position (assumed in roughly [-1..+1])
    float px = g_playerPosX.load(std::memory_order_relaxed);
    float py = g_playerPosY.load(std::memory_order_relaxed);
    float pz = g_playerPosZ.load(std::memory_order_relaxed);

    // -- Persistent state across all callbacks --
    static double phaseLead = 0.0;
    static double phaseBass = 0.0;
    static double beatAcc = 0.0;
    static double lfoPhase = 0.0;
    static double stepCounter = 0.0;

    // PAD (drone) LFO/filter state
    static double lfoPhasePad = 0.0;
    static float  noiseLP = 0.0f;
    static float  lastPadSample = 0.0f;

    // BELL (random chime) state
    static bool   bellActive = false;
    static double bellPhase = 0.0;
    static double bellEnv = 0.0;
    static double bellFreq = 0.0;
    // ----------------------------------------------

    const double TWO_PI = 2.0 * 3.14159265358979323846;

    for (ma_uint32 i = 0; i < frameCount; ++i) {
        // (1) LEAD Arpeggio
        double tempoFactor = 0.5 + 0.5 * std::sin(px * 4.0);
        tempoFactor = clampFloat(float(tempoFactor), 0.2f, 2.0f);

        lfoPhase += 0.2 / AUDIO_SAMPLE_RATE;
        if (lfoPhase >= 1.0) lfoPhase -= 1.0;
        double lfoLead = std::sin(lfoPhase * TWO_PI);

        stepCounter += tempoFactor / AUDIO_SAMPLE_RATE;
        if (stepCounter >= SCALE_NOTES) stepCounter -= SCALE_NOTES;
        int noteIndex = static_cast<int>(std::floor(stepCounter)) % SCALE_NOTES;
        if (noteIndex < 0) noteIndex += SCALE_NOTES;

        double freqLead = cMajorScale[noteIndex];
        freqLead *= (1.0 + 0.05 * lfoLead + 0.05 * std::sin(pz * 10.0));

        phaseLead += freqLead / AUDIO_SAMPLE_RATE;
        if (phaseLead >= 1.0) phaseLead -= 1.0;
        float sampleLead = static_cast<float>(std::sin(phaseLead * TWO_PI));

        // (2) BASS Drone
        double baseBass = 55.0;
        double modBass = 0.5 * std::sin(py * 10.0);
        double freqBass = baseBass * (1.0 + modBass);
        freqBass = clampFloat(float(freqBass), 40.0f, 100.0f);

        phaseBass += freqBass / AUDIO_SAMPLE_RATE;
        if (phaseBass >= 1.0) phaseBass -= 1.0;
        float sampleBass = 0.5f * static_cast<float>(std::sin(phaseBass * TWO_PI));

        // (3) Percussive Click
        double bpmRate = 1.0 + 3.0 * ((px + 1.0) / 2.0);
        bpmRate = clampFloat(float(bpmRate), 1.0f, 4.0f);
        beatAcc += bpmRate / AUDIO_SAMPLE_RATE;

        float samplePerc = 0.0f;
        if (beatAcc >= 1.0) {
            beatAcc -= 1.0;
            samplePerc = nextNoiseFloat() * 0.25f;
        }

        // (4) Evolving Noise Pad + Simple Feedback Echo
        lfoPhasePad += 0.05 / AUDIO_SAMPLE_RATE;
        if (lfoPhasePad >= 1.0) lfoPhasePad -= 1.0;
        double lfoPadAmp = 0.5 + 0.5 * std::sin(lfoPhasePad * TWO_PI);

        float rawNoise = nextNoiseFloat() * 0.3f;
        noiseLP = 0.995f * noiseLP + 0.005f * rawNoise;
        float padRaw = noiseLP + 0.02f * sampleLead;
        float padSmoothed = 0.9f * lastPadSample + 0.1f * padRaw;
        lastPadSample = padSmoothed;

        // Pull one sample from the echo buffer
        float echoSample = echoBuffer[echoIndex];
        // Write new value into the buffer (simple feedback)
        echoBuffer[echoIndex] = padSmoothed + 0.3f * echoSample;
        if (++echoIndex >= 24000) echoIndex = 0;

        float samplePad = (padSmoothed + 0.4f * echoSample) * float(lfoPadAmp * 0.5);

        // (5) Random Bell Chime
        if (!bellActive) {
            double threshold = 0.9995 + 0.0005 * (pz * 0.5 + 0.5);
            if (nextNoiseFloat() > threshold) {
                bellActive = true;
                int idx = std::rand() % SCALE_NOTES;
                bellFreq = cMajorScale[idx] * 2.0;  // one octave up
                bellPhase = 0.0;
                bellEnv = 1.0;
            }
        }

        float sampleBell = 0.0f;
        if (bellActive) {
            bellPhase += bellFreq / AUDIO_SAMPLE_RATE;
            if (bellPhase >= 1.0) bellPhase -= 1.0;
            sampleBell = float(std::sin(bellPhase * TWO_PI) * bellEnv);
            bellEnv *= 0.998;
            if (bellEnv < 0.001) bellActive = false;
        }

        // (6) MIX & PAN
        float mixLead = sampleLead * 0.5f;
        float mixBass = sampleBass * 0.3f;
        float mixPerc = samplePerc * 0.3f;
        float mixPad = samplePad * 0.6f;
        float mixBell = sampleBell * 0.4f;

        // PAN lead based on px
        float leadPan = 0.5f + 0.5f * std::sin(px * 8.0f);
        leadPan = clampFloat(leadPan, 0.0f, 1.0f);
        float bassLeft = mixBass * 1.0f;
        float bassRight = mixBass * 0.9f;
        float leadLeft = mixLead * (1.0f - leadPan);
        float leadRight = mixLead * leadPan;

        // PAD centered but drifting a bit
        float padPan = 0.5f + 0.5f * std::sin(lfoPhasePad * TWO_PI + px * 2.0f);
        padPan = clampFloat(padPan, 0.0f, 1.0f);
        float padLeft = mixPad * (1.0f - padPan);
        float padRight = mixPad * padPan;

        // Perc click panned opposite lead
        float percPan = 1.0f - leadPan;
        float percLeft = mixPerc * (1.0f - percPan);
        float percRight = mixPerc * percPan;

        // Bell slightly to the right
        float bellLeft = mixBell * 0.4f;
        float bellRight = mixBell * 0.6f;

        float outL = leadLeft + bassLeft + percLeft + padLeft + bellLeft;
        float outR = leadRight + bassRight + percRight + padRight + bellRight;

        outL = clampFloat(outL, -1.0f, 1.0f);
        outR = clampFloat(outR, -1.0f, 1.0f);

        out[2 * i + 0] = outL;
        out[2 * i + 1] = outR;
    }
}

// (6) -- Seed the random-number generator once at startup
void seedNoiseGenerator() {
    std::srand(static_cast<unsigned>(std::time(nullptr)));
}
