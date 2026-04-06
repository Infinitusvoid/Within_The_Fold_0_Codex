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
    return vec2(sin(uv.x * 10.0 + iTime * 0.5), cos(uv.y * 10.0 + iTime * 0.3));
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 3.0 + iTime * 0.8) * 0.1,
        cos(uv.y * 5.0 + iTime * 0.4) * 0.2
    );
}

vec3 palette(float t)
{
    return vec3(0.1 + 0.4*sin(t + iTime * 0.2), 0.4 + 0.4*cos(t + iTime * 0.1), 0.7 + 0.3*sin(t + iTime * 0.3));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Base Movement (using waveB)
    uv = waveB(uv);

    // Rotation based on position and time
    float angle = iTime * 1.5 + uv.x * 2.0 + uv.y * 1.5;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv *= rotationMatrix;

    // Secondary Distortion (using waveA)
    uv = waveA(uv);

    // Palette calculation
    float t = (uv.x * 3.0 + uv.y) * 10.0 + iTime * 0.5;
    vec3 col = palette(t);

    // Complex color adjustments based on time and position, emphasizing interaction
    col += 0.5 * sin(iTime * 0.5 + uv.x * 5.0 + uv.y * 3.0);
    col += 0.3 * sin(uv.x * 12.0 + iTime * 0.3);
    col += 0.2 * cos(uv.y * 8.0 + iTime * 0.1);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
