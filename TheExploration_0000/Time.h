#pragma once

struct Time
{
    void update();

    float get_delta_time();

    // Returns the most recently calculated FPS (frames per second)
   // Note: this value updates approximately once per second.
    float get_fps() const;

private:
    // Render loop
    float deltaTime = 0.0f;
    float lastFrame = 0.0f;

    // --- for FPS calculation ---
    float fpsTimeAccumulator = 0.0f;   // Accumulated time over which frames are counted
    int   frameCount = 0;      // Number of frames counted within the accumulator
    float fps = 0.0f;   // Last computed frames-per-second
};