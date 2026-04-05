#pragma once

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

// (4) -- ECHO buffer for simple reverb
static float  echoBuffer[24000];    // about 0.5 seconds at 48 kHz (stereo interleaved)
static int    echoIndex = 0;

// (5) -- The audio callback itself
void audio_callback(ma_device* /*device*/, void* pOutput, const void* /*pInput*/, ma_uint32 frameCount) {
    float* out = static_cast<float*>(pOutput);

    // Read player position (assumed in roughly [-1..+1])
    float px = g_playerPosX.load(std::memory_order_relaxed);
    float py = g_playerPosY.load(std::memory_order_relaxed);
    float pz = g_playerPosZ.load(std::memory_order_relaxed);

    // -- Persistent state across all callbacks --
    static double leadPhase = 0.0;
    static double melPhase = 0.0;
    static double melEnv = 0.0;
    static double melFreq = 0.0;
    static bool   melActive = false;

    static double chordPhase[3] = { 0.0, 0.0, 0.0 };
    static int    chordIndex = 0;
    static double chordEnv = 0.0;
    static double chordTimeAcc = 0.0;

    static double windLFOPhase = 0.0;
    static float  prevWindIn = 0.0f;
    static float  prevWindOut = 0.0f;

    static double lfoMainPhase = 0.0;
    // ----------------------------------------------------------

    const double PI = 3.14159265358979323846;
    const double TWO_PI = 2.0 * PI;

    for (ma_uint32 i = 0; i < frameCount; ++i) {
        // ==========================
        // (1) CHORD PROGRESSION
        // ==========================
        // Cycle chord every about 2 seconds:
        chordTimeAcc += 1.0 / AUDIO_SAMPLE_RATE;
        if (chordTimeAcc >= 2.0) {
            chordTimeAcc -= 2.0;
            chordIndex = (chordIndex + 1) % 3; // 3 chords: C, F, G
            chordEnv = 1.0;                    // reset attack
        }
        // Ramp chordEnv down slowly
        if (chordEnv > 0.0) chordEnv *= 0.9999;

        // Determine root index (C=0, F=3, G=4 in C major)
        int rootScaleIdx;
        if (chordIndex == 0) rootScaleIdx = 0; // C
        else if (chordIndex == 1) rootScaleIdx = 3; // F
        else rootScaleIdx = 4; // G

        // Build triad: root, third, fifth (one octave lower)
        int thirdIdx = (rootScaleIdx + 2) % SCALE_NOTES;
        int fifthIdx = (rootScaleIdx + 4) % SCALE_NOTES;

        double freqRoot = cMajorScale[rootScaleIdx] * 0.5;   // C3, F3, G3
        double freqThird = cMajorScale[thirdIdx] * 0.5;   // E3, A3, B3
        double freqFifth = cMajorScale[fifthIdx] * 0.5;   // G3, C4, D4

        // Advance each voice's phase
        chordPhase[0] += freqRoot / AUDIO_SAMPLE_RATE;
        chordPhase[1] += freqThird / AUDIO_SAMPLE_RATE;
        chordPhase[2] += freqFifth / AUDIO_SAMPLE_RATE;
        for (int k = 0; k < 3; ++k) {
            if (chordPhase[k] >= 1.0) chordPhase[k] -= 1.0;
        }
        float sampleRoot = static_cast<float>(std::sin(chordPhase[0] * TWO_PI));
        float sampleThird = static_cast<float>(std::sin(chordPhase[1] * TWO_PI));
        float sampleFifth = static_cast<float>(std::sin(chordPhase[2] * TWO_PI));
        float sampleChord = (sampleRoot + sampleThird + sampleFifth) / 3.0f;
        sampleChord *= static_cast<float>(0.5 * chordEnv); // chord volume

        // ==========================
        // (2) WIND NOISE
        // ==========================
        // White noise -> high-pass filter -> LFO modulated amplitude
        windLFOPhase += 0.03 / AUDIO_SAMPLE_RATE;
        if (windLFOPhase >= 1.0) windLFOPhase -= 1.0;
        double windLFO = 0.5 + 0.5 * std::sin(windLFOPhase * TWO_PI);

        float rawWind = nextNoiseFloat() * 0.3f;
        // One-pole high-pass: y[n] = x[n] - x[n-1] + R * y[n-1]
        // Choose R close to 0.995 for gentle cutoff around 200 Hz
        float hpR = 0.995f;
        float windOut = rawWind - prevWindIn + hpR * prevWindOut;
        prevWindIn = rawWind;
        prevWindOut = windOut;
        float sampleWind = windOut * static_cast<float>(windLFO * 0.4);

        // ==========================
        // (3) LEAD MELODY (random note occasionally)
        // ==========================
        // Occasionally trigger a bright melody note (flute-like)
        if (!melActive) {
            // Probability influenced by player Z (more forward => more active)
            double thresh = 0.998 + 0.002 * (pz * 0.5 + 0.5);
            if (nextNoiseFloat() > thresh) {
                melActive = true;
                // pick random scale degree and octave (4th or 5th octave)
                int idx = std::rand() % SCALE_NOTES;
                double octave = (std::rand() & 1) ? 2.0 : 4.0; // 2.0 => 5th octave, 4.0 => 7th octave
                melFreq = cMajorScale[idx] * octave;
                melPhase = 0.0;
                melEnv = 1.0;
            }
        }
        float sampleMel = 0.0f;
        if (melActive) {
            melPhase += melFreq / AUDIO_SAMPLE_RATE;
            if (melPhase >= 1.0) melPhase -= 1.0;
            // Simple sine with exponential decay
            sampleMel = static_cast<float>(std::sin(melPhase * TWO_PI) * melEnv);
            melEnv *= 0.995;
            if (melEnv < 0.001) melActive = false;
        }

        // ==========================
        // (4) MIX & ECHO REVERB
        // ==========================
        float mixChord = sampleChord * 0.5f;  // warm background
        float mixWind = sampleWind * 0.3f;  // airy texture
        float mixMel = sampleMel * 0.6f;  // bright melody

        // Simple stereo panning:
        // - Chord centered
        float chordLeft = mixChord;
        float chordRight = mixChord;
        // - Wind slightly wide, modulated by player X
        float windPan = 0.5f + 0.5f * std::sin(px * 5.0f);
        windPan = clampFloat(windPan, 0.0f, 1.0f);
        float windLeft = mixWind * (1.0f - windPan);
        float windRight = mixWind * windPan;
        // - Melody panned based on player X more strongly
        float melPan = 0.5f + 0.5f * std::sin(px * 10.0f);
        melPan = clampFloat(melPan, 0.0f, 1.0f);
        float melLeft = mixMel * (1.0f - melPan);
        float melRight = mixMel * melPan;

        // Sum dry signals
        float dryL = chordLeft + windLeft + melLeft;
        float dryR = chordRight + windRight + melRight;

        // Write into echo buffer for reverb-like tail (interleaved stereo)
        float echoInL = dryL + 0.4f * echoBuffer[echoIndex];
        float echoInR = dryR + 0.4f * echoBuffer[echoIndex + 1];
        echoBuffer[echoIndex] = echoInL;
        echoBuffer[echoIndex + 1] = echoInR;
        int nextEchoIndex = echoIndex + 2;
        if (nextEchoIndex >= 24000) nextEchoIndex = 0;
        echoIndex = nextEchoIndex;

        // Output is mix of dry + small echo
        float outL = dryL + 0.3f * echoInL;
        float outR = dryR + 0.3f * echoInR;

        // Clamp final output
        outL = clampFloat(outL, -1.0f, 1.0f);
        outR = clampFloat(outR, -1.0f, 1.0f);

        if (g_play_audio.load())
        {
            out[2 * i + 0] = outL;
            out[2 * i + 1] = outR;
        }
        else
        {
            out[2 * i + 0] = 0.0f;
            out[2 * i + 1] = 0.f;
        }
    }
}

// (6) -- Seed the random-number generator once at startup
void seedNoiseGenerator() {
    std::srand(static_cast<unsigned>(std::time(nullptr)));
}
