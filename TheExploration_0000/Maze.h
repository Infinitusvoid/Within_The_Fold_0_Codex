#pragma once

#include <glm/glm.hpp>
#include <vector>

namespace Maze_
{
    struct Maze
    {
        int width;
        int height;

        std::vector<std::vector<int>> layout;
    };

    void init(Maze& maze);

    int height_at(const Maze& maze, float x, float z);
    bool isWall(const Maze& maze, float x, float z);

    glm::vec3 generate_start_camera_position(const Maze_::Maze& maze);
}