
#include <functional>
#include <iostream>
#include <vector>
#include <queue>
#include <cmath>
#include <unordered_set>
#include <unordered_map>
#include <assert.h>

#include "ImageUtils.h"

#include "CppCommponents/Random.h"
#include "CppCommponents/Search_BreadthFirst_2d.h"

#include "CppCommponents/Folder.h"

namespace MazeGenerate_
{
	namespace Dungeon2dMapGenerator_V0_
	{
		struct Parameters
		{
			int number_of_rooms_x = 2;
			int number_of_rooms_y = 2;
			int size_of_room_external_x = 32;
			int size_of_room_external_y = 32;

			int size_of_room_internal_x_min = 10;
			int size_of_room_internal_x_max = 22;
			int size_of_room_internal_y_min = 10;
			int size_of_room_internal_y_max = 22;

			int number_of_iteration_of_adding_walls = 400;
			std::function<int(int)> f_random_points_per_itereation;


			std::function<void(int width, int height, int x, int y, int r, int g, int b, int a)> f;

			bool printing_out;
		};

		void run(Parameters& parameters);
	}

	const char* filepath_generate_0 = "maze_generated/generate_0.png";
	const char* filepath_generate_1 = "maze_generated/generate_1.png";
	
	namespace Dungeon2dMapGenerator_V0_
	{
		struct XYInt
		{
			int x;
			int y;
		};

		struct Connection
		{
			int room_index_a;
			int entrance_index_a;

			int room_index_b;
			int entrance_index_b;
		};

		struct Room
		{
			int position_x;
			int position_y;
			int size_x;
			int size_y;

			std::vector<XYInt> entrances;
		};

		struct IntXY
		{
			int x;
			int y;
		};

		bool operator==(const IntXY& lhs, const IntXY& rhs) {
			return (lhs.x == rhs.x) && (lhs.y == rhs.y);
		}


	}
}



// Specialize std::hash for our IntXY structure. This allows IntXY to be used as a key in unordered containers.
namespace std
{
	template <>
	struct hash<MazeGenerate_::Dungeon2dMapGenerator_V0_::IntXY>
	{
		std::size_t operator()(const MazeGenerate_::Dungeon2dMapGenerator_V0_::IntXY& p) const noexcept
		{
			// Compute individual hash values for x and y and combine them.
			std::size_t h1 = std::hash<int>{}(p.x);
			std::size_t h2 = std::hash<int>{}(p.y);
			// Combine the results (a simple combination; you might use a more robust method in production).
			return h1 ^ (h2 << 1);
		}
	};
}

namespace MazeGenerate_
{
    namespace Dungeon2dMapGenerator_V0_
    {
        struct Element
        {
            int value;
        };

        struct Grid2dInt
        {
            std::unordered_map<IntXY, Element> map_;
        };

        namespace Grid2dInt_
        {
            // Insert an element at (x, y) with a given value.
            void insert(Grid2dInt& grid, int x, int y, int val)
            {
                IntXY coords{ x, y };
                grid.map_[coords] = Element{ val };
            }

            // Check if a cell exists
            bool contains(const Grid2dInt& grid, int x, int y)
            {
                return grid.map_.find({ x,y }) != grid.map_.end();
            }

            // Access element at (x,y), throws if not present
            Element& at(Grid2dInt& grid, int x, int y)
            {
                return grid.map_.at({ x,y });
            }

            const Element& at(const Grid2dInt& grid, int x, int y)
            {
                return grid.map_.at({ x,y });
            }

            // Remove an element
            bool erase(Grid2dInt& grid, int x, int y)
            {
                return grid.map_.erase({ x,y }) > 0;
            }

            // Clear the entire grid
            void clear(Grid2dInt& grid)
            {
                grid.map_.clear();
            }

            // Number of stored cells
            std::size_t size(const Grid2dInt& grid)
            {
                return grid.map_.size();
            }

