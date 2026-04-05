#include <string>

std::string f_embeded_GLSL_source_vertex_shader_exploring_0000()
{
    return "#version 330 core\n"
"layout(location = 0) in vec3 aPos;\n"
"layout(location = 1) in vec2 aTexCoord;\n"
"\n"
"// uniform mat4 uMVP;\n"
"uniform mat4 model;\n"
"uniform mat4 view;\n"
"uniform mat4 projection;\n"
"\n"
"out vec2 TexCoord;\n"
"out vec3 WorldPos;    // <-- pass this to the fragment shader\n"
"out vec3 LocalPos;\n"
"\n"
"void main() {\n"
"    // Compute world space position\n"
"    vec4 worldPosition = model * vec4(aPos, 1.0);\n"
"    WorldPos = worldPosition.xyz;\n"
"    LocalPos = aPos;\n"
"    // gl_Position = uMVP * vec4(aPos, 1.0);\n"
"    gl_Position = projection * view * model * vec4(aPos, 1.0f);\n"
"\n"
"    TexCoord = vec2(aTexCoord.x, aTexCoord.y);\n"
"}\n"
"\n"
"";
}
