#define MINIAUDIO_IMPLEMENTATION  
#include "../External_libs/miniaudio/miniaudio.h"   // Single-header miniaudio library for audio output

#include <numbers>
#include <atomic>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <conio.h>       // for _kbhit() and _getch() on Windows (non-blocking input)
#include <thread>
#include <chrono>
#include <iostream>

using namespace std::chrono_literals;  // for using 16ms as 16ms literal

// Audio configuration constants
constexpr ma_format   AUDIO_FORMAT = ma_format_f32;   // 32-bit float samples :contentReference[oaicite:5]{index=5}
constexpr ma_uint32   AUDIO_CHANNELS = 2;               // stereo output (2 channels)
constexpr ma_uint32   AUDIO_SAMPLE_RATE = 48000;        // 48 kHz sample rate

// Shared game state (accessible from both game thread and audio thread)
std::atomic<float> g_playerPosX(0.0f);   // player X position
std::atomic<float> g_playerPosY(0.0f);   // player Y position
std::atomic<float> g_playerPosZ(0.0f);   // player Z position
std::atomic<bool>  g_enemyActive(false); // whether an enemy event is active

static std::atomic<bool>  g_play_audio(true); // whether an enemy event is active

// #include "Music_0.h"
// #include "Music_1.h"
// #include "Music_2.h"
// #include "Music_3.h"
// #include "Music_4.h"
// #include "Music_5.h" //
#include "Music_6.h" // Nice
// #include "Music_7.h"
// #include "Music_8.h"
// #include "Music_9.h"
// #include "Music_10.h" //
// #include "Music_11.h"
// #include "Music_12.h" // repetative
// #include "Music_13.h"
// #include "Music_14.h"
// #include "Music_15.h"
// #include "Music_16.h" 
// #include "Music_17.h"
// #include "Music_18.h"
// #include "Music_19.h"
// #include "Music_20.h"
// #include "Music_W_04_06_2025_20_43.h"


struct Audio
{
    ma_device device;
    ma_device_config deviceConfig;
};


Audio g_audio;




void f_audio_off()
{
    std::cout << "audio playing on\n";
    g_play_audio.store(false);
}

void f_audio_on()
{
    std::cout << "audio playing off\n";
    g_play_audio.store(true);
}


bool f_audio_init()
{
    // 1. Configure the miniaudio device for playback
    g_audio.deviceConfig = ma_device_config_init(ma_device_type_playback);
    g_audio.deviceConfig.sampleRate = AUDIO_SAMPLE_RATE;
    g_audio.deviceConfig.playback.format = AUDIO_FORMAT;
    g_audio.deviceConfig.playback.channels = AUDIO_CHANNELS;
    g_audio.deviceConfig.dataCallback = audio_callback;
    g_audio.deviceConfig.pUserData = NULL;  // Not used here since we're using globals for state

    // 2. Initialize the audio device
    
    if (ma_device_init(NULL, &g_audio.deviceConfig, &g_audio.device) != MA_SUCCESS)
    {
        std::fprintf(stderr, "Failed to open playback device.\n");
        return false;
    }

    // 3. Start the device (begins audio callback in a separate thread)
    if (ma_device_start(&g_audio.device) != MA_SUCCESS)
    {
        std::fprintf(stderr, "Failed to start audio device.\n");
        ma_device_uninit(&g_audio.device);
        return false;
    }

    std::printf("Audio device started. Running game loop... (Press Enter to quit)\n");

    return true;
}

// you put this into the game loop
void f_audio_main_loop(float played_x, float player_y, float player_z)
{
    g_playerPosX.store(played_x);
    g_playerPosY.store(player_y);
    g_playerPosZ.store(player_z);

    
    // Update player position (move forward and wrap around for demo)
    {
        float pos = g_playerPosX.load();
        pos += 0.1f;
        if (pos > 100.0f) pos = 0.0f;
        g_playerPosX.store(pos);

        // Simulate an enemy event when player is in a certain range (50 <= x < 60)
        if (pos >= 50.0f && pos < 60.0f) {
            g_enemyActive.store(true);
        }
        else {
            g_enemyActive.store(false);
        }
    }


    // (Game logic and rendering would normally happen here)
    std::this_thread::sleep_for(16ms);  // simulate ~60 FPS frame delay

    // Check for user input to quit (non-blocking)
    if (_kbhit()) {
        int ch = _getch();
        if (ch == '\r' || ch == '\n') {
            // Break loop on Enter key
            return;
        }
    }
}

void f_audio_clean_up()
{
    std::printf("Shutting down...\n");
    // 5. Clean up: stop audio device and free resources
    ma_device_uninit(&g_audio.device);
}

//// Main function: initialize audio, run a simulated game loop, and clean up on exit.
//int main_background_music_example()
//{
//    
//    main_audio_loop();
//    // 4. Simulated game loop: update player position and trigger events
//    while (true) {
//        
//    }
//
//    
//    return 0;
//}