            // Retrieve the 4-way neighbors of a cell (x,y)
            std::vector<std::pair<IntXY, Element*>> getNeighbors(Grid2dInt& grid, int x, int y)
            {
                static const int dx[4] = { 1, -1, 0, 0 };
                static const int dy[4] = { 0, 0, 1, -1 };

                std::vector<std::pair<IntXY, Element*>> neighbors;
                for (int i = 0; i < 4; ++i) {
                    IntXY c{ x + dx[i], y + dy[i] };
                    auto it = grid.map_.find(c);
                    if (it != grid.map_.end()) {
                        neighbors.emplace_back(c, &it->second);
                    }
                }
                return neighbors;
            }


            /// Return a full, independent copy of this grid
            Grid2dInt clone(const Grid2dInt& grid)
            {
                Grid2dInt g;
                g.map_ = grid.map_;      // unordered_map’s operator= will copy everything
                return g;
            }

            // Determine bounding rectangle of occupied cells
            void getBounds(const Grid2dInt& grid, IntXY& min, IntXY& max)
            {
                if (grid.map_.empty())
                {
                    min = { 0,0 };
                    max = { 0,0 };
                    return;
                }
                int minX = std::numeric_limits<int>::max();
                int minY = std::numeric_limits<int>::max();
                int maxX = std::numeric_limits<int>::min();
                int maxY = std::numeric_limits<int>::min();

                for (auto& kv : grid.map_) {
                    minX = std::min(minX, kv.first.x);
                    minY = std::min(minY, kv.first.y);
                    maxX = std::max(maxX, kv.first.x);
                    maxY = std::max(maxY, kv.first.y);
                }
                min = { minX, minY };
                max = { maxX, maxY };
            }

            // Print each populated cell
            void print(const Grid2dInt& grid)
            {
                for (const auto& kv : grid.map_) {
                    std::cout << "(" << kv.first.x << ", " << kv.first.y << ") => "
                        << kv.second.value << '\n';
                }
            }

            // Visualize grid as full matrix (empty cells shown as dot)
            void printGrid(const Grid2dInt& grid)
            {
                IntXY mn, mx;
                getBounds(grid, mn, mx);
                for (int y = mx.y; y >= mn.y; --y) {
                    for (int x = mn.x; x <= mx.x; ++x) {
                        auto it = grid.map_.find({ x,y });
                        if (it != grid.map_.end()) {
                            std::cout << it->second.value;
                        }
                        else {
                            std::cout << ".";
                        }
                        std::cout << ' ';
                    }
                    std::cout << '\n';
                }
            }
        }




        namespace Room_
        {
            void draw(Room& room, Grid2dInt& grid, int value_room, int value_entrance)
            {
                for (int y = room.position_y; y < (room.position_y + room.size_y); y++)
                {
                    for (int x = room.position_x; x < (room.position_x + room.size_x); x++)
                    {
                        Grid2dInt_::insert(grid, x, y, value_room);
                    }
                }

                for (auto& entrance : room.entrances)
                {
                    Grid2dInt_::insert(grid, entrance.x, entrance.y, value_entrance);
                }
            }

            void get_random_grid_thats_adjenson_to_room(Room& room, int& x, int& y)
            {
                if (Random::random_bool())
                {
                    if (Random::random_bool())
                    {
                        x = room.position_x - 1;
                        y = room.position_y + Random::random_int(0, room.size_y - 1);
                    }
                    else
                    {
                        x = room.position_x + room.size_x;
                        y = room.position_y + Random::random_int(0, room.size_y - 1);
                    }
                }
                else
                {
                    if (Random::random_bool())
                    {
                        x = room.position_x + Random::random_int(0, room.size_x - 1);
                        y = room.position_y - 1;
                    }
                    else
                    {
                        x = room.position_x + Random::random_int(0, room.size_x - 1);
                        y = room.position_y + room.size_y;
                    }
                }

            }

