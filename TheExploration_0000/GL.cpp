#include "GL.h"

namespace GL_
{
    GLFWwindow* init_window(int width, int height, void (*framebuffer_size_callback_maze)(GLFWwindow*, int, int), void (*mouse_callback_maze)(GLFWwindow*, double, double))
    {
        GLFWwindow* window;
        {
            // Initialize GLFW and configure OpenGL context (version 3.3 Core Profile)
            glfwInit();
            glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
            glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
            glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#ifdef __APPLE__
            glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif

            // Create a GLFW window
            window = glfwCreateWindow(width, height, "Within The Fold 0", NULL, NULL);
            if (window == NULL) {
                std::cerr << "Failed to create GLFW window" << std::endl;
                glfwTerminate();

                assert(false);
            }
            glfwMakeContextCurrent(window);
            glfwSetFramebufferSizeCallback(window, framebuffer_size_callback_maze);

            // Load OpenGL function pointers using GLAD
            if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
                std::cerr << "Failed to initialize GLAD" << std::endl;

                assert(false);
            }
        }

        {
            // Set initial viewport
            glViewport(0, 0, width, height);
            // Configure global OpenGL state
            glEnable(GL_DEPTH_TEST);  // enable depth testing for 3D
            glEnable(GL_CULL_FACE);   // enable face culling to hide back faces of cubes
            glCullFace(GL_BACK);
            glFrontFace(GL_CCW);
        }

        {
            // Capture the mouse for FPS look
            glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
            glfwSetCursorPosCallback(window, mouse_callback_maze);
        }

        return window;
    }

    void clear_screen(float r, float g, float b)
    {
        // Rendering commands
        glClearColor(r, g, b, 1.0f);  // clear to a sky-blue color
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }

    void swap_buffers_pull_events(GLFWwindow* window)
    {
        // Swap the front/back buffers and poll events
        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    void update_viewport(GLFWwindow* window, int width, int height)
    {
        glViewport(0, 0, width, height);
    }

    
    namespace VAO_
    {
        void init(VAO& vao)
        {
            glGenVertexArrays(1, &vao.id);
        }

        void bind(const VAO& vao)
        {
            glBindVertexArray(vao.id);
        }

        void unbind()
        {
            glBindVertexArray(0);
        }

        void linkAttrib
        (
            GLuint index,
            GLint size,
            GLenum type,
            GLsizei stride,
            const void* offset
        )
        {
            // Assumes that the right VAO and VBO are already bound
            glVertexAttribPointer(index, size, type, GL_FALSE, stride, offset);
            glEnableVertexAttribArray(index);
        }
    }

    namespace VBO_
    {
        void init
        (
            VBO& buf,
            GLsizeiptr size,
            const void* data,
            GLenum usage
        )
        {
            glGenBuffers(1, &buf.id);
            glBindBuffer(GL_ARRAY_BUFFER, buf.id);
            glBufferData(GL_ARRAY_BUFFER, size, data, usage);
        }

        void bind(const VBO& buf)
        {
            glBindBuffer(GL_ARRAY_BUFFER, buf.id);
        }

        void unbind()
        {
            glBindBuffer(GL_ARRAY_BUFFER, 0);
        }
    }
}


