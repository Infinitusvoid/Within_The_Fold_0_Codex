#pragma once

#include "Global_constants.h"

namespace DrawCommandsSingleMaterial_
{
    namespace Mesh_
    {
        struct Mesh
        {
            GL_::VAO vao;
            GL_::VBO vbo;
            GLsizei vertexCount;
        };

        void init(Mesh& mesh, const std::vector<float>& vertices)
        {
            constexpr GLsizei floats_per_vertex = 5;

            mesh.vertexCount = static_cast<GLsizei>(vertices.size() / floats_per_vertex);
            const GLsizei stride = floats_per_vertex * sizeof(float);

            GL_::VAO_::init(mesh.vao);
            GL_::VBO_::init
            (
                mesh.vbo,
                vertices.size() * sizeof(float),
                vertices.data()
            );

            GL_::VAO_::bind(mesh.vao);
            GL_::VBO_::bind(mesh.vbo);

            GL_::VAO_::linkAttrib(0, 3, GL_FLOAT, stride, (void*)0);
            GL_::VAO_::linkAttrib(1, 2, GL_FLOAT, stride, (void*)(3 * sizeof(float)));

            GL_::VAO_::unbind();
            GL_::VBO_::unbind();
        }

        void draw(const Mesh& mesh)
        {
            GL_::VAO_::bind(mesh.vao);
            glDrawArrays(GL_TRIANGLES, 0, mesh.vertexCount);
            GL_::VAO_::unbind();
        }

        void draw_mesh_instances(const Mesh& mesh, const ShaderHot_::ShaderHot& shader, const std::vector<glm::vec3>& positions, const float scale)
        {
            ShaderHot_::use(shader);
            GL_::VAO_::bind(mesh.vao);

            for (int i = 0; i < static_cast<int>(positions.size()); i++)
            {
                glm::mat4 model = glm::mat4(1.0f);
                model = glm::translate(model, positions[i] * scale);
                model = glm::scale(model, glm::vec3(scale));
                ShaderHot_::setMat4(shader, "model", model);
                ShaderHot_::setVec3(shader, "uCubePos", positions[i]);
                ShaderHot_::setVec3(shader, "iCubePos", positions[i]);
                ShaderHot_::setVec3(shader, "uCubeCenter", positions[i] + glm::vec3(0.5f));

                glDrawArrays(GL_TRIANGLES, 0, mesh.vertexCount);
            }

            GL_::VAO_::unbind();
        }

        void draw_mesh_instances_runtime_shader(const Mesh& mesh, const ShaderRuntime& shader, const std::vector<glm::vec3>& positions, const float scale)
        {
            ShaderRuntime_::use(shader);
            GL_::VAO_::bind(mesh.vao);

            for (int i = 0; i < static_cast<int>(positions.size()); i++)
            {
                glm::mat4 model = glm::mat4(1.0f);
                model = glm::translate(model, positions[i] * scale);
                model = glm::scale(model, glm::vec3(scale));
                ShaderRuntime_::setMat4(shader, "model", model);
                ShaderRuntime_::setVec3(shader, "uCubePos", positions[i]);
                ShaderRuntime_::setVec3(shader, "iCubePos", positions[i]);
                ShaderRuntime_::setVec3(shader, "uCubeCenter", positions[i] + glm::vec3(0.5f));

                glDrawArrays(GL_TRIANGLES, 0, mesh.vertexCount);
            }

            GL_::VAO_::unbind();
        }

