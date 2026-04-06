#pragma once

#include "Global_constants.h"
#include "EditableShaders.h"

#include <iostream>

namespace Enviroment_
{
    struct Cubes
    {
        struct Cube
        {
            enum class ElementType
            {
                wall,
                room,
                corridor,
                empty
            };

            ElementType type;

            int material_id_top;
            int material_id_bottom;
            int material_id_front;
            int material_id_back;
            int material_id_left;
            int material_id_right;
        };

    public:
        Cubes() :
            data(grid_size_x * grid_size_y * grid_size_z)
        {
        }

        Cube* get_cube(int x, int y, int z)
        {
            if (valid_index(x, y, z))
            {
                return &data[calculate_index(x, y, z)];
            }

            return nullptr;
        }

        bool valid_index(int x, int y, int z) const
        {
            if (x < 0 || y < 0 || z < 0)
            {
                return false;
            }

            if (x >= grid_size_x || y >= grid_size_y || z >= grid_size_z)
            {
                return false;
            }

            return true;
        }

        int number_of_cubes()
        {
            return grid_size_x * grid_size_y * grid_size_z;
        }

        void loop(const std::function<void(Cube* cube, int x, int y, int z)>& f)
        {
            const int X = grid_size_x;
            const int Y = grid_size_y;
            const int layer = X * Y;

            for (int z = 0; z < grid_size_z; ++z)
            {
                const int baseZ = z * layer;
                for (int y = 0; y < Y; ++y)
                {
                    const int baseYZ = baseZ + y * X;
                    for (int x = 0; x < X; ++x)
                    {
                        const int idx = baseYZ + x;
                        f(&data[idx], x, y, z);
                    }
                }
            }
        }

    private:
        std::vector<Cube> data;

        int calculate_index(int x, int y, int z) const
        {
            return
                (grid_size_x * grid_size_y) * z +
                (grid_size_x * y) +
                x;
        }

        static constexpr int grid_size_x = 66;
        static constexpr int grid_size_y = 11;
        static constexpr int grid_size_z = 66;
    };

    struct Enviroment
    {
        Cubes cubes;
        Materials materials;
    };

    inline std::vector<Texture_::Texture> create_default_material_textures()
    {
        std::vector<Texture_::Texture> textures;

        {
            const int texture_unit = 0;
            Texture_::Texture texture;
            Texture_::create(texture, texture_unit);
            Texture_::create_procedural(texture, 32, 32, [](float u, float v)
            {
                uint8_t r = static_cast<uint8_t>(255 * u);
                uint8_t g = static_cast<uint8_t>(255 * u);
                uint8_t b = static_cast<uint8_t>(255 * u);
                uint8_t a = 255;
                return RGBA(r, g, b, a);
            });
            textures.push_back(texture);
        }

        {
            const int texture_unit = 1;
            Texture_::Texture texture;
            Texture_::create(texture, texture_unit);
            Texture_::create_procedural(texture, 32, 32, [](float u, float v)
            {
                uint8_t r = static_cast<uint8_t>(255 * u);
                uint8_t g = static_cast<uint8_t>(255 * v);
                uint8_t b = static_cast<uint8_t>(255 * (1.0f - u));
                uint8_t a = 255;
                return RGBA(r, g, b, a);
            });
            textures.push_back(texture);
        }

        return textures;
    }

    struct EditableMaterialPool
    {
        std::vector<int> raymarching_material_ids;
        std::vector<int> shadertoy_material_ids;
    };

