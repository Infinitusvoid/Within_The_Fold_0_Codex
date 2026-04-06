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

vec2 waveA(vec2 uv) {
    uv += vec2(sin(uv.x * 6.0 + iTime * 0.5), cos(uv.y * 4.0 + iTime * 0.2));
    uv += vec2(cos(uv.x * 5.0 + iTime * 0.6), sin(uv.y * 3.5 + iTime * 0.3));
    uv = vec2(sin(uv.x * 7.0 + iTime * 0.1), cos(uv.y * 5.0 + iTime * 0.5));
    uv = vec2(cos(uv.x * 4.5 + iTime * 0.7), sin(uv.y * 2.0 + iTime * 0.4));
    uv += vec2(tan(uv.x * (4.0 + sin(iTime * 0.3))) * 0.1, tan(uv.y * (2.5 + sin(iTime * 0.3))) * 0.05);
    return uv;
}

vec2 waveB(vec2 uv) {
    return vec2(sin(uv.x * 10.0 + iTime * 0.5), cos(uv.y * 15.0 - iTime * 0.4));
}

vec3 palette(float t) {
    float r = 0.1 + 0.9 * sin(t * 0.6 + iTime * 0.5);
    float g = 0.8 - 0.5 * cos(t * 1.2 - iTime * 0.3);
    float b = 0.3 + 0.7 * sin(t * 2.0 + iTime * 0.1);
    return vec3(r, g, b);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 8.0 + t * 0.4) * 0.5 + 0.5;
    float e = cos(uv.y * 9.0 - t * 0.5) * 0.4 + 0.6;
    float f = 0.1 + sin(uv.x * 2.0 + uv.y * 2.0 + t * 0.8) * 0.5;
    return vec3(d, e, f);
}

vec2 xoffset(vec2 uv, float t) {
    float s = sin(t * 0.6) * 0.4 + 0.5;
    float c = cos(t * 0.7) * 0.3 + 0.7;
    float shift = sin(uv.x * 25.0 + t * 0.1) * 0.15;
    float ripple = cos(uv.y * 30.0 - t * 0.5) * 0.1;
    return uv * vec2(s, c) + vec2(shift * 0.3, ripple * 0.15);
}

mat2 rotate(vec2 uv, float angle) {
    return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // Map coordinates to[-1, 1] centered
    uv = uv * 2.0 - 1.0;

    // Apply complex distortion first
    vec2 s = xoffset(uv, iTime);
    vec2 distorted_uv = s;

    // Combine patterns (Mixing waveA derived components B and waveB)
    vec2 w1 = waveA(distorted_uv);
    vec2 w2 = waveB(distorted_uv);
    vec2 combined_wave = mix(w1, w2, 0.3);

    // Create warp based position
    vec2 warped_uv = xoffset(combined_wave, iTime * 0.8);

    // Apply dynamic scaling/warping effects
    float scale = 1.0 + 0.3 * sin(iTime * 1.5);
    vec2 dynamic_scale = vec2(scale, scale);
    vec2 final_uv = warped_uv * dynamic_scale;

    // Additional time modulation
    final_uv *= vec2(1.0 + cos(iTime * 0.8), 1.0 + sin(iTime * 0.6));
    final_uv *= 1.0 + sin(iTime * 0.5) * 0.15;

    // Rotation logic using UVs as input to rotation definition
    float angle = iTime * 0.5 + final_uv.x * 5.0 + final_uv.y * 3.0;
    mat2 rot = rotate(final_uv, angle);
    final_uv = rot * final_uv;

    // Time calculation for patterning parameters
    float t = final_uv.x * final_uv.y * 10.0 + iTime * 0.3;

    // Apply combined coloration logic
    vec3 col_base = colorFromUV(combined_wave, iTime);
    vec3 col_palette = palette(t);

    // Final Chromatic Mixing
    float r_mix = mix(col_palette.r, col_base.r * 0.8 + 0.2, 0.6);
    float g_mix = col_palette.g * 0.5 + col_base.g * 0.5;
    float b_mix = col_palette.b * 1.1 + sin(final_uv.x * 15.0 + iTime * 0.4);

    fragColor = vec4(r_mix, g_mix, b_mix, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
