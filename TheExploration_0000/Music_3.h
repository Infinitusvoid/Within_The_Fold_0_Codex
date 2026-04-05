#pragma once

#define TWO_PI std::numbers::pi * 2.0


// --- Helper Functions ---
static float clampFloat(float v, float lo, float hi) {
    return (v < lo) ? lo : (v > hi) ? hi : v;
}

// Simple Linear Congruential Generator for noise
static uint32_t s_lcgState = 12345; // Seed
float next_random_float() {
    s_lcgState = 1664525u * s_lcgState + 1013904223u;
    return static_cast<float>(s_lcgState & 0xFFFF) / 65535.0f; // 0.0 to 1.0
}
float next_random_signed_float() {
    return next_random_float() * 2.0f - 1.0f; // -1.0 to 1.0
}

// Simple Attack-Release Envelope
// attackTime and releaseTime in seconds
struct AREnvelope {
    double attackTimeSamples;
    double releaseTimeSamples;
    double currentTimeSamples;
    bool active;
    bool releasing;

    AREnvelope(double attack, double release)
        : attackTimeSamples(attack* AUDIO_SAMPLE_RATE),
        releaseTimeSamples(release* AUDIO_SAMPLE_RATE),
        currentTimeSamples(0),
        active(false),
        releasing(false) {
    }

    void trigger() {
        active = true;
        releasing = false;
        currentTimeSamples = 0;
    }

    void release() {
        if (active) {
            releasing = true;
            // CurrentTimeSamples keeps its value to start release from current amp
        }
    }

    float process() {
        if (!active) return 0.0f;

        float amp = 0.0f;
        if (!releasing) { // Attack phase
            if (currentTimeSamples < attackTimeSamples) {
                amp = static_cast<float>(currentTimeSamples / attackTimeSamples);
                currentTimeSamples++;
            }
            else {
                amp = 1.0f; // Sustain implicitly at 1.0 until release
            }
        }
        else { // Release phase
            if (currentTimeSamples < releaseTimeSamples) { // Check if releaseTimeSamples is 0
                if (releaseTimeSamples > 0) { // Avoid division by zero
                    amp = 1.0f - static_cast<float>(currentTimeSamples / releaseTimeSamples);
                }
                else {
                    amp = 0.0f; // Instant release if releaseTimeSamples is 0
                }
                currentTimeSamples++;
            }
            else {
                amp = 0.0f;
                active = false; // Envelope finished
            }
        }
        return clampFloat(amp, 0.0f, 1.0f);
    }

    // Simpler version for things that don't need a hold/sustain
    // Trigger will play attack and then immediately go to release
    void trigger_oneshot() {
        active = true;
        releasing = false;
        currentTimeSamples = 0;
    }

    float process_oneshot() {
        if (!active) return 0.0f;

        float amp = 0.0f;
        if (currentTimeSamples < attackTimeSamples) { // Attack
            amp = (attackTimeSamples > 0) ? static_cast<float>(currentTimeSamples / attackTimeSamples) : 1.0f;
            currentTimeSamples++;
            if (currentTimeSamples >= attackTimeSamples) {
                releasing = true; // Automatically start releasing after attack
                currentTimeSamples = 0; // Reset for release phase
            }
        }
        else if (releasing) { // Release
            if (currentTimeSamples < releaseTimeSamples) {
                amp = (releaseTimeSamples > 0) ? (1.0f - static_cast<float>(currentTimeSamples / releaseTimeSamples)) : 0.0f;
                currentTimeSamples++;
            }
            else {
                amp = 0.0f;
                active = false;
            }
        }
        return clampFloat(amp, 0.0f, 1.0f);
    }
};


// --- Scales ---
// C Minor Pentatonic: C, Eb, F, G, Bb
const double cMinorPentatonic[] = { 261.63, 311.13, 349.23, 392.00, 466.16 };
const int NUM_CMINORPENT_NOTES = sizeof(cMinorPentatonic) / sizeof(double);

