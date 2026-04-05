#pragma once

#include "Global_constants.h"

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

            // int material_id;

            int material_id_top;
            int material_id_bottom;
            int material_id_front;
            int material_id_back;
            int material_id_left;
            int material_id_right;
        };

    public:
        Cubes() :
            data(grid_size_x* grid_size_y* grid_size_z)
        {
        }

        Cube* get_cube(int x, int y, int z)
        {
            if (valid_index(x, y, z))
            {
                return &data[calculate_index(x, y, z)];
            }
            else
            {
                return nullptr;
            }
        }

        bool valid_index(int x, int y, int z) const
        {
            if (x < 0)
            {
                return false;
            }

            if (y < 0)
            {
                return false;
            }

            if (z < 0)
            {
                return false;
            }

            if (x >= grid_size_x)
            {
                return false;
            }

            if (y >= grid_size_y)
            {
                return false;
            }

            if (z >= grid_size_z)
            {
                return false;
            }

            return true;
        }


        int number_of_cubes()
        {
            return grid_size_x * grid_size_y * grid_size_z;
        }

        // call f(cube_ptr, x, y, z) for every cube in order
        void loop(const std::function<void(Cube* cube, int x, int y, int z)>& f)
        {
            int X = grid_size_x;
            int Y = grid_size_y;
            int layer = X * Y;

            for (int z = 0; z < grid_size_z; ++z) {
                int baseZ = z * layer;
                for (int y = 0; y < Y; ++y) {
                    int baseYZ = baseZ + y * X;
                    for (int x = 0; x < X; ++x) {
                        int idx = baseYZ + x;
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
        Cubes  cubes;
        Materials materials;
    };

    struct Room
    {
        std::vector<int> materials_index_0;
        std::vector<int> materials_index_1;
        std::vector<int> materials_index_2;
        std::vector<int> materials_index_3;

        int index = -1;

        int material_id = -1;

        Room(int index, Materials& materials)
        {
            this->index = index;
            const int max_materials_per_room = 10;
            
            bool use_for_all_material_the_example_glsl = false;

            auto f_generate_material =  [&](std::vector<int>& materials_index_n, const std::string& fregment_shader_filepath)
            {
                    std::vector< Texture_::Texture> textures;

                    {

                        {
                            int texture_unit = 0;
                            Texture_::Texture texture;
                            Texture_::create(texture, texture_unit);
                            Texture_::create_procedural(texture, 32, 32, [](float u, float v) {
                                uint8_t r = 255 * u;
                                uint8_t g = 255 * u;
                                uint8_t b = 255 * u;
                                uint8_t a = 255;
                                return RGBA(r, g, b, a);
                                });
                            textures.push_back(texture);
                        }

                        {
                            int texture_unit = 1;
                            Texture_::Texture texture;
                            Texture_::create(texture, texture_unit);
                            Texture_::create_procedural(texture, 32, 32, [](float u, float v) {
                                uint8_t r = 255 * u;
                                uint8_t g = 255 * u;
                                uint8_t b = 255 * u;
                                uint8_t a = 255;
                                return RGBA(r, g, b, a);
                                });
                            textures.push_back(texture);
                        }
                    }

                    {
                        const char* vertex_shader_path = "generated_shaders/vertex_shader_exploring_0000.glsl";
                        std::string fragment_shader_path_example_glsl = "generated_shaders/example.glsl";

                        int material_id = Materials_::create_material(materials, vertex_shader_path, fregment_shader_filepath, textures);
                        materials_index_n.push_back(material_id);
                    }
                    
            };

            auto f_generate_material_with_runtime_shader = [&](std::vector<int>& materials_index_n)
                {
                    std::vector< Texture_::Texture> textures;

                    {

                        {
                            int texture_unit = 0;
                            Texture_::Texture texture;
                            Texture_::create(texture, texture_unit);
                            Texture_::create_procedural(texture, 32, 32, [](float u, float v) {
                                uint8_t r = 255 * u;
                                uint8_t g = 255 * u;
                                uint8_t b = 255 * u;
                                uint8_t a = 255;
                                return RGBA(r, g, b, a);
                                });
                            textures.push_back(texture);
                        }

                        {
                            int texture_unit = 1;
                            Texture_::Texture texture;
                            Texture_::create(texture, texture_unit);
                            Texture_::create_procedural(texture, 32, 32, [](float u, float v) {
                                uint8_t r = 255 * u;
                                uint8_t g = 255 * u;
                                uint8_t b = 255 * u;
                                uint8_t a = 255;
                                return RGBA(r, g, b, a);
                                });
                            textures.push_back(texture);
                        }
                    }

                    {
                        // int material_id = Materials_::create_material(materials, vertex_shader_path, fregment_shader_filepath, textures);
                        ShaderRuntime* shader_runtime = GenerateShaders_::generate_shader();
                        int material_id = Materials_::create_material_runtime(materials, shader_runtime, textures);
                        materials_index_n.push_back(material_id);
                    }

                };

            if (index == 0)
            {
                
                if (Global_constants_::use_runtime_generated_shaders_without_writing_files)
                {
                    for (int i = 0; i < max_materials_per_room; i++)
                    {
                        f_generate_material_with_runtime_shader(materials_index_0);
                    }
                }
                else
                {
                    std::vector<std::string> filepaths = Folder::getFilePathsInFolder("generated_shaders/room_0");
                    for (int i = 0; i < std::min<int>(filepaths.size(), max_materials_per_room); i++)
                    {
                        f_generate_material(materials_index_0, filepaths[i]);
                    }
                }
                
            }
            else if (index == 1)
            {
                if (Global_constants_::use_runtime_generated_shaders_without_writing_files)
                {
                    for (int i = 0; i < max_materials_per_room; i++)
                    {
                        f_generate_material_with_runtime_shader(materials_index_1);
                    }
                }
                else
                {
                    std::vector<std::string> filepaths = Folder::getFilePathsInFolder("generated_shaders/room_1");

                    for (int i = 0; i < std::min<int>(filepaths.size(), max_materials_per_room); i++)
                    {
                        f_generate_material(materials_index_1, filepaths[i]);
                    }
                }
            }
            else if (index == 2)
            {
               


                if (Global_constants_::use_runtime_generated_shaders_without_writing_files)
                {
                    for (int i = 0; i < max_materials_per_room; i++)
                    {
                        f_generate_material_with_runtime_shader(materials_index_2);
                    }
                }
                else
                {
                    std::vector<std::string> filepaths = Folder::getFilePathsInFolder("generated_shaders/room_2");
                    for (int i = 0; i < std::min<int>(filepaths.size(), max_materials_per_room); i++)
                    {
                        f_generate_material(materials_index_2, filepaths[i]);
                    }
                }
            }
            else if (index == 3)
            {
              

                if (Global_constants_::use_runtime_generated_shaders_without_writing_files)
                {
                    for (int i = 0; i < max_materials_per_room; i++)
                    {
                        f_generate_material_with_runtime_shader(materials_index_3);
                    }
                }
                else
                {
                    std::vector<std::string> filepaths = Folder::getFilePathsInFolder("generated_shaders/room_3");
                    for (int i = 0; i < max_materials_per_room; i++)
                    {
                        f_generate_material(materials_index_3, filepaths[i]);
                    }
                }
            }
        }

        int get_material(int x, int y, int z)
        {
            if (index == 0)
            {
                return Random::random_element(materials_index_0);
            }
            else if (index == 1)
            {
                return Random::random_element(materials_index_1);
            }
            else if (index == 2)
            {
                return Random::random_element(materials_index_2);
            }
            else if (index == 3)
            {
                return Random::random_element(materials_index_3);
            }

            return material_id;
        }


    };

    namespace Cubes_
    {
        void add_cube_with_room(Cubes& cubes, int x, int y, int z, Cubes::Cube::ElementType  element_type, Room& room)
        {
            Cubes::Cube* const cube = cubes.get_cube(x, y, z);

            // assert(cube == nullptr);

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


            Room room_0(0, enviroment.materials);
            Room room_1(1, enviroment.materials);
            Room room_2(2, enviroment.materials);
            Room room_3(3, enviroment.materials);

            enviroment.cubes.loop([](Cubes::Cube* cube, int x, int y, int z) { cube->type = Cubes::Cube::ElementType::empty; });

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
                        int height_at_x_y = Maze_::height_at(maze, x, y);
                        Cubes_::add_cube_with_room(enviroment.cubes, x, 0, y, Cubes::Cube::ElementType::wall, *active_room);
                        Cubes_::add_cube_with_room(enviroment.cubes, x, height_at_x_y + 1, y, Cubes::Cube::ElementType::wall, *active_room);


                        // hight x - 1, y
                        {
                            int height = Maze_::height_at(maze, x - 1, y);
                            if (height < height_at_x_y)
                            {
                                for (int i = height + 1; i <= height_at_x_y; i++)
                                {
                                    Cubes_::add_cube_with_room(enviroment.cubes, x - 1, i, y, Cubes::Cube::ElementType::wall, *active_room);
                                }
                            }
                        }

                        // hight x + 1, y
                        {
                            int height = Maze_::height_at(maze, x + 1, y);
                            if (height < height_at_x_y)
                            {
                                for (int i = height + 1; i <= height_at_x_y; i++)
                                {
                                    Cubes_::add_cube_with_room(enviroment.cubes, x + 1, i, y, Cubes::Cube::ElementType::wall, *active_room);
                                }
                            }
                        }

                        // hight x, y + 1
                        {
                            int height = Maze_::height_at(maze, x, y + 1);
                            if (height < height_at_x_y)
                            {
                                for (int i = height + 1; i <= height_at_x_y; i++)
                                {
                                    Cubes_::add_cube_with_room(enviroment.cubes, x, i, y + 1, Cubes::Cube::ElementType::wall, *active_room);
                                }
                            }
                        }

                        // hight x, y - 1
                        {
                            int height = Maze_::height_at(maze, x, y - 1);
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

            {

                for (int index_material = 0; index_material < enviroment.materials.list.size(); index_material++)
                {
                    DrawCommandsSingleMaterial_::DrawCommandsSingleMaterial drawcommands_single_material;
                    drawcommands_single_material.material = enviroment.materials.list[index_material];

                    auto f_loop = [&](Cubes::Cube* cube, int x, int y, int z)
                        {

                            const glm::vec position_cube = glm::vec3(x, y - 1, z);

                            assert(cube != nullptr);

                            if (cube->type == Cubes::Cube::ElementType::wall)
                            {
                                if (index_material == cube->material_id_top)
                                {
                                    bool need_wall_on_top = true;
                                    {
                                        Cubes::Cube* cube_ = enviroment.cubes.get_cube(x, y + 1, z);
                                        if (cube_ != nullptr)
                                        {
                                            if (cube_->type == Cubes::Cube::ElementType::wall)
                                            {
                                                need_wall_on_top = false;
                                            }
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
                                        Cubes::Cube* cube_ = enviroment.cubes.get_cube(x, y - 1, z);
                                        if (cube_ != nullptr && cube_->type == Cubes::Cube::ElementType::wall)
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
                                        Cubes::Cube* cube_ = enviroment.cubes.get_cube(x, y, z + 1);
                                        if (cube_ != nullptr && cube_->type == Cubes::Cube::ElementType::wall)
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
                                        Cubes::Cube* cube_ = enviroment.cubes.get_cube(x, y, z - 1);
                                        if (cube_ != nullptr && cube_->type == Cubes::Cube::ElementType::wall)
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
                                        Cubes::Cube* cube_ = enviroment.cubes.get_cube(x - 1, y, z); // we need to add 1 to y as we to conteract the offset at start
                                        if (cube_ != nullptr && cube_->type == Cubes::Cube::ElementType::wall)
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
                                        Cubes::Cube* cube_ = enviroment.cubes.get_cube(x + 1, y, z);
                                        if (cube_ != nullptr && cube_->type == Cubes::Cube::ElementType::wall)
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

            }


            return drawcommands;
        }
    }

}
