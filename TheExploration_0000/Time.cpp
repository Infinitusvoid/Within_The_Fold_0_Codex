#include "Time.h"

#include <GLFW/glfw3.h>

void Time::update()
{
    // Per-frame time logic
    {
        float currentFrame = glfwGetTime();
        deltaTime = currentFrame - lastFrame;
        lastFrame = currentFrame;
    }


    // 2) Accumulate for FPS calculation
    fpsTimeAccumulator += deltaTime;
    frameCount++;

    // 3) If at least one second has passed, compute FPS
    if (fpsTimeAccumulator >= 1.0f)
    {
        fps = static_cast<float>(frameCount) / fpsTimeAccumulator;
        // reset for next interval
        frameCount = 0;
        fpsTimeAccumulator = 0.0f;
    }
}

float Time::get_delta_time()
{
    return deltaTime;
}

// Returns the most recently calculated FPS (frames per second)
// Note: this value updates approximately once per second.

float Time::get_fps() const
{
    return fps;
}