    inline EditableMaterialPool build_editable_material_pool(Materials& materials)
    {
        EditableShaders_::ensure_editable_shader_files();

        const std::string vertex_shader_path = EditableShaders_::default_vertex_shader_path();
        const EditableShaders_::EditableShaderSettings& editable_shader_settings = EditableShaders_::settings();
        const EditableShaders_::ShaderDiscoveryResult shader_discovery = EditableShaders_::discover_fragment_shader_entries();

        EditableMaterialPool material_pool;
        material_pool.raymarching_material_ids.reserve(shader_discovery.raymarching.size());
        material_pool.shadertoy_material_ids.reserve(shader_discovery.shadertoy.size());

        for (const EditableShaders_::ShaderFileEntry& shader_entry : shader_discovery.all)
        {
            std::vector<Texture_::Texture> textures = create_default_material_textures();
            const int material_id = Materials_::create_material(materials, vertex_shader_path, shader_entry.filepath, textures);
            Materials::Material& material = materials.list.back();

            if (material.shader == nullptr || material.shader->ID == 0)
            {
                for (Texture_::Texture& texture : material.textures)
                {
                    Texture_::free(texture);
                }

                delete material.shader;
                materials.list.pop_back();
                std::cout << "[EditableShaders] Skipped " << shader_entry.filepath << " because it failed to compile.\n";
                continue;
            }

            if (shader_entry.family == EditableShaders_::ShaderFamily::shadertoy)
            {
                material_pool.shadertoy_material_ids.push_back(material_id);
            }
            else
            {
                material_pool.raymarching_material_ids.push_back(material_id);
            }

            if (editable_shader_settings.startup.print_shader_summary)
            {
                std::cout
                    << "[EditableShaders] Loaded "
                    << EditableShaders_::shader_family_name(shader_entry.family)
                    << " shader: "
                    << shader_entry.filepath
                    << "\n";
            }
        }

        const size_t total_loaded_materials =
            material_pool.raymarching_material_ids.size() +
            material_pool.shadertoy_material_ids.size();

        if (total_loaded_materials == 0)
        {
            std::cout << "[EditableShaders] No editable shaders were found.\n";
        }
        else
        {
            std::cout
                << "[EditableShaders] Material mix weights -> raymarching: "
                << editable_shader_settings.shader_mix.raymarching_weight
                << ", shadertoy: "
                << editable_shader_settings.shader_mix.shadertoy_weight
                << "\n";

            std::cout
                << "[EditableShaders] Shader caps -> raymarching: "
                << EditableShaders_::shader_limit_label(editable_shader_settings.shader_mix.max_raymarching_shaders)
                << ", shadertoy: "
                << EditableShaders_::shader_limit_label(editable_shader_settings.shader_mix.max_shadertoy_shaders)
                << "\n";

            std::cout
                << "[EditableShaders] Loaded "
                << material_pool.raymarching_material_ids.size()
                << " raymarching shaders";

            if (shader_discovery.raymarching_found != material_pool.raymarching_material_ids.size())
            {
                std::cout << " (from " << shader_discovery.raymarching_found << " found)";
            }

            std::cout
                << " and "
                << material_pool.shadertoy_material_ids.size()
                << " shadertoy shaders";

            if (shader_discovery.shadertoy_found != material_pool.shadertoy_material_ids.size())
            {
                std::cout << " (from " << shader_discovery.shadertoy_found << " found)";
            }

            std::cout << ".\n";
        }

        return material_pool;
    }

    struct Room
    {
        int index = -1;
        std::vector<int> raymarching_material_ids;
        std::vector<int> shadertoy_material_ids;
        double raymarching_weight = 0.70;
        double shadertoy_weight = 0.30;

        Room
        (
            int index,
            const EditableMaterialPool& material_pool,
            const EditableShaders_::EditableShaderSettings& editable_shader_settings
        )
        {
            this->index = index;
            this->raymarching_material_ids = material_pool.raymarching_material_ids;
            this->shadertoy_material_ids = material_pool.shadertoy_material_ids;
            this->raymarching_weight = editable_shader_settings.shader_mix.raymarching_weight;
            this->shadertoy_weight = editable_shader_settings.shader_mix.shadertoy_weight;
        }

        int get_material(int x, int y, int z)
        {
            (void)x;
            (void)y;
            (void)z;

            const bool has_raymarching = !raymarching_material_ids.empty();
            const bool has_shadertoy = !shadertoy_material_ids.empty();

            if (!has_raymarching && !has_shadertoy)
            {
                return 0;
            }

            if (has_raymarching && !has_shadertoy)
            {
                return Random::random_element(raymarching_material_ids);
            }

            if (!has_raymarching && has_shadertoy)
            {
                return Random::random_element(shadertoy_material_ids);
            }

            const float safe_raymarching_weight =
                (raymarching_weight > 0.0) ? static_cast<float>(raymarching_weight) : 0.0f;

            const float safe_shadertoy_weight =
                (shadertoy_weight > 0.0) ? static_cast<float>(shadertoy_weight) : 0.0f;

            const float total_weight = safe_raymarching_weight + safe_shadertoy_weight;
            if (total_weight <= 0.0f)
            {
                return Random::random_bool()
                    ? Random::random_element(raymarching_material_ids)
                    : Random::random_element(shadertoy_material_ids);
            }

            const float chosen_weight = Random::random_float(0.0f, total_weight);
            if (chosen_weight < safe_raymarching_weight)
            {
                return Random::random_element(raymarching_material_ids);
            }

            return Random::random_element(shadertoy_material_ids);
        }
    };

