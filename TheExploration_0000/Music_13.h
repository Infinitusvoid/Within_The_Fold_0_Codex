

#include <vector>   // For std::vector (used in FFT conceptual part)
#include <complex>  // For std::complex (used in FFT conceptual part)
#include <cmath>    // For various math functions (sin, cos, sqrt, atan2, etc.)
#include <cstdlib>  // For rand()
#include <ctime>    // For time() in seedNoiseGenerator

#define M_PI std::numbers::pi

    // Existing utility functions and constants
static float clampFloat(float v, float lo, float hi)
{
    return (v < lo) ? lo : (v > hi) ? hi : v;
}

constexpr int SCALE_NOTES = 7;
static const double cMajorScale[SCALE_NOTES] =
{
    261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88
};
static const double aMinorScale[SCALE_NOTES] = {
    220.00, 246.94, 277.18, 293.66, 329.63, 369.99, 415.30
};

static uint32_t lcgState = 1;
static float nextNoiseFloat() { // Generates [-1.0, 1.0]
    lcgState = 1664525u * lcgState + 1013904223u;
    return float(((lcgState >> 16) & 0xFFFF) / 65535.0 * 2.0 - 1.0);
}
// Helper to get noise in [0.0, 1.0] for probabilities
static float nextPositiveNoiseFloat() {
    return (nextNoiseFloat() * 0.5f + 0.5f);
}


// Delay buffer for multi-tap ambient reverb
constexpr int REVERB_BUFFER_SIZE = 96000; // 2 seconds at 48kHz
static float reverbBufferL[REVERB_BUFFER_SIZE] = { 0 };
static float reverbBufferR[REVERB_BUFFER_SIZE] = { 0 };
static int reverbWriteIndex = 0;

// Simple 1-pole filter
struct OnePole {
    float a0, b1;
    float z1;
    OnePole() : a0(1.0f), b1(0.0f), z1(0.0f) {}
    inline float process(float x) {
        float y = a0 * x + b1 * z1;
        z1 = y; // Naive update, careful with denormals in real use.
        // A common way to prevent denormals is: z1 = y + 1e-18f - 1e-18f;
        return y;
    }
    inline void setLowpass(float cutoffFreq, unsigned sampleRate) {
        float x = expf(-2.0f * (float)M_PI * cutoffFreq / float(sampleRate));
        b1 = x;
        a0 = 1.0f - x;
    }
    inline void setHighpass(float cutoffFreq, unsigned sampleRate) {
        float x = expf(-2.0f * (float)M_PI * cutoffFreq / float(sampleRate));
        // Coefficient calculation for HPF can vary, this is one common way for 1-pole
        a0 = (1.0f + x) * 0.5f; // Gain normalized
        b1 = -x; // This forms y[n] = a0*x[n] - a0*x[n-1] + b1*y[n-1] if x[n-1] was used.
        // The current struct implies y[n] = a0*x[n] + b1*y[n-1].
        // For y[n] = G*(x[n] - x[n-1]) + x*y[n-1], a0 implies G, z1 needs to store x[n-1] too or use different formula.
        // Let's use standard HPF from `a0 = (1+x)/2; b1 = -(1+x)/2; float y = a0*x + b1*z1_x + x*z1_y;`
        // Simpler for this struct:
        this->a0 = (1.0f + x) / 2.0f; // x(n) term
        this->b1 = x;                 // y(n-1) term
        // The process should be y = a0 * (x - z1_x) + b1 * z1_y
        // To keep `process` simple, let's use the structure:
        // y[n] = x[n] - LPF(x[n]) -> y[n] = x[n] - ( (1-b1_lpf)*x[n] + b1_lpf*y_lpf[n-1] )
        // For this one-pole:
        // a0_hp = (1.0f + x) * 0.5f; b1_hp = -x; // This would be correct if z1 was x - y
        // Let's use common method:
        // x_hpf = x - x_lpf;
        // For simplicity: set a highpass as `a0 = 1.0f - (1.0f - x); b1 = x; then y_hpf = x - y_lpf`
        // This structure is primarily a LPF. For HPF, it might be better to chain or use different coeffs.
        // Using a common one-pole HPF for y[n] = A*x[n] - A*x[n-1] + B*y[n-1]
        // The current struct: y[n] = a0 * x[n] + b1 * z1;  (z1 is y[n-1])
        // So, for HPF: a0_true = (1+x)/2; b1_true = x; then output = a0_true * (x - z1_input_history) + b1_true * z1_output_history
        // Given the current `process` method, it's tricky to make it a "true" 1-pole HPF without changing `process` or what `z1` stores.
        // The existing setHighpass `a0=(1+x)*0.5; b1=-x;` is one form of 1-pole HPF. It will work.
        float alpha = expf(-2.0f * (float)M_PI * cutoffFreq / float(sampleRate));
        this->a0 = (1.0f + alpha) / 2.0f;
        this->b1 = -(1.0f + alpha) / 2.0f; // Mistake: b1 should be for y[n-1], a0 for x[n] and x[n-1]
        // Correct for y[n] = a0*x[n] + a0_1*x[n-1] + b1*y[n-1]
        // If process is y = a0*x + b1*z1 (where z1 is y[n-1] after passing through a0*x[n-1])
        // The existing setHighpass used in the original code is:
        // b1 = -x; a0 = (1.0f + x) * 0.5f;
        // This seems to be a filter derived from y[n] = G * (x[n] - x[n-1]) + B * y[n-1]
        // But simplified to fit the z1 = y form. It will have a high-pass characteristic.
        this->b1 = x; // This is standard for y[n] = A * (x[n] - x_prev) + x * y[n-1]
        // However, the provided code was `b1 = -x; a0 = (1.0f+x)*0.5f;` let's stick to that.
        this->b1 = -x; // as in original
        this->a0 = (1.0f + x) * 0.5f; // as in original
    }
};


// Envelope generator
struct Envelope {
    float value;
    float decay;
    bool active;
    Envelope() : value(0.0f), decay(0.999f), active(false) {}
    inline void trigger(float initial = 1.0f, float decayRate = 0.999f) {
        value = initial;
        decay = decayRate; // Per sample decay
        active = true;
    }
    inline float process() {
        if (!active) return 0.0f;
        float out = value;
        value *= decay;
        if (value < 0.0005f) { // Threshold to deactivate
            active = false;
            value = 0.0f;
        }
        return out;
    }
};

