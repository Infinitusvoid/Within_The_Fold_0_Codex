#version 330 core
uniform vec3 iResolution;
uniform float iTime;
uniform float iTimeDelta;
uniform int iFrame;
uniform vec4 iMouse;
uniform vec4 iDate;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform float iChannelTime[4];
uniform vec3 iChannelResolution[4];
out vec4 FragColor;

mat2 rot(float a){ float c=cos(a), s=sin(a); return mat2(c,-s,s,c); }
vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.0,0.3,0.65)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // Apply time-based rotation and offset
    vec2 p = uv * 4.0 - 2.0;
    p.x *= iResolution.x / iResolution.y;
    p *= rot(iTime * 0.5 + 1.0);

    // Calculate flow based on distance and coordinate manipulation
    float dist = length(p);

    // Introduce a complex flow based on the direction and distance
    float flow = sin(dist * 8.0 + iTime * 1.5) * 2.0 + p.y * 3.0;

    // Use flow for coloring and palette manipulation
    vec3 color = pal(flow * 5.0 + iTime * 0.2) * (0.5 + 0.5 * flow);

    fragColor = vec4(color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