    namespace Cubes_
    {
        void add_cube_with_room(Cubes& cubes, int x, int y, int z, Cubes::Cube::ElementType element_type, Room& room)
        {
            Cubes::Cube* const cube = cubes.get_cube(x, y, z);
            if (cube == nullptr)
            {
                return;
            }

            cube->material_id_top = room.get_material(x, y, z);
            cube->material_id_bottom = room.get_material(x, y, z);
            cube->material_id_front = room.get_material(x, y, z);
            cube->material_id_back = room.get_material(x, y, z);
            cube->material_id_left = room.get_material(x, y, z);
            cube->material_id_right = room.get_material(x, y, z);
            cube->type = element_type;
        }
    }

    namespace Enviroment_
    {
        Enviroment generate_enviroment(Maze_::Maze maze)
        {
            Enviroment enviroment;
            const EditableShaders_::EditableShaderSettings& editable_shader_settings = EditableShaders_::settings();

            const EditableMaterialPool material_pool = build_editable_material_pool(enviroment.materials);

            Room room_0(0, material_pool, editable_shader_settings);
            Room room_1(1, material_pool, editable_shader_settings);
            Room room_2(2, material_pool, editable_shader_settings);
            Room room_3(3, material_pool, editable_shader_settings);

            enviroment.cubes.loop([](Cubes::Cube* cube, int x, int y, int z)
            {
                cube->type = Cubes::Cube::ElementType::empty;
            });

            for (int y = 0; y < maze.width; y++)
            {
                for (int x = 0; x < maze.height; x++)
                {
                    int room_index = 0;
                    {
                        int iy = 0;
                        if (y > maze.height / 2)
                        {
                            iy = 1;
                        }

                        int ix = 0;
                        if (x > maze.width / 2)
                        {
                            ix = 1;
                        }

                        room_index = iy * 2 + ix;
                    }

                    Room* active_room = nullptr;
                    {
                        if (room_index == 0)
                        {
                            active_room = &room_0;
                        }
                        else if (room_index == 1)
                        {
                            active_room = &room_1;
                        }
                        else if (room_index == 2)
                        {
                            active_room = &room_2;
                        }
                        else if (room_index == 3)
                        {
                            active_room = &room_3;
                        }

                        assert(active_room != nullptr);
                    }

                    if (Maze_::isWall(maze, x, y))
                    {
                        Cubes_::add_cube_with_room(enviroment.cubes, x, 1, y, Cubes::Cube::ElementType::wall, *active_room);
                    }
                    else
                    {
                        const int height_at_x_y = Maze_::height_at(maze, x, y);
                        Cubes_::add_cube_with_room(enviroment.cubes, x, 0, y, Cubes::Cube::ElementType::wall, *active_room);
                        Cubes_::add_cube_with_room(enviroment.cubes, x, height_at_x_y + 1, y, Cubes::Cube::ElementType::wall, *active_room);

                        {
                            const int height = Maze_::height_at(maze, x - 1, y);
                            if (height < height_at_x_y)
                            {
                                for (int i = height + 1; i <= height_at_x_y; i++)
                                {
                                    Cubes_::add_cube_with_room(enviroment.cubes, x - 1, i, y, Cubes::Cube::ElementType::wall, *active_room);
                                }
                            }
                        }

                        {
                            const int height = Maze_::height_at(maze, x + 1, y);
                            if (height < height_at_x_y)
                            {
                                for (int i = height + 1; i <= height_at_x_y; i++)
                                {
                                    Cubes_::add_cube_with_room(enviroment.cubes, x + 1, i, y, Cubes::Cube::ElementType::wall, *active_room);
                                }
                            }
                        }

                        {
                            const int height = Maze_::height_at(maze, x, y + 1);
                            if (height < height_at_x_y)
                            {
                                for (int i = height + 1; i <= height_at_x_y; i++)
                                {
                                    Cubes_::add_cube_with_room(enviroment.cubes, x, i, y + 1, Cubes::Cube::ElementType::wall, *active_room);
                                }
                            }
                        }

                        {
                            const int height = Maze_::height_at(maze, x, y - 1);
                            if (height < height_at_x_y)
                            {
                                for (int i = height + 1; i <= height_at_x_y; i++)
                                {
                                    Cubes_::add_cube_with_room(enviroment.cubes, x, i, y - 1, Cubes::Cube::ElementType::wall, *active_room);
                                }
                            }
                        }
                    }
                }
            }

            return enviroment;
        }

