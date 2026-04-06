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

vec2 flowA(vec2 uv)
{
    return uv * 2.0 + vec2(
        sin(uv.x * 7.0 + iTime * 2.0) * 0.2,
        cos(uv.y * 5.0 + iTime * 3.0) * 0.2
    );
}

vec2 flowB(vec2 uv)
{
    return vec2(
        sin(uv.x * 12.0 + iTime * 0.8) * 0.12,
        cos(uv.y * 9.0 + iTime * 1.5) * 0.15
    );
}

vec3 palette(float t)
{
    return vec3(
        0.15 + 0.5*sin(t * 1.5 + iTime * 0.5),
        0.6 + 0.35*cos(t * 2.0 + iTime * 0.7),
        0.85 - 0.4*sin(t * 0.9 + iTime * 0.4)
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Primary Flow Distortion
    uv = flowB(uv);

    // Ripples and Distortion based on time
    float wavePhase = uv.x * 5.0 + uv.y * 6.0 + iTime * 3.0;
    uv = uv + vec2(
        sin(wavePhase * 0.3) * 0.2,
        cos(wavePhase * 0.4) * 0.1
    );

    // Rotational Warping based on distance from center and time
    float angle = (uv.x + uv.y) * 3.0 + iTime * 1.5;
    float scale = 1.0 + sin(uv.x * 5.0) * 0.1;
    mat2 rotationMatrix = mat2(cos(angle * 0.7), -sin(angle * 0.7), sin(angle * 0.7), cos(angle * 0.7));
    uv = uv * scale * rotationMatrix;

    // Secondary Flow Refinement
    uv = flowA(uv);

    // Palette calculation
    float t = (uv.x * 9.0 + uv.y * 7.0) * 11.0 + iTime * 0.5;
    vec3 col = palette(t);

    // Enhanced Color Modulation
    col += 0.9 * sin(iTime * 1.2 + uv.x * 9.0);
    col += 0.7 * cos(uv.y * 8.0 + iTime * 0.3);
    col += 0.5 * sin(uv.x * 15.0 + uv.y * 5.0 + iTime * 0.1);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