        inline void drawInstanced
        (
            const Mesh& mesh,
            ShaderHot_::ShaderHot& shader,
            std::function<bool(float&, float&, float&)> f,
            float scale
        )
        {
            ShaderHot_::use(shader);
            GL_::VAO_::bind(mesh.vao);

            float x;
            float y;
            float z;
            while (f(x, y, z))
            {
                glm::mat4 model = glm::mat4(1.0f);
                glm::vec3 pos = glm::vec3(x, y, z);
                model = glm::translate(model, pos * scale);
                model = glm::scale(model, glm::vec3(scale));

                ShaderHot_::setMat4(shader, "model", model);
                ShaderHot_::setVec3(shader, "uCubePos", pos);
                ShaderHot_::setVec3(shader, "iCubePos", pos);
                ShaderHot_::setVec3(shader, "uCubeCenter", pos + glm::vec3(0.5f));

                glDrawArrays(GL_TRIANGLES, 0, mesh.vertexCount);
            }

            GL_::VAO_::unbind();
        }
    }

    struct DrawCommandsSingleMaterial
    {
        std::vector<glm::vec3> cube_full_positions;
        std::vector<glm::vec3> cube_top_positions;
        std::vector<glm::vec3> cube_bottom_positions;
        std::vector<glm::vec3> cube_left_positions;
        std::vector<glm::vec3> cube_right_positions;
        std::vector<glm::vec3> cube_front_positions;
        std::vector<glm::vec3> cube_back_positions;

        Mesh_::Mesh mesh_full_positions;
        Mesh_::Mesh mesh_top_positions;
        Mesh_::Mesh mesh_bottom_positions;
        Mesh_::Mesh mesh_left_positions;
        Mesh_::Mesh mesh_right_positions;
        Mesh_::Mesh mesh_front_positions;
        Mesh_::Mesh mesh_back_positions;

        Materials::Material material;
    };

    inline glm::vec3 texture_resolution_or_viewport(const Materials::Material& material, int texture_index, const glm::vec2& viewport_size)
    {
        if (texture_index >= 0 && texture_index < static_cast<int>(material.textures.size()))
        {
            const Texture_::Texture& texture = material.textures[texture_index];
            return glm::vec3(static_cast<float>(texture.width), static_cast<float>(texture.height), 1.0f);
        }

        return glm::vec3(viewport_size, 1.0f);
    }

    inline glm::vec2 editable_surface_resolution()
    {
        // Shadertoy adapters use a stable virtual canvas so effects stay attached
        // to cube/object space instead of inheriting the current window size.
        return glm::vec2(1024.0f, 1024.0f);
    }

