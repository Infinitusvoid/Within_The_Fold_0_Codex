#include <iostream>
#include <cmath>
#include <vector>
#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <memory>

#include "CppCommponents/Random.h"
#include "CppCommponents/Folder.h"

#include "CppCommponents/File.h"

#include "CubeGeometryBuilder.h"
#include "Time.h"
#include "ImageUtils.h"

#include "GL.h"



#include "Materials.h"

#include "Maze.h"
#include "MazeCamera.h"
#include "EditableShaders.h"


struct MazeGlobal
{
    // Settings
    int SCR_WIDTH = 1920;
    int SCR_HEIGHT = 1080;

    // We will capture mouse movement to rotate the camera view
    // MazeCamera* cameraPtr = nullptr;

    bool firstMouse = true;
    float lastX = SCR_WIDTH / 2.0f;
    float lastY = SCR_HEIGHT / 2.0f;
};

MazeGlobal global;

void framebuffer_size_callback_maze(GLFWwindow* window, int width, int height);
void mouse_callback_maze(GLFWwindow* window, double xpos, double ypos);

#include "DrawCommandsSingleMaterial.h"
#include "Enviroment.h"
#include "CameraControl.h"

void f_audio_off();
void f_audio_on();
bool f_audio_init();
void f_audio_main_loop(float played_x, float player_y, float player_z);
void f_audio_clean_up();

struct Engine
{
    GLFWwindow* window;

    Maze_::Maze maze;

    Time time;
    CameraControl camera_control;
    
    MazeCamera* camera;
};

namespace Engine_
{
    void init(Engine& engine)
    {
        Maze_::init(engine.maze);

        engine.window = GL_::init_window(global.SCR_WIDTH, global.SCR_HEIGHT, framebuffer_size_callback_maze, mouse_callback_maze);
        
        

        engine.camera = new MazeCamera(glm::vec3(1.5f, 0.5f, 1.5f), 0.0f, 0.0f);
        engine.camera->Position = Maze_::generate_start_camera_position(engine.maze);
    }

    void run(Engine& engine)
    {
        Enviroment_::Enviroment enviroment = Enviroment_::Enviroment_::generate_enviroment(engine.maze);
        std::vector<DrawCommandsSingleMaterial_::DrawCommandsSingleMaterial> drawcommands_enviroment = Enviroment_::Enviroment_::generate_draw_commands(enviroment);

        std::chrono::steady_clock::time_point lastHotCheck = std::chrono::steady_clock::now();
        f_audio_init();

        bool first_loop = true;
        int frame_index = 0;

        while (!glfwWindowShouldClose(engine.window))
        {
            engine.time.update();
            engine.camera_control.update(engine.window, *engine.camera, engine.time, engine.maze);

            const int safe_width = std::max(global.SCR_WIDTH, 1);
            const int safe_height = std::max(global.SCR_HEIGHT, 1);

            glm::mat4 projection = glm::perspective(glm::radians(45.0f),
                (float)safe_width / (float)safe_height,
                0.01f, 100.0f);

            GL_::clear_screen(0.1f, 0.6f, 0.9f);

            f_audio_main_loop(engine.camera->Position.x, engine.camera->Position.y, engine.camera->Position.z);

            glm::mat4 view = engine.camera->GetViewMatrix();
            glm::mat4 model = glm::mat4(1.0f);
            const glm::vec2 viewport_size = glm::vec2((float)safe_width, (float)safe_height);

            {
                for (DrawCommandsSingleMaterial_::DrawCommandsSingleMaterial& draw_commands_single_material : drawcommands_enviroment)
                {
                    DrawCommandsSingleMaterial_::draw
                    (
                        draw_commands_single_material,
                        model,
                        view,
                        projection,
                        glfwGetTime(),
                        engine.time.get_delta_time(),
                        frame_index,
                        viewport_size,
                        engine.camera->Position
                    );
                }
            }

            {
                auto now = std::chrono::steady_clock::now();
                if (now - lastHotCheck > std::chrono::milliseconds(Global_constants_::shader_hot_reload_interval_ms))
                {
                    lastHotCheck = now;
                    for (auto& material : drawcommands_enviroment)
                    {
                        if (material.material.shader != nullptr)
                        {
                            ShaderHot_::checkForChanges(*material.material.shader);
                        }
                    }
                }
            }

            {
                if (Global_constants_::print_out_fps)
                {
                    std::cout << "fps : " << engine.time.get_fps() << "\n";
                }
            }

            GL_::swap_buffers_pull_events(engine.window);


            if (first_loop)
            {
                first_loop = false;
                engine.camera_control.toggleFullscreen(engine.window);
            }

            frame_index++;
        }

        f_audio_clean_up();
    }
}


Engine engine;

int main()
{
    EditableShaders_::ensure_editable_shader_files();

    {
        const EditableShaders_::EditableShaderSettings& editable_shader_settings = EditableShaders_::settings();
        const std::string& raymarching_folder = EditableShaders_::raymarching_shader_folder();
        const std::string& shadertoy_folder = EditableShaders_::shadertoy_shader_folder();

        std::cout << "Starting the game...\n";
        std::cout << "Settings file          : " << EditableShaders_::settings_file_path().string() << "\n";
        std::cout << "Editable shaders are loaded from these folders:\n";
        std::cout << "  Raymarching : " << raymarching_folder << "\n";
        std::cout << "  Shadertoy   : " << shadertoy_folder << "\n";
        std::cout
            << "Shader mix weights     : raymarching="
            << editable_shader_settings.shader_mix.raymarching_weight
            << ", shadertoy="
            << editable_shader_settings.shader_mix.shadertoy_weight
            << "\n";
        std::cout
            << "Shader caps            : raymarching="
            << EditableShaders_::shader_limit_label(editable_shader_settings.shader_mix.max_raymarching_shaders)
            << ", shadertoy="
            << EditableShaders_::shader_limit_label(editable_shader_settings.shader_mix.max_shadertoy_shaders)
            << "\n";
        std::cout << "Missing folders are created automatically, and starter shaders are seeded if enabled in settings.json.\n";
        std::cout << "Shader edits are hot reloaded while the game is running.\n\n";

        std::cout << "=== Controls ===\n";
        std::cout << "W, A, S, D : Move\n";
        std::cout << "F          : Toggle Fullscreen\n";
        std::cout << "2          : Toggle Fly Mode / Walk Mode\n";
        std::cout << "M          : Toggle Sound On/Off\n";
        std::cout << "\n";
    }

    Engine_::init(engine);
    Engine_::run(engine);
    return 0;
}

void framebuffer_size_callback_maze(GLFWwindow* window, int width, int height)
{
    global.SCR_WIDTH = std::max(width, 1);
    global.SCR_HEIGHT = std::max(height, 1);
    GL_::update_viewport(window, global.SCR_WIDTH, global.SCR_HEIGHT);
}

void mouse_callback_maze(GLFWwindow* window, double xpos, double ypos)
{
    if (global.firstMouse) {
        global.lastX = xpos;
        global.lastY = ypos;
        global.firstMouse = false;
    }
    float xoffset = xpos - global.lastX;
    float yoffset = global.lastY - ypos;  // Reversed: y coordinate goes from bottom to top
    global.lastX = xpos;
    global.lastY = ypos;
    if (engine.camera) {
        engine.camera->ProcessMouseMovement(xoffset, yoffset);
    }
}