// --- NEW: Karplus-Strong Synth ---
constexpr int KS_MAX_BUFFER_LENGTH = 2048; // Max delay line for low notes
constexpr int NUM_KS_STRINGS = 3;

struct KarplusStrongString {
    float buffer[KS_MAX_BUFFER_LENGTH];
    int bufferLength; // Current actual length for pitch
    int writePos;
    float prev_out; // For simple 1-pole LPF in feedback: (curr + prev_out) * 0.5
    bool active;
    float envelope;
    float decayFactor; // Per-sample decay for envelope

    KarplusStrongString() : bufferLength(100), writePos(0), prev_out(0.0f), active(false), envelope(0.0f), decayFactor(0.995f) {
        for (int i = 0; i < KS_MAX_BUFFER_LENGTH; ++i) buffer[i] = 0.0f;
    }

    void excite(float fundamentalFreq, float decayTime /*approx seconds*/, unsigned sampleRate) {
        if (fundamentalFreq <= 0) return;
        bufferLength = static_cast<int>((float)sampleRate / fundamentalFreq);
        if (bufferLength >= KS_MAX_BUFFER_LENGTH) bufferLength = KS_MAX_BUFFER_LENGTH - 1;
        if (bufferLength < 10) bufferLength = 10; // Min length

        for (int i = 0; i < bufferLength; ++i) {
            buffer[i] = nextNoiseFloat() * 0.5f; // Fill with noise
        }
        writePos = 0;
        prev_out = 0.0f;
        active = true;
        envelope = 1.0f;
        // decayFactor = expf(-1.0f / (decayTime * sampleRate)); // More accurate decay time
        // Simplified:
        if (decayTime > 0.01f) {
            decayFactor = powf(0.001f, 1.0f / (decayTime * (float)sampleRate));
        }
        else {
            decayFactor = 0.99f;
        }
    }

    float process() {
        if (!active) return 0.0f;

        int readPos = (writePos - bufferLength + KS_MAX_BUFFER_LENGTH) % KS_MAX_BUFFER_LENGTH;
        float current_sample = buffer[readPos];

        // Simple averaging filter in feedback loop for damping high frequencies (makes it less bright over time)
        float feedback_sample = (current_sample + prev_out) * 0.5f * 0.99f; // 0.99f is feedback gain, slightly less than 1 for stability
        prev_out = current_sample; // Or could be feedback_sample for slightly different timbre

        buffer[writePos] = feedback_sample * envelope;
        writePos = (writePos + 1) % KS_MAX_BUFFER_LENGTH;

        envelope *= decayFactor;
        if (envelope < 0.001f) {
            active = false;
        }
        return current_sample * envelope; // Output is pre-envelope signal scaled by envelope
    }
};
static KarplusStrongString ksStrings[NUM_KS_STRINGS];
// --- END Karplus-Strong Synth ---


// --- NEW: Spectral Freeze ---
constexpr int FFT_FRAME_SIZE = 1024; // Power of 2 for FFT
constexpr int FFT_HOP_SIZE = FFT_FRAME_SIZE / 4; // Typical hop size for OLA

// Placeholder FFT/IFFT functions (conceptual)
// A real implementation (e.g. from KissFFT or other library) would be needed here.
using Complex = std::complex<float>;
void conceptual_fft(const float* in, std::vector<Complex>&out_spectrum, int size) {
    // This is a STUB. Fill out_spectrum based on 'in'.
    // Typically 'out_spectrum' would be size/2 + 1 for real FFT.
    if (out_spectrum.size() != (size_t)size / 2 + 1) out_spectrum.resize(size / 2 + 1);
    // For placeholder, just zero it or put some dummy data.
    for (size_t k = 0; k < out_spectrum.size(); ++k) out_spectrum[k] = Complex(0.0f, 0.0f);
}
void conceptual_ifft(const std::vector<Complex>&in_spectrum, float* out_signal, int size) {
    // This is a STUB. Fill 'out_signal' based on 'in_spectrum'.
    // For placeholder, just zero it.
    for (int i = 0; i < size; ++i) out_signal[i] = 0.0f;
}

static float spectralFreeze_hannWindow[FFT_FRAME_SIZE];
static bool  spectralFreeze_windowInitialized = false;

static float spectralFreeze_inputBuffer[FFT_FRAME_SIZE] = { 0 };
static int   spectralFreeze_inputBufferPos = 0;
static std::vector<Complex> spectralFreeze_frozenMagnitudes(FFT_FRAME_SIZE / 2 + 1);
static float spectralFreeze_outputBuffer[FFT_FRAME_SIZE] = { 0 }; // For OLA
static int   spectralFreeze_samplesSinceLastIFFT = 0;
static bool  spectralFreeze_isActive = false;
static int   spectralFreeze_durationCounter = 0;
static float spectralFreeze_crossfade = 0.0f; // 0 = normal, 1 = frozen
// --- END Spectral Freeze ---


// Global variables for player position (assuming these are updated elsewhere)
// These need to be accessible. If they are not global, pass them in.
// For this example, I'm assuming they are global as per the original context.
#include <atomic> // For std::atomic
extern std::atomic<float> g_playerPosX;
extern std::atomic<float> g_playerPosY;
extern std::atomic<float> g_playerPosZ;



