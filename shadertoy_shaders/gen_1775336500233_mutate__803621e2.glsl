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

vec2 flowB(vec2 uv)
{
    return vec2(sin(uv.x * 10.0 + iTime * 0.8), cos(uv.y * 5.0 + iTime * 1.1));
}

vec2 flowA(vec2 uv)
{
    return uv * 3.0 + vec2(
        sin(uv.x * 4.5 + iTime * 1.3),
        cos(uv.y * 3.5 + iTime * 0.9)
    );
}

vec3 palette(float t)
{
    return vec3(
        0.1 + 0.2 * sin(t * 0.5 + iTime * 0.2),
        0.6 + 0.3 * cos(t * 0.6 + iTime * 0.1),
        0.9 - 0.1 * sin(t * 0.4 + iTime * 0.3)
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Base Distortion (using flowB)
    uv = flowB(uv);

    // Apply a complex, scaled rotation
    float angle = iTime * 3.0 + uv.x * 1.2 + uv.y * 0.8;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv *= rotationMatrix;

    // Secondary Distortion (using flowA)
    uv = flowA(uv);

    // Palette calculation
    float t = (uv.x * 5.0 + uv.y * 3.0) * 7.0 + iTime * 0.6;
    vec3 col = palette(t);

    // Chromatic adjustments based on interaction and time
    float shift = sin(uv.x * 8.0 + iTime * 1.5);
    float blend = cos(uv.y * 6.0 + iTime * 0.9);

    col += 0.8 * shift;
    col += 0.4 * blend;
    col += 0.2 * sin(iTime * 0.5 + uv.x * 10.0);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
