#pragma once

#include "ShaderHot.h"
#include "ShaderRuntime.h"

#include "Texture.h"



struct Materials
{
    struct Material
    {
        ShaderHot_::ShaderHot* shader;
        ShaderRuntime* shader_runtime;

        std::vector<Texture_::Texture> textures;
    };

    std::vector<Material> list;
};


namespace Materials_
{
    int create_material(Materials& materials, std::string filepath_vertex, std::string filepath_fragment, std::vector<Texture_::Texture>& textures)
    {
        Materials::Material material;
        material.shader = new ShaderHot_::ShaderHot();
        material.shader_runtime = nullptr;
        ShaderHot_::load(*material.shader, filepath_vertex, filepath_fragment);
        material.textures = textures;
        materials.list.push_back(material);

        assert(materials.list.size() > 0);

        return materials.list.size() - 1; // material ID
    }

    int create_material_runtime(Materials& materials, ShaderRuntime* shader_runtime, std::vector<Texture_::Texture>& textures)
    {
        Materials::Material material;
        material.shader = nullptr;
        material.shader_runtime = shader_runtime;
        material.textures = textures;
        materials.list.push_back(material);

        assert(materials.list.size() > 0);

        return materials.list.size() - 1; // material ID
    }
}