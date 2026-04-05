#include "ShaderHot.h"

#include <filesystem>

#include "CppCommponents/File.h"

#include <iostream>

#include <glad/glad.h>
#include <glm/glm.hpp>

#include <string>
#include <fstream>
#include <sstream>
#include <iostream>

namespace ShaderHot_
{
	// helpers to print the logs
	void printShaderLog(GLuint shader, const char* type)
	{
		GLchar log[1024];
		glGetShaderInfoLog(shader, 1024, nullptr, log);
		std::cerr << "[HotShader] " << type << " compile error:\n"
			<< log << "\n-----------------------------------\n";
	}
	void printProgramLog(GLuint prog, const char* type)
	{
		GLchar log[1024];
		glGetProgramInfoLog(prog, 1024, nullptr, log);
		std::cerr << "[HotShader] " << type << " link error:\n"
			<< log << "\n===================================\n";
	}

	// read, compile, link; returns 0 on any failure
	GLuint compileFromFiles(const char* vertFile, const char* fragFile)
	{
		std::string vCode, fCode;
		try
		{
			// (You probably have a File::readFileToString helper:)
			vCode = File::readFileToString(vertFile);
			fCode = File::readFileToString(fragFile);
		}
		catch (const std::exception& e) {
			std::cerr << "[HotShader] File read error: " << e.what() << "\n";
			return 0;
		}

		const char* vSrc = vCode.c_str();
		const char* fSrc = fCode.c_str();
		GLint ok;
		GLuint vert = glCreateShader(GL_VERTEX_SHADER);
		glShaderSource(vert, 1, &vSrc, nullptr);
		glCompileShader(vert);
		glGetShaderiv(vert, GL_COMPILE_STATUS, &ok);
		if (!ok) {
			printShaderLog(vert, "VERTEX");
			glDeleteShader(vert);
			return 0;
		}

		GLuint frag = glCreateShader(GL_FRAGMENT_SHADER);
		glShaderSource(frag, 1, &fSrc, nullptr);
		glCompileShader(frag);
		glGetShaderiv(frag, GL_COMPILE_STATUS, &ok);
		if (!ok) {
			printShaderLog(frag, "FRAGMENT");
			glDeleteShader(vert);
			glDeleteShader(frag);
			return 0;
		}

		GLuint prog = glCreateProgram();
		glAttachShader(prog, vert);
		glAttachShader(prog, frag);
		glLinkProgram(prog);
		glGetProgramiv(prog, GL_LINK_STATUS, &ok);
		if (!ok) {
			printProgramLog(prog, "PROGRAM");
			glDeleteShader(vert);
			glDeleteShader(frag);
			glDeleteProgram(prog);
			return 0;
		}

		// cleanup
		glDeleteShader(vert);
		glDeleteShader(frag);
		return prog;
	}

	void load(ShaderHot& shader)
	{
		// compile into a temp program
		GLuint newProg = compileFromFiles(shader.filepath_vertex_shader.c_str(), shader.filepath_fragment_shader.c_str());
		if (newProg != 0)
		{
			// success! swap out the old
			if (shader.ID != 0)
			{
				glDeleteProgram(shader.ID);
			}
			shader.ID = newProg;
			std::cout << "[HotShader] Shader reloaded successfully (ID=" << shader.ID << ")\n";
		}
		else
		{
			// compile/link errors are already printed; old ID stays valid
			std::cout << "[HotShader] Reload failed; keeping old shader (ID=" << shader.ID << ")\n";
		}
	}

	void load(ShaderHot& shader, std::string filepath_vertex, std::string filepath_fragment)
	{
		shader.filepath_vertex_shader = filepath_vertex;
		shader.filepath_fragment_shader = filepath_fragment;
		load(shader);
	}

