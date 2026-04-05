#pragma once

// ----------------------------------------
// Includes & forward declarations
// ----------------------------------------
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <ctime>
#include <atomic>
#include "miniaudio.h" // for ma_device, ma_uint32

// Externally defined player position (each in roughly [-1..+1])
extern std::atomic<float> g_playerPosX;
extern std::atomic<float> g_playerPosY;
extern std::atomic<float> g_playerPosZ;

// Forward-declare seed function (call at startup)
void seedNoiseGenerator();

// ----------------------------------------
// (1) -- Utility clamp and random helpers
// ----------------------------------------
static float clampFloat(float v, float lo, float hi) {
    return (v < lo) ? lo : (v > hi) ? hi : v;
}

static double rand01() {
    // Uniform random [0..1)
    return (double)(std::rand() & 0x7FFF) / 32768.0;
}

// ----------------------------------------
// (2) -- Linear Congruential Generator state for white noise
// ----------------------------------------
static uint32_t lcgState = 1;

static float nextNoiseFloat() {
    // Advance LCG and return float in [-1..+1]
    lcgState = 1664525u * lcgState + 1013904223u;
    return float(((lcgState >> 16) & 0xFFFF) / 65535.0 * 2.0 - 1.0);
}

// ----------------------------------------
// (3) -- Scale & chord data
// ----------------------------------------
constexpr int SCALE_NOTES = 7;
static const double cMajorScale[SCALE_NOTES] = {
    261.63, // C4
    293.66, // D4
    329.63, // E4
    349.23, // F4
    392.00, // G4
    440.00, // A4
    493.88  // B4
};

// Chord roots in C major: C, F, G
static const int chordRoots[3] = { 0, 3, 4 };

// ----------------------------------------
// (4) -- First-order Markov transition tables
//       Melody-degree chain (7 degrees × 3 octaves = 21 states)
//       Rhythm-duration chain (quarter, eighth, sixteenth)
// ----------------------------------------
constexpr int MELODY_STATES = SCALE_NOTES * 3;
// This table will be initialized at startup
static double melodyTrans[MELODY_STATES][MELODY_STATES];

// Rhythm states: 0 = quarter, 1 = eighth, 2 = sixteenth
constexpr int RHYTHM_STATES = 3;
static const double rhythmTrans[RHYTHM_STATES][RHYTHM_STATES] = {
    // if previous was quarter, likely next is quarter or eighth, rarely sixteenth
    { 0.6, 0.3, 0.1 },
    // if previous was eighth, can go quarter/eighth/sixteenth
    { 0.2, 0.5, 0.3 },
    // if previous was sixteenth, likely stay sixteenth or go to eighth
    { 0.1, 0.4, 0.5 }
};

// ----------------------------------------
// (5) -- Internal buffers & state
// ----------------------------------------


// Chord progression (4 beats per measure, change every ~2 seconds @120 BPM)
static double chordPhase[3] = { 0.0, 0.0, 0.0 };
static int    chordIndex = 0;
static double chordEnv = 0.0;
static double chordTimeAcc = 0.0;

// Echo/reverb buffer (stereo interleaved)
static float echoBuffer[24000];
static int   echoIndex = 0;

// Sequencer: schedule up to 16 “melody events” per measure (1 measure = 4 beats).
// Each event carries: startSample, freq, phase, env, active.
struct MelodyEvent {
    int    startSample; // offset in samples from start of measure
    double freq;
    double phase;
    double env;
    bool   active;
};
static MelodyEvent measureEvents[16];
static int eventCount = 0;

// Scheduler counters
static double measureSampleCounter = 0.0;       // counts samples within current measure
static double samplesPerBeat = AUDIO_SAMPLE_RATE * 60.0 / 120.0; // @120 BPM
static double samplesPerMeasure = samplesPerBeat * 4.0;             // 4 beats

// Last chosen Markov states (for continuity between measures)
static int lastMelodyState = 0; // start on C5 (state 0)
static int lastRhythmState = 0; // start on quarter note

// Player-driven bias (updated each measure build)
static int playerOctaveBias = 0;

