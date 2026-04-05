#include <string>

std::string f_embeded_GLSL_source_fragment_shader()
{
    return "#version 330 core\n"
"\n"
"in vec2 TexCoord;\n"
"in vec3 WorldPos;\n"
"\n"
"// texture samplers\n"
"uniform sampler2D texture1;\n"
"uniform sampler2D texture2;\n"
"\n"
"out vec4 FragColor;\n"
"uniform vec3 uColor;\n"
"\n"
"void main()\n"
"{\n"
"    // FragColor = vec4(uColor, 1.0);\n"
"    FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), 0.2);\n"
"}";
}
