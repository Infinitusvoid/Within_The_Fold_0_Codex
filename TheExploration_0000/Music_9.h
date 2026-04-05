#pragma once

#define M_PI std::numbers::pi

static float clampFloat(float v, float lo, float hi) {
    return (v < lo) ? lo : (v > hi) ? hi : v;
}

// Smooth interpolation between values
static float lerp(float a, float b, float t) {
    return a + t * (b - a);
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

// Enhanced echo buffers
constexpr int ECHO_BUFFER_SIZE = 24000;
static float echoBufferL[ECHO_BUFFER_SIZE] = { 0 };
static float echoBufferR[ECHO_BUFFER_SIZE] = { 0 };
static int echoIndex = 0;

// Soundscape definitions (4 unique environments)
enum Soundscape {
    FOREST_GLADE,
    CRYSTAL_CAVERN,
    CELESTIAL_SPHERE,
    MECHANICAL_GARDEN,
    NUM_SOUNDSCAPES
};

// Rhythm pattern definitions (16-step sequences)
constexpr int PATTERN_LENGTH = 16;
static const uint8_t kickPatterns[NUM_SOUNDSCAPES][PATTERN_LENGTH] = {
    // Forest Glade: Organic, earthy rhythm
    {1,0,0,1, 0,1,0,0, 1,0,0,1, 0,0,1,0},
    // Crystal Cavern: Precise, sparkling rhythm
    {1,0,1,0, 0,1,0,0, 1,0,1,0, 0,1,0,0},
    // Celestial Sphere: Floating, ethereal rhythm
    {1,0,0,0, 0,0,1,0, 0,0,0,0, 1,0,0,0},
    // Mechanical Garden: Industrial, complex rhythm
    {1,1,0,1, 0,1,0,1, 1,0,1,1, 0,1,0,0}
};

static const uint8_t snarePatterns[NUM_SOUNDSCAPES][PATTERN_LENGTH] = {
    {0,0,1,0, 0,1,0,0, 0,0,1,0, 0,1,0,0},
    {0,0,0,1, 0,0,0,1, 0,0,0,1, 0,0,0,1},
    {0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0},
    {0,1,0,0, 1,0,0,1, 0,1,0,0, 1,0,0,1}
};

static const uint8_t hihatPatterns[NUM_SOUNDSCAPES][PATTERN_LENGTH] = {
    {1,1,0,1, 1,0,1,1, 1,1,0,1, 1,0,1,1},
    {1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0},
    {0,1,0,1, 0,1,0,1, 0,1,0,1, 0,1,0,1},
    {1,1,1,0, 1,1,1,0, 1,1,1,0, 1,1,1,0}
};

// Additional rhythm layer: Percussion textures
static const uint8_t percPatterns[NUM_SOUNDSCAPES][PATTERN_LENGTH] = {
    {0,1,0,0, 1,0,0,1, 0,1,0,0, 1,0,0,1}, // Wood blocks
    {0,0,1,0, 0,0,1,0, 0,0,1,0, 0,0,1,0},  // Chimes
    {1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0},  // Gong hits
    {1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0}   // Metal clicks
};

// Chord progressions for each soundscape
static const int chordProgressions[NUM_SOUNDSCAPES][4] = {
    // Forest Glade: I-IV-vi-V (C, F, Am, G)
    {0, 3, 5, 4},
    // Crystal Cavern: I-iii-vi-ii (C, Em, Am, Dm)
    {0, 2, 5, 1},
    // Celestial Sphere: I-V-vi-IV (C, G, Am, F)
    {0, 4, 5, 3},
    // Mechanical Garden: i-VI-III-vii (Cm, Ab, Eb, Bdim)
    {0, 6, 2, 5}  // Using relative minors for darker feel
};

// Soundscape transition parameters
struct SoundscapeParams {
    float brightness;
    float resonance;
    float rhythmDensity;
    float harmonicComplexity;
};

static const SoundscapeParams soundscapeParams[NUM_SOUNDSCAPES] = {
    // Forest Glade
    {0.7f, 0.4f, 0.6f, 0.5f},
    // Crystal Cavern
    {1.0f, 0.8f, 0.7f, 0.8f},
    // Celestial Sphere
    {0.9f, 0.6f, 0.4f, 1.0f},
    // Mechanical Garden
    {0.5f, 0.9f, 1.0f, 0.7f}
};

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

    // Rhythm state
    static double rhythmAcc = 0.0;
    static int rhythmStep = 0;
    static double kickEnv = 0.0;
    static double snareEnv = 0.0;
    static double hihatEnv = 0.0;
    static double percEnv = 0.0;  // New percussion layer
    static double kickPhase = 0.0;

    // Movement-based effects
    static double movementFilter = 0.0;
    static double movementLFO = 0.0;

    // Soundscape journey system
    static Soundscape currentSoundscape = FOREST_GLADE;
    static Soundscape targetSoundscape = FOREST_GLADE;
    static float soundscapeProgress = 0.0f; // 0-1 transition progress
    static float totalDistance = 0.0f;
    static float lastX = 0.0f, lastY = 0.0f, lastZ = 0.0f;
    const float SOUNDSCAPE_CHANGE_DISTANCE = 4.0f;

    // Calculate movement speed (delta since last frame)
    float moveSpeed = std::sqrt(
        (px - lastX) * (px - lastX) +
        (py - lastY) * (py - lastY) +
        (pz - lastZ) * (pz - lastZ)
    );
    lastX = px; lastY = py; lastZ = pz;
    totalDistance += moveSpeed;

    // Check for soundscape transition
    if (totalDistance >= SOUNDSCAPE_CHANGE_DISTANCE) {
        totalDistance = 0.0f;
        targetSoundscape = static_cast<Soundscape>((currentSoundscape + 1) % NUM_SOUNDSCAPES);
        soundscapeProgress = 0.0f; // Start transition

        // Reset musical elements for fresh start in new soundscape
        chordIndex = 0;
        chordEnv = 1.0;
        rhythmStep = 0;
    }

    // Update soundscape transition
    if (soundscapeProgress < 1.0f) {
        soundscapeProgress += 0.2f / AUDIO_SAMPLE_RATE * frameCount;
        if (soundscapeProgress >= 1.0f) {
            soundscapeProgress = 1.0f;
            currentSoundscape = targetSoundscape;
        }
    }

    // Get interpolated soundscape parameters
    SoundscapeParams currentParams = soundscapeParams[currentSoundscape];
    SoundscapeParams targetParams = soundscapeParams[targetSoundscape];
    float brightness = lerp(currentParams.brightness, targetParams.brightness, soundscapeProgress);
    float resonance = lerp(currentParams.resonance, targetParams.resonance, soundscapeProgress);
    float rhythmDensity = lerp(currentParams.rhythmDensity, targetParams.rhythmDensity, soundscapeProgress);
    float harmonicComplexity = lerp(currentParams.harmonicComplexity, targetParams.harmonicComplexity, soundscapeProgress);

    // Update movement-based LFO
    movementLFO += moveSpeed * 5.0;
    if (movementLFO >= 2.0 * M_PI) movementLFO -= 2.0 * M_PI;

    // Movement-sensitive filter (opens when moving)
    movementFilter = 0.2f + 0.8f * clampFloat(moveSpeed * 5.0f, 0.0f, 1.0f);

    for (ma_uint32 i = 0; i < frameCount; ++i) {
        // Spatial effects based on position
        float spatialDepth = clampFloat(pz * 0.5f + 0.5f, 0.1f, 1.0f);
        float spatialWidth = clampFloat(px * 0.5f + 0.5f, 0.1f, 1.0f);

        // Dynamic tempo based on player Y position and soundscape
        double tempoFactor = 0.7 + 0.6 * sin(py * 3.0 + movementLFO);
        tempoFactor = clampFloat(tempoFactor * (0.8f + rhythmDensity * 0.4f), 0.3f, 1.8f);

        // Chord progression (changes every 2 seconds)
        chordTimeAcc += tempoFactor / AUDIO_SAMPLE_RATE;
        if (chordTimeAcc >= 2.0) {
            chordTimeAcc -= 2.0;
            chordIndex = (chordIndex + 1) % 4;
            chordEnv = 1.0;
        }
        chordEnv *= 0.9995;

        // Chord tones based on current progression
        int rootIdx = chordProgressions[currentSoundscape][chordIndex];
        double freqRoot = cMajorScale[rootIdx] * 0.5;
        double freqThird = cMajorScale[(rootIdx + 2) % SCALE_NOTES] * 0.5;
        double freqFifth = cMajorScale[(rootIdx + 4) % SCALE_NOTES] * 0.5;

        // Add harmonic complexity based on soundscape
        if (harmonicComplexity > 0.5f) {
            freqThird *= 1.0 + 0.02 * harmonicComplexity * sin(pz * 4.0);
            freqFifth *= 1.0 + 0.03 * harmonicComplexity * sin(px * 4.0);
        }

        // Update chord phases with spatial modulation
        chordPhase[0] += freqRoot * (1.0 + 0.02 * sin(py * 4.0)) / AUDIO_SAMPLE_RATE;
        chordPhase[1] += freqThird * (1.0 + 0.02 * sin(pz * 4.0)) / AUDIO_SAMPLE_RATE;
        chordPhase[2] += freqFifth * (1.0 + 0.02 * sin(px * 4.0)) / AUDIO_SAMPLE_RATE;

        for (int k = 0; k < 3; ++k) {
            if (chordPhase[k] >= 1.0) chordPhase[k] -= 1.0;
        }

        float sampleChord = (sin(chordPhase[0] * 2.0 * M_PI) +
            sin(chordPhase[1] * 2.0 * M_PI) +
            sin(chordPhase[2] * 2.0 * M_PI)) / 3.0f * chordEnv;

        // Bass follows chord root with Y modulation
        double freqBass = freqRoot * 0.5 * (1.0 + 0.4 * sin(py * 6.0 + movementLFO));
        phaseBass += clampFloat(freqBass, 30.0f, 120.0f) / AUDIO_SAMPLE_RATE;
        if (phaseBass >= 1.0) phaseBass -= 1.0;
        float sampleBass = 0.5f * sin(phaseBass * 2.0 * M_PI);

        // Stepping lead melody with movement modulation
        stepCounter += tempoFactor * (0.8 + 0.4 * moveSpeed) / AUDIO_SAMPLE_RATE;
        if (stepCounter >= SCALE_NOTES) stepCounter -= SCALE_NOTES;
        int noteIndex = static_cast<int>(floor(stepCounter)) % SCALE_NOTES;
        double freqLead = cMajorScale[noteIndex] * (1.0 + brightness * 0.3);

        lfoMainPhase += (0.3 + moveSpeed * 0.2) / AUDIO_SAMPLE_RATE;
        if (lfoMainPhase >= 1.0) lfoMainPhase -= 1.0;
        freqLead *= (1.0 + 0.15 * sin(lfoMainPhase * 2.0 * M_PI) + 0.1 * sin(pz * 10.0));

        phaseLead += freqLead / AUDIO_SAMPLE_RATE;
        if (phaseLead >= 1.0) phaseLead -= 1.0;
        float sampleLead = sin(phaseLead * 2.0 * M_PI) * (0.7f + brightness * 0.3f);

        // Random melodic ornaments (triggered by movement)
        float sampleOrnament = 0.0f;
        if (!melActive) {
            if (nextNoiseFloat() > (0.985f - moveSpeed * 0.05f)) {
                melActive = true;
                int idx = rand() % SCALE_NOTES;
                // Higher probability of interesting notes when moving fast
                int octave = (moveSpeed > 0.5) ? (2 + rand() % 2) : (1 + rand() % 2);
                melFreq = cMajorScale[idx] * octave * (1.0f + resonance * 0.2f);
                melPhase = 0.0;
                melEnv = 1.0;
            }
        }
        if (melActive) {
            melPhase += melFreq / AUDIO_SAMPLE_RATE;
            if (melPhase >= 1.0) melPhase -= 1.0;
            sampleOrnament = sin(melPhase * 2.0 * M_PI * 2) * melEnv; // Octave higher
            melEnv *= 0.99 - moveSpeed * 0.02; // Faster decay when moving
            if (melEnv < 0.001) melActive = false;
        }

        // ========================
        // ENHANCED RHYTHM SECTION
        // ========================
        rhythmAcc += tempoFactor * 4.0 / AUDIO_SAMPLE_RATE; // 16th notes
        if (rhythmAcc >= 1.0) {
            rhythmAcc -= 1.0;
            rhythmStep = (rhythmStep + 1) % PATTERN_LENGTH;

            // Trigger drums based on current soundscape patterns
            if (kickPatterns[currentSoundscape][rhythmStep]) {
                kickEnv = 1.0;
                kickPhase = 0.0;
            }
            if (snarePatterns[currentSoundscape][rhythmStep]) {
                snareEnv = 1.0;
            }
            if (hihatPatterns[currentSoundscape][rhythmStep]) {
                hihatEnv = 1.0;
            }
            if (percPatterns[currentSoundscape][rhythmStep]) {
                percEnv = 1.0;
            }
        }

        // Kick drum with pitch drop
        double kickFreq = 50.0 + 150.0 * kickEnv;
        kickPhase += kickFreq / AUDIO_SAMPLE_RATE;
        if (kickPhase >= 1.0) kickPhase -= 1.0;
        float sampleKick = sin(kickPhase * 2.0 * M_PI) * kickEnv * 0.6f;
        kickEnv *= 0.92 + moveSpeed * 0.03; // Slightly longer decay when moving

        // Snare drum (noise with resonance)
        float sampleSnare = nextNoiseFloat() * snareEnv * 0.4f * (0.8f + resonance * 0.2f);
        snareEnv *= 0.88;

        // Hi-hat (filtered noise)
        float sampleHihat = nextNoiseFloat() * hihatEnv * 0.3f;
        // Apply high-pass filtering
        sampleHihat = sampleHihat - prevWindIn + 0.95f * prevWindOut;
        prevWindIn = sampleHihat;
        prevWindOut = sampleHihat;
        hihatEnv *= 0.82;

        // New percussion layer (textural elements)
        float samplePerc = nextNoiseFloat() * percEnv * 0.25f;
        percEnv *= 0.85;

        float sampleDrums = sampleKick + sampleSnare + sampleHihat + samplePerc;

        // Atmospheric wind layer with movement modulation
        windLFOPhase += (0.02 + moveSpeed * 0.01) / AUDIO_SAMPLE_RATE;
        if (windLFOPhase >= 1.0) windLFOPhase -= 1.0;
        double windLFO = 0.3 + 0.7 * sin(windLFOPhase * 2.0 * M_PI);

        float rawWind = nextNoiseFloat() * 0.25f;
        float windOut = rawWind - prevWindIn + 0.98f * prevWindOut;
        float sampleWind = windOut * windLFO * (0.3 + moveSpeed * 0.2);

        // ========================
        // SPATIAL MIXING WITH SOUNDSCAPE TRANSITIONS
        // ========================
        // Dynamic panning based on movement and soundscape
        float leadPan = 0.5f + 0.5f * sin(px * 8.0f + movementLFO);
        float ornamentPan = 1.0f - leadPan;
        float windPan = 0.5f + 0.4f * sin(px * 3.0f);

        // Joyful transition effect - pitch rise during soundscape changes
        float transitionBoost = 1.0f;
        if (soundscapeProgress < 1.0f) {
            float t = soundscapeProgress;
            // Rising pitch effect during first half of transition
            if (t < 0.5f) {
                transitionBoost = 1.0f + 0.5f * sin(t * M_PI);
            }
            // Bell-like resonance during second half
            else {
                transitionBoost = 1.0f + 0.3f * sin((t - 0.5f) * 2.0f * M_PI);
            }
        }

        float mixL =
            sampleChord * (0.5f + harmonicComplexity * 0.2f) * spatialDepth * movementFilter +
            sampleBass * 0.5f * movementFilter +
            sampleLead * 0.4f * (1.0f - leadPan) * transitionBoost +
            sampleOrnament * (0.6f + brightness * 0.2f) * (1.0f - ornamentPan) +
            sampleDrums * (0.7f + rhythmDensity * 0.3f) * (1.0f - leadPan) +
            sampleWind * 0.3f * (1.0f - windPan);

        float mixR =
            sampleChord * (0.5f + harmonicComplexity * 0.2f) * spatialDepth * movementFilter +
            sampleBass * 0.45f * movementFilter +
            sampleLead * 0.4f * leadPan * transitionBoost +
            sampleOrnament * (0.6f + brightness * 0.2f) * ornamentPan +
            sampleDrums * (0.7f + rhythmDensity * 0.3f) * leadPan +
            sampleWind * 0.3f * windPan;

        // Enhanced stereo echo effect with movement modulation
        float echoL = echoBufferL[echoIndex];
        float echoR = echoBufferR[echoIndex];

        // Movement changes echo feedback
        float echoFeedback = 0.5f + moveSpeed * 0.2f + resonance * 0.2f;
        echoBufferL[echoIndex] = mixL + echoL * echoFeedback;
        echoBufferR[echoIndex] = mixR + echoR * (echoFeedback - 0.1f);
        echoIndex = (echoIndex + 1) % ECHO_BUFFER_SIZE;

        float outL = clampFloat(mixL + echoL * 0.4f, -1.0f, 1.0f);
        float outR = clampFloat(mixR + echoR * 0.4f, -1.0f, 1.0f);

        // Apply movement-based filter
        outL *= movementFilter * (1.0f + brightness * 0.2f);
        outR *= movementFilter * (1.0f + brightness * 0.2f);

        out[2 * i] = outL;
        out[2 * i + 1] = outR;
    }
}

void seedNoiseGenerator() {
    srand(static_cast<unsigned>(time(nullptr)));
}