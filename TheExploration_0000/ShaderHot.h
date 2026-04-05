#pragma once

#include <string>
#include <unordered_map>

#include <chrono>
#include <filesystem>
#include <filesystem>
#include <chrono>
#include <string>
#include "../External_libs/glm_0_9_9_7/glm/glm/glm.hpp"

namespace ShaderHot_
{
	struct ShaderHot
	{
		std::string filepath_fragment_shader;
		std::string filepath_vertex_shader;

		std::filesystem::file_time_type last_vert_write;
		std::filesystem::file_time_type last_frag_write;

		int ID = 0;
		mutable std::unordered_map<std::string, int> uniform_locations;
	};

	void load(ShaderHot& shader);
	void load(ShaderHot& shader, std::string filepath_vertex, std::string filepath_fragment);
	void checkForChanges(ShaderHot& shader);

	void use(const ShaderHot& shader);
	void setBool(const ShaderHot& shader, const std::string& name, bool value);
	void setInt(const ShaderHot& shader, const std::string& name, int value);
	void setFloat(const ShaderHot& shader, const std::string& name, float value);
	void setVec2(const ShaderHot& shader, const std::string& name, const glm::vec2& value);
	void setVec2(const ShaderHot& shader, const std::string& name, float x, float y);
	void setVec3(const ShaderHot& shader, const std::string& name, const glm::vec3& value);
	void setVec3(const ShaderHot& shader, const std::string& name, float x, float y, float z);
	void setVec4(const ShaderHot& shader, const std::string& name, const glm::vec4& value);
	void setVec4(const ShaderHot& shader, const std::string& name, float x, float y, float z, float w);
	void setMat2(const ShaderHot& shader, const std::string& name, const glm::mat2& mat);
	void setMat3(const ShaderHot& shader, const std::string& name, const glm::mat3& mat);
	void setMat4(const ShaderHot& shader, const std::string& name, const glm::mat4& mat);
}
