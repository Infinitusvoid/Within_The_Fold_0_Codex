# Within_The_Fold_0  
  
#### We are generating interactive experiences  
* We start the program unique textures, sounds and the enviroment is generated  
* We generate things are load and some thing may be generated at runtime, even shaders are generated and unique everytime you start the game  

## The simple maze template 
[Template that AI generate as the starting point on build of this project](TheSimpleMazeTemplate.md)

#### Notes 

Well now we are drawing the same mesh with diffrent transform with the same shader 

Well to construct one room 
We will use let say 10 shaders 
We will use 10 different textures 
We can generate the mesh and set it to GPU or 
We have like 6 diffrent meshes that we use to generate the whole level 
 Top, Botton, Left, Right, Front, Back

We if we assume all the rooms to be the size 
than we could have things like that 

create_cube(room_index_x, room_index_y, room_index_z, local_index_x, local_index_y, local_index_z, size_of_cube, shader_id, texture_id_1, texture_2)

Well let's thing if we want the rooms to be the same size or not 

Well generating the rooms could be first explored without generaing it in 3d we can for start build the generator that generates as a 2d image let's try that first 


#### Let's generate 2d maps first 
Yea we did that the code is in the repository 
https://github.com/Infinitusvoid/Dungeon2dMapGenerator_V0/tree/main
Will later make sense to add it as a static lib or copy paste the project


#### Many problems can be understand and explored as Image generation and processing in general of images 

Think about how you can represent things in images and then process the images to solve the problem 

## TODO

#### Preprocessing image and generating new Image

we read the map image 
we find what colors are in the image 
we than buid a map what is the meaning of each color 
 * black empty space
 * white wall
 * cyan room
 * blue corridor
 * entrance

For later
Well there is an option to we turn all the black pixel that we can get to from the blue into blue pixels, flow algorithm 
This way we may make more interesting walking path 

But for now We just turn all black pixel into white 
Thre are also green pixels that represent entrance into room that we turn into blue pixels  

we may move this functionally into the Dungeon2dMapGenerator_V0 when we decide so under some flag that we set for example 

#### Visualize the map 

Now we want to visualize the map with using cubes we have some hight by instancing cubes we build the whole map 
We observe how it's with performance adding some fps to messure what is the fps would be great for debuging 

We than assign diffrent tint to cubes that are in each room there will be for 4 room 
this way we visualize where the space of each room starts and ends 

We set diffrent hights for the each room

One way of going forward would be to use 6 diffrent meshes one 
could be for the
top,
buttom,
left,
right,
front,
back

this way we can create the map by calling 

cube(int side, int x, int y, int shader, std::vector<int> textures)

than we have the post processing steps so we batch and display all the geometry thet uses the same shader and it's from same side etc 





 
 ## Notes that were in main  

Engine
    ShaderPrograms
        VertexShaders
        FragmentShaders
        Textures
        Scenes
            Floor
                Room 
                VFX & custom geometry
                Souds
                Cubes
                    



## Cobe dumps may be usefull in future or may not 

```
// well let's do some calculation about requirement about generating the world  this way 
            // The flat map size is 64 * 64 = 4 kb if we use one byte
            // Well if we have 10 floors we can multiply that by 10 
            // 64 * 64 * 10 = 40 kb
            // for each cube we woud like to store many thing 

            // well one shader per cube seems resonable for now
            // int shader_id      4 bytes

            // we could have a material id instead that stores info as we want 

            // the number of texture
            // int texture_0      4 bytes
            // int texture_1      4 bytes
            // int texture_2      4 bytes
            // int texture_3      4 bytes


            // well let's go over again 
            // the cube type (int) 
            // the material id (int)

            // well this way the whole map with max height 10 
            // would b
            // 64 * 64 * 10 * 2 = 81920 bytes

            // the benefits are if two files are using the same material 
            // tha can be batched together and rendered to gether in single batch 
            // wel this means they use the same texture and the same shader


            /*
            for (int r = 0; r < maze.height; ++r)
            {
                for (int c = 0; c < maze.width; ++c)
                {
                    if (maze.layout[r][c] == 1)
                    {
                        // elements.push_back({ c,  1, r });
                        add_cube(c, 1, r, ElementType::wall);
                    }
                    else if (maze.layout[r][c] == 0)
                    {
                        add_cube(c, 1, r, ElementType::room);
                    }
                    else if (maze.layout[r][c] == 4)
                    {
                        add_cube(c, 1, r, ElementType::corridor);
                    }
                }
            }
            */
```


## Usage Notes 
W, A, S, D for movment
F : toggle between fullscreen / window 
2 : toggle fly / walk
M : toggle sound on / sound off

## Description  
When you start the game there is a new maze that is procedurally generated  
With 4 rooms, that you can explore and visit  
Audio visual exexperience, good for relaxation, and reflection  
Unique visual each time you will star the game the new unique visual are generated  
