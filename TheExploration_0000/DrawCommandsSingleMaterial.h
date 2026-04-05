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
            // (no EBO for now)

            GLsizei vertexCount;
        };

        // initialize from raw vertex data (interleaved floats)
        void init(Mesh& mesh, const std::vector<float>& vertices)
        {
            // 1) how many floats per vertex? (e.g. vec3 pos + vec2 uv = 5)
            constexpr GLsizei floats_per_vertex = 5;

            mesh.vertexCount = static_cast<GLsizei>(vertices.size() / floats_per_vertex);
            const GLsizei stride = floats_per_vertex * sizeof(float); // size in bytes

            GL_::VAO_::init(mesh.vao);
            GL_::VBO_::init
            (
                mesh.vbo,
                vertices.size() * sizeof(float),
                vertices.data()
            );

            GL_::VAO_::bind(mesh.vao);
            GL_::VBO_::bind(mesh.vbo);

            // position attribute (location=0, 3 floats at offset 0)
            GL_::VAO_::linkAttrib(
                /*index=*/0,
                /*size=*/3,
                /*type=*/GL_FLOAT,
                /*stride=*/stride,
                /*offset=*/(void*)0
            );

            // tex-coord attribute (location=1, 2 floats at offset 3*sizeof(float))
            GL_::VAO_::linkAttrib(
                /*index=*/1,
                /*size=*/2,
                /*type=*/GL_FLOAT,
                /*stride=*/stride,
                /*offset=*/(void*)(3 * sizeof(float))
            );

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
            // use shader
            // bind mesh
            // loop
            //  send model matrix to shader
            //  draw model
            // unbind mesh

            // shader.use();
            ShaderHot_::use(shader);
            GL_::VAO_::bind(mesh.vao);

            for (int i = 0; i < positions.size(); i++)
            {
                glm::mat4 model = glm::mat3(1.0f);
                model = glm::translate(model, positions[i] * scale);
                model = glm::scale(model, glm::vec3(scale));
                // shader.setMat4("model", model);
                ShaderHot_::setMat4(shader, "model", model);

                ShaderHot_::setVec3(shader, "uCubePos", positions[i]);

                glDrawArrays(GL_TRIANGLES, 0, mesh.vertexCount);
            }
            GL_::VAO_::unbind();
        }

        void draw_mesh_instances_runtime_shader(const Mesh& mesh, const ShaderRuntime& shader, const std::vector<glm::vec3>& positions, const float scale)
        {
            // use shader
            // bind mesh
            // loop
            //  send model matrix to shader
            //  draw model
            // unbind mesh

            // shader.use();
            ShaderRuntime_::use(shader);
            GL_::VAO_::bind(mesh.vao);

            for (int i = 0; i < positions.size(); i++)
            {
                glm::mat4 model = glm::mat3(1.0f);
                model = glm::translate(model, positions[i] * scale);
                model = glm::scale(model, glm::vec3(scale));
                // shader.setMat4("model", model);
                ShaderRuntime_::setMat4(shader, "model", model);

                ShaderRuntime_::setVec3(shader, "uCubePos", positions[i]);

                glDrawArrays(GL_TRIANGLES, 0, mesh.vertexCount);
            }
            GL_::VAO_::unbind();
        }

        // Draw this mesh once per entry in 'sides', setting a "model" mat4 each time
        inline void drawInstanced
        (
            const Mesh& mesh,
            ShaderHot_::ShaderHot& shader,
            std::function<bool(float&, float&, float&)> f,
            float scale
        )
        {
            // Make sure the shader is bound
            // shader.use();
            ShaderHot_::use(shader);

            // Bind our VAO/vertex-data
            GL_::VAO_::bind(mesh.vao);

            // Loop over each cube-side, build its model matrix, pass it and draw

            float x, y, z;
            while (f(x, y, z))
            {
                // 1) start from identity
                glm::mat4 model = glm::mat4(1.0f);

                // 2) translate to the instance position, then scale
                glm::vec3 pos = glm::vec3(
                    x,
                    y,
                    z
                );
                model = glm::translate(model, pos * scale);
                model = glm::scale(model, glm::vec3(scale));

                // 3) optional per-instance rotation
                // float angle = 20.0f * static_cast<float>(i);
                /*
                float angle = 0.0;

                model = glm::rotate(
                    model,
                    glm::radians(angle),
                    glm::vec3(1.0f, 0.3f, 0.5f)
                );
                */

                // 4) upload the model matrix
                // shader.setMat4("model", model);
                ShaderHot_::setMat4(shader, "model", model);

                // 5) draw that one cube (using your mesh.vertexCount)
                glDrawArrays(GL_TRIANGLES, 0, mesh.vertexCount);
            }

            // unbind to restore clean state
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


    void init(DrawCommandsSingleMaterial& drawcommands)
    {
        // init mesh
        {
            auto f_fix_vertices_positions = [](std::vector<float>& vertices)
                {
                    for (int i = 0; i < vertices.size() / 5; i++)
                    {
                        vertices[i * 5 + 0] += 0.5;
                        vertices[i * 5 + 1] += 0.5;
                        vertices[i * 5 + 2] += 0.5;
                    };
                };

            // init mesh for full positions
            {
                std::vector<float> vertices = CubeGeometryBuilder::generateAll();
                f_fix_vertices_positions(vertices);


                Mesh_::init(drawcommands.mesh_full_positions, vertices);
            }

            // init mesh for top positions
            {
                std::vector<float> vertices = CubeGeometryBuilder::generate(CubeGeometryBuilder::CubeFace::Top);
                f_fix_vertices_positions(vertices);

                Mesh_::init(drawcommands.mesh_top_positions, vertices);
            }

            // init mesh for bottom positions
            {
                std::vector<float> vertices = CubeGeometryBuilder::generate(CubeGeometryBuilder::CubeFace::Bottom);
                f_fix_vertices_positions(vertices);

                Mesh_::init(drawcommands.mesh_bottom_positions, vertices);
            }

            // init mesh for front positions
            {
                std::vector<float> vertices = CubeGeometryBuilder::generate(CubeGeometryBuilder::CubeFace::Front);
                f_fix_vertices_positions(vertices);

                Mesh_::init(drawcommands.mesh_front_positions, vertices);
            }

            // init mesh for back positions
            {
                std::vector<float> vertices = CubeGeometryBuilder::generate(CubeGeometryBuilder::CubeFace::Back);
                f_fix_vertices_positions(vertices);

                Mesh_::init(drawcommands.mesh_back_positions, vertices);
            }

            // init mesh for left positions
            {
                std::vector<float> vertices = CubeGeometryBuilder::generate(CubeGeometryBuilder::CubeFace::Left);
                f_fix_vertices_positions(vertices);

                Mesh_::init(drawcommands.mesh_left_positions, vertices);
            }

            // init mesh for right positions
            {
                std::vector<float> vertices = CubeGeometryBuilder::generate(CubeGeometryBuilder::CubeFace::Right);
                f_fix_vertices_positions(vertices);

                Mesh_::init(drawcommands.mesh_right_positions, vertices);
            }
        }


    }

    void draw(DrawCommandsSingleMaterial& drawcommands, glm::mat4 model, glm::mat4 view, glm::mat4 projection, float time, glm::vec3 camera_position)
    {
        // assert( (drawcommands.material.shader == nullptr) || (drawcommands.material.shader_runtime == nullptr) ); 
        // assert( (drawcommands.material.shader != nullptr) || (drawcommands.material.shader_runtime != nullptr) );

        

        // Shader hot drawing
        if (Global_constants_::use_runtime_generated_shaders_without_writing_files)
        {
            if (drawcommands.material.shader_runtime != nullptr)
            {

                ShaderRuntime_::use(*drawcommands.material.shader_runtime);

                for (int i = 0; i < drawcommands.material.textures.size(); i++)
                {

                    Texture_::bind(drawcommands.material.textures[i]);
                    std::string uniformName = "texture" + std::to_string(i + 1); // i+1 if your GLSL has texture1, texture2...
                    ShaderRuntime_::setInt(*drawcommands.material.shader_runtime, uniformName, i);
                }


                ShaderRuntime_::setMat4(*drawcommands.material.shader_runtime, "model", model);
                ShaderRuntime_::setMat4(*drawcommands.material.shader_runtime, "view", view);
                ShaderRuntime_::setMat4(*drawcommands.material.shader_runtime, "projection", projection);
                ShaderRuntime_::setVec3(*drawcommands.material.shader_runtime, "uColor", glm::vec3(Random::generate_random_float_0_to_1(), Random::generate_random_float_0_to_1(), Random::generate_random_float_0_to_1()));
                ShaderRuntime_::setFloat(*drawcommands.material.shader_runtime, "time", time);
                ShaderRuntime_::setVec3(*drawcommands.material.shader_runtime, "uCamPos", camera_position);

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

                for (int i = 0; i < drawcommands.material.textures.size(); i++)
                {

                    Texture_::bind(drawcommands.material.textures[i]);
                    std::string uniformName = "texture" + std::to_string(i + 1); // i+1 if your GLSL has texture1, texture2...
                    ShaderHot_::setInt(*drawcommands.material.shader, uniformName, i);
                }


                ShaderHot_::setMat4(*drawcommands.material.shader, "model", model);
                ShaderHot_::setMat4(*drawcommands.material.shader, "view", view);
                ShaderHot_::setMat4(*drawcommands.material.shader, "projection", projection);
                ShaderHot_::setVec3(*drawcommands.material.shader, "uColor", glm::vec3(Random::generate_random_float_0_to_1(), Random::generate_random_float_0_to_1(), Random::generate_random_float_0_to_1()));
                ShaderHot_::setFloat(*drawcommands.material.shader, "time", time);
                ShaderHot_::setVec3(*drawcommands.material.shader, "uCamPos", camera_position);


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
