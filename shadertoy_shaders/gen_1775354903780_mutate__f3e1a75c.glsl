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
    return uv * 1.5 + vec2(
        sin(uv.x * 5.0 + iTime * 1.5) * 0.1,
        cos(uv.y * 6.5 + iTime * 1.0) * 0.1
    );
}

vec2 flowB(vec2 uv)
{
    return vec2(
        sin(uv.x * 10.0 + iTime * 0.5) * 0.15,
        cos(uv.y * 8.0 + iTime * 0.9) * 0.1
    );
}

vec3 palette(float t)
{
    return vec3(
        0.1 + 0.5*sin(t * 1.2 + iTime * 0.3),
        0.5 + 0.4*cos(t * 1.5 + iTime * 0.7),
        0.9 - 0.3*sin(t * 0.8 + iTime * 0.5)
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Primary Flow Distortion
    uv = flowB(uv);

    // Wave Distortion (using phase based on time)
    float wavePhase = uv.x * 3.5 + uv.y * 4.0 + iTime * 2.0;
    uv = uv + vec2(
        sin(wavePhase * 0.4) * 0.25,
        cos(wavePhase * 0.3) * 0.15
    );

    // Complex Warping/Rotation
    float angle = iTime * 1.3 + uv.x * 2.0 + uv.y * 1.5;
    mat2 rotationMatrix = mat2(cos(angle * 0.8), -sin(angle * 0.8), sin(angle * 0.8), cos(angle * 0.8));
    uv *= rotationMatrix;

    // Final Fine Detail Movement
    uv = flowA(uv);

    // Palette calculation
    float t = (uv.x * 8.0 + uv.y * 6.0) * 10.0 + iTime * 0.6;
    vec3 col = palette(t);

    // Enhanced Color Modulation
    col += 0.8 * sin(iTime * 1.1 + uv.x * 8.0);
    col += 0.5 * cos(uv.y * 7.5 + iTime * 0.4);
    col += 0.6 * sin(uv.x * 12.0 + uv.y * 4.0 + iTime * 0.2);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
