#pragma once

// Structure to hold audio generation state (phases for oscillators, etc.)
struct MusicState {
    double phase1;
    double phase2;
    unsigned int noiseSeed;
} g_musicState = { 0.0, 0.0, 22222 };  // initialize phases to 0, noise seed to an arbitrary value

// Audio callback function: this is called on a separate audio thread by miniaudio to fill the output buffer.
void audio_callback(ma_device* pDevice, void* pOutput, const void* pInput, ma_uint32 frameCount)
{
    float* output = static_cast<float*>(pOutput);
    (void)pInput;  // Input not used (playback only)

    // Generate `frameCount` audio frames of output :contentReference[oaicite:6]{index=6}.
    for (ma_uint32 i = 0; i < frameCount; ++i) {
        // Read the current game state (atomic vars ensure thread-safe reads)
        float playerX = g_playerPosX.load();
        bool  enemyFlag = g_enemyActive.load();

        // Determine music parameters based on game state
        float baseFreq = 220.0f;              // Base tone frequency (220 Hz = A3 note)
        baseFreq += playerX * 0.5f;           // Vary base frequency with player position (demo effect)
        float highFreq = baseFreq * 2.0f;     // Second tone an octave above base
        float noiseLevel = 0.1f;              // Base background noise level
        if (enemyFlag) {
            // If enemy is active, make music more intense
            highFreq *= 1.5f;                // increase high tone frequency (adds tension)
            noiseLevel = 0.3f;               // increase noise volume for a "harsher" sound
        }

        // Generate audio sample (procedural ambient sound)
        // Two sine waves (base and high tone)
        float sample = sinf(2.0f * float(std::numbers::pi) * g_musicState.phase1) * 0.2f;   // base tone (amplitude 0.2)
        sample += sinf(4.0f * float(std::numbers::pi) * g_musicState.phase2) * 0.15f;  // high tone (amplitude 0.15)
        // Add a noise component (simple pseudo-random noise)
        g_musicState.noiseSeed = g_musicState.noiseSeed * 1664525u + 1013904223u; // Linear Congruential Generator
        // Use high 16 bits of noiseSeed as random value and scale to [-1,1]
        float noiseSample = ((g_musicState.noiseSeed >> 16) / 65535.0f) * 2.0f - 1.0f;
        sample += noiseSample * noiseLevel;  // scaled noise added to the mix

        // Increment phase for next sample (phase is fractional, 1.0 = full cycle)
        g_musicState.phase1 += baseFreq / AUDIO_SAMPLE_RATE;
        g_musicState.phase2 += highFreq / AUDIO_SAMPLE_RATE;
        // Wrap phase values to [0,1) to prevent floating-point drift
        if (g_musicState.phase1 >= 1.0) g_musicState.phase1 -= floor(g_musicState.phase1);
        if (g_musicState.phase2 >= 1.0) g_musicState.phase2 -= floor(g_musicState.phase2);

        // Write the same sample to both left and right channels (stereo output)
        output[2 * i + 0] = sample;
        output[2 * i + 1] = sample;
    }
}