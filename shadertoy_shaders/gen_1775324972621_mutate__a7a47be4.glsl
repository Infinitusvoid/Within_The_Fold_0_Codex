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

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 15.0 + iTime * 1.2), cos(uv.y * 12.0 + iTime * 0.8));
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 5.0 + iTime * 0.5) * 0.25,
        cos(uv.y * 7.0 + iTime * 0.6) * 0.15
    );
}

vec3 palette(float t)
{
    float c = t * 0.5;
    return vec3(
        0.1 + 0.5 * sin(c + iTime * 0.5),
        0.5 + 0.4 * cos(c + iTime * 0.3),
        0.7 + 0.3 * sin(c + iTime * 0.1)
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Base movement (using waveB)
    uv = waveB(uv);

    // Advanced Flow Field Distortion
    float flowX = uv.x * 10.0 + iTime * 2.0;
    float flowY = uv.y * 15.0 + iTime * 1.5;

    // Rotation based on flow and position
    float angle = flowX * 0.5 + flowY * 0.8;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv *= rotationMatrix;

    // Secondary Distortion (using waveA)
    uv = waveA(uv);

    // Palette calculation using combined distortion
    float t = (uv.x * 4.0 + uv.y * 2.0) * 12.0 + iTime * 1.0;
    vec3 col = palette(t);

    // Complex color shifts based on frequency modulation
    float freq = 1.0 + sin(iTime * 1.5);
    col += 0.5 * sin(uv.x * 8.0 * freq + iTime * 0.7);
    col += 0.4 * cos(uv.y * 6.0 * freq + iTime * 0.5);
    col += 0.3 * sin(uv.x * 20.0 + uv.y * 10.0 + iTime * 0.2);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