    inline void bind_shared_uniforms_hot
    (
        const ShaderHot_::ShaderHot& shader,
        Materials::Material& material,
        const glm::mat4& model,
        const glm::mat4& view,
        const glm::mat4& projection,
        float time,
        float delta_time,
        int frame_index,
        const glm::vec2& viewport_size,
        const glm::vec3& camera_position
    )
    {
        const glm::vec3 random_color =
        {
            Random::generate_random_float_0_to_1(),
            Random::generate_random_float_0_to_1(),
            Random::generate_random_float_0_to_1()
        };

        for (int i = 0; i < static_cast<int>(material.textures.size()); i++)
        {
            Texture_::bind(material.textures[i]);
            const std::string uniform_name = "texture" + std::to_string(i + 1);
            ShaderHot_::setInt(shader, uniform_name, i);
        }

        const int texture_count = static_cast<int>(material.textures.size());
        const int channel_0 = 0;
        const int channel_1 = (texture_count > 1) ? 1 : 0;

        ShaderHot_::setInt(shader, "iChannel0", channel_0);
        ShaderHot_::setInt(shader, "iChannel1", channel_1);
        ShaderHot_::setInt(shader, "iChannel2", channel_0);
        ShaderHot_::setInt(shader, "iChannel3", channel_1);

        ShaderHot_::setVec3(shader, "iChannelResolution[0]", texture_resolution_or_viewport(material, channel_0, viewport_size));
        ShaderHot_::setVec3(shader, "iChannelResolution[1]", texture_resolution_or_viewport(material, channel_1, viewport_size));
        ShaderHot_::setVec3(shader, "iChannelResolution[2]", texture_resolution_or_viewport(material, channel_0, viewport_size));
        ShaderHot_::setVec3(shader, "iChannelResolution[3]", texture_resolution_or_viewport(material, channel_1, viewport_size));

        ShaderHot_::setFloat(shader, "iChannelTime[0]", time);
        ShaderHot_::setFloat(shader, "iChannelTime[1]", time);
        ShaderHot_::setFloat(shader, "iChannelTime[2]", time);
        ShaderHot_::setFloat(shader, "iChannelTime[3]", time);

        ShaderHot_::setMat4(shader, "model", model);
        ShaderHot_::setMat4(shader, "view", view);
        ShaderHot_::setMat4(shader, "projection", projection);

        ShaderHot_::setVec3(shader, "uColor", random_color);
        ShaderHot_::setFloat(shader, "time", time);
        ShaderHot_::setFloat(shader, "uTime", time);
        ShaderHot_::setFloat(shader, "iTime", time);
        ShaderHot_::setFloat(shader, "uDeltaTime", delta_time);
        ShaderHot_::setFloat(shader, "iTimeDelta", delta_time);
        ShaderHot_::setInt(shader, "uFrame", frame_index);
        ShaderHot_::setInt(shader, "iFrame", frame_index);
        ShaderHot_::setVec2(shader, "uResolution", viewport_size);
        ShaderHot_::setVec2(shader, "uViewportSize", viewport_size);
        ShaderHot_::setVec2(shader, "uSurfaceResolution", editable_surface_resolution());
        ShaderHot_::setVec3(shader, "iResolution", glm::vec3(viewport_size, 1.0f));
        ShaderHot_::setVec4(shader, "iMouse", glm::vec4(0.0f));
        ShaderHot_::setVec3(shader, "uCamPos", camera_position);
        ShaderHot_::setVec3(shader, "uPlayerPos", camera_position);
        ShaderHot_::setVec3(shader, "iPlayerPos", camera_position);
        ShaderHot_::setInt(shader, "uTextureCount", texture_count);
    }

    inline void bind_shared_uniforms_runtime
    (
        const ShaderRuntime& shader,
        Materials::Material& material,
        const glm::mat4& model,
        const glm::mat4& view,
        const glm::mat4& projection,
        float time,
        float delta_time,
        int frame_index,
        const glm::vec2& viewport_size,
        const glm::vec3& camera_position
    )
    {
        const glm::vec3 random_color =
        {
            Random::generate_random_float_0_to_1(),
            Random::generate_random_float_0_to_1(),
            Random::generate_random_float_0_to_1()
        };

        for (int i = 0; i < static_cast<int>(material.textures.size()); i++)
        {
            Texture_::bind(material.textures[i]);
            const std::string uniform_name = "texture" + std::to_string(i + 1);
            ShaderRuntime_::setInt(shader, uniform_name, i);
        }

        const int texture_count = static_cast<int>(material.textures.size());
        const int channel_0 = 0;
        const int channel_1 = (texture_count > 1) ? 1 : 0;

        ShaderRuntime_::setInt(shader, "iChannel0", channel_0);
        ShaderRuntime_::setInt(shader, "iChannel1", channel_1);
        ShaderRuntime_::setInt(shader, "iChannel2", channel_0);
        ShaderRuntime_::setInt(shader, "iChannel3", channel_1);

        ShaderRuntime_::setVec3(shader, "iChannelResolution[0]", texture_resolution_or_viewport(material, channel_0, viewport_size));
        ShaderRuntime_::setVec3(shader, "iChannelResolution[1]", texture_resolution_or_viewport(material, channel_1, viewport_size));
        ShaderRuntime_::setVec3(shader, "iChannelResolution[2]", texture_resolution_or_viewport(material, channel_0, viewport_size));
        ShaderRuntime_::setVec3(shader, "iChannelResolution[3]", texture_resolution_or_viewport(material, channel_1, viewport_size));

        ShaderRuntime_::setFloat(shader, "iChannelTime[0]", time);
        ShaderRuntime_::setFloat(shader, "iChannelTime[1]", time);
        ShaderRuntime_::setFloat(shader, "iChannelTime[2]", time);
        ShaderRuntime_::setFloat(shader, "iChannelTime[3]", time);

        ShaderRuntime_::setMat4(shader, "model", model);
        ShaderRuntime_::setMat4(shader, "view", view);
        ShaderRuntime_::setMat4(shader, "projection", projection);

        ShaderRuntime_::setVec3(shader, "uColor", random_color);
        ShaderRuntime_::setFloat(shader, "time", time);
        ShaderRuntime_::setFloat(shader, "uTime", time);
        ShaderRuntime_::setFloat(shader, "iTime", time);
        ShaderRuntime_::setFloat(shader, "uDeltaTime", delta_time);
        ShaderRuntime_::setFloat(shader, "iTimeDelta", delta_time);
        ShaderRuntime_::setInt(shader, "uFrame", frame_index);
        ShaderRuntime_::setInt(shader, "iFrame", frame_index);
        ShaderRuntime_::setVec2(shader, "uResolution", viewport_size);
        ShaderRuntime_::setVec2(shader, "uViewportSize", viewport_size);
        ShaderRuntime_::setVec2(shader, "uSurfaceResolution", editable_surface_resolution());
        ShaderRuntime_::setVec3(shader, "iResolution", glm::vec3(viewport_size, 1.0f));
        ShaderRuntime_::setVec4(shader, "iMouse", glm::vec4(0.0f));
        ShaderRuntime_::setVec3(shader, "uCamPos", camera_position);
        ShaderRuntime_::setVec3(shader, "uPlayerPos", camera_position);
        ShaderRuntime_::setVec3(shader, "iPlayerPos", camera_position);
        ShaderRuntime_::setInt(shader, "uTextureCount", texture_count);
    }

