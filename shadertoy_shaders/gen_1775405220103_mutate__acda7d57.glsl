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

vec3 pal(float t)
{
    return 0.55 + 0.45*cos(6.28318*(vec3(0.08,0.35,0.67)+t));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    // Polar coordinates
    float r = length(uv);
    float a = atan(uv.y, uv.x);

    // Introduce radial depth/scaling based on r and a
    // Shift the depth calculation
    float z = 2.0 / (r * 0.7 + 0.1 + 0.5 * cos(a * 3.0));

    // Complex wave mixing based on angle, radial depth, and time
    float freq = 2.0 + r * 8.0;
    float phase_r = iTime * 1.2 + a * 7.5;
    float phase_z = iTime * 2.5 + z * 4.0;

    // Introduce rotational waves
    float wave1 = sin(freq * 4.0 + phase_r);
    float wave2 = cos(freq * 1.5 + phase_z * 0.8);

    // Introduce a swirling, detailed band pattern
    float banded = sin(r * 80.0 + iTime * 6.0) * cos(a * 30.0 + iTime * 2.0);

    // Generate fractal noise based on position and time
    float noise = fract(sin(r * 250.0 + iTime * 15.0) * 512.3);

    // Calculate color modulation using depth (z) and wave interaction
    // The depth z now controls the base color shift more directly
    vec3 col = pal(0.1 + 0.5 * z + 0.4 * wave1);

    // Combine modulation factors: use noise and bands for texture contrast
    float modulation = 0.2 + 0.6 * abs(banded) + 0.4 * noise;
    col *= modulation;

    // Apply heavy radial falloff based on the distance, making the center extremely bright
    col *= exp(-1.5 * r * r); 

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
