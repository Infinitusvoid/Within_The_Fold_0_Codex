#include "ShaderRuntime.h"

#include <iostream>
#include <unordered_map>
#include <glad/glad.h>

#include <glm/glm.hpp>

struct ShaderRuntime
{
	int ID;
    mutable std::unordered_map<std::string, GLint> uniform_locations;
};

namespace ShaderRuntime_
{
    static GLint get_uniform_location(const ShaderRuntime& shader, const std::string& name)
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

    
    static void printProgramLog(GLuint program)
    {
        GLint length = 0;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &length);
        if (length > 1)
        {
            GLchar* log = new GLchar[length];
            glGetProgramInfoLog(program, length, nullptr, log);
            std::cerr << "[ShaderRuntime] PROGRAM link error:\n"
                << log << "\n===================================\n";
            delete[] log;
        }
    }

    static void printShaderLog(GLuint shader, const char* type)
    {
        GLint length = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
        if (length > 1)
        {
            GLchar* log = new GLchar[length];
            glGetShaderInfoLog(shader, length, nullptr, log);
            std::cerr << "[ShaderRuntime] " << type << " compile error:\n"
                << log << "\n-----------------------------------\n";
            delete[] log;
        }
    }

    // Compile a single shader from source string. Returns shader ID, or 0 on failure.
    static GLuint compileShader(GLenum shaderType, const char* src)
    {
        GLuint shader = glCreateShader(shaderType);
        glShaderSource(shader, 1, &src, nullptr);
        glCompileShader(shader);

        GLint ok = GL_FALSE;
        glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
        if (!ok)
        {
            const char* typeStr = (shaderType == GL_VERTEX_SHADER) ? "VERTEX"
                : (shaderType == GL_FRAGMENT_SHADER) ? "FRAGMENT"
                : "UNKNOWN";
            printShaderLog(shader, typeStr);
            glDeleteShader(shader);
            return 0;
        }
        return shader;
    }

    ShaderRuntime* create(const char* source_code_vertex_shader, const char* source_code_fragment_shader)
    {
        // 1) Compile vertex shader
        GLuint vert = compileShader(GL_VERTEX_SHADER, source_code_vertex_shader);
        if (vert == 0)
        {
            std::cerr << "[ShaderRuntime] Failed to compile vertex shader.\n";
            return nullptr;
        }

        // 2) Compile fragment shader
        GLuint frag = compileShader(GL_FRAGMENT_SHADER, source_code_fragment_shader);
        if (frag == 0)
        {
            std::cerr << "[ShaderRuntime] Failed to compile fragment shader.\n";
            glDeleteShader(vert);
            return nullptr;
        }

        // 3) Create program and attach
        GLuint program = glCreateProgram();
        glAttachShader(program, vert);
        glAttachShader(program, frag);
        glLinkProgram(program);

        // 4) Check link status
        GLint linkOK = GL_FALSE;
        glGetProgramiv(program, GL_LINK_STATUS, &linkOK);
        if (!linkOK)
        {
            printProgramLog(program);
            glDeleteShader(vert);
            glDeleteShader(frag);
            glDeleteProgram(program);
            return nullptr;
        }

        // 5) Cleanup compiled shader objects; the program keeps its own copy
        glDeleteShader(vert);
        glDeleteShader(frag);

        // 6) Wrap into ShaderRuntime and return
        ShaderRuntime* result = new ShaderRuntime;
        result->ID = static_cast<int>(program);
        return result;
    }

	int get_id(ShaderRuntime* shader)
	{
		return shader->ID;
	}





    // ------------------------------------------------------------------------
    void use(const ShaderRuntime& shader)
    {
        glUseProgram(shader.ID);
    }
    // utility uniform functions
    // ------------------------------------------------------------------------
    void setBool(const ShaderRuntime& shader, const std::string& name, bool value)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniform1i(location, (int)value);
        }
    }
    // ------------------------------------------------------------------------
    void setInt(const ShaderRuntime& shader, const std::string& name, int value)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniform1i(location, value);
        }
    }
    // ------------------------------------------------------------------------
    void setFloat(const ShaderRuntime& shader, const std::string& name, float value)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniform1f(location, value);
        }
    }
    // ------------------------------------------------------------------------
    void setVec2(const ShaderRuntime& shader, const std::string& name, const glm::vec2& value)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniform2fv(location, 1, &value[0]);
        }
    }
    void setVec2(const ShaderRuntime& shader, const std::string& name, float x, float y)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniform2f(location, x, y);
        }
    }
    // ------------------------------------------------------------------------
    void setVec3(const ShaderRuntime& shader, const std::string& name, const glm::vec3& value)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniform3fv(location, 1, &value[0]);
        }
    }
    void setVec3(const ShaderRuntime& shader, const std::string& name, float x, float y, float z)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniform3f(location, x, y, z);
        }
    }
    // ------------------------------------------------------------------------
    void setVec4(const ShaderRuntime& shader, const std::string& name, const glm::vec4& value)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniform4fv(location, 1, &value[0]);
        }
    }
    void setVec4(const ShaderRuntime& shader, const std::string& name, float x, float y, float z, float w)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniform4f(location, x, y, z, w);
        }
    }
    // ------------------------------------------------------------------------
    void setMat2(const ShaderRuntime& shader, const std::string& name, const glm::mat2& mat)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniformMatrix2fv(location, 1, GL_FALSE, &mat[0][0]);
        }
    }
    // ------------------------------------------------------------------------
    void setMat3(const ShaderRuntime& shader, const std::string& name, const glm::mat3& mat)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniformMatrix3fv(location, 1, GL_FALSE, &mat[0][0]);
        }
    }
    // ------------------------------------------------------------------------
    void setMat4(const ShaderRuntime& shader, const std::string& name, const glm::mat4& mat)
    {
        const GLint location = get_uniform_location(shader, name);
        if (location >= 0)
        {
            glUniformMatrix4fv(location, 1, GL_FALSE, &mat[0][0]);
        }
    }

}
