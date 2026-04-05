#include "ShaderHot.h"

#include <filesystem>

#include "EditableShaders.h"

#include <iostream>

#include <glad/glad.h>
#include <glm/glm.hpp>

#include <string>

namespace ShaderHot_
{
    GLint get_uniform_location(const ShaderHot& shader, const std::string& name)
    {
        auto found = shader.uniform_locations.find(name);
        if (found != shader.uniform_locations.end())
        {
            return found->second;
        }

        const GLint location = glGetUniformLocation(shader.ID, name.c_str());
        shader.uniform_locations.emplace(name, location);
        return location;
    }

    void printShaderLog(GLuint shader, const char* type, const std::string& filepath)
    {
        GLchar log[1024];
        glGetShaderInfoLog(shader, 1024, nullptr, log);
        std::cerr << "[HotShader] " << type << " compile error in " << filepath << ":\n"
            << log << "\n-----------------------------------\n";
    }

    void printProgramLog(GLuint program, const std::string& vertex_filepath, const std::string& fragment_filepath)
    {
        GLchar log[1024];
        glGetProgramInfoLog(program, 1024, nullptr, log);
        std::cerr << "[HotShader] PROGRAM link error for\n"
            << "  vertex:   " << vertex_filepath << "\n"
            << "  fragment: " << fragment_filepath << "\n"
            << log << "\n===================================\n";
    }

    GLuint compileShaderFromSource(GLenum shader_type, const std::string& source, const std::string& filepath)
    {
        const char* src = source.c_str();
        GLuint shader = glCreateShader(shader_type);
        glShaderSource(shader, 1, &src, nullptr);
        glCompileShader(shader);

        GLint ok = GL_FALSE;
        glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
        if (!ok)
        {
            const char* shader_name = (shader_type == GL_VERTEX_SHADER) ? "VERTEX" : "FRAGMENT";
            printShaderLog(shader, shader_name, filepath);
            glDeleteShader(shader);
            return 0;
        }

        return shader;
    }

    GLuint compileFromFiles(const std::string& vertex_filepath, const std::string& fragment_filepath)
    {
        const std::string vertex_source = EditableShaders_::load_vertex_shader_source(vertex_filepath);
        const std::string fragment_source = EditableShaders_::load_fragment_shader_source(fragment_filepath);

        if (vertex_source.empty())
        {
            std::cerr << "[HotShader] Vertex source is empty: " << vertex_filepath << "\n";
            return 0;
        }

        if (fragment_source.empty())
        {
            std::cerr << "[HotShader] Fragment source is empty: " << fragment_filepath << "\n";
            return 0;
        }

        GLuint vertex_shader = compileShaderFromSource(GL_VERTEX_SHADER, vertex_source, vertex_filepath);
        if (vertex_shader == 0)
        {
            return 0;
        }

        GLuint fragment_shader = compileShaderFromSource(GL_FRAGMENT_SHADER, fragment_source, fragment_filepath);
        if (fragment_shader == 0)
        {
            glDeleteShader(vertex_shader);
            return 0;
        }

        GLuint program = glCreateProgram();
        glAttachShader(program, vertex_shader);
        glAttachShader(program, fragment_shader);
        glLinkProgram(program);

        GLint ok = GL_FALSE;
        glGetProgramiv(program, GL_LINK_STATUS, &ok);
        if (!ok)
        {
            printProgramLog(program, vertex_filepath, fragment_filepath);
            glDeleteShader(vertex_shader);
            glDeleteShader(fragment_shader);
            glDeleteProgram(program);
            return 0;
        }

        glDeleteShader(vertex_shader);
        glDeleteShader(fragment_shader);
        return program;
    }

    void updateWriteTimes(ShaderHot& shader)
    {
        std::error_code vertex_error;
        std::error_code fragment_error;

        const auto vertex_time = std::filesystem::last_write_time(shader.filepath_vertex_shader, vertex_error);
        const auto fragment_time = std::filesystem::last_write_time(shader.filepath_fragment_shader, fragment_error);

        if (!vertex_error)
        {
            shader.last_vert_write = vertex_time;
        }

        if (!fragment_error)
        {
            shader.last_frag_write = fragment_time;
        }
    }

