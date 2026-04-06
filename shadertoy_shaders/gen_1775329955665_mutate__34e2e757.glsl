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

vec2 map(vec2 uv)
{
    float t = iTime * 0.5;
    uv *= vec2(1.0 + 0.04 * sin(t + uv.x * 12.0), 1.0 + 0.04 * cos(t + uv.y * 18.0));
    uv.x += sin(uv.y * 8.0 + t * 2.5) * 0.12;
    uv.y += cos(uv.x * 4.0 + t) * 0.08;
    return uv;
}

vec2 wave(vec2 uv)
{
    float t = iTime * 1.2;
    return vec2(sin(uv.x * 10.0 + t * 1.8), cos(uv.y * 7.5 - t * 0.9));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 1.5 + iTime * 0.2);
    float g = 0.4 + 0.5 * sin(t * 1.1 + iTime * 0.15);
    float b = 0.3 + 0.6 * cos(t * 1.3 + iTime * 0.3);
    return vec3(r, g, b);
}

mat2 rotate(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 rotate_vu(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 noise(vec2 uv)
{
    return vec2(sin(uv.x * 6.0 + iTime * 0.3), cos(uv.y * 9.0 - iTime * 0.6));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Initial warp and noise
    vec2 pos = uv * 3.0 + iTime * 1.0;
    vec2 distortion = noise(pos * 2.0);
    vec2 warped_uv = uv + distortion * 0.15;

    vec2 p = warped_uv;

    // Geometric Distortion based on map
    p = map(p);

    // Complex Dynamic Rotation
    float angle1 = sin(iTime * 0.5) + p.x * p.y * 4.0;
    p = rotate_vu(p, angle1);

    float angle2 = iTime * 0.7 + p.x * 2.0 + p.y * 1.0;
    p = rotate_vu(p, angle2);

    // Apply internal motion based on results
    p += vec2(
        sin(p.x * 1.8 + iTime * 0.8),
        cos(p.y * 2.2 + iTime * 0.5) * 0.5
    );

    // Apply final wave mapping
    p = wave(p);

    // Coordinate lookup and coloring input
    float flow_time = p.x * 6.0 + p.y * 5.0 + iTime * 2.5;

    vec3 col = palette(flow_time * 0.5);

    // Complex modulation
    float amplitude = sin(p.x * 15.0 + iTime * 1.5);
    float phase = cos(p.y * 10.0 + iTime * 2.0);

    col += 0.6 * amplitude * phase;
    col += 1.0 * sin(p.x * 8.0 + iTime * 0.5);

    // Density modulation
    float density = smoothstep(0.35, 0.55, p.y * 2.5 - 1.0);

    col.r = density;
    col.g = sin(p.x * 18.0 + iTime * 0.6);

    // Pattern generation
    col.b = 0.3 + 0.5 * abs(sin((col.g * col.r * 50.0 + p.y * flow_time) * cos(p.x * iTime * 4.0)) / sin(col.g * 3.0 + p.x * flow_time * 0.7));

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
