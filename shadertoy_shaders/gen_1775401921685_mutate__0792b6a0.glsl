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
    float z = 2.0 / (r + 0.5);

    // Complex wave mixing based on angle, radial depth, and time
    float freq = 3.0 + r * 5.0;
    float phase_r = iTime * 0.8 + a * 5.0;
    float phase_z = iTime * 1.5 + z * 3.0;

    float wave1 = sin(freq * 3.0 + phase_r);
    float wave2 = cos(freq * 2.5 + phase_z);

    // Introduce a swirling, detailed band pattern
    float banded = sin(r * 50.0 + iTime * 4.0) * cos(a * 20.0 + iTime * 1.5);

    // Generate smooth noise
    float noise = fract(sin(r * 100.0 + iTime * 10.0) * 43758.5453);

    // Calculate color modulation using depth (z) and time for shifting
    vec3 col = pal(0.05 + 0.3 * z + 0.5 * wave1);

    // Combine modulation factors: use noise for overall darkness/contrast, and waves for texture
    float modulation = 0.3 + 0.5 * abs(banded) + 0.5 * noise;
    col *= modulation;

    // Apply heavy radial falloff based on the distance
    col *= exp(-2.0 * r * r); 

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