    void load(ShaderHot& shader)
    {
        GLuint new_program = compileFromFiles(shader.filepath_vertex_shader, shader.filepath_fragment_shader);
        if (new_program != 0)
        {
            if (shader.ID != 0)
            {
                glDeleteProgram(shader.ID);
            }

            shader.ID = new_program;
            shader.uniform_locations.clear();
            updateWriteTimes(shader);
            std::cout << "[HotShader] Shader reloaded successfully (ID=" << shader.ID << ")\n";
        }
        else
        {
            std::cout << "[HotShader] Reload failed; keeping old shader (ID=" << shader.ID << ")\n";
        }
    }

    void load(ShaderHot& shader, std::string filepath_vertex, std::string filepath_fragment)
    {
        shader.filepath_vertex_shader = filepath_vertex;
        shader.filepath_fragment_shader = filepath_fragment;
        load(shader);
    }

    void checkForChanges(ShaderHot& shader)
    {
        std::error_code vertex_error;
        const auto vertex_time = std::filesystem::last_write_time(shader.filepath_vertex_shader, vertex_error);
        if (vertex_error)
        {
            std::cout << "file missing : " << shader.filepath_vertex_shader << "\n";
            return;
        }

        std::error_code fragment_error;
        const auto fragment_time = std::filesystem::last_write_time(shader.filepath_fragment_shader, fragment_error);
        if (fragment_error)
        {
            std::cout << "file missing : " << shader.filepath_fragment_shader << "\n";
            return;
        }

        if (vertex_time != shader.last_vert_write || fragment_time != shader.last_frag_write)
        {
            shader.last_vert_write = vertex_time;
            shader.last_frag_write = fragment_time;
            std::cout << "[HotShader] Detected change, reloading...\n";
            load(shader);
        }
    }

    void use(const ShaderHot& shader)
    {
        glUseProgram(shader.ID);
    }

    void setBool(const ShaderHot& shader, const std::string& name, bool value)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniform1i(location, static_cast<int>(value));
        }
    }

    void setInt(const ShaderHot& shader, const std::string& name, int value)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniform1i(location, value);
        }
    }

    void setFloat(const ShaderHot& shader, const std::string& name, float value)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniform1f(location, value);
        }
    }

    void setVec2(const ShaderHot& shader, const std::string& name, const glm::vec2& value)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniform2fv(location, 1, &value[0]);
        }
    }

    void setVec2(const ShaderHot& shader, const std::string& name, float x, float y)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniform2f(location, x, y);
        }
    }

    void setVec3(const ShaderHot& shader, const std::string& name, const glm::vec3& value)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniform3fv(location, 1, &value[0]);
        }
    }

    void setVec3(const ShaderHot& shader, const std::string& name, float x, float y, float z)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniform3f(location, x, y, z);
        }
    }

    void setVec4(const ShaderHot& shader, const std::string& name, const glm::vec4& value)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniform4fv(location, 1, &value[0]);
        }
    }

    void setVec4(const ShaderHot& shader, const std::string& name, float x, float y, float z, float w)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniform4f(location, x, y, z, w);
        }
    }

    void setMat2(const ShaderHot& shader, const std::string& name, const glm::mat2& mat)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniformMatrix2fv(location, 1, GL_FALSE, &mat[0][0]);
        }
    }

    void setMat3(const ShaderHot& shader, const std::string& name, const glm::mat3& mat)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniformMatrix3fv(location, 1, GL_FALSE, &mat[0][0]);
        }
    }

    void setMat4(const ShaderHot& shader, const std::string& name, const glm::mat4& mat)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniformMatrix4fv(location, 1, GL_FALSE, &mat[0][0]);
        }
    }
}