// ----------------------------------------
// (6) -- Helper: initialize uniform melodyTrans
//           (call once at startup)
// ----------------------------------------
static bool melodyTableInited = false;
static void initMelodyTable() {
    if (melodyTableInited) return;

    for (int i = 0; i < MELODY_STATES; i++) {
        double rowSum = 0.0;
        for (int j = 0; j < MELODY_STATES; j++) {
            double w = 1.0;
            // Boost weight if same degree+octave
            if (j == i) {
                w += 3.0;
            }
            // If same scale degree but different octave, moderate boost
            if ((j % SCALE_NOTES) == (i % SCALE_NOTES) &&
                (j / SCALE_NOTES) != (i / SCALE_NOTES)) {
                w += 1.5;
            }
            // If next degree is ±1 within same octave, small boost
            if ((j / SCALE_NOTES) == (i / SCALE_NOTES) &&
                abs((j % SCALE_NOTES) - (i % SCALE_NOTES)) == 1) {
                w += 1.0;
            }
            melodyTrans[i][j] = w;
            rowSum += w;
        }
        // Normalize the row so it sums to 1.0
        for (int j = 0; j < MELODY_STATES; j++) {
            melodyTrans[i][j] /= rowSum;
        }
    }
    melodyTableInited = true;
}

// ----------------------------------------
// (7) -- Choose next state from a transition row
// ----------------------------------------
static int sampleNextState(const double* transRow, int stateCount) {
    double r = rand01();
    double accum = 0.0;
    for (int i = 0; i < stateCount; i++) {
        accum += transRow[i];
        if (r < accum) {
            return i;
        }
    }
    return stateCount - 1; // fallback
}

// ----------------------------------------
// (8) -- Build measureEvents[] for the next measure
//         Generates pitch + rhythm via Markov chains
// ----------------------------------------
static void buildNextMeasure(int octaveBias, float playerZ) {
    // Ensure the melodyTrans table is initialized
    initMelodyTable();

    eventCount = 0;
    int currentMelState = lastMelodyState;
    int currentRhyState = lastRhythmState;

    // For each of the 4 beats in the measure:
    for (int beat = 0; beat < 4; beat++) {
        double accumulatedBeatDur = 0.0;            // in beat-units
        double beatSampleBase = beat * samplesPerBeat;

        // Chain through rhythm states until we fill exactly 1 beat unit
        while (accumulatedBeatDur < 1.0 - 1e-6) {
            // 1) Sample next rhythm state
            int nextR = sampleNextState(&rhythmTrans[currentRhyState][0], RHYTHM_STATES);
            currentRhyState = nextR;

            // Convert state -> duration in “beat units”
            double durBeatUnits = (nextR == 0) ? 1.0   // quarter
                : (nextR == 1) ? 0.5   // eighth
                : 0.25; // sixteenth

            if (accumulatedBeatDur + durBeatUnits > 1.0 + 1e-6) {
                // If it would exceed 1 beat, clamp to exactly end of beat
                durBeatUnits = 1.0 - accumulatedBeatDur;
            }

            // 2) Sample next melody state (degree+octave)
            int nextM = sampleNextState(&melodyTrans[currentMelState][0], MELODY_STATES);
            currentMelState = nextM;

            int degree = nextM % SCALE_NOTES;   // 0..6
            int octaveIdx = nextM / SCALE_NOTES;   // 0=5th, 1=6th, 2=7th octave
            int baseOctave = 5 + octaveIdx;        // 5, 6, or 7
            int finalOctave = baseOctave + octaveBias;
            double freq = cMajorScale[degree] * std::pow(2.0, finalOctave - 4.0);

            // 3) Convert durBeatUnits -> samples
            int durSamples = (int)std::floor(durBeatUnits * samplesPerBeat + 0.5);

            // 4) Compute startSample relative to measure start
            int startSample = (int)std::floor(beatSampleBase + accumulatedBeatDur * samplesPerBeat + 0.5);

            // 5) Schedule this event if there is room
            if (eventCount < 16) {
                measureEvents[eventCount].startSample = startSample;
                measureEvents[eventCount].freq = freq;
                measureEvents[eventCount].phase = 0.0;
                measureEvents[eventCount].env = 1.0;
                measureEvents[eventCount].active = true;
                eventCount++;
            }

            accumulatedBeatDur += durBeatUnits;
        }
    }

    // Save for continuity into next measure
    lastMelodyState = currentMelState;
    lastRhythmState = currentRhyState;
}

