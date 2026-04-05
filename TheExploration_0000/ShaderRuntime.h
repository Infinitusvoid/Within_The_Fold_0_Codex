#pragma once

#include <string>
#include <glm/glm.hpp>

struct ShaderRuntime;


namespace ShaderRuntime_
{
	ShaderRuntime* create(const char* source_code_vertex_shader, const char* source_code_fragment_shader);
	int get_id(ShaderRuntime* shader);

	void use(const ShaderRuntime& shader);
	void setBool(const ShaderRuntime& shader, const std::string& name, bool value);
	void setInt(const ShaderRuntime& shader, const std::string& name, int value);
	void setFloat(const ShaderRuntime& shader, const std::string& name, float value);
	void setVec2(const ShaderRuntime& shader, const std::string& name, const glm::vec2& value);
	void setVec2(const ShaderRuntime& shader, const std::string& name, float x, float y);
	void setVec3(const ShaderRuntime& shader, const std::string& name, const glm::vec3& value);
	void setVec3(const ShaderRuntime& shader, const std::string& name, float x, float y, float z);
	void setVec4(const ShaderRuntime& shader, const std::string& name, const glm::vec4& value);
	void setVec4(const ShaderRuntime& shader, const std::string& name, float x, float y, float z, float w);
	void setMat2(const ShaderRuntime& shader, const std::string& name, const glm::mat2& mat);
	void setMat3(const ShaderRuntime& shader, const std::string& name, const glm::mat3& mat);
	void setMat4(const ShaderRuntime& shader, const std::string& name, const glm::mat4& mat);
}

