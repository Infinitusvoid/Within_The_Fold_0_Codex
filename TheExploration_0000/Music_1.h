#pragma once

#include <array>


// Structure to hold all the state needed for procedural generation
struct MusicState {
    double phaseMain;
    double phaseBright;

    double lfoPhase;

    uint32_t noiseSeed;

    double currentFreq;
    double targetFreq;

    uint32_t samplesUntilNextNote;

    double freqIncrement;
};

static MusicState g_musicState = {
    0.0,    // phaseMain
    0.0,    // phaseBright
    0.0,    // lfoPhase
    13579u, // noiseSeed (arbitrary nonzero start)
    261.63, // currentFreq
    261.63, // targetFreq
    0,      // samplesUntilNextNote (we ll set it in the callback)
    0.0     // freqIncrement
};

constexpr std::array<double, 5> PENTATONIC = {
    261.63, // C4
    293.66, // D4
    329.63, // E4
    392.00, // G4
    440.00  // A4
};


constexpr double NOTE_DURATION_SEC = 4.0;


constexpr double LFO_RATE_HZ = 0.1; // one full cycle every 10 seconds


void audio_callback(ma_device* pDevice, void* pOutput, const void* /*pInput*/, ma_uint32 frameCount) {
    float* output = static_cast<float*>(pOutput);
    (void)pDevice; // unused

    for (ma_uint32 i = 0; i < frameCount; ++i) {
        
        if (g_musicState.samplesUntilNextNote == 0) {
        
            g_musicState.noiseSeed = g_musicState.noiseSeed * 1664525u + 1013904223u;
            uint32_t idx = (g_musicState.noiseSeed >> 16) % PENTATONIC.size();
            g_musicState.targetFreq = PENTATONIC[idx];

        
            g_musicState.samplesUntilNextNote = static_cast<uint32_t>(NOTE_DURATION_SEC * AUDIO_SAMPLE_RATE);

          
            double diff = g_musicState.targetFreq - g_musicState.currentFreq;
            g_musicState.freqIncrement = diff / double(g_musicState.samplesUntilNextNote);
        }

        
        g_musicState.currentFreq += g_musicState.freqIncrement;
        --g_musicState.samplesUntilNextNote;

        // Compute the “bright” oscillator as a perfect fifth above current (ratio = 3/2)
        double brightFreq = g_musicState.currentFreq * 1.5;

        // Update the LFO phase
        g_musicState.lfoPhase += (LFO_RATE_HZ / double(AUDIO_SAMPLE_RATE));
        if (g_musicState.lfoPhase >= 1.0) {
            g_musicState.lfoPhase -= std::floor(g_musicState.lfoPhase);
        }

        // Calculate amplitude modulation from LFO (range 0.75  1.00)
        // Make it never go to zero, just subtly swell and fade
        double lfoValue = std::sin(2.0 * std::numbers::pi * g_musicState.lfoPhase) * 0.125 + 0.875;

        // Generate the main sine wave
        double sampleMain = std::sin(2.0 * std::numbers::pi * g_musicState.phaseMain);

        // Generate the bright sine wave
        double sampleBright = std::sin(2.0 * std::numbers::pi * g_musicState.phaseBright);

        // Generate a small noise component via LCG
        g_musicState.noiseSeed = g_musicState.noiseSeed * 1664525u + 1013904223u;
        float noise = ((g_musicState.noiseSeed >> 16) / 65535.0f) * 2.0f - 1.0f;

        // Mix them:
        //  - main drone at amplitude 0.2
        //  - bright oscillator at amplitude 0.1
        //  - noise at amplitude 0.05
        double mixedSample = sampleMain * 0.20
            + sampleBright * 0.10
            + noise * 0.05;

        // Apply the LFO envelope
        mixedSample *= lfoValue;

        // Advance phases for the next sample
        g_musicState.phaseMain += g_musicState.currentFreq / double(AUDIO_SAMPLE_RATE);
        g_musicState.phaseBright += brightFreq / double(AUDIO_SAMPLE_RATE);

        // Wrap phases into [0,1)
        if (g_musicState.phaseMain >= 1.0) {
            g_musicState.phaseMain -= std::floor(g_musicState.phaseMain);
        }
        if (g_musicState.phaseBright >= 1.0) {
            g_musicState.phaseBright -= std::floor(g_musicState.phaseBright);
        }

        // Write the same sample to left and right channels
        float outF = static_cast<float>(mixedSample);
        output[2 * i + 0] = outF;
        output[2 * i + 1] = outF;
    }
}