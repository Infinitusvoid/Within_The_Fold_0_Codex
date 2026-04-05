#pragma once

// ----------------------------------------
// (1) -- Utility clamp function & scale data
// ----------------------------------------
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

// ----------------------------------------
// (2) -- File-scope LCG state for noise
// ----------------------------------------
static uint32_t lcgState = 1;
static float nextNoiseFloat() {
    // Linear-congruential generator -> [-1..+1]
    lcgState = 1664525u * lcgState + 1013904223u;
    return float(((lcgState >> 16) & 0xFFFF) / 65535.0 * 2.0 - 1.0);
}

// ----------------------------------------
// (3) -- ECHO buffer for simple reverb
// ----------------------------------------
static float echoBuffer[24000]; // about 0.5 seconds at 48 kHz (stereo interleaved)
static int echoIndex = 0;

// ----------------------------------------
// (4) -- Fractal (Logistic) state & Kick-clock
// ----------------------------------------


// Primary melody (one note per beat)
static double fractalX1 = 0.5;
static const double fractalR1 = 3.8;

// Secondary melody (runs at a faster subdivision rate, modulated by px)
static double fractalX2 = 0.25;
static const double fractalR2 = 3.9;

// ARP fill (runs when player is near center in Y)
static double arpPhase = 0.0;
static bool   arpActive = false;
static double arpFreq = 0.0;
static double arpEnv = 0.0;

// Secondary-melody scheduler
static double subdivisionSamples = 0.0;  // will be computed from px
static double subdivCounter = 0.0;       // keeps track for secondary melody

// BPM clock for the kick
static float  bpm = 120.0f;
static double samplesPerQuarter = AUDIO_SAMPLE_RATE * 60.0 / 120.0;
static double sampleCounter = 0.0;
static double nextBeatSample = 0.0;
static bool   beatJustTriggered = false;

// Primary melody envelope & pitch
static bool   mel1Active = false;
static double mel1Freq = 0.0;
static double mel1Phase = 0.0;
static double mel1Env = 0.0;

// Secondary melody envelope & pitch
static bool   mel2Active = false;
static double mel2Freq = 0.0;
static double mel2Phase = 0.0;
static double mel2Env = 0.0;

