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

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 0.7) * 0.3 + 0.7;
    float c = cos(t * 0.8) * 0.4 + 0.6;
    return uv * vec2(s, c) + vec2(sin(uv.x * 15.0 + t * 0.5), cos(uv.y * 20.0 - t * 0.6));
}

vec2 wave(vec2 uv)
{
    return vec2(sin(uv.x * 4.0 + iTime * 0.3), cos(uv.y * 2.0 + iTime * 0.6));
}

vec3 palette(float t)
{
    return vec3(0.5 + 0.5 * cos(t + iTime * 0.1), 0.5 + 0.5 * sin(t + iTime * 0.2), 0.5 + 0.5 * cos(t + iTime * 0.3));
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(sin(uv.x * 3.0 + iTime * 0.4) * tan(uv.y * 1.5 + iTime * 0.6), cos(uv.y * 2.5 + iTime * 0.7) * sin(uv.x * 1.2 + iTime * 0.5));
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 4.0 + iTime * 0.2) * cos(uv.y * 2.5 + iTime * 0.4), cos(uv.x * 3.0 + iTime * 0.1) * sin(uv.y * 2.0 + iTime * 0.3));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Center and initial normalization (from B)
    uv = uv * vec2(2.0, 1.0) - vec2(0.5, 0.0);

    // Apply initial distortion from A
    uv = distort(uv, iTime * 0.5);

    // Apply wave effects from both A and B
    vec2 warped_uv = wave(uv);
    warped_uv = waveA(warped_uv);
    warped_uv = waveB(warped_uv);

    // Geometric rotation (from B)
    float angle = iTime * 0.6 + sin(warped_uv.x) * cos(warped_uv.y) * 0.4 + warped_uv.x * warped_uv.y * 0.5;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 final_uv = rotationMatrix * warped_uv;

    // Dynamic scaling and shifts (A's complexity)
    float scaleA = 1.0 + 0.5*cos(iTime * 0.3 + final_uv.x * 3.0);
    float scaleB = 1.0 + 0.5*fract(iTime * 0.4 + final_uv.y * 2.0);

    float warp_intensity = 1.0 + abs(final_uv.x) * 0.5;
    final_uv *= warp_intensity;

    vec2 dynamic_scale = vec2(1.0 + scaleA, 1.0 + scaleA) * vec2(1.0 + scaleB, 1.0 + scaleB);
    final_uv *= dynamic_scale;
    final_uv *= vec2(1.0 + sin(iTime * 0.5), 1.0 + cos(iTime * 0.5));
    final_uv *= 1.0 + sin(iTime * 0.5) * 0.2;

    // Final rotation adjustment
    final_uv = rotate(final_uv, iTime * 0.3 + final_uv.x * 1.5 + final_uv.y * 0.5);

    // Time calculation and palette application
    float t = final_uv.x * final_uv.y * 8.0 + iTime * 0.4;
    vec3 col = palette(t);

    // Complex color mixing (A's formula mixed with B's structure)
    float r_pat = sin(t * 1.5) * 0.5 + 0.5;
    float g_pat = cos(t * 1.2) * 0.5 + 0.5;

    // R component: influenced by radial pattern and final position
    col.r = mix(0.8, 0.2, r_pat) * (0.5 + 0.5 * final_uv.x);

    // G component: influenced by angular pattern and vertical position
    col.g = mix(0.8, 0.2, g_pat) * (0.5 + 0.5 * final_uv.y);

    // B component: based on a different geometric interaction
    col.b = abs(sin(t * 2.0)) * 0.7 + 0.1;
    col.b *= palette(t).b * 1.5;

    // Final subtle adjustment
    float s = cos(final_uv.x * 12.0 + iTime * 0.7);
    float t2 = sin(final_uv.y * 18.0 + iTime * 0.3);
    vec3 col2 = vec3(s, t2, 0.5 + 0.5 * sin(final_uv.x + final_uv.y + iTime * 0.5));
    col = mix(col, col2, 0.3);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