// C Dorian: C, D, Eb, F, G, A, Bb
const double cDorian[] = { 261.63, 293.66, 311.13, 349.23, 392.00, 440.00, 466.16 };
const int NUM_CDORIAN_NOTES = sizeof(cDorian) / sizeof(double);

// A Lydian Dominant (for a floaty, slightly tense space feel) A, B, C#, D#, E, F#, G
// (Actually, let's use C Lydian for simplicity: C, D, E, F#, G, A, B)
const double cLydian[] = { 261.63, 293.66, 329.63, 369.99, 392.00, 440.00, 493.88 }; // F# is 369.99
const int NUM_CLYDIAN_NOTES = sizeof(cLydian) / sizeof(double);


// --- Global Audio State (static variables from your example, plus new ones) ---
static double g_masterTime = 0.0; // To keep track of overall time

// Pad state
constexpr int NUM_PAD_OSCILLATORS = 4;
static double g_padPhases[NUM_PAD_OSCILLATORS] = { 0.0 };
static double g_padLfoPhases[NUM_PAD_OSCILLATORS] = { 0.0 }; // For amplitude modulation
static int g_padChordStep = 0;
static double g_padChordStepCounter = 0.0;

// Arpeggiator state
static double g_arpPhase = 0.0;
static AREnvelope g_arpEnv(0.05, 0.3); // Quick attack, medium release
static int g_arpNoteIndex = 0;
static double g_arpStepCounter = 0.0;
static double g_arpOctave = 1.0; // Multiplier for arp frequency

// Cosmic Dust state
constexpr int NUM_DUST_PARTICLES = 5;
static double g_dustPhases[NUM_DUST_PARTICLES] = { 0.0 };
static double g_dustFreqs[NUM_DUST_PARTICLES] = { 0.0 };
static AREnvelope g_dustEnvs[NUM_DUST_PARTICLES] = { AREnvelope(0.01, 0.5), AREnvelope(0.02, 0.6), AREnvelope(0.015, 0.4), AREnvelope(0.025, 0.7), AREnvelope(0.01, 0.55) };
static double g_dustTriggerCounter = 0.0;

// Bass Drone state
static double g_bassPhase = 0.0;
static AREnvelope g_bassEnv(2.0, 3.0); // Slow attack, slow release for drone
static int g_bassNoteIndex = 0; // Will follow pad's root

// Rhythmic Pulse state
static double g_pulsePhase = 0.0;
static AREnvelope g_pulseEnv(0.005, 0.1); // Very short, plucky
static double g_pulseBeatAccumulator = 0.0;

// General LFO for panning or subtle global effects
static double g_globalLfoPhase = 0.0;


