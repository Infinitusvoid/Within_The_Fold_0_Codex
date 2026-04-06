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

vec2 flow(vec2 uv, float t)
{
    vec2 offset = vec2(
        sin(uv.x * 8.0 + t * 2.0) * 0.5,
        cos(uv.y * 6.0 + t * 1.5) * 0.5
    );
    return uv + offset;
}

vec3 palette(float t)
{
    return vec3(
        0.5 + 0.5 * sin(t * 0.8 + iTime * 0.5),
        0.5 + 0.5 * cos(t * 0.7 + iTime * 0.4),
        0.5 + 0.5 * sin(t * 1.2 + iTime * 0.6)
    );
}

vec2 waveX(vec2 uv)
{
    return uv * 5.0 + vec2(
        sin(uv.x * 10.0 + iTime * 1.5),
        cos(uv.y * 12.0 + iTime * 1.8)
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Flow and distortion
    uv = flow(uv, iTime * 0.5);

    vec2 wave = waveX(uv);

    // Time-based movement and rotation
    float angle = uv.x * 5.0 + uv.y * 5.0 + iTime * 1.5;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv *= rotationMatrix;

    // Secondary modulation
    vec2 warped_uv = flow(uv, iTime * 0.3);

    float t = (warped_uv.x + warped_uv.y) * 8.0 + iTime * 1.0;
    vec3 col = palette(t);

    // Complex color mixing based on time and coordinates
    float f = sin(iTime * 2.5 + warped_uv.x * 7.0);
    float g = cos(iTime * 3.0 + warped_uv.y * 8.0);

    col += 0.8 * f;
    col += 0.6 * g;

    // Add a subtle background gradient based on position
    col += 0.2 * uv.x * 0.5 + 0.2 * uv.y * 0.5;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
