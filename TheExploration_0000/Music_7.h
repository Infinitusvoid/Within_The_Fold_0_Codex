#pragma once

static float clampFloat(float v, float lo, float hi) {
    return (v < lo) ? lo : (v > hi) ? hi : v;
}

constexpr int SCALE_NOTES = 7;
static const double cMajorScale[SCALE_NOTES] = {
    261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88
};

static uint32_t lcgState = 1;
static float nextNoiseFloat() {
    lcgState = 1664525u * lcgState + 1013904223u;
    return float(((lcgState >> 16) & 0xFFFF) / 65535.0 * 2.0 - 1.0);
}

// Enhanced echo buffer with stereo separation
constexpr int ECHO_BUFFER_SIZE = 24000;
static float echoBufferL[ECHO_BUFFER_SIZE] = { 0 };
static float echoBufferR[ECHO_BUFFER_SIZE] = { 0 };
static int echoIndex = 0;

void audio_callback(ma_device* /*device*/, void* pOutput, const void* /*pInput*/, ma_uint32 frameCount) {
    float* out = static_cast<float*>(pOutput);

    float px = g_playerPosX.load(std::memory_order_relaxed);
    float py = g_playerPosY.load(std::memory_order_relaxed);
    float pz = g_playerPosZ.load(std::memory_order_relaxed);

    // Persistent state
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

    const double PI = 3.14159265358979323846;
    const double TWO_PI = 2.0 * PI;

    for (ma_uint32 i = 0; i < frameCount; ++i) {
        // Calculate spatial effects
        float spatialDepth = clampFloat(pz * 0.5f + 0.5f, 0.1f, 1.0f);
        float spatialWidth = clampFloat(px * 0.5f + 0.5f, 0.1f, 1.0f);

        // Dynamic tempo based on player position
        double tempoFactor = 0.5 + 0.5 * sin(px * 4.0);
        tempoFactor = clampFloat(tempoFactor, 0.2f, 2.0f);

        // Chord progression (changes every 2 seconds)
        chordTimeAcc += tempoFactor / AUDIO_SAMPLE_RATE;
        if (chordTimeAcc >= 2.0) {
            chordTimeAcc -= 2.0;
            chordIndex = (chordIndex + 1) % 3;
            chordEnv = 1.0;
        }
        chordEnv *= 0.9995;

        // Chord tones (C, F, G progressions)
        int rootIdx = chordIndex == 0 ? 0 : (chordIndex == 1 ? 3 : 4);
        double freqRoot = cMajorScale[rootIdx] * 0.5;
        double freqThird = cMajorScale[(rootIdx + 2) % SCALE_NOTES] * 0.5;
        double freqFifth = cMajorScale[(rootIdx + 4) % SCALE_NOTES] * 0.5;

        // Update chord phases with spatial modulation
        chordPhase[0] += freqRoot * (1.0 + 0.01 * sin(py * 3.0)) / AUDIO_SAMPLE_RATE;
        chordPhase[1] += freqThird * (1.0 + 0.01 * sin(pz * 3.0)) / AUDIO_SAMPLE_RATE;
        chordPhase[2] += freqFifth * (1.0 + 0.01 * sin(px * 3.0)) / AUDIO_SAMPLE_RATE;

        for (int k = 0; k < 3; ++k) {
            if (chordPhase[k] >= 1.0) chordPhase[k] -= 1.0;
        }

        float sampleChord = (sin(chordPhase[0] * TWO_PI) +
            sin(chordPhase[1] * TWO_PI) +
            sin(chordPhase[2] * TWO_PI)) / 3.0f * chordEnv;

        // Bass follows chord root with Y modulation
        double freqBass = freqRoot * 0.5 * (1.0 + 0.3 * sin(py * 5.0));
        phaseBass += clampFloat(freqBass, 40.0f, 100.0f) / AUDIO_SAMPLE_RATE;
        if (phaseBass >= 1.0) phaseBass -= 1.0;
        float sampleBass = 0.4f * sin(phaseBass * TWO_PI);

        // Stepping lead melody
        stepCounter += tempoFactor / AUDIO_SAMPLE_RATE;
        if (stepCounter >= SCALE_NOTES) stepCounter -= SCALE_NOTES;
        int noteIndex = static_cast<int>(floor(stepCounter)) % SCALE_NOTES;
        double freqLead = cMajorScale[noteIndex];

        lfoMainPhase += 0.2 / AUDIO_SAMPLE_RATE;
        if (lfoMainPhase >= 1.0) lfoMainPhase -= 1.0;
        freqLead *= (1.0 + 0.1 * sin(lfoMainPhase * TWO_PI) + 0.05 * sin(pz * 8.0));

        phaseLead += freqLead / AUDIO_SAMPLE_RATE;
        if (phaseLead >= 1.0) phaseLead -= 1.0;
        float sampleLead = sin(phaseLead * TWO_PI);

        // Random melodic ornaments (triggered by player Z)
        float sampleOrnament = 0.0f;
        if (!melActive) {
            if (nextNoiseFloat() > (0.995f - pz * 0.01f)) {
                melActive = true;
                int idx = rand() % SCALE_NOTES;
                melFreq = cMajorScale[idx] * (2.0 + (rand() % 2));
                melPhase = 0.0;
                melEnv = 1.0;
            }
        }
        if (melActive) {
            melPhase += melFreq / AUDIO_SAMPLE_RATE;
            if (melPhase >= 1.0) melPhase -= 1.0;
            sampleOrnament = sin(melPhase * TWO_PI) * melEnv;
            melEnv *= 0.992;
            if (melEnv < 0.001) melActive = false;
        }

        // Percussive elements
        beatAcc += (1.0 + 2.0 * spatialWidth) / AUDIO_SAMPLE_RATE;
        float samplePerc = 0.0f;
        if (beatAcc >= 1.0) {
            beatAcc -= 1.0;
            samplePerc = nextNoiseFloat() * 0.3f;
        }

        // Atmospheric wind layer
        windLFOPhase += 0.03 / AUDIO_SAMPLE_RATE;
        if (windLFOPhase >= 1.0) windLFOPhase -= 1.0;
        double windLFO = 0.5 + 0.5 * sin(windLFOPhase * TWO_PI);

        float rawWind = nextNoiseFloat() * 0.2f;
        float windOut = rawWind - prevWindIn + 0.995f * prevWindOut;
        prevWindIn = rawWind;
        prevWindOut = windOut;
        float sampleWind = windOut * windLFO;

        // Spatial mixing and panning
        float leadPan = 0.5f + 0.5f * sin(px * 8.0f);
        float ornamentPan = 1.0f - leadPan;
        float windPan = 0.5f + 0.4f * sin(px * 3.0f);

        float mixL =
            sampleChord * 0.6f * spatialDepth +
            sampleBass * 0.5f +
            sampleLead * 0.5f * (1.0f - leadPan) +
            sampleOrnament * 0.7f * (1.0f - ornamentPan) +
            samplePerc * 0.4f * (1.0f - leadPan) +
            sampleWind * 0.4f * (1.0f - windPan);

        float mixR =
            sampleChord * 0.6f * spatialDepth +
            sampleBass * 0.45f +
            sampleLead * 0.5f * leadPan +
            sampleOrnament * 0.7f * ornamentPan +
            samplePerc * 0.4f * leadPan +
            sampleWind * 0.4f * windPan;

        // Enhanced stereo echo effect
        float echoL = echoBufferL[echoIndex];
        float echoR = echoBufferR[echoIndex];

        echoBufferL[echoIndex] = mixL + echoL * 0.6f;
        echoBufferR[echoIndex] = mixR + echoR * 0.5f;
        echoIndex = (echoIndex + 1) % ECHO_BUFFER_SIZE;

        float outL = clampFloat(mixL + echoL * 0.4f, -1.0f, 1.0f);
        float outR = clampFloat(mixR + echoR * 0.4f, -1.0f, 1.0f);

        out[2 * i] = outL;
        out[2 * i + 1] = outR;
    }
}

void seedNoiseGenerator() {
    srand(static_cast<unsigned>(time(nullptr)));
}