// Audio callback
void audio_callback(ma_device* /*device*/, void* pOutput, const void* /*pInput*/, ma_uint32 frameCount) {
    float* out = static_cast<float*>(pOutput);

    float px = g_playerPosX.load(std::memory_order_relaxed);
    float py = g_playerPosY.load(std::memory_order_relaxed);
    float pz = g_playerPosZ.load(std::memory_order_relaxed);

    // Persistent state
    static double phaseLead = 0.0;
    static double phaseBass = 0.0;
    // static double stepCounter = 0.0; // Replaced by fractal melody
    static double chordTimeAcc = 0.0;
    static int chordIndex = 0;
    static double chordEnv = 0.0;
    static double chordPhase[3] = { 0.0, 0.0, 0.0 };
    static double windLFOPhase = 0.0;
    static float prevWindIn = 0.0f;
    static float prevWindOut = 0.0f;
    // static bool melActive = false; // This was for simple melody, now for FM bells
    // static double melPhase = 0.0;
    // static double melEnv = 0.0;
    // static double melFreq = 0.0;

    // Drum voices
    static Envelope kickEnv;
    static Envelope snareEnv;
    static Envelope hatEnv;
    static double kickPhase = 0.0;

    // FM bells (ornaments)
    struct FMBell { bool active; double carrierPhase, modPhase, carrierFreq, modFreq, env; };
    static FMBell bells[4] = {}; // Existing ornamental sounds

    // Filters (declare once)
    static OnePole chordLPF_L;
    static OnePole chordLPF_R;
    static OnePole windHPF_L;
    static OnePole windHPF_R;
    static OnePole bassLPF_L;
    static OnePole bassLPF_R;
    static OnePole snareHPF_L;
    static OnePole snareHPF_R;
    static OnePole hatHPF_L;
    static OnePole hatHPF_R;
    static OnePole padLPF_L;
    static OnePole padLPF_R;
    static OnePole brrLPF;
    static OnePole brrHPF;

    // Brr LFO
    static double brrLFOPhase = 0.0;
    static double brrPanPhase = 0.0;

    // Rhythm sequencing
    static double barPhase = 0.0;
    static int prevBeatStep = -1;
    static bool rhythmPattern = false; // Toggles rhythmic complexity

    // Distance-based section change
    static float prevPx = px, prevPy = py, prevPz = pz;
    static float distAccum = 0.0f;

    // Spatial pan LFO
    static double spatialPanPhase = 0.0;

    // Ambient pad voices
    static double padPhase[4] = { 0.0, 0.0, 0.0, 0.0 };
    static double padEnv = 0.0;
    static double padEnvDecay = 0.9998;

    // --- NEW: Fractal Melody State ---
    static double fractalMelody_logisticX = 0.5; // Current value of the logistic map
    static double fractalMelody_currentFreq = 0.0;
    static Envelope fractalMelody_env;
    static bool fractalMelody_newNoteTriggered = false;
    // --- END Fractal Melody State ---

    // --- NEW: Parameter Mapping State ---
    static float smoothedPlayerVelocity = 0.0f;
    // --- END Parameter Mapping State ---

    // --- NEW: Dynamic Mixing State ---
    static float mixOverallLoudness = 0.0f;
    // --- END Dynamic Mixing State ---


    const double PI = M_PI; // Use M_PI for consistency if available
    const double TWO_PI = 2.0 * PI;
    const unsigned SAMPLE_RATE = AUDIO_SAMPLE_RATE; // Assuming this is set elsewhere, e.g., 48000

    // --- NEW: Initialize Hann window for Spectral Freeze (once) ---
    if (!spectralFreeze_windowInitialized) {
        for (int n = 0; n < FFT_FRAME_SIZE; n++) {
            spectralFreeze_hannWindow[n] = 0.5f * (1.0f - cosf((float)(2.0 * PI * n) / (FFT_FRAME_SIZE - 1)));
        }
        spectralFreeze_windowInitialized = true;
    }
    // --- END Hann Window Init ---

    // Compute travel distance and velocity for parameter mapping
    float dx_frame = px - prevPx;
    float dy_frame = py - prevPy;
    float dz_frame = pz - prevPz;
    float traveled_this_callback = sqrtf(dx_frame * dx_frame + dy_frame * dy_frame + dz_frame * dz_frame);
    distAccum += traveled_this_callback;
    prevPx = px; prevPy = py; prevPz = pz;

    // Player velocity for parameter mapping
    float currentVelocity = 0.0f;
    if (frameCount > 0) {
        currentVelocity = traveled_this_callback / ((float)frameCount / (float)SAMPLE_RATE); // units per second
    }
    smoothedPlayerVelocity = smoothedPlayerVelocity * 0.95f + currentVelocity * 0.05f; // Smooth it


    // Every 4 meters, toggle rhythm and trigger pad envelope
    if (distAccum >= 4.0f) {
        distAccum -= 4.0f;
        rhythmPattern = !rhythmPattern;
        barPhase = 0.0; // Reset bar phase on section change
        prevBeatStep = -1;
        chordIndex = (chordIndex + 1) % 4; // Change chord
        chordEnv = 1.0; // Trigger chord envelope
        padEnv = 1.0;   // Trigger pad envelope in new section
    }

    for (ma_uint32 i = 0; i < frameCount; ++i) {
        // 1) LFO updates
        spatialPanPhase += 0.015 / SAMPLE_RATE; // Slow global LFO for panning
        if (spatialPanPhase >= 1.0) spatialPanPhase -= 1.0;
        windLFOPhase += 0.04 / SAMPLE_RATE; // LFO for wind amplitude
        if (windLFOPhase >= 1.0) windLFOPhase -= 1.0;
        brrLFOPhase += 0.1 / SAMPLE_RATE; // LFO for "brr" amplitude
        if (brrLFOPhase >= 1.0) brrLFOPhase -= 1.0;
        brrPanPhase += 0.08 / SAMPLE_RATE; // LFO for "brr" panning
        if (brrPanPhase >= 1.0) brrPanPhase -= 1.0;


        // 2) Spatial factors (less used now, but kept for potential modulation)
        float spatialDepth = clampFloat(pz * 0.5f + 0.5f, 0.1f, 1.0f);
        float spatialWidthFactor = clampFloat(px * 0.5f + 0.5f, 0.1f, 1.0f); // Original width factor related to px


        // 3) Tempo factor based on player position
        double tempoFactor = 0.6 + 0.4 * sin(px * 2.5);
        tempoFactor = clampFloat(tempoFactor, 0.2, 2.0);


        // 4) Chord progression
        chordTimeAcc += tempoFactor / SAMPLE_RATE;
        if (chordTimeAcc >= 1.5) { // Change chord every 1.5 beats (tempo adjusted)
            chordTimeAcc -= 1.5;
            chordIndex = (chordIndex + 1) % 4;
            chordEnv = 1.0;
        }
        chordEnv *= 0.9985; // Chord envelope decay


        // 5) Chord frequencies
        int rootIdx;
        switch (chordIndex) {
        case 0: rootIdx = 0; break; // I
        case 1: rootIdx = 3; break; // IV
        case 2: rootIdx = 4; break; // V
        case 3: rootIdx = 5; break; // vi (or VI if major)
        default: rootIdx = 0; break;
        }
        const double* currentScale = (py > 0.0f) ? cMajorScale : aMinorScale; // Select scale based on py
        double freqRoot = currentScale[rootIdx] * 0.5; // Octave down
        double freqThird = currentScale[(rootIdx + 2) % SCALE_NOTES] * 0.5;
        double freqFifth = currentScale[(rootIdx + 4) % SCALE_NOTES] * 0.5;


        // 6) Update chord phases & generate raw chord signal
        chordPhase[0] += freqRoot * (1.0 + 0.02 * sin(py * 3.5)) / SAMPLE_RATE;
        chordPhase[1] += freqThird * (1.0 + 0.02 * sin(pz * 3.5)) / SAMPLE_RATE;
        chordPhase[2] += freqFifth * (1.0 + 0.02 * sin(px * 3.5)) / SAMPLE_RATE;
        for (int k = 0; k < 3; ++k) if (chordPhase[k] >= 1.0) chordPhase[k] -= 1.0;

        float rawChord = (sinf((float)(chordPhase[0] * TWO_PI)) +
            sinf((float)(chordPhase[1] * TWO_PI)) +
            sinf((float)(chordPhase[2] * TWO_PI))) / 3.0f * (float)chordEnv;


        // 7) Chord filter (now with player direction modulation)
        double filterLFO1 = 0.5 + 0.5 * sin(px * 2.0 + spatialPanPhase * TWO_PI);
        float baseCutoffChord = 300.0f + (float)filterLFO1 * 2400.0f;

        // --- NEW: Player direction controlling filter cutoff ---
        float moveAngleXY = atan2f(dy_frame, dx_frame + 0.0001f); // Angle in XY plane (-PI to PI)
        float directionMod = (moveAngleXY / (float)PI + 1.0f) * 0.5f; // Map to 0-1
        float cutoffMultiplierFromDirection = 0.5f + directionMod * 1.0f; // Modulate from 0.5x to 1.5x
        float actualCutoffChord = baseCutoffChord * cutoffMultiplierFromDirection;
        actualCutoffChord = clampFloat(actualCutoffChord, 100.0f, 8000.0f);
        // --- END Player direction filter mod ---

        chordLPF_L.setLowpass(actualCutoffChord, SAMPLE_RATE);
        chordLPF_R.setLowpass(actualCutoffChord * (1.0f + 0.1f * sinf(px * 4.0f)), SAMPLE_RATE); // Slight stereo difference
        float sampleChordL = chordLPF_L.process(rawChord * 0.65f * spatialDepth);
        float sampleChordR = chordLPF_R.process(rawChord * 0.65f * spatialDepth);


        // 8) Bass
        double filterLFO2 = 0.5 + 0.5 * cos(py * 2.5 + spatialPanPhase * TWO_PI);
        double freqBass = freqRoot * 0.4 * (1.0 + 0.3 * sin(py * 5.5)); // Lower fundamental
        phaseBass += clampFloat((float)freqBass, 40.0f, 140.0f) / SAMPLE_RATE;
        if (phaseBass >= 1.0) phaseBass -= 1.0;
        float rawBass = sinf((float)(phaseBass * TWO_PI));
        float cutoffBass = 100.0f + (float)filterLFO2 * 900.0f;
        bassLPF_L.setLowpass(cutoffBass, SAMPLE_RATE);
        bassLPF_R.setLowpass(cutoffBass * 1.05f, SAMPLE_RATE);
        float sampleBassL = 0.6f * bassLPF_L.process(rawBass * 0.8f);
        float sampleBassR = 0.6f * bassLPF_R.process(rawBass * 0.8f);


        // --- 9) NEW: Fractal Generative Melody (replaces old lead) ---
        // Note generation is tied to kick drum trigger (see rhythm section)
        float sampleLeadVal = 0.0f;
        if (fractalMelody_env.active) {
            phaseLead += fractalMelody_currentFreq / SAMPLE_RATE;
            if (phaseLead >= 1.0) phaseLead -= 1.0;
            // Simple sine wave for melody, could be more complex (e.g. saw, square with LPF)
            float rawLead = sinf((float)(phaseLead * TWO_PI));
            sampleLeadVal = rawLead * fractalMelody_env.process() * 0.5f; // Apply envelope
        }
        float leadPan = 0.5f + 0.5f * cosf((float)(spatialPanPhase * TWO_PI + px * 1.5f));
        float sampleLeadL = sampleLeadVal * (1.0f - leadPan);
        float sampleLeadR = sampleLeadVal * leadPan;
        // --- END Fractal Melody ---


        // 10) FM bells and Karplus-Strong percussion (ornaments)
        float sampleOrnamentL = 0.0f, sampleOrnamentR = 0.0f;
        // FM Bells (existing) - slightly adjusted probability
        static bool fmBellMelActive = false; // Renamed to avoid conflict
        static double fmBellMelPhase = 0.0;
        static double fmBellMelEnv = 0.0;
        static double fmBellMelFreq = 0.0;

        if (!fmBellMelActive) {
            if (nextPositiveNoiseFloat() > (0.998f - pz * 0.02f)) { // Adjusted probability
                fmBellMelActive = true;
                int idx = rand() % SCALE_NOTES;
                fmBellMelFreq = currentScale[idx] * (2.0 + (rand() % 2)); // Higher octave
                fmBellMelPhase = 0.0;
                fmBellMelEnv = 1.0;
            }
        }
        if (fmBellMelActive) {
            fmBellMelPhase += fmBellMelFreq / SAMPLE_RATE;
            if (fmBellMelPhase >= 1.0) fmBellMelPhase -= 1.0;
            float tone = sinf((float)(fmBellMelPhase * TWO_PI)) * (float)fmBellMelEnv;
            fmBellMelEnv *= 0.989; // Decay
            if (fmBellMelEnv < 0.001) fmBellMelActive = false;
            float pan = 0.5f + 0.5f * sinf((float)(spatialPanPhase * TWO_PI * 1.2f));
            sampleOrnamentL += tone * 0.3f * (1.0f - pan);
            sampleOrnamentR += tone * 0.3f * pan;
        }
        // Complex FM Bells (existing)
        if (nextPositiveNoiseFloat() > (0.9993f - pz * 0.025f)) { // Adjusted probability
            for (int b = 0; b < 4; ++b) {
                if (!bells[b].active) {
                    bells[b].active = true;
                    bells[b].carrierFreq = 440.0 + (nextNoiseFloat()) * 150.0; // More variance
                    bells[b].modFreq = bells[b].carrierFreq * (1.0f + nextPositiveNoiseFloat() * 2.0f); // Ratio more varied
                    bells[b].carrierPhase = 0.0;
                    bells[b].modPhase = 0.0;
                    bells[b].env = 1.0;
                    break;
                }
            }
        }
        for (int b = 0; b < 4; ++b) {
            if (bells[b].active) {
                bells[b].modPhase += bells[b].modFreq / SAMPLE_RATE;
                if (bells[b].modPhase >= 1.0) bells[b].modPhase -= 1.0;
                double modulator = sin(bells[b].modPhase * TWO_PI) * (60.0 + nextPositiveNoiseFloat() * 40.0); // Modulation index varied
                bells[b].carrierPhase += (bells[b].carrierFreq + modulator) / SAMPLE_RATE;
                if (bells[b].carrierPhase >= 1.0) bells[b].carrierPhase -= 1.0;
                float bellSample = float(sin(bells[b].carrierPhase * TWO_PI) * bells[b].env);
                bells[b].env *= (0.994 - nextPositiveNoiseFloat() * 0.01); // Varied decay
                if (bells[b].env < 0.001) { bells[b].active = false; bells[b].env = 0.0f; }
                float pan = 0.1f + 0.8f * nextPositiveNoiseFloat(); // Wider pan range
                sampleOrnamentL += bellSample * (1.0f - pan) * 0.15f; // Reduced gain
                sampleOrnamentR += bellSample * pan * 0.15f;
            }
        }

        // --- NEW: Karplus-Strong Metallic Percussion ---
        if (nextPositiveNoiseFloat() > 0.9985f) { // Random trigger for KS
            for (int s = 0; s < NUM_KS_STRINGS; ++s) {
                if (!ksStrings[s].active) {
                    float freq = 300.0f + nextPositiveNoiseFloat() * 1000.0f; // Metallic range
                    float decayTime = 0.1f + nextPositiveNoiseFloat() * 0.4f; // Short, metallic decays
                    ksStrings[s].excite(freq, decayTime, SAMPLE_RATE);
                    break;
                }
            }
        }
        float ks_mixed_sample = 0.0f;
        for (int s = 0; s < NUM_KS_STRINGS; ++s) {
            ks_mixed_sample += ksStrings[s].process();
        }
        // Simple panning for KS sounds as a group
        float ksPan = 0.5f + 0.5f * nextNoiseFloat(); // Random pan per frame for the group
        sampleOrnamentL += ks_mixed_sample * (1.0f - ksPan) * 0.2f; // Adjust gain as needed
        sampleOrnamentR += ks_mixed_sample * ksPan * 0.2f;
        // --- END Karplus-Strong ---


        // 11) Ambient pad layer
        float samplePadL = 0.0f, samplePadR = 0.0f;
        if (padEnv > 0.0001) {
            padEnv *= padEnvDecay;
            double detuneAmounts[4] = { -0.01, 0.0, 0.01, 0.02 };
            for (int p = 0; p < 4; ++p) {
                double baseFreq = freqRoot * (1.0 + detuneAmounts[p]);
                padPhase[p] += baseFreq / SAMPLE_RATE;
                if (padPhase[p] >= 1.0) padPhase[p] -= 1.0;
                float saw = (float)(padPhase[p] * 2.0 - 1.0); // Sawtooth
                // Stereo width for pad using slight phase offset in LFO for pan
                float padPanLFO = sinf((float)(spatialPanPhase * TWO_PI + p * 0.25 * PI));
                float pan = 0.5f + 0.5f * padPanLFO;
                samplePadL += saw * (1.0f - pan) * 0.1f * (float)padEnv; // Reduced gain slightly
                samplePadR += saw * pan * 0.1f * (float)padEnv;
            }
            float padCutoff = 200.0f + (float)(0.5 + 0.5 * cos(spatialPanPhase * TWO_PI)) * 1000.0f;
            padLPF_L.setLowpass(padCutoff, SAMPLE_RATE);
            padLPF_R.setLowpass(padCutoff * 1.05f, SAMPLE_RATE); // Slight stereo filter diff
            samplePadL = padLPF_L.process(samplePadL); // Removed *0.8 as gain adjusted above
            samplePadR = padLPF_R.process(samplePadR);
        }


        // 12) "Brr" layer: playful constant texture
        float rawBrr = nextNoiseFloat() * 0.2f;
        brrLPF.setLowpass(1200.0f, SAMPLE_RATE);
        float brrLow = brrLPF.process(rawBrr);
        brrHPF.setHighpass(400.0f, SAMPLE_RATE);
        float brrBand = brrHPF.process(brrLow);
        float brrAmp = 0.3f * (float)(0.5 + 0.5 * sin(brrLFOPhase * TWO_PI));
        float brrSample = brrBand * brrAmp;
        float brrPan = 0.5f + 0.5f * sinf((float)(brrPanPhase * TWO_PI));
        float sampleBrrL = brrSample * (1.0f - brrPan) * 0.4f;
        float sampleBrrR = brrSample * brrPan * 0.4f;


        // 13) Rhythm sequencing (4-beat bar)
        barPhase += tempoFactor / SAMPLE_RATE;
        if (barPhase >= 4.0) { // 4 beats per bar
            barPhase -= 4.0;
            prevBeatStep = -1; // Allow retrigger on beat 0
        }
        int beatStep = static_cast<int>(floor(barPhase)) % 4;

        fractalMelody_newNoteTriggered = false; // Reset trigger flag

        if (beatStep != prevBeatStep) {
            prevBeatStep = beatStep; // Update previous beat step
            bool kickJustTriggered = false;
            if (!rhythmPattern) { // Simpler rhythm
                if (beatStep == 0) { kickEnv.trigger(1.0f, 0.994f); kickJustTriggered = true; }
                if (beatStep == 2) { snareEnv.trigger(1.0f, 0.988f); }
                hatEnv.trigger(0.5f, 0.96f); // Hats on all quarter notes
            }
            else { // More complex rhythm
                if (beatStep == 0 || beatStep == 2) { kickEnv.trigger(1.0f, 0.991f); kickJustTriggered = true; }
                if (beatStep == 1 || beatStep == 3) { snareEnv.trigger(1.0f, 0.982f); }
                hatEnv.trigger(0.4f, 0.94f); // Hats on all quarter notes
            }

            // --- NEW: Fractal Melody Trigger on Kick ---
            if (kickJustTriggered) {
                // Logistic map: x_n+1 = r * x_n * (1 - x_n)
                // Parameter 'r' for logistic map, could be dynamic (e.g., 3.57 to 4.0 for chaos)
                double r_logistic = 3.57 + clampFloat(px, -1.0f, 1.0f) * 0.2 + 0.22f; // Map px to range near 3.57-3.99
                r_logistic = clampFloat((float)r_logistic, 3.57f, 3.99f);
                fractalMelody_logisticX = r_logistic * fractalMelody_logisticX * (1.0 - fractalMelody_logisticX);

                int fractalNoteIndex = static_cast<int>(fractalMelody_logisticX * SCALE_NOTES);
                fractalNoteIndex = clampFloat(fractalNoteIndex, 0, SCALE_NOTES - 1);

                fractalMelody_currentFreq = currentScale[fractalNoteIndex] * (1.0 + (rand() % 3)); // Random octave (1x, 2x, 3x)
                fractalMelody_env.trigger(1.0f, powf(0.2f, 1.0f / (0.3f * (float)SAMPLE_RATE / (float)tempoFactor))); // Decay over ~0.3 beats
                fractalMelody_newNoteTriggered = true;
            }
            // --- END Fractal Melody Trigger ---
        }
        // Off-beat hats for complex rhythm
        float eighthPhase = fmodf((float)barPhase, 1.0f) * 2.0f; // Phase within current beat, for 8ths
        // (barPhase - floor(barPhase)) gives phase within current beat
        static int prevEighthStep = -1;
        int currentEighthStep = static_cast<int>(floor(fmodf((float)barPhase, 1.0f) * 2.0f)); // 0 or 1 for each half of beat
        if (rhythmPattern) {
            // Trigger on every 8th note if prevEighthStep used, or on specific 8ths
            if ((beatStep * 2 + currentEighthStep) % 2 != 0) { // If on an off-beat 8th
                // Check if it's a new 8th step to avoid retriggering
                if ((beatStep * 2 + currentEighthStep) != prevEighthStep) {
                    hatEnv.trigger(0.3f, 0.92f); // Quieter off-beat hats
                }
            }
            prevEighthStep = beatStep * 2 + currentEighthStep;
        }


        // 14) Percussion synthesis
        float sampleKickL = 0.0f, sampleKickR = 0.0f;
        float sampleSnareL = 0.0f, sampleSnareR = 0.0f;
        float sampleHatL = 0.0f, sampleHatR = 0.0f;

        if (kickEnv.active) {
            float pitchMod = powf(kickEnv.value, 2.0f) * 45.0f; // Pitch sweep
            kickPhase += (55.0f + pitchMod) / SAMPLE_RATE;
            if (kickPhase >= 1.0) kickPhase -= 1.0;
            float k = sinf((float)(kickPhase * TWO_PI)) * kickEnv.process();
            sampleKickL += k * 0.9f;
            sampleKickR += k * 0.9f;
        }

        if (snareEnv.active) {
            float noise = nextNoiseFloat() * snareEnv.process();
            // Adding a tonal body to snare:
            static double snareTonePhase = 0.0;
            snareTonePhase += 180.0 / SAMPLE_RATE; // ~180Hz tone
            if (snareTonePhase >= 1.0) snareTonePhase -= 1.0;
            float toneBody = sinf((float)(snareTonePhase * TWO_PI)) * 0.3f * snareEnv.value; // Use main env value

            snareHPF_L.setHighpass(1800.0f, SAMPLE_RATE); // For noisy part
            // snareLPF_L.setLowpass(400.0f, SAMPLE_RATE); // For tonal part (needs another filter instance)
            float s_noise = snareHPF_L.process(noise);
            float s = s_noise + toneBody;
            sampleSnareL += s * 0.5f; // Adjusted gain
            sampleSnareR += s * 0.5f;
        }

        if (hatEnv.active) {
            float noise = nextNoiseFloat() * hatEnv.process() * 0.3f;
            hatHPF_L.setHighpass(9000.0f, SAMPLE_RATE); // Very high cutoff for 'chick'
            hatHPF_R.setHighpass(9000.0f, SAMPLE_RATE);
            float hh = hatHPF_L.process(noise); // Use L for both, or make distinct
            // Simple stereo effect for hats
            if ((i % 4) < 2) sampleHatL += hh * 0.5f; // Pan slightly left for two samples
            else             sampleHatR += hh * 0.5f; // Then right
        }


        // 15) Atmospheric wind & NEW Spectral Freeze
        float rawWind = nextNoiseFloat() * 0.25f; // Base noise for wind
        // Resonant filter for wind "whoosh"
        float windFiltOut = rawWind - prevWindIn + 0.97f * prevWindOut;
        prevWindIn = rawWind;
        prevWindOut = windFiltOut;

        double windLFOVal = 0.5 + 0.5 * sin(windLFOPhase * TWO_PI);
        float windWet = windFiltOut * (float)windLFOVal * 0.3f;

        // --- Spectral Freeze Logic ---
        // Probability to trigger freeze
        if (!spectralFreeze_isActive && nextPositiveNoiseFloat() > 0.9998f) { // Low probability per sample
            spectralFreeze_isActive = true;
            spectralFreeze_durationCounter = SAMPLE_RATE * (2 + (int)(nextPositiveNoiseFloat() * 3.0f)); // Freeze for 2-5 seconds
            // Capture current wind spectrum (conceptually)
            // Fill input buffer (last FFT_FRAME_SIZE samples of windWet or windFiltOut)
            // For simplicity, let's assume spectralFreeze_inputBuffer has been filled elsewhere or use current windFiltOut
            // Here, we'd ideally take a snapshot of 'windFiltOut' over FFT_FRAME_SIZE
            // For this placeholder, we'll just use the current sample to "seed" an idea
            for (int k = 0; k < FFT_FRAME_SIZE; ++k) spectralFreeze_inputBuffer[k] = windFiltOut * spectralFreeze_hannWindow[k]; // Simplistic fill
            conceptual_fft(spectralFreeze_inputBuffer, spectralFreeze_frozenMagnitudes, FFT_FRAME_SIZE);
            spectralFreeze_samplesSinceLastIFFT = FFT_HOP_SIZE; // Start IFFT process
            spectralFreeze_crossfade = 0.0f; // Start crossfading in
        }

        float frozenWindSample = 0.0f;
        if (spectralFreeze_isActive) {
            if (spectralFreeze_crossfade < 1.0f) spectralFreeze_crossfade += 1.0f / (0.1f * SAMPLE_RATE); // 0.1s crossfade
            spectralFreeze_crossfade = clampFloat(spectralFreeze_crossfade, 0.0f, 1.0f);

            if (spectralFreeze_samplesSinceLastIFFT >= FFT_HOP_SIZE) {
                // Generate new phases (random phases for a "washy" freeze)
                std::vector<Complex> currentSpectrum(FFT_FRAME_SIZE / 2 + 1);
                for (size_t k = 0; k < spectralFreeze_frozenMagnitudes.size(); ++k) {
                    float magnitude = std::abs(spectralFreeze_frozenMagnitudes[k]); // Use stored magnitude
                    double random_phase = nextPositiveNoiseFloat() * TWO_PI;
                    currentSpectrum[k] = std::polar(magnitude, (float)random_phase);
                }
                // Shift old output buffer samples
                for (int k = 0; k < FFT_FRAME_SIZE - FFT_HOP_SIZE; ++k) {
                    spectralFreeze_outputBuffer[k] = spectralFreeze_outputBuffer[k + FFT_HOP_SIZE];
                }
                // Zero out the part that will receive new IFFT output
                for (int k = FFT_FRAME_SIZE - FFT_HOP_SIZE; k < FFT_FRAME_SIZE; ++k) {
                    spectralFreeze_outputBuffer[k] = 0.0f;
                }

                float ifft_segment[FFT_FRAME_SIZE];
                conceptual_ifft(currentSpectrum, ifft_segment, FFT_FRAME_SIZE);

                // Overlap-add
                for (int k = 0; k < FFT_FRAME_SIZE; ++k) {
                    spectralFreeze_outputBuffer[k] += ifft_segment[k] * spectralFreeze_hannWindow[k];
                }
                spectralFreeze_samplesSinceLastIFFT = 0;
            }
            frozenWindSample = spectralFreeze_outputBuffer[spectralFreeze_samplesSinceLastIFFT]; // This is simplified OLA read
            spectralFreeze_samplesSinceLastIFFT++;

            spectralFreeze_durationCounter--;
            if (spectralFreeze_durationCounter <= 0) {
                spectralFreeze_isActive = false; // Deactivate after duration (will crossfade out)
            }
        }
        else {
            if (spectralFreeze_crossfade > 0.0f) spectralFreeze_crossfade -= 1.0f / (0.1f * SAMPLE_RATE); // Crossfade out
            spectralFreeze_crossfade = clampFloat(spectralFreeze_crossfade, 0.0f, 1.0f);
        }
        // Use crossfader to mix between normal and frozen wind
        float finalWindSignal = windWet * (1.0f - spectralFreeze_crossfade) + frozenWindSample * spectralFreeze_crossfade;
        // --- END Spectral Freeze ---

        float cutoffWindL = 300.0f + (float)filterLFO2 * 400.0f; // filterLFO2 from bass section
        float cutoffWindR = 300.0f + (float)filterLFO2 * 450.0f;
        windHPF_L.setHighpass(cutoffWindL, SAMPLE_RATE);
        windHPF_R.setHighpass(cutoffWindR, SAMPLE_RATE);
        float sampleWindL = windHPF_L.process(finalWindSignal);
        float sampleWindR = windHPF_R.process(finalWindSignal);


        // 16) Granular shaker (existing)
        float shaker = 0.0f;
        if (nextPositiveNoiseFloat() > 0.9985f) {
            shaker = nextNoiseFloat() * 0.15f; // Bipolar noise for click
        }
        static float shakerEnv = 0.0f; // Envelope for shaker
        shakerEnv = shaker != 0.0f ? 1.0f : shakerEnv * 0.95f; // Fast attack, slower decay
        float sampleShaker = shaker * shakerEnv; // Use original shaker impulse * envelope
        float sampleShakerL = sampleShaker * 0.5f;
        float sampleShakerR = sampleShaker * 0.5f;


        // 17) Mix dry signals
        float mixL_dry =
            sampleChordL +
            sampleBassL +
            sampleLeadL +
            sampleOrnamentL +
            samplePadL +
            sampleKickL +
            sampleSnareL +
            sampleHatL +
            sampleWindL +
            sampleShakerL +
            sampleBrrL;

        float mixR_dry =
            sampleChordR +
            sampleBassR +
            sampleLeadR +
            sampleOrnamentR +
            samplePadR +
            sampleKickR +
            sampleSnareR +
            sampleHatR +
            sampleWindR +
            sampleShakerR +
            sampleBrrR;

        // --- NEW: Player Velocity -> Distortion ---
        // Max expected velocity, e.g. 10 units/sec. Normalize and map.
        float normVelocity = clampFloat(smoothedPlayerVelocity / 10.0f, 0.0f, 1.0f);
        float distortionAmount = normVelocity * 0.8f; // 0.0 to 0.8 distortion factor
        if (distortionAmount > 0.01f) { // Apply if significant
            // Simple tanh distortion: gain compensation might be needed for high amounts
            float drive = 1.0f + distortionAmount * 4.0f; // Increase drive with distortionAmount
            mixL_dry = tanhf(mixL_dry * drive) / (drive > 0.01f ? (drive * 0.5f + 0.5f) : 1.0f); // Basic auto-gain attempt
            mixR_dry = tanhf(mixR_dry * drive) / (drive > 0.01f ? (drive * 0.5f + 0.5f) : 1.0f);
        }
        // --- END Velocity Distortion ---


        // 18) Multi-tap ambient reverb
        int tapOffsets[4] = {
            (int)(0.1 * SAMPLE_RATE), (int)(0.23 * SAMPLE_RATE),
            (int)(0.47 * SAMPLE_RATE), (int)(0.85 * SAMPLE_RATE)
        };
        float tapGains[4] = { 0.5f, 0.35f, 0.2f, 0.1f };
        float revL = 0.0f, revR = 0.0f;
        for (int t = 0; t < 4; ++t) {
            int readIndex = (reverbWriteIndex - tapOffsets[t] + REVERB_BUFFER_SIZE) % REVERB_BUFFER_SIZE;
            revL += reverbBufferL[readIndex] * tapGains[t];
            revR += reverbBufferR[readIndex] * tapGains[t];
        }
        // Feedback into reverb buffer
        float fbMixL = mixL_dry + revL * 0.4f; // Reverb feedback amount
        float fbMixR = mixR_dry + revR * 0.4f;
        reverbBufferL[reverbWriteIndex] = clampFloat(fbMixL, -1.0f, 1.0f);
        reverbBufferR[reverbWriteIndex] = clampFloat(fbMixR, -1.0f, 1.0f);
        reverbWriteIndex = (reverbWriteIndex + 1) % REVERB_BUFFER_SIZE;

        // Mix reverb with dry signal for output
        float outL = mixL_dry + revL * 0.3f; // Reverb send to mix
        float outR = mixR_dry + revR * 0.3f;


        // --- 19) Final spatial stereo width (now with Dynamic Mixing) and rotation ---
        // Measure overall loudness of the dry mix (pre-reverb)
        float currentFrameInstantLoudness = (fabsf(mixL_dry) + fabsf(mixR_dry)) * 0.5f;
        mixOverallLoudness = mixOverallLoudness * 0.995f + currentFrameInstantLoudness * 0.005f; // Smooth loudness

        // Dynamic width: quieter -> wider, louder -> narrower
        // mixOverallLoudness typically 0 to ~0.5 for non-clipping common audio.
        // Target width range: 0.2 (mono-ish) to 1.5 (wide)
        float dynamicWidth = 1.5f - mixOverallLoudness * 2.6f; // If loudness=0.5, width = 1.5 - 1.3 = 0.2
        // If loudness=0.1, width = 1.5 - 0.26 = 1.24
        dynamicWidth = clampFloat(dynamicWidth, 0.2f, 1.5f);

        // Original player X position based width, can be combined or overridden.
        // Let's combine: use dynamicWidth as the main factor, px modulates it slightly.
        float finalWidthSetting = dynamicWidth * (0.8f + spatialWidthFactor * 0.4f); // e.g. px influence reduced
        finalWidthSetting = clampFloat(finalWidthSetting, 0.1f, 2.0f); // Clamp final width

        float mid = (outL + outR) * 0.5f;
        float side = (outR - outL) * 0.5f; // Current side signal

        side *= finalWidthSetting; // Apply dynamic width adjustment

        float rot = 0.5f + 0.5f * sinf((float)(spatialPanPhase * TWO_PI)); // Rotation LFO
        // This rotation is more of a L/R balance based on LFO after M/S.
        // A true rotation: L' = L*cos(a) - R*sin(a), R' = L*sin(a) + R*cos(a)
        // The current code is more like a panner for the 'side' component or a stereo balance.
        // Let's assume the existing logic for "rotation" is what's intended:
        float finalL = mid - side * rot;        // if rot=0, L = M-0 = M. if rot=1, L = M-S.
        float finalR = mid + side * (1.0f - rot); // if rot=0, R = M+S. if rot=1, R = M-0 = M.
        // This seems to make side signal pan.
        // Original: mid - side*rot and mid + side*rot (typo? or specific effect?)
        // Correct MS to LR with width 'w' and pan 'p' (0=L, 0.5=C, 1=R for 'mid'):
        // L_final = mid * (1-p_mid) + (mid - side * w) * p_side_L
        // R_final = mid * p_mid    + (mid + side * w) * p_side_R
        // The existing code: finalL = mid - side * rot; finalR = mid + side * rot;
        // If rot = 0.5, it's mid - 0.5*side and mid + 0.5*side. (Slightly narrow?)
        // Standard M/S to L/R: L = M+S, R = M-S. To control width: L = M + S*W, R = M - S*W
        // The original was: (outL+outR)*0.5; side = (outR-outL)*0.5 * width;
        // finalL = mid - side*rot; finalR = mid + side*rot;
        // This seems to be panning the 'difference' part.
        // Let's use a more standard width control:
        mid = (outL + outR) * 0.5f;
        side = (outR - outL) * 0.5f; // This is S = (R-L)/2. If L=M+S', R=M-S', then S=( (M-S') - (M+S') )/2 = -S'.
        // So, if using S = (R-L)/2, then L_new = M - S*width, R_new = M + S*width.

        float tempL = mid - side * finalWidthSetting;
        float tempR = mid + side * finalWidthSetting;

        // Apply the rotation LFO (as a simple stereo balance post-width)
        float L_rot = tempL * (1.0f - rot) + tempR * rot; // rot=0 -> L, rot=1 -> R
        float R_rot = tempL * rot + tempR * (1.0f - rot); // rot=0 -> R, rot=1 -> L
        // This is a typical "stereo rotation" or balance control.

        out[2 * i] = clampFloat(L_rot, -1.0f, 1.0f);
        out[2 * i + 1] = clampFloat(R_rot, -1.0f, 1.0f);
        // --- END Final Mix Stage ---
    }
}
