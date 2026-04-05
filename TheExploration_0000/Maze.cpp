#include "Maze.h"

#include <iostream>

#include "CppCommponents/ImageRGBA.h"
#include "ImageUtils.h"

#include "CppCommponents/Random.h"

#include "MazeGenerate.h"

namespace Maze_
{
    

    std::vector<std::vector<int>> get_layout_0000()
    {
        std::vector<std::vector<int>> layout =
        {
            { 0,0,0,0,0,0,0,0,0,0 },
            { 0,1,1,1,1,0,1,1,1,0 },
            { 0,1,0,0,1,0,1,0,1,0 },
            { 0,1,0,1,1,1,1,0,1,0 },
            { 0,1,0,1,0,0,1,0,1,0 },
            { 0,1,1,1,1,0,1,1,1,0 },
            { 0,1,0,0,1,0,0,0,1,0 },
            { 0,1,0,1,1,1,1,0,1,0 },
            { 0,1,1,1,1,1,1,1,1,0 },
            { 0,0,0,0,0,0,0,0,0,0 }
        };

        return layout;
    }

    std::vector<std::vector<int>> get_layout_0001()
    {
        std::vector<std::vector<int>> layout =
        {
        {0,0,0,0,0,0,0,0,0,0},
        {0,1,1,1,1,2,2,2,2,0},
        {0,1,1,1,1,2,2,2,2,0},
        {0,1,1,1,1,2,2,2,2,0},
        {0,1,1,1,1,2,2,2,2,0},
        {0,7,7,0,0,4,4,4,4,0},
        {0,7,7,0,1,4,4,4,4,0},
        {0,4,4,1,1,4,4,4,4,0},
        {0,2,2,1,1,4,4,4,4,0},
        {0,0,0,0,0,0,0,0,0,0}
        };

        return layout;
    }

    std::vector<std::vector<int>> get_layout_from_image()
    {

        

        // const char* file_path = "maze_generated/generate_1.png";

        ImageRGBA* image = MazeGenerate_::generate();

        // preprocessing step
        {
            ImageUtils_::map_color(image, { 0, 255, 0, 255 }, { 0, 0, 255, 255 });
            ImageUtils_::map_color(image, { 0, 0, 0, 255 }, { 255, 255, 255, 255 });
        }

        std::vector<std::vector<int>> local_layout;

        // generating layout from image
        {
            RGBA color_wall = RGBA(255, 255, 255, 255);
            RGBA color_building = RGBA(0, 255, 255, 255);
            RGBA color_corridors = RGBA(0, 0, 255, 255);

            int image_width = ImageRGBA_::get_width(*image);
            int image_height = ImageRGBA_::get_height(*image);

            // std::cout << "image_width : " << image_width << "\n";
            // std::cout << "image_height : " << image_height << "\n";

            int border_value = 0;

            // top border
            {
                std::vector<int> row;
                for (int y = 0; y <= image_height + 1; y++)
                {
                    row.push_back(border_value);
                }
                local_layout.push_back(std::move(row));
            }


            for (int y = 0; y < image_height; y++)
            {
                std::vector<int> row;


                row.push_back(border_value);

                for (int x = 0; x < image_width; x++)
                {
                    RGBA color = ImageRGBA_::get_pixel(*image, x, y);

                    if (ImageUtils_::equal(color, color_wall))
                    {
                        row.push_back(0);
                    }
                    else if (ImageUtils_::equal(color, color_corridors))
                    {
                        row.push_back(2);
                    }
                    else if (ImageUtils_::equal(color, color_building))
                    {
                        row.push_back(7);
                    }
                    else
                    {
                        row.push_back(1);
                    }
                }

                row.push_back(border_value);


                local_layout.push_back(std::move(row));
            }

            // bottom border
            {
                std::vector<int> row;
                for (int y = 0; y <= image_height + 1; y++)
                {
                    row.push_back(border_value);
                }
                local_layout.push_back(std::move(row));
            }

            // print layout
            if (false)
            {
                std::cout << "\n";
                for (int i = 0; i < local_layout.size(); i++)
                {
                    std::cout << "\n";
                    for (int j = 0; j < local_layout[i].size(); j++)
                    {
                        std::cout << local_layout[i][j] << " ";
                    }
                }
                std::cout << "\n";
            }


        }

        ImageRGBA_::free_image(image);






        // local_layout = get_layout_0001();

        return local_layout;
    }

    void init(Maze& maze)
    {
        maze.layout = get_layout_from_image();
        // layout = get_layout_0001();

        maze.width = maze.layout.size();
        maze.height = maze.layout[0].size();
    }

    int height_at(const Maze& maze, float x, float z)
    {
        // Convert continuous coordinates to maze grid indices
        int col = (int)std::floor(x);
        int row = (int)std::floor(z);
        // Outside the maze bounds is considered a wall to prevent leaving the area
        if (row < 0 || row >= maze.height || col < 0 || col >= maze.width) {
            return true;
        }
        // Return true if this grid cell is a wall
        return (maze.layout[row][col]);
    }

    bool isWall(const Maze& maze, float x, float z)
    {
        // Convert continuous coordinates to maze grid indices
        int col = (int)std::floor(x);
        int row = (int)std::floor(z);
        // Outside the maze bounds is considered a wall to prevent leaving the area
        if (row < 0 || row >= maze.height || col < 0 || col >= maze.width)
        {
            return true;
        }
        // Return true if this grid cell is a wall
        return (maze.layout[row][col] == 0);
    }

    glm::vec3 generate_start_camera_position(const Maze_::Maze& maze)
    {
        while (true)
        {
            int x = Random::random_int(2, maze.width - 2);
            int y = Random::random_int(2, maze.width - 2);

            if (
                !isWall(maze, x, y) &&
                !isWall(maze, x + 1, y) &&
                !isWall(maze, x - 1, y) &&
                !isWall(maze, x, y + 1) &&
                !isWall(maze, x, y - 1)
                )
            {
                return glm::vec3(x + 0.24, 0.5, y + 0.24);
            }
        }
    }
}

