#pragma once

void f_audio_off();
void f_audio_on();

struct CameraControl
{
    // ---- "FLY" MODE TOGGLE
    bool flyMode = true;   // do we allow free 3D flight?
    bool fLatch = false;  // simple edge-detector so “F” toggles once per press

    // ---- COLLISION FLAGS
    const bool disable_collision = false;
    const bool collision_height = true;

    // new latch for fullscreen:
    bool fsLatch = false;


    // ---- WINDOW/SCREEN STATE
    bool       isFullscreen = false;
    int        windowPosX = 100;
    int        windowPosY = 100;
    int        windowWidth = 800;
    int        windowHeight = 600;
    GLFWmonitor* monitor = nullptr;
    const GLFWvidmode* mode = nullptr;

    // ---- PHYSICS STATE
    glm::vec3 velocity = glm::vec3(0.0f);
    glm::vec3 acceleration = glm::vec3(0.0f);

    // ---- TUNABLES
    //   You can tweak these at runtime or via a config file to "feel" how you like:
    float thrustStrength = 10.0f; // how hard we accelerate when a key is pressed (units/sec)
    float dragCoefficient = 4.0f; // simple linear drag (units/sec) pulling velocity -> 0
    float maxSpeed = 10.0f; // top horizontal-speed (units/sec)
    float maxVerticalSpeed = 10.0f; // top vertical speed when flying (units/sec)

    // audio toggle
    bool audioLatch = false;
    bool audio_playing = true;

    // ---- CONSTRUCTOR
    CameraControl() = default;

    // ---- FULLSCREEN TOGGLE
    void toggleFullscreen(GLFWwindow* window)
    {
        isFullscreen = !isFullscreen;

        if (isFullscreen)
        {
            // Save window position/size
            glfwGetWindowPos(window, &windowPosX, &windowPosY);
            glfwGetWindowSize(window, &windowWidth, &windowHeight);

            // Go fullscreen
            monitor = glfwGetPrimaryMonitor();
            mode = glfwGetVideoMode(monitor);
            glfwSetWindowMonitor(window,
                monitor,
                0, 0,
                mode->width,
                mode->height,
                mode->refreshRate);

            // If you store your global SCR_WIDTH/HEIGHT elsewhere:
            global.SCR_WIDTH = mode->width;
            global.SCR_HEIGHT = mode->height;
        }
        else
        {
            // Restore windowed
            glfwSetWindowMonitor(window,
                nullptr,
                windowPosX,
                windowPosY,
                windowWidth,
                windowHeight,
                0);

            global.SCR_WIDTH = windowWidth;
            global.SCR_HEIGHT = windowHeight;
        }
    }