    void init(DrawCommandsSingleMaterial& drawcommands)
    {
        auto f_fix_vertices_positions = [](std::vector<float>& vertices)
        {
            for (int i = 0; i < static_cast<int>(vertices.size()) / 5; i++)
            {
                vertices[i * 5 + 0] += 0.5f;
                vertices[i * 5 + 1] += 0.5f;
                vertices[i * 5 + 2] += 0.5f;
            }
        };

        {
            std::vector<float> vertices = CubeGeometryBuilder::generateAll();
            f_fix_vertices_positions(vertices);
            Mesh_::init(drawcommands.mesh_full_positions, vertices);
        }

        {
            std::vector<float> vertices = CubeGeometryBuilder::generate(CubeGeometryBuilder::CubeFace::Top);
            f_fix_vertices_positions(vertices);
            Mesh_::init(drawcommands.mesh_top_positions, vertices);
        }

        {
            std::vector<float> vertices = CubeGeometryBuilder::generate(CubeGeometryBuilder::CubeFace::Bottom);
            f_fix_vertices_positions(vertices);
            Mesh_::init(drawcommands.mesh_bottom_positions, vertices);
        }

        {
            std::vector<float> vertices = CubeGeometryBuilder::generate(CubeGeometryBuilder::CubeFace::Front);
            f_fix_vertices_positions(vertices);
            Mesh_::init(drawcommands.mesh_front_positions, vertices);
        }

        {
            std::vector<float> vertices = CubeGeometryBuilder::generate(CubeGeometryBuilder::CubeFace::Back);
            f_fix_vertices_positions(vertices);
            Mesh_::init(drawcommands.mesh_back_positions, vertices);
        }

        {
            std::vector<float> vertices = CubeGeometryBuilder::generate(CubeGeometryBuilder::CubeFace::Left);
            f_fix_vertices_positions(vertices);
            Mesh_::init(drawcommands.mesh_left_positions, vertices);
        }

        {
            std::vector<float> vertices = CubeGeometryBuilder::generate(CubeGeometryBuilder::CubeFace::Right);
            f_fix_vertices_positions(vertices);
            Mesh_::init(drawcommands.mesh_right_positions, vertices);
        }
    }

