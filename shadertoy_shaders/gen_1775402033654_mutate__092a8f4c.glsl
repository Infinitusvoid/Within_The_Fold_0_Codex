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

    // Introduce radial depth
    float z = 1.0 / (r * 2.0 + 1.0);

    // Complex spatial flow based on angle and radial distance
    float freq_r = 5.0 + r * 10.0;
    float phase_a = iTime * 0.5 + a * 3.0;
    float phase_r_shift = iTime * 0.3 + r * 1.5;

    // Sine/Cosine layering
    float wave1 = sin(freq_r * 4.0 + phase_a);
    float wave2 = cos(freq_r * 1.5 + phase_r_shift);

    // Introducing finer rotational structure using angle
    float rotation_band = sin(r * 40.0 + iTime * 1.2) * cos(a * 25.0 + iTime * 1.8);

    // Generate chaotic noise based on position and time
    float noise = fract(sin(r * 150.0 + iTime * 50.0) * 3.14159);

    // Color modulation driven by depth and wave interactions
    vec3 col = pal(0.1 + 0.6 * z + 0.4 * wave1);

    // Combine modulation using the rotational and noise factors
    float modulation = 0.2 + 0.5 * abs(rotation_band) + 0.3 * noise;
    col *= modulation;

    // Apply exponential falloff for central brightening/darkening
    col *= exp(-2.5 * r * r); 

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
