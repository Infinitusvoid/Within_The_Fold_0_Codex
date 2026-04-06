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
        sin(uv.x * 10.0 + t),
        cos(uv.y * 8.0 + t * 0.5)
    );
    return uv + offset * 0.5;
}

vec3 palette(float t)
{
    vec3 c = vec3(
        0.5 + 0.5 * sin(t * 0.6 + iTime * 0.5),
        0.5 + 0.5 * cos(t * 0.7 + iTime * 0.4),
        0.5 + 0.5 * sin(t * 1.0 + iTime * 0.7)
    );
    return c;
}

vec2 swirl(vec2 uv, float t)
{
    vec2 offset = vec2(
        sin(uv.x * 12.0 + t * 2.0),
        cos(uv.y * 15.0 + t * 2.5)
    );
    return uv + offset;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Base flow and distortion
    vec2 warped_uv = swirl(uv, iTime * 0.5);

    // Rotation and primary wave
    float angle = warped_uv.x * 10.0 + warped_uv.y * 10.0 + iTime * 1.2;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 rotated_uv = rotationMatrix * warped_uv;

    // Secondary modulation based on flow
    vec2 flow_offset = flow(rotated_uv, iTime * 0.3);

    // Time-based modulation parameter
    float t = (flow_offset.x * 5.0 + flow_offset.y * 5.0) * 5.0 + iTime * 1.5;
    vec3 col = palette(t);

    // Complex color mixing using phase shifts
    float red_shift = sin(iTime * 4.0 + rotated_uv.x * 3.0);
    float green_shift = cos(iTime * 3.5 + rotated_uv.y * 4.0);

    col.r = mix(col.r, 0.5 + 0.5 * red_shift, 0.5);
    col.g = mix(col.g, 0.5 + 0.5 * green_shift, 0.5);
    col.b = mix(col.b, 0.5 + 0.5 * sin(iTime * 2.0 + rotated_uv.x * 1.5), 0.5);

    // Add subtle radial gradient
    float dist = length(rotated_uv - 0.5);
    col += (1.0 - dist) * 0.3;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
