// Clamp a float between lo and hi.
static float clampFloat(float v, float lo, float hi) {
    return (v < lo) ? lo : (v > hi) ? hi : v;
}

// The C major scale used for the melodic lead.
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

    // Load player positions (assume these are defined externally)
    float px = g_playerPosX.load(std::memory_order_relaxed);
    float py = g_playerPosY.load(std::memory_order_relaxed);
    float pz = g_playerPosZ.load(std::memory_order_relaxed);

    // Existing phase variables for lead, bass, beat and LFO.
    static double phaseLead = 0.0;
    static double phaseBass = 0.0;
    static double beatAcc = 0.0;
    static double lfoPhase = 0.0;
    static double stepCounter = 0.0;

    // NEW: Phase variables for the pad (drone) layer.
    static double phasePad1 = 0.0, phasePad2 = 0.0, phasePad3 = 0.0;
    // We'll use chord tones from the C major chord: C, E, and G.
    const double padFreqs[3] = { cMajorScale[0], cMajorScale[2], cMajorScale[4] };

    // NEW: Simple delay buffers for a basic reverb effect.
    constexpr int delayBufferSize = AUDIO_SAMPLE_RATE / 2; // 0.5 second delay
    static float delayBufferL[delayBufferSize] = { 0 };
    static float delayBufferR[delayBufferSize] = { 0 };
    static int delayIndex = 0;

    // Noise generator state for the percussive element.
    static uint32_t lcgState = 1;
    auto nextNoise = [&]() -> float {
        lcgState = 1664525u * lcgState + 1013904223u;
        return float(((lcgState >> 16) & 0xFFFF) / 65535.0 * 2.0 - 1.0);
        };

    constexpr double TWO_PI = 2.0 * std::numbers::pi;

    for (ma_uint32 i = 0; i < frameCount; ++i) {

        // Determine a tempo factor based on the player's X position.
        double tempoFactor = 0.5 + 0.5 * sin(px * 4.0);
        if (tempoFactor < 0.2) tempoFactor = 0.2;
        if (tempoFactor > 2.0) tempoFactor = 2.0;

        // Update LFO phase for subtle rhythmic modulation.
        lfoPhase += 0.2 / AUDIO_SAMPLE_RATE;
        if (lfoPhase >= 1.0) lfoPhase -= 1.0;
        double lfo = sin(lfoPhase * TWO_PI);

        // Advance the note sequence for the lead melody.
        stepCounter += tempoFactor / AUDIO_SAMPLE_RATE;
        if (stepCounter >= SCALE_NOTES) stepCounter -= SCALE_NOTES;
        int noteIndex = static_cast<int>(floor(stepCounter)) % SCALE_NOTES;
        if (noteIndex < 0) noteIndex += SCALE_NOTES;
        double freqLead = cMajorScale[noteIndex];
        freqLead *= (1.0 + 0.1 * lfo + 0.1 * sin(pz * 10.0));

        // Compute lead phase and sample.
        phaseLead += freqLead / AUDIO_SAMPLE_RATE;
        if (phaseLead >= 1.0) phaseLead -= 1.0;
        float sampleLead = static_cast<float>(sin(phaseLead * TWO_PI));

        // Bass component modulated by player Y.
        double freqBass = 55.0 * (1.0 + 0.5 * sin(py * 10.0));
        if (freqBass < 40.0)  freqBass = 40.0;
        if (freqBass > 100.0) freqBass = 100.0;
        phaseBass += freqBass / AUDIO_SAMPLE_RATE;
        if (phaseBass >= 1.0) phaseBass -= 1.0;
        float sampleBass = 0.5f * static_cast<float>(sin(phaseBass * TWO_PI));

        // Percussive noise element synced with an internal beat.
        double bpmRate = 1.0 + 3.0 * ((px + 1.0) / 2.0);
        if (bpmRate < 1.0) bpmRate = 1.0;
        if (bpmRate > 4.0) bpmRate = 4.0;
        beatAcc += bpmRate / AUDIO_SAMPLE_RATE;
        float samplePerc = 0.0f;
        if (beatAcc >= 1.0) {
            beatAcc -= 1.0;
            samplePerc = nextNoise() * 0.3f;
        }

        // NEW: Ambient pad layer - a smooth drone based on a C major chord.
        // Each pad oscillator is slightly modulated by the player's positions.
        phasePad1 += (padFreqs[0] * (1.0 + 0.005 * sin(px * 3.0))) / AUDIO_SAMPLE_RATE;
        phasePad2 += (padFreqs[1] * (1.0 + 0.005 * sin(py * 3.0))) / AUDIO_SAMPLE_RATE;
        phasePad3 += (padFreqs[2] * (1.0 + 0.005 * sin(pz * 3.0))) / AUDIO_SAMPLE_RATE;
        if (phasePad1 >= 1.0) phasePad1 -= 1.0;
        if (phasePad2 >= 1.0) phasePad2 -= 1.0;
        if (phasePad3 >= 1.0) phasePad3 -= 1.0;
        float samplePad = 0.0f;
        samplePad += 0.3f * static_cast<float>(sin(phasePad1 * TWO_PI));
        samplePad += 0.3f * static_cast<float>(sin(phasePad2 * TWO_PI));
        samplePad += 0.3f * static_cast<float>(sin(phasePad3 * TWO_PI));
        samplePad /= 3.0f;

        // Mix the layers with individual gains.
        float mixLead = sampleLead * 0.5f;
        float mixBass = sampleBass * 0.4f;
        float mixPerc = samplePerc * 0.3f;
        float mixPad = samplePad * 0.5f;

        // Pan the lead and percussive elements based on player position.
        float leadPan = 0.5f + 0.5f * sin(px * 10.0);
        if (leadPan < 0.0f) leadPan = 0.0f;
        if (leadPan > 1.0f) leadPan = 1.0f;
        float percPan = 1.0f - leadPan;

        float bassLeft = mixBass * 1.0f;
        float bassRight = mixBass * 0.9f;

        float leadLeft = mixLead * (1.0f - leadPan);
        float leadRight = mixLead * leadPan;

        float percLeft = mixPerc * (1.0f - percPan);
        float percRight = mixPerc * percPan;

        // The pad remains centered.
        float padLeft = mixPad;
        float padRight = mixPad;

        // Sum the dry (non-delayed) signal for each stereo channel.
        float dryLeft = leadLeft + bassLeft + percLeft + padLeft;
        float dryRight = leadRight + bassRight + percRight + padRight;

        // NEW: Apply a simple delay (reverb) effect.
        float delayedLeft = delayBufferL[delayIndex];
        float delayedRight = delayBufferR[delayIndex];

        // Write a blend of the current signal and the previously delayed signal.
        delayBufferL[delayIndex] = dryLeft + delayedLeft * 0.2f;
        delayBufferR[delayIndex] = dryRight + delayedRight * 0.2f;
        delayIndex = (delayIndex + 1) % delayBufferSize;

        // Mix the dry and wet signals. Clamp to avoid clipping.
        float outL = clampFloat(dryLeft * 0.8f + delayedLeft * 0.2f, -1.0f, 1.0f);
        float outR = clampFloat(dryRight * 0.8f + delayedRight * 0.2f, -1.0f, 1.0f);

        out[2 * i + 0] = outL;
        out[2 * i + 1] = outR;
    }
}

// Function to seed the noise generator.
void seedNoiseGenerator() {
    std::srand(static_cast<unsigned>(std::time(nullptr)));
}