// ----------------------------------------
// (9) -- The audio callback itself
//         (miniaudio signature)
// ----------------------------------------
void audio_callback(ma_device* /*device*/, void* pOutput, const void* /*pInput*/, ma_uint32 frameCount) {
    float* out = static_cast<float*>(pOutput);

    // Read player position (each in [-1..+1])
    float px = g_playerPosX.load(std::memory_order_relaxed);
    float py = g_playerPosY.load(std::memory_order_relaxed);
    float pz = g_playerPosZ.load(std::memory_order_relaxed);

    // Update playerOctaveBias based on pz:
    //   if pz > +0.3 -> shift melody up 1 octave
    //   if pz < -0.3 -> shift melody down 1 octave
    if (pz > 0.3f) {
        playerOctaveBias = 1;
    }
    else if (pz < -0.3f) {
        playerOctaveBias = -1;
    }
    else {
        playerOctaveBias = 0;
    }

    // On the very first callback or after each measure, rebuild the next measure
    static bool inited = false;
    if (!inited) {
        buildNextMeasure(playerOctaveBias, pz);
        inited = true;
    }

    // Update chord progression (every ~2 seconds = 4 beats @120 BPM)
    chordTimeAcc += (double)frameCount / AUDIO_SAMPLE_RATE;
    if (chordTimeAcc >= 2.0) {
        chordTimeAcc -= 2.0;
        chordIndex = (chordIndex + 1) % 3;
        chordEnv = 1.0;
    }
    if (chordEnv > 0.0) {
        chordEnv *= 0.9999;
    }

    int rootScaleIdx = chordRoots[chordIndex];
    int thirdIdx = (rootScaleIdx + 2) % SCALE_NOTES;
    int fifthIdx = (rootScaleIdx + 4) % SCALE_NOTES;
    double freqRoot = cMajorScale[rootScaleIdx] * 0.5;  // C3, F3, or G3
    double freqThird = cMajorScale[thirdIdx] * 0.5;  // E3, A3, or B3
    double freqFifth = cMajorScale[fifthIdx] * 0.5;  // G3, C4, or D4

    static double windLFOPhase = 0.0;
    static float  prevWindIn = 0.0f;
    static float  prevWindOut = 0.0f;

    const double PI = 3.14159265358979323846;
    const double TWO_PI = 2.0 * PI;

    for (ma_uint32 i = 0; i < frameCount; ++i) {
        // 1) Generate chord voices
        chordPhase[0] += freqRoot / AUDIO_SAMPLE_RATE;
        chordPhase[1] += freqThird / AUDIO_SAMPLE_RATE;
        chordPhase[2] += freqFifth / AUDIO_SAMPLE_RATE;
        for (int k = 0; k < 3; k++) {
            if (chordPhase[k] >= 1.0) chordPhase[k] -= 1.0;
        }
        float sampleRoot = (float)sin(chordPhase[0] * TWO_PI);
        float sampleThird = (float)sin(chordPhase[1] * TWO_PI);
        float sampleFifth = (float)sin(chordPhase[2] * TWO_PI);
        float sampleChord = (sampleRoot + sampleThird + sampleFifth) / 3.0f;
        sampleChord *= (float)(0.5 * chordEnv);

        // 2) Generate wind noise
        windLFOPhase += 0.03 / AUDIO_SAMPLE_RATE;
        if (windLFOPhase >= 1.0) {
            windLFOPhase -= 1.0;
        }
        double windLFO = 0.5 + 0.5 * sin(windLFOPhase * TWO_PI);

        float rawWind = nextNoiseFloat() * 0.3f;
        float windOut = rawWind - prevWindIn + 0.995f * prevWindOut;
        prevWindIn = rawWind;
        prevWindOut = windOut;
        float sampleWind = windOut * (float)(windLFO * 0.4);

        // 3) Trigger any melody events whose startSample == current sample index
        int intCounter = (int)(measureSampleCounter + 0.5);
        for (int e = 0; e < eventCount; e++) {
            if (measureEvents[e].active && measureEvents[e].startSample == intCounter) {
                measureEvents[e].phase = 0.0;
                measureEvents[e].env = 1.0;
            }
        }

        // 4) Sum all active melody voices
        float sampleMel = 0.0f;
        for (int e = 0; e < eventCount; e++) {
            if (measureEvents[e].env > 0.0) {
                measureEvents[e].phase += measureEvents[e].freq / AUDIO_SAMPLE_RATE;
                if (measureEvents[e].phase >= 1.0) {
                    measureEvents[e].phase -= 1.0;
                }
                sampleMel += (float)(sin(measureEvents[e].phase * TWO_PI) * measureEvents[e].env * 0.7);
                measureEvents[e].env *= 0.996; // decay
                if (measureEvents[e].env < 0.001) {
                    measureEvents[e].active = false;
                }
            }
        }

        // 5) Optional drone if player Y > +0.5
        float sampleSec = 0.0f;
        if (py > 0.5f) {
            static double dronePhase = 0.0;
            double droneFreq = 98.00; // G2
            dronePhase += droneFreq / AUDIO_SAMPLE_RATE * 0.1; // very slow
            if (dronePhase >= 1.0) {
                dronePhase -= 1.0;
            }
            sampleSec = (float)(sin(dronePhase * TWO_PI) * 0.2);
        }

        // 6) Mix & echo/reverb
        float mixChord = sampleChord * 0.4f;
        float mixWind = sampleWind * 0.25f;
        float mixMel = sampleMel * 0.6f;
        float mixSec = sampleSec * 0.3f;

        // Simple stereo panning based on px
        float chordLeft = mixChord * 0.5f;
        float chordRight = mixChord * 0.5f;

        float windPan = 0.5f + 0.5f * sin(px * 5.0f);
        windPan = clampFloat(windPan, 0.0f, 1.0f);
        float windLeft = mixWind * (1.0f - windPan);
        float windRight = mixWind * windPan;

        float melPan = 0.5f + 0.5f * sin(px * 10.0f);
        melPan = clampFloat(melPan, 0.0f, 1.0f);
        float melLeft = mixMel * (1.0f - melPan);
        float melRight = mixMel * melPan;

        float secLeft = mixSec * 0.5f;
        float secRight = mixSec * 0.5f;

        float dryL = chordLeft + windLeft + melLeft + secLeft;
        float dryR = chordRight + windRight + melRight + secRight;

        // Write into echo buffer (stereo interleaved)
        float echoInL = dryL + 0.4f * echoBuffer[echoIndex];
        float echoInR = dryR + 0.4f * echoBuffer[echoIndex + 1];
        echoBuffer[echoIndex] = echoInL;
        echoBuffer[echoIndex + 1] = echoInR;

        int nextEcho = echoIndex + 2;
        if (nextEcho >= 24000) nextEcho = 0;
        echoIndex = nextEcho;

        float outL = clampFloat(dryL + 0.3f * echoInL, -1.0f, 1.0f);
        float outR = clampFloat(dryR + 0.3f * echoInR, -1.0f, 1.0f);

        out[2 * i + 0] = outL;
        out[2 * i + 1] = outR;

        // 7) Advance measureSampleCounter; if measure ends, rebuild next measure
        measureSampleCounter += 1.0;
        if (measureSampleCounter >= samplesPerMeasure) {
            measureSampleCounter -= samplesPerMeasure;
            buildNextMeasure(playerOctaveBias, pz);
        }
    }
}

// ----------------------------------------
// (10) -- Seed random once at startup
//            Call this from your initialization code
// ----------------------------------------
void seedNoiseGenerator() {
    std::srand((unsigned)std::time(nullptr));
    initMelodyTable();
    measureSampleCounter = 0.0;
    // Zero out echo buffer
    for (int i = 0; i < 24000; i++) {
        echoBuffer[i] = 0.0f;
    }
}