void audio_callback(ma_device* /*device*/, void* pOutput, const void* /*pInput*/, ma_uint32 frameCount) {
    float* out = static_cast<float*>(pOutput);

    // Get player positions (atomic loads)
    float px = g_playerPosX.load(std::memory_order_relaxed); // Range -1 to 1 typically
    float py = g_playerPosY.load(std::memory_order_relaxed);
    float pz = g_playerPosZ.load(std::memory_order_relaxed);

    // --- Parameter Mapping from Player Position ---
    // Map px, py, pz to values between 0 and 1 for easier use
    float pxf = (px + 1.0f) * 0.5f; // 0 to 1
    float pyf = (py + 1.0f) * 0.5f; // 0 to 1
    float pzf = (pz + 1.0f) * 0.5f; // 0 to 1

    // Select scale based on pz
    const double* currentScale;
    int numScaleNotes;
    int scaleChoice = static_cast<int>(pzf * 3.0f); // 0, 1, or 2
    if (scaleChoice == 0) {
        currentScale = cMinorPentatonic;
        numScaleNotes = NUM_CMINORPENT_NOTES;
    }
    else if (scaleChoice == 1) {
        currentScale = cDorian;
        numScaleNotes = NUM_CDORIAN_NOTES;
    }
    else {
        currentScale = cLydian;
        numScaleNotes = NUM_CLYDIAN_NOTES;
    }

    // Tempo for rhythmic elements (BPM-like)
    // Lower pxf = slower, higher pxf = faster. Let's aim for 30-120 BPM range.
    double baseBPM = 30.0 + pxf * 90.0; // Range: 30 to 120 BPM
    double beatsPerSample = baseBPM / 60.0 / AUDIO_SAMPLE_RATE;

    // Arp speed: pxf also influences this, but let's add more range
    double arpNotesPerSecond = 1.0 + pxf * 7.0; // 1 to 8 notes per second
    double arpNoteDurationSamples = AUDIO_SAMPLE_RATE / arpNotesPerSecond;

    // Pad chord progression speed (slower)
    double padChordChangeSeconds = 4.0 + (1.0 - pzf) * 8.0; // 4 to 12 seconds per chord change
    double padChordChangeSamples = padChordChangeSeconds * AUDIO_SAMPLE_RATE;

    // Cosmic dust trigger rate
    double dustTriggersPerSecond = 0.2 + pyf * 2.0; // 0.2 to 2.2 triggers per second
    double dustTriggerIntervalSamples = AUDIO_SAMPLE_RATE / dustTriggersPerSecond;

    // Arp Octave based on py
    // pyf = 0 -> 0.5 (octave down), pyf = 0.5 -> 1.0 (base), pyf = 1.0 -> 2.0 (octave up)
    g_arpOctave = std::pow(2.0, (pyf - 0.5) * 2.0); // pyf maps to -1 to 1 for exponent

    // Bass Envelope decay (pz affects sustain)
    g_bassEnv.releaseTimeSamples = (1.0 + pzf * 4.0) * AUDIO_SAMPLE_RATE; // 1 to 5 sec release

    // --- Main Audio Loop ---
    for (ma_uint32 i = 0; i < frameCount; ++i) {
        g_masterTime += 1.0 / AUDIO_SAMPLE_RATE;

        // --- 1. Atmospheric Pad ---
        float padSample = 0.0f;

        // Pad Chord Progression (simple I-IV-V-I-ish, relative to scale root)
        // Using indices: 0 (root), N/2 (middle), N-1 (highest in scale for dominant feel)
        int chordRootsIndices[] = { 0, numScaleNotes / 2, (numScaleNotes * 3) / 4, numScaleNotes / 3 };
        if (numScaleNotes < 3) { // Basic safety for tiny scales
            chordRootsIndices[1] = 0; chordRootsIndices[2] = 0; chordRootsIndices[3] = 0;
        }
        else if (numScaleNotes < 4) {
            chordRootsIndices[2] = 0; chordRootsIndices[3] = 0;
        }


        g_padChordStepCounter += 1.0;
        if (g_padChordStepCounter >= padChordChangeSamples) {
            g_padChordStep = (g_padChordStep + 1) % 4;
            g_padChordStepCounter = 0.0;
            // Retrigger bass drone on chord change
            g_bassEnv.trigger();
            g_bassNoteIndex = chordRootsIndices[g_padChordStep];
        }
        double padRootFreq = currentScale[chordRootsIndices[g_padChordStep]] * 0.25; // 2 octaves down

        // Pad Oscillators
        double padFreqMultipliers[] = { 1.0, 1.5, 2.0, 2.5 }; // Root, 5th, Octave, Octave+5th (approx)
        // For pentatonic, this might be root, 3rd, 4th, 5th-ish
        if (numScaleNotes == NUM_CMINORPENT_NOTES) { // Eb, F, G for C minor pentatonic
            padFreqMultipliers[1] = currentScale[1] / currentScale[0]; // Eb/C
            padFreqMultipliers[2] = currentScale[2] / currentScale[0]; // F/C
            padFreqMultipliers[3] = currentScale[3] / currentScale[0]; // G/C
        } // Similar logic could be added for other scales if desired. Default is harmonic series.


        float padBrightness = 0.5f + pyf * 0.5f; // py influences brightness/complexity

        for (int k = 0; k < NUM_PAD_OSCILLATORS; ++k) {
            double detune = 1.0 + (k - NUM_PAD_OSCILLATORS / 2.0) * 0.005; // Slight detune
            double freq = padRootFreq * padFreqMultipliers[k] * detune;

            g_padPhases[k] += freq / AUDIO_SAMPLE_RATE;
            if (g_padPhases[k] >= 1.0) g_padPhases[k] -= 1.0;

            // Amplitude LFO for shimmer
            g_padLfoPhases[k] += (0.05 + k * 0.03) / AUDIO_SAMPLE_RATE; // Different LFO speeds
            if (g_padLfoPhases[k] >= 1.0) g_padLfoPhases[k] -= 1.0;
            double lfoVal = 0.6 + 0.4 * std::sin(g_padLfoPhases[k] * TWO_PI);

            padSample += static_cast<float>(std::sin(g_padPhases[k] * TWO_PI) * lfoVal * padBrightness);
        }
        padSample /= (NUM_PAD_OSCILLATORS * 1.5f); // Normalize and reduce volume

        // --- 2. Arpeggiator ---
        float arpSample = 0.0f;
        g_arpStepCounter += 1.0;
        if (g_arpStepCounter >= arpNoteDurationSamples) {
            g_arpStepCounter = 0.0;
            g_arpNoteIndex = (g_arpNoteIndex + 1) % numScaleNotes;
            g_arpEnv.trigger_oneshot();
        }

        double arpFreq = currentScale[g_arpNoteIndex] * g_arpOctave; // Apply octave based on py
        g_arpPhase += arpFreq / AUDIO_SAMPLE_RATE;
        if (g_arpPhase >= 1.0) g_arpPhase -= 1.0;

        arpSample = static_cast<float>(std::sin(g_arpPhase * TWO_PI)) * g_arpEnv.process_oneshot();


        // --- 3. Cosmic Dust ---
        float dustSample = 0.0f;
        g_dustTriggerCounter += 1.0;
        if (g_dustTriggerCounter >= dustTriggerIntervalSamples) {
            g_dustTriggerCounter = 0.0;
            for (int k = 0; k < NUM_DUST_PARTICLES; ++k) {
                if (!g_dustEnvs[k].active) { // Find an inactive particle
                    g_dustEnvs[k].trigger_oneshot();
                    g_dustFreqs[k] = 2000.0 + next_random_float() * 8000.0; // High frequencies
                    g_dustPhases[k] = next_random_float(); // Random start phase
                    break; // Trigger one per interval on average
                }
            }
        }

        for (int k = 0; k < NUM_DUST_PARTICLES; ++k) {
            if (g_dustEnvs[k].active) {
                g_dustPhases[k] += g_dustFreqs[k] / AUDIO_SAMPLE_RATE;
                if (g_dustPhases[k] >= 1.0) g_dustPhases[k] -= 1.0;
                dustSample += static_cast<float>(std::sin(g_dustPhases[k] * TWO_PI)) * g_dustEnvs[k].process_oneshot();
            }
        }
        dustSample /= (NUM_DUST_PARTICLES * 2.0f); // Normalize and reduce volume

        // --- 4. Bass Drone ---
        float bassSample = 0.0f;
        double bassFreq = currentScale[g_bassNoteIndex] * 0.125; // 3 octaves down from scale note
        g_bassPhase += bassFreq / AUDIO_SAMPLE_RATE;
        if (g_bassPhase >= 1.0) g_bassPhase -= 1.0;

        // Only trigger bass envelope externally on chord change. It sustains otherwise.
        // If bassEnv is not active at the start of a chord (e.g. first run), trigger it.
        if (!g_bassEnv.active && g_padChordStepCounter < 10) { // Trigger at start of new chord
            g_bassEnv.trigger();
        }

        bassSample = static_cast<float>(std::sin(g_bassPhase * TWO_PI)) * g_bassEnv.process();


        // --- 5. Rhythmic Pulse ---
        float pulseSample = 0.0f;
        g_pulseBeatAccumulator += beatsPerSample; // Use BPM mapped from px
        if (g_pulseBeatAccumulator >= 1.0) {
            g_pulseBeatAccumulator -= 1.0;
            g_pulseEnv.trigger_oneshot();
            // Pulse pitch could be root of current chord, or fixed
            // For simplicity, let's use a fixed low pitch for a "kick" like feel
        }
        double pulseFreq = 60.0 + pxf * 40.0; // Pulse pitch varies slightly with px
        g_pulsePhase += pulseFreq / AUDIO_SAMPLE_RATE;
        if (g_pulsePhase >= 1.0) g_pulsePhase -= 1.0;
        pulseSample = static_cast<float>(std::sin(g_pulsePhase * TWO_PI)) * g_pulseEnv.process_oneshot();


        // --- Mixing ---
        // Volumes for each layer
        float padVol = 0.4f;
        float arpVol = 0.5f;
        float dustVol = 0.3f;
        float bassVol = 0.6f;
        float pulseVol = 0.4f;

        // Global LFO for panning main elements (Pad and Arp)
        g_globalLfoPhase += 0.1 / AUDIO_SAMPLE_RATE; // Slow LFO
        if (g_globalLfoPhase >= 1.0) g_globalLfoPhase -= 1.0;
        float globalLfoPan = 0.5f + 0.5f * std::sin(static_cast<float>(g_globalLfoPhase * TWO_PI)); // 0 to 1

        // Panning
        // Pad: gentle global LFO pan
        float padL = padSample * padVol * (1.0f - globalLfoPan);
        float padR = padSample * padVol * globalLfoPan;

        // Arp: panned by player's X position (pxf)
        float arpPan = pxf; // 0 to 1
        float arpL = arpSample * arpVol * (1.0f - arpPan);
        float arpR = arpSample * arpVol * arpPan;

        // Dust: Wide stereo, individual particles could be panned, but for simplicity, just make it wide
        // Or, use a faster LFO for dust panning
        float dustPanLfoSpeed = 0.7f;
        float dustPan = 0.5f + 0.5f * std::sin(static_cast<float>(g_masterTime * TWO_PI * dustPanLfoSpeed));
        float dustL = dustSample * dustVol * (1.0f - dustPan);
        float dustR = dustSample * dustVol * dustPan;

        // Bass: Mostly mono, slightly wider if pz is high (more "enveloping")
        float bassPanCenter = 0.5f;
        float bassWidth = pzf * 0.2f; // Max 20% width
        float bassL = bassSample * bassVol * (bassPanCenter - bassWidth / 2.0f + (1.0f - bassPanCenter));
        float bassR = bassSample * bassVol * (bassPanCenter + bassWidth / 2.0f + (0.0f - bassPanCenter));
        // Corrected simple panning for bass (more centered)
        bassL = bassSample * bassVol * (1.0f - pzf * 0.1f); // Slightly less in right if pzf is high
        bassR = bassSample * bassVol * (1.0f - (1.0f - pzf) * 0.1f); // Slightly less in left if pzf is low


        // Pulse: Centered
        float pulseL = pulseSample * pulseVol * 0.5f;
        float pulseR = pulseSample * pulseVol * 0.5f;


        // Final Mix
        float outL = padL + arpL + dustL + bassL + pulseL;
        float outR = padR + arpR + dustR + bassR + pulseR;

        // Clipping protection (soft clipping could be nicer but simple clamp is fine)
        out[2 * i + 0] = clampFloat(outL, -1.0f, 1.0f);
        out[2 * i + 1] = clampFloat(outR, -1.0f, 1.0f);
    }
}

// You would need this function if you were using the LCG from the original example for percussion
// For the new code, I've used a self-contained next_random_float()
void seedNoiseGenerator() {
    s_lcgState = static_cast<unsigned>(std::time(nullptr));
}