            std::vector<Room> generate_rooms
            (
                int number_of_rooms_x, int number_of_rooms_y,
                int size_of_room_external_x, int size_of_room_external_y,
                int size_of_room_internal_x_min, int size_of_room_internal_x_max,
                int size_of_room_internal_y_min, int size_of_room_internal_y_max,
                std::vector<Connection>& connections
            )
            {

                assert((size_of_room_external_x - 2) > size_of_room_internal_x_max);
                assert((size_of_room_external_y - 2) > size_of_room_internal_y_max);

                std::vector<Room> rooms;

                for (int index_room_y = 0; index_room_y < number_of_rooms_y; index_room_y++)
                {
                    for (int index_room_x = 0; index_room_x < number_of_rooms_x; index_room_x++)
                    {
                        int x_offset_external = size_of_room_external_x * index_room_x;
                        int y_offset_external = size_of_room_external_y * index_room_y;

                        int room_size_x = Random::random_int(size_of_room_internal_x_min, size_of_room_internal_x_max);
                        int room_size_y = Random::random_int(size_of_room_internal_y_min, size_of_room_internal_y_max);
                        int room_offset_internal_x = Random::random_int(2, size_of_room_external_x - 2 - room_size_x);
                        int room_offset_internal_y = Random::random_int(2, size_of_room_external_y - 2 - room_size_y);

                        int x = x_offset_external + room_offset_internal_x;
                        int y = y_offset_external + room_offset_internal_y;

                        {
                            Room room;
                            room.position_x = x;
                            room.position_y = y;
                            room.size_x = room_size_x;
                            room.size_y = room_size_y;

                            rooms.push_back(room);
                        }
                    }
                }

                {
                    for (int i = 0; i < rooms.size(); i++)
                    {
                        if (i < (rooms.size() - 1))
                        {
                            {
                                Connection connection;
                                connection.entrance_index_a = 0;
                                connection.entrance_index_b = 0;

                                connection.room_index_a = i;
                                connection.room_index_b = i + 1;
                                connections.push_back(connection);
                            }


                            {
                                Connection connection;
                                connection.entrance_index_a = 1;
                                connection.entrance_index_b = 1;

                                connection.room_index_a = i;
                                connection.room_index_b = i + 1;
                                connections.push_back(connection);
                            }

                        }
                        else
                        {

                        }

                    }

                    {
                        Connection connection;
                        connection.entrance_index_a = 0;
                        connection.entrance_index_b = 0;

                        connection.room_index_a = rooms.size() - 1;
                        connection.room_index_b = 0;
                        connections.push_back(connection);
                    }





                }

                return rooms;
            }

            void add_entrances(Room& room, int number_of_entrances)
            {
                int x = 0;
                int y = 0;

                while (room.entrances.size() != number_of_entrances)
                {
                    Room_::get_random_grid_thats_adjenson_to_room(room, x, y);

                    bool valid = true;
                    for (auto& xy : room.entrances)
                    {
                        if (x == xy.x && y == xy.y)
                        {
                            valid = false;
                            break;
                        }
                    }

                    if (valid)
                    {
                        room.entrances.push_back({ x, y });
                    }

                }





            }
        }



        namespace Grid_
        {
            void init_grid(Grid2dInt& grid, int size_x, int size_y, int value)
            {
                for (int y = 0; y < size_y; y++)
                {
                    for (int x = 0; x < size_x; x++)
                    {
                        Grid2dInt_::insert(grid, x, y, value);
                    }
                }
            }

            void add_wall_at_random_position(Grid2dInt& grid, int size_x, int size_y)
            {
                int x = Random::random_int(0, size_x - 1);
                int y = Random::random_int(0, size_y - 1);

                Grid2dInt_::insert(grid, x, y, 1);
            }

        }


