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

vec3 pal(float t){ return 0.5 + 0.5*sin(10.0*(vec3(0.1, 0.5, 2.0)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;

    // Use a depth-like factor based on the Y coordinate
    float depth = 1.0 / (uv.y * 3.0 + 1.5);

    // Calculate flow coordinates
    vec2 p = uv;
    float x = p.x * depth * 3.0;
    float y = depth + iTime * 0.5;
    float z = p.y * depth * 2.0;

    // Use smoothstep differently for contrast
    float l_factor = smoothstep(0.4, 0.1, abs(fract(x) - 0.5));
    float r_factor = smoothstep(0.3, 0.0, abs(fract(y) - 0.5));

    // Blend the factors for glow
    float glow = (l_factor + r_factor) * 1.5 / (1.0 + depth * depth);

    // Color based on combined flow and time input
    vec3 col = pal(x * 5.0 + z) * glow;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
