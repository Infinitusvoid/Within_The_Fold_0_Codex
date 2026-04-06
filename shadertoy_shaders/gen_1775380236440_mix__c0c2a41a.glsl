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

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 5.0 + iTime * 0.8),
        cos(uv.y * 4.5 - iTime * 0.6)
    );
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 8.0 + iTime * 1.2), cos(uv.y * 5.5 - iTime * 0.7));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.5 + iTime * 0.4);
    float g = 0.4 + 0.6 * cos(t * 1.3 + iTime * 0.25);
    float b = 0.2 + 0.4 * sin(t * 1.8 - iTime * 0.15);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 1.1) * 0.5 + 0.5;
    float c = cos(t * 1.5) * 0.4 + 0.6;
    float shift = sin(uv.x * 12.0 + t * 0.3) * 0.18;
    float ripple = cos(uv.y * 10.0 - t * 0.5) * 0.12;
    return uv * vec2(s, c) + vec2(shift, ripple);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 6.5 + t * 0.4) * 0.5 + 0.5;
    float e = cos(uv.y * 7.5 - t * 0.5) * 0.5 + 0.5;
    float f = 0.2 + sin(uv.x * 3.5 + uv.y * 2.5 + t * 0.6) * 0.35;
    return vec3(d, e, f);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Base normalization
    uv = uv * 2.0 - 1.0;

    // Apply initial timing modulation and structure smoothing
    uv *= 1.0 + sin(iTime * 0.6) * 0.15;

    // 1. Complex Motion Baseline (Rotation based on A structure)
    float angle1 = sin(iTime * 0.5) + uv.x * uv.y * 2.5;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv = rotationMatrix * uv;

    float angle2 = iTime * 0.9 + uv.x * 0.6 + uv.y * 0.4;
    uv = rotate(uv, angle2);

    // 2. Distortion (from A)
    vec2 distorted_uv = distort(uv, iTime);

    // 3. Chain Wave Patterns (Mixing A and B)
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // 4. Material Data Retrieval (from A)
    vec3 col_base = colorFromUV(distorted_uv, iTime);

    // 5. Dynamic Variable Generation ? Palette (from A ? B)
    float t = distorted_uv.x * 8.0 + distorted_uv.y * 4.0 + iTime * 2.0;
    vec3 col_palette = palette(t);

    // Apply flow and warp for mixing (from A, adapted)
    float flow = sin(distorted_uv.x * 20.0 + iTime * 3.0) * 0.3;
    float warp = cos(distorted_uv.y * 9.0 + iTime * 1.5) * 0.15;

    // Mix base color and palette using flow/warp as modulation
    vec3 mixed_color = mix(col_base, col_palette, flow * 0.35 + warp * 0.65);

    // Introduce fractal noise (from B)
    float noise = fract(sin(t * 10.0 + length(distorted_uv) * 30.0) * 43758.5453);

    // Apply color adjustments from B's modulation (using distance/polar concept)
    vec2 center = vec2(0.5);
    vec2 p = distorted_uv - center;
    float r = length(p);
    float theta = atan(p.y, p.x);

    float dist_factor = 1.0 / (r * 2.5 + 1.0);

    float r_mod = sin(t * 4.0 + theta * 11.0) * 0.5 + 0.5;
    float g_mod = cos(t * 3.5 + r * 6.0) * 0.5 + 0.5;
    float b_mod = sin(t * 5.0 + theta * 13.0) * 0.5 + 0.5;

    // Mix base color and palette using B's modulation
    vec3 final_color = mix(mixed_color, col_palette * r_mod + col_palette * g_mod + col_palette * b_mod, 0.5);

    // Apply noise shift
    final_color += noise * 0.1;

    // Apply final ambient lighting based on distance and time (from B)
    float ambient = 0.05 + dist_factor * 1.8;
    final_color *= ambient * (1.0 + sin(t * 3.0));

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