        namespace Connection_
        {
            bool connect(Grid2dInt& grid, int total_size_x, int total_size_y, std::vector<Connection>& connections, int value_for_connection, std::vector<Room>& rooms)
            {
                for (Connection& connection : connections)
                {
                    assert(connection.room_index_a != connection.room_index_b);

                    assert(connection.entrance_index_a < 2);
                    assert(connection.entrance_index_b < 2);

                    Search_BreadthFirst_2d_::BFSResult result = Search_BreadthFirst_2d_::search
                    (
                        total_size_x,
                        total_size_y,
                        rooms[connection.room_index_a].entrances[connection.entrance_index_a].x,
                        rooms[connection.room_index_a].entrances[connection.entrance_index_a].y,
                        rooms[connection.room_index_b].entrances[connection.entrance_index_b].x,
                        rooms[connection.room_index_b].entrances[connection.entrance_index_b].y,
                        [&](int x, int y)
                        {
                            bool wall = (Grid2dInt_::at(grid, x, y).value == 4) || (Grid2dInt_::at(grid, x, y).value == 1);

                            return wall;
                        }
                    );

                    // Search_BreadthFirst_2d_::display_result(result);

                    if (result.found)
                    {
                        for (Search_BreadthFirst_2d_::Point xy : result.path)
                        {
                            if (Grid2dInt_::at(grid, xy.x, xy.y).value != 2)
                            {
                                Grid2dInt_::insert(grid, xy.x, xy.y, value_for_connection);
                            }
                        }
                    }
                    else
                    {
                        return false;
                    }
                }

                return true;
            }
        }
    }

    namespace Dungeon2dMapGenerator_V0_
    {


        // Visualize grid as PNG
        ImageRGBA* visualize(Grid2dInt& grid, int image_width, int image_height) {
            // color map: index 0 -> wall (black), index 1 -> path (white)
            std::vector<RGBA> colors =
            {
                RGBA(0,   0,   0, 255),
                RGBA(255, 255, 255, 255),
                RGBA(0, 255,   0, 255),
                RGBA(0,   0, 255, 255),
                RGBA(0, 255, 255, 255),
                RGBA(100, 220, 200, 255),
                RGBA(100, 220, 100, 255)
            };

            const int width = image_width, height = image_height;
            ImageRGBA* img = ImageRGBA_::create(width, height);

            // determine grid bounds
            IntXY minC, maxC;
            Grid2dInt_::getBounds(grid, minC, maxC);
            int cols = maxC.x - minC.x + 1;
            int rows = maxC.y - minC.y + 1;

            // compute cell size (in pixels)
            int cellW = (cols > 0) ? width / cols : width;
            int cellH = (rows > 0) ? height / rows : height;

            // clear background to black
            for (int y = 0; y < height; ++y)
                for (int x = 0; x < width; ++x)
                    ImageRGBA_::set_pixel(*img, x, y, colors[0]);

            // draw each cell
            for (int gy = minC.y; gy <= maxC.y; ++gy) {
                for (int gx = minC.x; gx <= maxC.x; ++gx) {
                    int val = Grid2dInt_::contains(grid, gx, gy) ? Grid2dInt_::at(grid, gx, gy).value : 0;
                    // clamp index to valid range
                    size_t idx = (val >= 0 && val < static_cast<int>(colors.size())) ? val : 0;
                    RGBA col = colors[idx];

                    int startX = (gx - minC.x) * cellW;
                    int startY = (gy - minC.y) * cellH;
                    for (int dy = 0; dy < cellH; ++dy) {
                        for (int dx = 0; dx < cellW; ++dx) {
                            int px = startX + dx;
                            int py = height - 1 - (startY + dy); // flip y for image coords
                            if (px >= 0 && px < width && py >= 0 && py < height)
                                ImageRGBA_::set_pixel(*img, px, py, col);
                        }
                    }
                }
            }

            //ImageRGBA_::save_png(*img, file_path);
            // ImageRGBA_::free_image(img);
            return img;
        }