	// call once per frame (or once per N frames / seconds)
	void checkForChanges(ShaderHot& shader)
	{

		std::error_code ec_vertex;
		auto vTime = std::filesystem::last_write_time(shader.filepath_vertex_shader, ec_vertex);
		
		if (ec_vertex)
		{
			/* log “file missing” and skip reload */
			std::cout << "file missing : " << shader.filepath_vertex_shader << "\n";
			return;
		}

		std::error_code ec_fragment;
		auto fTime = std::filesystem::last_write_time(shader.filepath_fragment_shader, ec_fragment);
		
		if (ec_fragment)
		{
			/* log “file missing” and skip reload */
			std::cout << "file missing : " << shader.filepath_fragment_shader << "\n";
			return;
		}


		if (vTime != shader.last_vert_write || fTime != shader.last_frag_write)
		{
			shader.last_vert_write = vTime;
			shader.last_frag_write = fTime;
			std::cout << "[HotShader] Detected change, reloading...\n";
			load(shader);
		}
	}


	// ------------------------------------------------------------------------
	void use(const ShaderHot& shader)
	{
		glUseProgram(shader.ID);
	}
	// utility uniform functions
	// ------------------------------------------------------------------------
	void setBool(const ShaderHot& shader, const std::string& name, bool value)
	{
		glUniform1i(glGetUniformLocation(shader.ID, name.c_str()), (int)value);
	}
	// ------------------------------------------------------------------------
	void setInt(const ShaderHot& shader, const std::string& name, int value)
	{
		glUniform1i(glGetUniformLocation(shader.ID, name.c_str()), value);
	}
	// ------------------------------------------------------------------------
	void setFloat(const ShaderHot& shader, const std::string& name, float value)
	{
		glUniform1f(glGetUniformLocation(shader.ID, name.c_str()), value);
	}
	// ------------------------------------------------------------------------
	void setVec2(const ShaderHot& shader, const std::string& name, const glm::vec2& value)
	{
		glUniform2fv(glGetUniformLocation(shader.ID, name.c_str()), 1, &value[0]);
	}
	void setVec2(const ShaderHot& shader, const std::string& name, float x, float y) 
	{
		glUniform2f(glGetUniformLocation(shader.ID, name.c_str()), x, y);
	}
	// ------------------------------------------------------------------------
	void setVec3(const ShaderHot& shader, const std::string& name, const glm::vec3& value)
	{
		glUniform3fv(glGetUniformLocation(shader.ID, name.c_str()), 1, &value[0]);
	}
	void setVec3(const ShaderHot& shader, const std::string& name, float x, float y, float z)
	{
		glUniform3f(glGetUniformLocation(shader.ID, name.c_str()), x, y, z);
	}
	// ------------------------------------------------------------------------
	void setVec4(const ShaderHot& shader, const std::string& name, const glm::vec4& value)
	{
		glUniform4fv(glGetUniformLocation(shader.ID, name.c_str()), 1, &value[0]);
	}
	void setVec4(const ShaderHot& shader, const std::string& name, float x, float y, float z, float w)
	{
		glUniform4f(glGetUniformLocation(shader.ID, name.c_str()), x, y, z, w);
	}
	// ------------------------------------------------------------------------
	void setMat2(const ShaderHot& shader, const std::string& name, const glm::mat2& mat)
	{
		glUniformMatrix2fv(glGetUniformLocation(shader.ID, name.c_str()), 1, GL_FALSE, &mat[0][0]);
	}
	// ------------------------------------------------------------------------
	void setMat3(const ShaderHot& shader, const std::string& name, const glm::mat3& mat)
	{
		glUniformMatrix3fv(glGetUniformLocation(shader.ID, name.c_str()), 1, GL_FALSE, &mat[0][0]);
	}
	// ------------------------------------------------------------------------
	void setMat4(const ShaderHot& shader, const std::string& name, const glm::mat4& mat)
	{
		glUniformMatrix4fv(glGetUniformLocation(shader.ID, name.c_str()), 1, GL_FALSE, &mat[0][0]);
	}

}