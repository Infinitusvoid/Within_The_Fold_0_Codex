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

vec3 pal(float t){ return 0.5 + 0.5*sin(15.0*(vec3(0.1, 0.5, 2.0)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;

    // Calculate a dynamic flow field based on time and position
    vec2 flow = uv * 4.0 + iTime * 0.5;

    // Use flow coordinates to calculate texture offsets
    float x_offset = flow.x * 1.5;
    float y_offset = flow.y * 1.0;

    // Calculate a pseudo-depth factor based on the UV coordinates
    float depth = 1.0 / (uv.x * 2.0 + 0.5);

    // Calculate flow coordinates for coloring
    float x = x_offset * depth * 2.0;
    float z = y_offset * depth * 3.0;

    // Use a new contrast mechanism based on the deviation from center
    float dist = abs(fract(x) - 0.5) + abs(fract(z) - 0.5);
    float l_factor = smoothstep(0.4, 0.1, dist * 0.5);
    float r_factor = smoothstep(0.3, 0.0, dist * 0.5);

    // Blend the factors for glow, introducing a warp based on time
    float glow = (l_factor + r_factor) * 1.8 / (1.0 + depth * depth * 0.5);

    // Color based on combined flow and time input, using the new depth perspective
    vec3 col = pal(x * 6.0 + z * 0.5) * glow;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