    void draw
    (
        DrawCommandsSingleMaterial& drawcommands,
        const glm::mat4& model,
        const glm::mat4& view,
        const glm::mat4& projection,
        float time,
        float delta_time,
        int frame_index,
        const glm::vec2& viewport_size,
        const glm::vec3& camera_position
    )
    {
        if (Global_constants_::use_runtime_generated_shaders_without_writing_files)
        {
            if (drawcommands.material.shader_runtime != nullptr)
            {
                ShaderRuntime_::use(*drawcommands.material.shader_runtime);
                bind_shared_uniforms_runtime
                (
                    *drawcommands.material.shader_runtime,
                    drawcommands.material,
                    model,
                    view,
                    projection,
                    time,
                    delta_time,
                    frame_index,
                    viewport_size,
                    camera_position
                );

                Mesh_::draw_mesh_instances_runtime_shader(drawcommands.mesh_full_positions, *drawcommands.material.shader_runtime, drawcommands.cube_full_positions, 1.0f);
                Mesh_::draw_mesh_instances_runtime_shader(drawcommands.mesh_top_positions, *drawcommands.material.shader_runtime, drawcommands.cube_top_positions, 1.0f);
                Mesh_::draw_mesh_instances_runtime_shader(drawcommands.mesh_bottom_positions, *drawcommands.material.shader_runtime, drawcommands.cube_bottom_positions, 1.0f);
                Mesh_::draw_mesh_instances_runtime_shader(drawcommands.mesh_front_positions, *drawcommands.material.shader_runtime, drawcommands.cube_front_positions, 1.0f);
                Mesh_::draw_mesh_instances_runtime_shader(drawcommands.mesh_back_positions, *drawcommands.material.shader_runtime, drawcommands.cube_back_positions, 1.0f);
                Mesh_::draw_mesh_instances_runtime_shader(drawcommands.mesh_left_positions, *drawcommands.material.shader_runtime, drawcommands.cube_left_positions, 1.0f);
                Mesh_::draw_mesh_instances_runtime_shader(drawcommands.mesh_right_positions, *drawcommands.material.shader_runtime, drawcommands.cube_right_positions, 1.0f);
            }
        }
        else
        {
            if (drawcommands.material.shader != nullptr)
            {
                ShaderHot_::use(*drawcommands.material.shader);
                bind_shared_uniforms_hot
                (
                    *drawcommands.material.shader,
                    drawcommands.material,
                    model,
                    view,
                    projection,
                    time,
                    delta_time,
                    frame_index,
                    viewport_size,
                    camera_position
                );

                Mesh_::draw_mesh_instances(drawcommands.mesh_full_positions, *drawcommands.material.shader, drawcommands.cube_full_positions, 1.0f);
                Mesh_::draw_mesh_instances(drawcommands.mesh_top_positions, *drawcommands.material.shader, drawcommands.cube_top_positions, 1.0f);
                Mesh_::draw_mesh_instances(drawcommands.mesh_bottom_positions, *drawcommands.material.shader, drawcommands.cube_bottom_positions, 1.0f);
                Mesh_::draw_mesh_instances(drawcommands.mesh_front_positions, *drawcommands.material.shader, drawcommands.cube_front_positions, 1.0f);
                Mesh_::draw_mesh_instances(drawcommands.mesh_back_positions, *drawcommands.material.shader, drawcommands.cube_back_positions, 1.0f);
                Mesh_::draw_mesh_instances(drawcommands.mesh_left_positions, *drawcommands.material.shader, drawcommands.cube_left_positions, 1.0f);
                Mesh_::draw_mesh_instances(drawcommands.mesh_right_positions, *drawcommands.material.shader, drawcommands.cube_right_positions, 1.0f);
            }
        }
    }

    void free(DrawCommandsSingleMaterial& drawcommands)
    {
        delete drawcommands.material.shader;
    }
}