        ImageRGBA* generate(const Parameters& parameters)
        {
            Grid2dInt grid;

            const int total_size_x = parameters.number_of_rooms_x * parameters.size_of_room_external_x;
            const int total_size_y = parameters.number_of_rooms_y * parameters.size_of_room_external_y;

            int image_width = total_size_x;
            int image_height = total_size_y;

            std::vector<Connection> connections;

            std::vector<Room> rooms = Room_::generate_rooms
            (
                parameters.number_of_rooms_x,
                parameters.number_of_rooms_y,
                parameters.size_of_room_external_x,
                parameters.size_of_room_external_y,
                parameters.size_of_room_internal_x_min,
                parameters.size_of_room_internal_x_max,
                parameters.size_of_room_internal_y_min,
                parameters.size_of_room_internal_y_max,
                connections
            );



            // Draw
            {
                Grid_::init_grid(grid, total_size_x, total_size_y, 0);
                for (auto& room : rooms)
                {
                    Room_::add_entrances(room, 2);
                    Room_::draw(room, grid, 4, 2);
                }

                if (Connection_::connect(grid, total_size_x, total_size_y, connections, 3, rooms))
                {
                //    std::cout << "everything connected\n";
                }

                // visualize(grid, image_width, image_height);
            }

            Grid2dInt grid_new = Grid2dInt_::clone(grid);

            {


                for (int i = 0; i < 400; i++)
                {

                    if (Random::random_bool())
                    {
                        for (int j = 0; j < 400; j++)
                        {
                            Grid_::add_wall_at_random_position(grid_new, total_size_x, total_size_y);
                        }
                    }
                    else
                    {
                        for (int j = 0; j < 40; j++)
                        {
                            Grid_::add_wall_at_random_position(grid_new, total_size_x, total_size_y);
                        }
                    }


                    if (Connection_::connect(grid_new, total_size_x, total_size_y, connections, 3, rooms))
                    {
                        // std::cout << "everything connected\n";
                        grid = Grid2dInt_::clone(grid_new);
                    }
                    else
                    {
                        // std::cout << "cant connect\n";
                        grid_new = Grid2dInt_::clone(grid);
                    }



                }

                // redraw
                {
                    Grid_::init_grid(grid, total_size_x, total_size_y, 0);

                    {
                        IntXY xy_min;
                        IntXY xy_max;
                        Grid2dInt_::getBounds(grid_new, xy_min, xy_max);

                        for (int y = 0; y < xy_max.y; y++)
                        {
                            for (int x = 0; x < xy_max.x; x++)
                            {
                                if (Grid2dInt_::at(grid_new, x, y).value == 1)
                                {
                                    Grid2dInt_::insert(grid, x, y, 1);
                                }
                            }
                        }
                    }



                    for (auto& room : rooms)
                    {
                        Room_::add_entrances(room, 2);
                        Room_::draw(room, grid, 4, 2);
                    }
                    Connection_::connect(grid, total_size_x, total_size_y, connections, 3, rooms);
                }








               ImageRGBA* image = visualize(grid, image_width, image_height);


               assert(image != nullptr);
                // ImageRGBA_::free_image(image);

                return image;
            }
        }
    }


    namespace Dungeon2dMapGenerator_V0_
    {
        ImageRGBA* generate_maze(Parameters& parameters)
        {
            // std::cout << "Dungeon2dMapGenerator_V0\n";

            return Dungeon2dMapGenerator_V0_::generate(parameters);
            
        }
    }


	ImageRGBA* generate()
	{
        

		Dungeon2dMapGenerator_V0_::Parameters parameters;
		parameters.number_of_rooms_x = 2;
		parameters.number_of_rooms_y = 2;

        ImageRGBA* image = Dungeon2dMapGenerator_V0_::generate_maze(parameters);

        assert(image != nullptr);

        return image;
	}
}