        std::vector<DrawCommandsSingleMaterial_::DrawCommandsSingleMaterial> generate_draw_commands(Enviroment& enviroment)
        {
            std::vector<DrawCommandsSingleMaterial_::DrawCommandsSingleMaterial> drawcommands;

            for (int index_material = 0; index_material < static_cast<int>(enviroment.materials.list.size()); index_material++)
            {
                DrawCommandsSingleMaterial_::DrawCommandsSingleMaterial drawcommands_single_material;
                drawcommands_single_material.material = enviroment.materials.list[index_material];

                auto f_loop = [&](Cubes::Cube* cube, int x, int y, int z)
                {
                    const glm::vec3 position_cube = glm::vec3(x, y - 1, z);

                    assert(cube != nullptr);

                    if (cube->type == Cubes::Cube::ElementType::wall)
                    {
                        if (index_material == cube->material_id_top)
                        {
                            bool need_wall_on_top = true;
                            {
                                Cubes::Cube* cube_above = enviroment.cubes.get_cube(x, y + 1, z);
                                if (cube_above != nullptr && cube_above->type == Cubes::Cube::ElementType::wall)
                                {
                                    need_wall_on_top = false;
                                }
                            }

                            if (need_wall_on_top)
                            {
                                drawcommands_single_material.cube_top_positions.push_back(position_cube);
                            }
                        }

                        if (index_material == cube->material_id_bottom)
                        {
                            bool need_wall_on_bottom = true;
                            {
                                Cubes::Cube* cube_below = enviroment.cubes.get_cube(x, y - 1, z);
                                if (cube_below != nullptr && cube_below->type == Cubes::Cube::ElementType::wall)
                                {
                                    need_wall_on_bottom = false;
                                }
                            }

                            if (y == 0)
                            {
                                need_wall_on_bottom = false;
                            }

                            if (need_wall_on_bottom)
                            {
                                drawcommands_single_material.cube_bottom_positions.push_back(position_cube);
                            }
                        }

                        if (index_material == cube->material_id_front)
                        {
                            bool needs_wall_on_front = true;
                            {
                                Cubes::Cube* cube_front = enviroment.cubes.get_cube(x, y, z + 1);
                                if (cube_front != nullptr && cube_front->type == Cubes::Cube::ElementType::wall)
                                {
                                    needs_wall_on_front = false;
                                }
                            }

                            if (needs_wall_on_front)
                            {
                                drawcommands_single_material.cube_front_positions.push_back(position_cube);
                            }
                        }

                        if (index_material == cube->material_id_back)
                        {
                            bool needs_wall_on_back = true;
                            {
                                Cubes::Cube* cube_back = enviroment.cubes.get_cube(x, y, z - 1);
                                if (cube_back != nullptr && cube_back->type == Cubes::Cube::ElementType::wall)
                                {
                                    needs_wall_on_back = false;
                                }
                            }

                            if (needs_wall_on_back)
                            {
                                drawcommands_single_material.cube_back_positions.push_back(position_cube);
                            }
                        }

                        if (index_material == cube->material_id_left)
                        {
                            bool needs_wall_on_left = true;
                            {
                                Cubes::Cube* cube_left = enviroment.cubes.get_cube(x - 1, y, z);
                                if (cube_left != nullptr && cube_left->type == Cubes::Cube::ElementType::wall)
                                {
                                    needs_wall_on_left = false;
                                }
                            }

                            if (needs_wall_on_left)
                            {
                                drawcommands_single_material.cube_left_positions.push_back(position_cube);
                            }
                        }

                        if (index_material == cube->material_id_right)
                        {
                            bool needs_wall_on_right = true;
                            {
                                Cubes::Cube* cube_right = enviroment.cubes.get_cube(x + 1, y, z);
                                if (cube_right != nullptr && cube_right->type == Cubes::Cube::ElementType::wall)
                                {
                                    needs_wall_on_right = false;
                                }
                            }

                            if (needs_wall_on_right)
                            {
                                drawcommands_single_material.cube_right_positions.push_back(position_cube);
                            }
                        }
                    }
                };

                enviroment.cubes.loop(f_loop);
                DrawCommandsSingleMaterial_::init(drawcommands_single_material);
                drawcommands.push_back(drawcommands_single_material);
            }

            return drawcommands;
        }
    }
}