// ----------------------------------------
// (5) -- The audio callback itself
// ----------------------------------------
void audio_callback(ma_device* /*device*/, void* pOutput, const void* /*pInput*/, ma_uint32 frameCount) {
    float* out = static_cast<float*>(pOutput);

    // Read player position (assumed in roughly [-1..+1])
    float px = g_playerPosX.load(std::memory_order_relaxed);
    float py = g_playerPosY.load(std::memory_order_relaxed);
    float pz = g_playerPosZ.load(std::memory_order_relaxed);

    // Persistent state across all callbacks (continued)
    static double chordPhase[3] = { 0.0, 0.0, 0.0 };
    static int    chordIndex = 0;
    static double chordEnv = 0.0;
    static double chordTimeAcc = 0.0;
    static double windLFOPhase = 0.0;
    static float  prevWindIn = 0.0f;
    static float  prevWindOut = 0.0f;
    static double lfoMainPhase = 0.0;

    const double PI = 3.14159265358979323846;
    const double TWO_PI = 2.0 * PI;

    // Compute secondary subdivision from px:
    // px in [-1..+1] -> subdivision between 4th notes (px=-1) and 16th notes (px=+1)
    // subdivisionSamples = samplesPerQuarter / (2^( (px+1)*1.5 )) 
    //   when px=-1 -> exponent=0 -> division by 1 -> quarter notes
    //   when px=+1 -> exponent=3 -> division by 8 -> 8th notes? adjust exponent to get 16th.
    double expo = ((double)px + 1.0) * 1.5; // range [0..3]
    double divn = pow(2.0, expo);
    subdivisionSamples = samplesPerQuarter / divn;

    for (ma_uint32 i = 0; i < frameCount; ++i) {
        // ==========================
        // Kick-Clock (BPM timer)
        // ==========================
        beatJustTriggered = false;
        sampleCounter += 1.0;
        if (sampleCounter >= nextBeatSample) {
            beatJustTriggered = true;
            nextBeatSample += samplesPerQuarter;
        }

        // ==========================
        // (1) CHORD PROGRESSION
        // ==========================
        chordTimeAcc += 1.0 / AUDIO_SAMPLE_RATE;
        if (chordTimeAcc >= 2.0) {
            chordTimeAcc -= 2.0;
            chordIndex = (chordIndex + 1) % 3; // 3 chords: C, F, G
            chordEnv = 1.0;
        }
        if (chordEnv > 0.0) chordEnv *= 0.9999;  // slow decay

        int rootScaleIdx;
        if (chordIndex == 0)      rootScaleIdx = 0; // C
        else if (chordIndex == 1) rootScaleIdx = 3; // F
        else                      rootScaleIdx = 4; // G

        int thirdIdx = (rootScaleIdx + 2) % SCALE_NOTES;
        int fifthIdx = (rootScaleIdx + 4) % SCALE_NOTES;
        double freqRoot = cMajorScale[rootScaleIdx] * 0.5;  // C3, F3, G3
        double freqThird = cMajorScale[thirdIdx] * 0.5;  // E3, A3, B3
        double freqFifth = cMajorScale[fifthIdx] * 0.5;  // G3, C4, D4

        chordPhase[0] += freqRoot / AUDIO_SAMPLE_RATE;
        chordPhase[1] += freqThird / AUDIO_SAMPLE_RATE;
        chordPhase[2] += freqFifth / AUDIO_SAMPLE_RATE;
        for (int k = 0; k < 3; ++k) {
            if (chordPhase[k] >= 1.0) chordPhase[k] -= 1.0;
        }

        float sampleRoot = static_cast<float>(sin(chordPhase[0] * TWO_PI));
        float sampleThird = static_cast<float>(sin(chordPhase[1] * TWO_PI));
        float sampleFifth = static_cast<float>(sin(chordPhase[2] * TWO_PI));
        float sampleChord = (sampleRoot + sampleThird + sampleFifth) / 3.0f;
        sampleChord *= static_cast<float>(0.5 * chordEnv);

        // ==========================
        // (2) WIND NOISE
        // ==========================
        windLFOPhase += 0.03 / AUDIO_SAMPLE_RATE;
        if (windLFOPhase >= 1.0) windLFOPhase -= 1.0;
        double windLFO = 0.5 + 0.5 * sin(windLFOPhase * TWO_PI);

        float rawWind = nextNoiseFloat() * 0.3f;
        // One-pole high-pass: y[n] = x[n] - x[n-1] + R * y[n-1]
        float hpR = 0.995f;
        float windOut = rawWind - prevWindIn + hpR * prevWindOut;
        prevWindIn = rawWind;
        prevWindOut = windOut;

        float sampleWind = windOut * static_cast<float>(windLFO * 0.4);

        // ==========================
        // (3) PRIMARY FRACTAL MELODY (one per beat, with pz-triggered “spur” notes)
        // ==========================
        if (beatJustTriggered) {
            // Step logistic map #1
            fractalX1 = fractalR1 * fractalX1 * (1.0 - fractalX1);

            // Map fractalX1 [0..1] -> 2 octaves in C major
            double scaled = fractalX1 * (SCALE_NOTES * 2);
            int idx = int(floor(scaled)) % (SCALE_NOTES * 2);
            int scaleDeg = idx % SCALE_NOTES;
            int octave = (idx / SCALE_NOTES) + 2;
            mel1Freq = cMajorScale[scaleDeg] * pow(2.0, octave - 4.0);
            mel1Phase = 0.0;
            mel1Env = 1.0;
            mel1Active = true;

            // If player is far forward (pz>0), occasionally spawn a “spur” note immediately
            double prob = 0.5 + 0.5 * (pz * 0.5 + 0.5); // [0.5..1.0]
            float rnd = (nextNoiseFloat() + 1.0f) * 0.5f; // [0..1]
            if (rnd < prob * 0.2f) {
                // One extra random note
                int extraIdx = std::rand() % SCALE_NOTES;
                double extraOct = ((std::rand() & 1) ? 2.0 : 3.0);
                double extraFreq = cMajorScale[extraIdx] * pow(2.0, extraOct - 4.0);
                // Layer it on mel2 slot (if free)
                if (!mel2Active) {
                    mel2Freq = extraFreq;
                    mel2Phase = 0.0;
                    mel2Env = 1.0;
                    mel2Active = true;
                }
            }
        }

        float sampleMel1 = 0.0f;
        if (mel1Active) {
            mel1Phase += mel1Freq / AUDIO_SAMPLE_RATE;
            if (mel1Phase >= 1.0) mel1Phase -= 1.0;
            sampleMel1 = static_cast<float>(sin(mel1Phase * TWO_PI) * mel1Env);
            mel1Env *= 0.994;
            if (mel1Env < 0.002) mel1Active = false;
        }

        // ==========================
        // (4) SECONDARY FRACTAL MELODY (runs at subdivision rate)
        // ==========================
        subdivCounter += 1.0;
        if (subdivCounter >= subdivisionSamples) {
            subdivCounter -= subdivisionSamples;

            // Step logistic-map #2
            fractalX2 = fractalR2 * fractalX2 * (1.0 - fractalX2);

            // Map fractalX2 [0..1] -> 1 octave in C major, octave shifted by py
            double scaled2 = fractalX2 * SCALE_NOTES;
            int idx2 = int(floor(scaled2)) % SCALE_NOTES;
            // Shift octave by py: py=-1 -> down 1 octave, py=+1 -> up 1 octave
            int oktShift = int(round(py * 1.0));
            int octave2 = 3 + oktShift;
            mel2Freq = cMajorScale[idx2] * pow(2.0, octave2 - 4.0);
            mel2Phase = 0.0;
            mel2Env = 1.0;
            mel2Active = true;
        }

        float sampleMel2 = 0.0f;
        if (mel2Active) {
            mel2Phase += mel2Freq / AUDIO_SAMPLE_RATE;
            if (mel2Phase >= 1.0) mel2Phase -= 1.0;
            sampleMel2 = static_cast<float>(sin(mel2Phase * TWO_PI) * mel2Env);
            mel2Env *= 0.996;
            if (mel2Env < 0.002) mel2Active = false;
        }

        // ==========================
        // (5) ARP FILL (when player near center in Y)
        // ==========================
        // If |py| < 0.3, run a quick arpeggio in a higher octave
        float sampleArp = 0.0f;
        if (fabs(py) < 0.3f) {
            if (!arpActive) {
                arpActive = true;
                // Choose a random scale degree and octave 5
                int arpDeg = std::rand() % SCALE_NOTES;
                arpFreq = cMajorScale[arpDeg] * pow(2.0, 5.0 - 4.0);
                arpPhase = 0.0;
                arpEnv = 1.0;
            }
        }
        else {
            arpActive = false;
            arpEnv = 0.0;
        }

        if (arpActive) {
            arpPhase += arpFreq / AUDIO_SAMPLE_RATE * 4.0;
            // speed it up by factor 4
            if (arpPhase >= 1.0) arpPhase -= 1.0;
            sampleArp = static_cast<float>(sin(arpPhase * TWO_PI) * arpEnv);
            arpEnv *= 0.990;
        }

        // ==========================
        // (6) MIX & ECHO REVERB
        // ==========================
        float mixChord = sampleChord * 0.4f;  // background
        float mixWind = sampleWind * 0.25f; // texture
        float mixMel1 = sampleMel1 * 0.6f;  // primary melody
        float mixMel2 = sampleMel2 * 0.5f;  // secondary melody
        float mixArp = sampleArp * 0.3f;  // arp fill

        // Stereo panning:
        // Chord centered
        float chordLeft = mixChord;
        float chordRight = mixChord;

        // Wind wide, modulated by px
        float windPan = 0.5f + 0.5f * sin(px * 5.0f);
        windPan = clampFloat(windPan, 0.0f, 1.0f);
        float windLeft = mixWind * (1.0f - windPan);
        float windRight = mixWind * windPan;

        // Melodies panned by px more strongly
        float mel1Pan = 0.5f + 0.5f * sin(px * 10.0f);
        mel1Pan = clampFloat(mel1Pan, 0.0f, 1.0f);
        float mel1Left = mixMel1 * (1.0f - mel1Pan);
        float mel1Right = mixMel1 * mel1Pan;

        float mel2Pan = 0.5f + 0.5f * sin(px * 12.0f);
        mel2Pan = clampFloat(mel2Pan, 0.0f, 1.0f);
        float mel2Left = mixMel2 * (1.0f - mel2Pan);
        float mel2Right = mixMel2 * mel2Pan;

        // Arp fill slightly centered
        float arpLeft = mixArp * 0.6f;
        float arpRight = mixArp * 0.4f;

        // Sum dry signals
        float dryL = chordLeft + windLeft + mel1Left + mel2Left + arpLeft;
        float dryR = chordRight + windRight + mel1Right + mel2Right + arpRight;

        // Write into echo buffer (interleaved stereo)
        float echoInL = dryL + 0.4f * echoBuffer[echoIndex];
        float echoInR = dryR + 0.4f * echoBuffer[echoIndex + 1];
        echoBuffer[echoIndex] = echoInL;
        echoBuffer[echoIndex + 1] = echoInR;

        int nextEchoIndex = echoIndex + 2;
        if (nextEchoIndex >= 24000) nextEchoIndex = 0;
        echoIndex = nextEchoIndex;

        // Output = dry + small echo
        float outL = dryL + 0.3f * echoInL;
        float outR = dryR + 0.3f * echoInR;

        // Clamp final output
        outL = clampFloat(outL, -1.0f, 1.0f);
        outR = clampFloat(outR, -1.0f, 1.0f);

        out[2 * i + 0] = outL;
        out[2 * i + 1] = outR;
    }
}

// ----------------------------------------
// (7) -- Seed the random-number generator once at startup
// ----------------------------------------
void seedNoiseGenerator() {
    std::srand(static_cast<unsigned>(std::time(nullptr)));
    // Initialize nextBeatSample so the first beat is immediate
    nextBeatSample = 0.0;
}
