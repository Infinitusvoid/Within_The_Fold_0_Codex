#pragma once

#include <numbers>


// Global phase accumulator for the 220 Hz sine wave:


static int counter = 0;

struct Wave
{
    void set_frequncy(float freq)
    {
        this->freq = freq;
        // Phase increment per sample:
        this->phaseIncrement = freq / AUDIO_SAMPLE_RATE; // ~0.0045833…
    }

    float generate_sample()
    {
        sinePhase += phaseIncrement;
        if (sinePhase >= 1.0f)
        {
            sinePhase -= floorf(sinePhase);
        }

        return sinf(std::numbers::pi * 2.0 * sinePhase);
    }

private:
    float freq = 220.0;

    float sinePhase = 0.0f;

    float phaseIncrement = 0.0f;
};

Wave g_wave_220;
Wave g_wave_440;
Wave g_wave_720;

std::vector<int> g_notes = {
    0, 1, 2, 1,
    1, 2, 1, 0,
    1, 0, 0, 1,
    3, 1, 1, 2,
    0, 1, 2, 1,
    0, 2, 1, 2,
    0, 1, 2, 1,
    0, 1, 1, 2,
    1, 1, 2, 2,
    1, 2, 2, 2, 0, 0,
    3, 3, 2, 2, 0, 0
};



int g_note_index = 0;




void audio_callback(ma_device* pDevice, void* pOutput, const void* pInput, ma_uint32 frameCount)
{
    float* output = static_cast<float*>(pOutput);
    (void)pInput;  // Input not used (playback only)


    float px = g_playerPosX.load();
    float py = g_playerPosY.load();
    float pz = g_playerPosZ.load();
    
    
    g_wave_220.set_frequncy(220);
    g_wave_440.set_frequncy(440);
    g_wave_720.set_frequncy(720);
    
    
    
    

    for (ma_uint32 i = 0; i < frameCount; ++i)
    {
     
        counter += 1;

        if (counter % 2000 == 0)
        {
            g_note_index += 1;
            g_note_index = g_note_index % g_notes.size();

        }

       

        
        float sample = 0.0;
        float sample_220 = g_wave_220.generate_sample();
        float sample_440 = g_wave_440.generate_sample();
        float sample_720 = g_wave_720.generate_sample();

        if (g_notes[g_note_index] == 1)
        {
            sample += sample_220;
        }
        else if (g_notes[g_note_index] == 2)
        {
            sample += sample_440;
        }
        else if (g_notes[g_note_index] == 3)
        {
            sample += sample_720;
        }
        
        /*if (notes[note_index] == 0)
        {
            sample = 0.0;
        }
        else if (notes[note_index] == 1)
        {
            sample = g_wave_220.generate_sample();
        }
        else if (notes[note_index] == 2)
        {
            sample = g_wave_440.generate_sample();
        }
        else if (notes[note_index] == 3)
        {
            sample = g_wave_720.generate_sample();
        }*/


        // Write the same sample to both left and right channels (stereo output)
        output[2 * i + 0] = sample;
        output[2 * i + 1] = sample;
    }
        
       
    
}