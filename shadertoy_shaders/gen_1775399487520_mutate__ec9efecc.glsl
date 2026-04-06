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

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.5;
    return vec2(
        sin(uv.x * 5.0 + uv.y * 2.0 + t),
        cos(uv.x * 3.0 - uv.y * 1.5 + t * 0.7)
    );
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 10.0 + iTime * 0.5), cos(uv.y * 15.0 + iTime * 0.3));
}

vec3 palette(float t)
{
    return vec3(0.5 + 0.5*sin(t + iTime * 0.1), 0.5 + 0.5*sin(t + iTime * 0.2), 0.5 + 0.5*cos(t + iTime * 0.3));
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 1.2 + iTime * 0.7) * 0.2,
        cos(uv.y * 1.5 + iTime * 0.6) * 0.3
    );
}

vec2 waveC(vec2 uv)
{
    float t = iTime * 0.8;
    return vec2(
        sin(uv.x * 8.0 + uv.y * 6.0 + t * 1.2),
        cos(uv.y * 4.0 - uv.x * 5.0 + t * 0.5)
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Apply waveC as base distortion
    uv = waveC(uv);

    // Apply rotation based on time and position
    float angle = iTime * 0.8 + uv.x * 0.5 + uv.y * 0.3;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv = rotate(uv, angle);

    // Apply waveB
    uv = waveB(uv);

    // Calculate time parameter for palette
    float t = (uv.x + uv.y) * 10.0 + iTime * 0.5;
    vec3 col = palette(t);

    // Complex modulation using rotated coordinates and waveA
    col += 0.7 * sin(iTime * 0.3 + uv.x * 4.0 + uv.y * 3.0 + vec3(0.2, 0.5, 0.8));
    col += 0.5 * sin(uv.y * 9.0 + iTime * 0.5 + sin(uv.x * 15.0 + iTime * 0.2));
    col += 0.4 * sin(iTime * 1.2 + uv.x * 20.0 + uv.y * 10.0);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
