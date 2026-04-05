#version 330 core
layout(location = 0) in vec3 aPos;
layout(location = 1) in vec2 aTexCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

out vec2 TexCoord;
out vec3 WorldPos;
out vec3 LocalPos;

void main()
{
    vec4 worldPosition = model * vec4(aPos, 1.0);
    WorldPos = worldPosition.xyz;
    LocalPos = aPos;
    TexCoord = aTexCoord;
    gl_Position = projection * view * worldPosition;
}
