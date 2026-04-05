#pragma once

#include <iostream>
#include <assert.h>
#include <glad/glad.h>
#include <GLFW/glfw3.h>

namespace GL_
{
    GLFWwindow* init_window(int width, int height, void (*framebuffer_size_callback_maze)(GLFWwindow*, int, int), void (*mouse_callback_maze)(GLFWwindow*, double, double));
    void clear_screen(float r, float g, float b);
    void swap_buffers_pull_events(GLFWwindow* window);
    void update_viewport(GLFWwindow* window, int width, int height);


    struct VAO
    {
        unsigned int id;
    };

    namespace VAO_
    {
        void init(VAO& vao);
        void bind(const VAO& vao);
        void unbind();
        void linkAttrib(GLuint index, GLint size, GLenum type, GLsizei stride, const void* offset);
    };
    

    struct VBO
    {
        unsigned int id;
    };

    namespace VBO_
    {
        void init(VBO& buf, GLsizeiptr size, const void* data, GLenum usage = GL_STATIC_DRAW);
        void bind(const VBO& buf);
        void unbind();
    }
}
