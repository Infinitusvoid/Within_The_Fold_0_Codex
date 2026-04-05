
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

void audio_callback(ma_device* /*device*/, void* pOutput, const void* /*pInput*/, ma_uint32 frameCount) {
    float* out = static_cast<float*>(pOutput);

    
    float px = g_playerPosX.load(std::memory_order_relaxed);
    float py = g_playerPosY.load(std::memory_order_relaxed);
    float pz = g_playerPosZ.load(std::memory_order_relaxed);

    
    static double phaseLead = 0.0;
    static double phaseBass = 0.0;
    static double beatAcc = 0.0;
    static double lfoPhase = 0.0;
    static double stepCounter = 0.0;

    
    static uint32_t lcgState = 1;
    auto nextNoise = [&]() -> float {
        lcgState = 1664525u * lcgState + 1013904223u;
        return float(((lcgState >> 16) & 0xFFFF) / 65535.0 * 2.0 - 1.0);
        };

    constexpr double TWO_PI = 2.0 * std::numbers::pi;

    for (ma_uint32 i = 0; i < frameCount; ++i) {
        
        
        double tempoFactor = 0.5 + 0.5 * std::sinf(px * 4.0);
        if (tempoFactor < 0.2) tempoFactor = 0.2;
        if (tempoFactor > 2.0) tempoFactor = 2.0;

        lfoPhase += 0.2 / AUDIO_SAMPLE_RATE;
        if (lfoPhase >= 1.0) lfoPhase -= 1.0;
        double lfo = std::sin(lfoPhase * TWO_PI);

        stepCounter += tempoFactor / AUDIO_SAMPLE_RATE;
        if (stepCounter >= SCALE_NOTES) stepCounter -= SCALE_NOTES;
        int noteIndex = static_cast<int>(std::floor(stepCounter)) % SCALE_NOTES;
        if (noteIndex < 0) noteIndex += SCALE_NOTES;

        double freqLead = cMajorScale[noteIndex];
        freqLead *= (1.0 + 0.1 * lfo + 0.1 * std::sin(pz * 10.0));

        phaseLead += freqLead / AUDIO_SAMPLE_RATE;
        if (phaseLead >= 1.0) phaseLead -= 1.0;
        float sampleLead = static_cast<float>(std::sin(phaseLead * TWO_PI));

        double freqBass = 55.0 * (1.0 + 0.5 * std::sin(py * 10.0));
        if (freqBass < 40.0)  freqBass = 40.0;
        if (freqBass > 100.0) freqBass = 100.0;

        phaseBass += freqBass / AUDIO_SAMPLE_RATE;
        if (phaseBass >= 1.0) phaseBass -= 1.0;
        float sampleBass = 0.5f * static_cast<float>(std::sin(phaseBass * TWO_PI));

        double bpmRate = 1.0 + 3.0 * ((px + 1.0) / 2.0);
        if (bpmRate < 1.0) bpmRate = 1.0;
        if (bpmRate > 4.0) bpmRate = 4.0;

        beatAcc += bpmRate / AUDIO_SAMPLE_RATE;
        float samplePerc = 0.0f;
        if (beatAcc >= 1.0) {
            beatAcc -= 1.0;
            samplePerc = nextNoise() * 0.3f;
        }

        float mixLead = sampleLead * 0.6f;
        float mixBass = sampleBass * 0.3f;
        float mixPerc = samplePerc * 0.4f;

        float leadPan = 0.5f + 0.5f * std::sinf(px * 10.0);
        if (leadPan < 0.0f) leadPan = 0.0f;
        if (leadPan > 1.0f) leadPan = 1.0f;
        float percPan = 1.0f - leadPan;

        float bassLeft = mixBass * 1.0f;
        float bassRight = mixBass * 0.9f;

        float leadLeft = mixLead * (1.0f - leadPan);
        float leadRight = mixLead * leadPan;

        float percLeft = mixPerc * (1.0f - percPan);
        float percRight = mixPerc * percPan;

        float outL = leadLeft + bassLeft + percLeft;
        float outR = leadRight + bassRight + percRight;

        if (outL > 1.0f) outL = 1.0f;
        if (outL < -1.0f) outL = -1.0f;
        if (outR > 1.0f) outR = 1.0f;
        if (outR < -1.0f) outR = -1.0f;

        out[2 * i + 0] = outL;
        out[2 * i + 1] = outR;
    }
}


void seedNoiseGenerator() {
    std::srand(static_cast<unsigned>(std::time(nullptr)));
}