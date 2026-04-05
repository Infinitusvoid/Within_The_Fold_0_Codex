#pragma once


#include "CppCommponents/ImageRGBA.h"

namespace Texture_
{
    struct Texture
    {
        struct Internal
        {
            int texture_unit = -1;
            unsigned int id = 0;
        } gl;

        int width;
        int height;
    };

    void create(Texture& texture, int texture_unit);

    bool create_procedural
    (
        Texture& texture,
        int width,
        int height,
        std::function<RGBA(float u, float v)> f_generator
    );

    bool create_from_ImageRGBA
    (
        Texture& texture,
        ImageRGBA& image
    );

    bool update_procedural
    (
        Texture& texture,
        std::function<RGBA(RGBA old, float u, float v)> f_modifier
    );

    void set_texture_unit(Texture& texture, int texture_unit);
    bool load_from_file(Texture& texture, const char* image_file_path);
    bool replace_texture(Texture& texture, const char* image_file_path);
    void bind(Texture& texture);
    void free(Texture& texture);



    // TODO this code work but likely has bugs
    bool async_generate_and_upload
    (
        Texture& tex,
        int width, int height,
        std::function<RGBA(float u, float v)> f_generator
    );

    // TODO this code work but likely has bugs ( place this in render loop )
    void process_all_async_uploads();

}