    // ---- PER-FRAME UPDATE
    //   - "camera" is your existing MazeCamera (unchanged).
    //   - "time" gives deltaTime = time.get_delta_time().
    //   - "maze" allows collision checks: Maze_::isWall(maze, x, z) and Maze_::height_a(...).
    void update(GLFWwindow* window,
        MazeCamera& camera,
        Time& time,
        Maze_::Maze& maze)
    {
        float dt = time.get_delta_time();

        // ---- 1. TOGGLE FLY MODE WITH "2" (edge detect)
        if (glfwGetKey(window, GLFW_KEY_2) == GLFW_PRESS)
        {
            if (!fLatch)
            {
                flyMode = !flyMode;
                fLatch = true;
                // e.g. std::cout << (flyMode ? "Fly ON\n" : "Fly OFF\n");
                // When you switch from flyMode -> walkMode, zero out vertical velocity:
                if (!flyMode)
                    velocity.y = 0.0f;
            }
        }
        else
        {
            fLatch = false;
        }

        // ---- 2. BUILD "DESIRED DIRECTION" FROM INPUT ----
        //    Instead of "offset += forwardDir * cameraSpeed" directly,
        //    we accumulate a desired direction vector, then turn it into acceleration.

        // A) Compute forwardDir: either true 3D if flying, or constrained to XZ if walking.
        glm::vec3 forwardDir = flyMode
            ? glm::normalize(camera.Front)
            : glm::normalize(glm::vec3(camera.Front.x, 0.0f, camera.Front.z));

        // B) The camera s right vector (always horizontal cross of Front x (0,1,0))
        glm::vec3 right = glm::normalize(glm::cross(camera.Front, glm::vec3(0.0f, 1.0f, 0.0f)));

        // C) Start with zero desired direction
        glm::vec3 desiredDir = glm::vec3(0.0f);

        // D) WASD controls for forward/back/left/right
        if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS) desiredDir += forwardDir;
        if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS) desiredDir -= forwardDir;
        if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS) desiredDir -= right;
        if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS) desiredDir += right;

        // E) If flying, allow vertical thrust with SPACE & LSHIFT
        if (flyMode)
        {
            if (glfwGetKey(window, GLFW_KEY_SPACE) == GLFW_PRESS)       desiredDir += camera.Up;
            if (glfwGetKey(window, GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS)  desiredDir -= camera.Up;
        }

        // F) Normalize desiredDir (if nonzero). This ensures pressing multiple keys
        //    doesn"t accelerate faster (i.e. diagonal same magnitude as straight).
        if (glm::length(desiredDir) > 0.0f)
            desiredDir = glm::normalize(desiredDir);

        // 3. COMPUTE ACCELERATION: THRUST + DRAG
        //    acceleration = thrustStrength * desiredDir  +  (-dragCoefficient * velocity)
        //
        //    - If desiredDir == 0, only drag remains, so velocity will decay to 0.
        //    - We zero out the vertical component of drag if we are in "walk" mode,
        //      because in walk-mode we forcibly set camera.Position.y = constant anyway.

        // Reset acceleration
        acceleration = glm::vec3(0.0f);

        // A) Add thrust
        acceleration += desiredDir * thrustStrength;

        // B) Subtract drag: F_drag = -dragCoefficient * velocity
        //    If walk-mode, zero out the Y-component of drag (so you don`t `pull down in mid-walk`).
        if (flyMode)
        {
            acceleration += -dragCoefficient * velocity;
        }
        else
        {
            // Force vertical drag to zero (we will clamp Y to fixed later).
            glm::vec3 horizVel = glm::vec3(velocity.x, 0.0f, velocity.z);
            glm::vec3 drag = -dragCoefficient * horizVel;
            acceleration.x += drag.x;
            acceleration.z += drag.z;
            // leave acceleration.y = 0, and we’ll set velocity.y = 0 in walk mode below
        }

        // ---- 4. INTEGRATE VELOCITY
        //    v_new = v_old + a * dt
        velocity += acceleration * dt;

        // ---- 5. CLAMP SPEED TO MAXS
        //    We clamp horizontal speed to maxSpeed. If flying, clamp vertical speed
        //    |v.y| <= maxVerticalSpeed as well. If walking, forcibly zero out v.y.

        if (flyMode)
        {
            // A) Horizontal clamp
            glm::vec2 horizV = glm::vec2(velocity.x, velocity.z);
            float   speedXZ = glm::length(horizV);
            if (speedXZ > maxSpeed)
            {
                glm::vec2 flatDir = horizV / speedXZ; // unit
                horizV = flatDir * maxSpeed;
                velocity.x = horizV.x;
                velocity.z = horizV.y;
            }

            // B) Vertical clamp
            if (std::fabs(velocity.y) > maxVerticalSpeed)
                velocity.y = (velocity.y > 0 ? 1.0f : -1.0f) * maxVerticalSpeed;
        }
        else
        {
            // Walk-mode: zero out vertical velocity completely
            velocity.y = 0.0f;

            // Then clamp horizontal similarly:
            glm::vec2 horizV = glm::vec2(velocity.x, velocity.z);
            float   speedXZ = glm::length(horizV);
            if (speedXZ > maxSpeed)
            {
                glm::vec2 flatDir = horizV / speedXZ;
                horizV = flatDir * maxSpeed;
                velocity.x = horizV.x;
                velocity.z = horizV.y;
            }
        }

        // ---- 6. COMPUTE PROPOSED OFFSET = velocity * dt
        glm::vec3 offset = velocity * dt;

        // ---- 7. COLLISION ON X/Z (SLIDE)
        //    Exactly as your old code, but now using offset.x/offset.z instead of cameraSpeed*dt

        auto sgn = [](float v) { return (0.0f < v) - (v < 0.0f); };
        const float pad = 0.05f;

        // TRY X:
        float tryX = camera.Position.x + offset.x;
        if (disable_collision ||
            !Maze_::isWall(maze,
                tryX + sgn(offset.x) * pad,
                camera.Position.z))
                {
                    camera.Position.x = tryX;
        }
        else
        {
            // Collision: zero out X velocity so next frame we don`t keep pushing
            velocity.x = 0.0f;
        }

        // TRY Z:
        float tryZ = camera.Position.z + offset.z;
        if (disable_collision ||
            !Maze_::isWall(maze,
                camera.Position.x,
                tryZ + sgn(offset.z) * pad))
        {
            camera.Position.z = tryZ;
        }
        else
        {
            // Collision on Z: zero that component
            velocity.z = 0.0f;
        }

        // ---- 8. APPLY Y (HEIGHT)
        if (flyMode)
        {
            // 1) How much we`d like to move this frame:
            float tryY = camera.Position.y + offset.y;

            if (collision_height)
            {
                // a) Define eye-offset from floor and from ceiling:
                const float eyeOffset = 0.1f;

                // b) Floor is always at y = eyeOffset:
                float floorH = eyeOffset;

                // c) Ceiling is (wall-height) minus eyeOffset:
                float heightMax = static_cast<float>(
                    Maze_::height_at(maze,
                        camera.Position.x,
                        camera.Position.z)
                    ) - eyeOffset;

                // d) Clamp tryY between [floorH, heightMax]:
                //    - If you try to go below floorH, you stay at floorH.
                //    - If you try to go above heightMax, you stay at heightMax.
                camera.Position.y = std::fmax(std::fmin(tryY, heightMax),
                    floorH);
            }
            else
            {
                // If height-collision is disabled, just let Y track tryY:
                camera.Position.y = tryY;
            }
        }
        else
        {
            // Walk-mode: head is fixed at y = 0.5f
            camera.Position.y = 0.5f;
        }

        // ---- 9. MOUSE ROTATION & ESC/FULLSCREEN
        // (Left unchanged from before-just call ProcessMouseMovement once per frame)
        double mx, my;
        glfwGetCursorPos(window, &mx, &my);
        static double lastX = mx, lastY = my;
        float dx = static_cast<float>(mx - lastX);
        float dy = static_cast<float>(lastY - my); // invert Y if that`s your convention
        lastX = mx; lastY = my;

        camera.ProcessMouseMovement(dx, dy);

        // ESC => close window:
        if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
            glfwSetWindowShouldClose(window, true);

        // F -> toggle fullscreen (edge detect)
        if (glfwGetKey(window, GLFW_KEY_F) == GLFW_PRESS)
        {
            if (!fsLatch)
            {
                toggleFullscreen(window);
                fsLatch = true;
            }
        }
        else
        {
            fsLatch = false;
        }




        // toggle audio 
        if (glfwGetKey(window, GLFW_KEY_M) == GLFW_PRESS)
        {
            if (!audioLatch)
            {
                audio_playing = !audio_playing;
                if (audio_playing)
                {
                    f_audio_on();
                }
                else
                {
                    f_audio_off();
                }
                
                audioLatch = true;
            }
        }
        else
        {
            audioLatch = false;
        }
        
    }
};
