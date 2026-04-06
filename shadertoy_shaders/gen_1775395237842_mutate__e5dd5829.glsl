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

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.02,0.34,0.68)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;
    vec2 p = uv * 2.0;
    float r = length(p);
    float a = atan(p.y, p.x);

    // Calculate wavy distortion based on polar coordinates and time
    float wave = sin(r * 20.0 + iTime * 3.0) * cos(a * 10.0);

    // Dynamic contrast modulation based on the wave
    float contrast = 1.0 + 1.5 * abs(wave * 0.5);

    // Radial distortion and shaping
    float d = r - 0.5 + 0.1 * contrast;
    float fill = smoothstep(0.02, 0.015, d);
    float ring = smoothstep(0.15, 0.0, r - 0.3);

    // Color modulation using radial position and wave effect
    vec3 color = pal(r * 15.0 + iTime) * contrast * (fill * 0.7 + ring * 0.3);

    fragColor = vec4(color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
