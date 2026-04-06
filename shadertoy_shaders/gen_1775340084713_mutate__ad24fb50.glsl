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
    float t = iTime * 0.8;
    float w1 = sin(uv.x * 10.0 + t * 1.5) * 0.5;
    float w2 = cos(uv.y * 8.0 + t * 1.2) * 0.4;
    float w3 = sin(length(uv) * 4.0 + t * 2.0) * 0.3;
    return vec2(w1 * 0.7 + w3 * 0.3, w2 * 0.6 + w3 * 0.4);
}

float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float circle(vec2 p, vec2 c, float r)
{
    return length(p - c) - r;
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(sin(uv.x * 8.0 + iTime * 1.0) * 0.4, cos(uv.y * 7.0 + iTime * 0.5) * 0.3);
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 5.0 + iTime * 1.5) * cos(uv.y * 4.0), cos(uv.y * 8.0 + iTime * 0.8) * sin(uv.x * 3.0));
}

float palette(float t)
{
    return 0.5 + 0.5 * sin(t * 3.0);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.4;
    float scale = 1.0 + 0.05 * sin(t + uv.x * 10.0);
    float shift = 1.0 + 0.04 * cos(t + uv.y * 8.0);
    uv.x *= scale;
    uv.y *= shift;
    uv.x += sin(uv.y * 6.0 + t * 4.0) * 0.2;
    uv.y += cos(uv.x * 7.0 + t * 1.8) * 0.15;
    return uv;
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 6.5 + t * 0.4) * 0.5 + 0.5;
    float e = cos(uv.y * 9.5 - t * 0.5) * 0.4 + 0.5;
    float f = 0.2 + sin(uv.x * 4.5 + uv.y * 3.5 + t * 0.6) * 0.3;
    return vec3(d, e, f);
}

vec2 noise(vec2 uv)
{
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return vec2(sin(6.28318 * (i.x + u.x)), cos(6.28318 * (i.y + u.y)));
}

vec3 colorFromWave(vec2 w)
{
    float r = 0.1 + 0.6 * sin(w.x * 25.0 + iTime * 0.5);
    float g = 0.4 + 0.5 * cos(w.y * 10.0 - iTime * 0.7);
    float b = 0.3 + 0.3 * sin(w.x * 8.0 + w.y * 4.0 + iTime * 0.2);
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Normalize and base inversion setup
    uv = uv * 2.0 - 1.0;

    // Apply initial timing modulation and structure smoothing
    uv *= 1.0 + sin(iTime * 0.7) * 0.25;

    // 1. Complex Motion Baseline (Focusing on rotational flow)
    float flow_rot = sin(iTime * 2.5) * 0.4;
    uv = rotate(uv, flow_rot * 1.5);

    // 2. Distortion and ripple interaction
    vec2 distorted_uv = distort(uv);

    // 3. Chain Wave Patterns
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // 4. Material Data Retrieval
    vec3 col_base = colorFromUV(distorted_uv, iTime * 0.5);
    vec2 w = waveB(distorted_uv);
    vec3 wave_color = colorFromWave(w);

    // 5. Dynamic Variable Generation (Introducing radial feedback)
    float r_depth = length(distorted_uv);
    float radial_focus = 1.0 - smoothstep(0.0, 0.2, r_depth * 5.0);

    // Mix base color and wave color, weighted by radial focus
    vec3 final_color = mix(col_base, wave_color, radial_focus * 0.8);

    // 6. Sculpting the Channels (Focus on texture mixing)

    // R Channel modulation (high frequency displacement based on flow)
    float r_mod = sin(distorted_uv.x * 45.0 + iTime * 2.0) * 2.5;
    final_color.r = mix(final_color.r, r_mod, 0.8);

    // G Channel complexity (mixing wave interaction and radial distortion)
    float g_base = cos(distorted_uv.y * 10.0 + iTime * 1.0) * 0.9;
    float g_ripple = sin(r_depth * 30.0) * 0.3;
    final_color.g = g_base + g_ripple;

    // B Channel definition (using chromatic density)
    float density = abs(distorted_uv.x * 7.0 + distorted_uv.y * 5.0);
    float contrast_val = smoothstep(0.0, 1.0, density * 1.5);
    final_color.b = 0.1 + contrast_val * 0.9;

    // Final texture application using noise driven by flow
    vec2 flow_noise_uv = uv * 8.0 + iTime * 1.5;
    float texture_val = noise(flow_noise_uv * 4.0).x * 1.5;

    // Introduce chromatic shift based on channel interactions
    float chromatic_mix = sin(final_color.r * final_color.g * 2.0 + texture_val * 10.0) * 0.7;
    final_color.b = mix(final_color.b, 0.7 + chromatic_mix, 0.5);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
