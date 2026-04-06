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

    // 1. Complex Motion Baseline (Modified: focusing on amplitude shift)
    float flow_base = sin(iTime * 1.5) * 0.5;
    uv.x += flow_base * 0.5;
    uv.y += flow_base * 0.3;

    // 2. Distortion (Exaggerated internal ripple effect)
    vec2 distorted_uv = distort(uv);

    // 3. Chain Wave Patterns
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // 4. Material Data Retrieval (Combining A and B color derivation)
    vec3 col_base = colorFromUV(distorted_uv, iTime);
    vec2 w = waveB(distorted_uv);
    vec3 wave_color = colorFromWave(w);

    // 5. Dynamic Variable Generation ? Flow Application (New structure focus)
    float t_flow = distorted_uv.x * 5.0 + distorted_uv.y * 5.0 + iTime * 0.5;
    vec3 col_palette = colorFromUV(distorted_uv, t_flow);

    // Apply flow modulation strongly
    float flow = sin(distorted_uv.x * 30.0 + iTime * 2.0) * 0.3;
    float warp = cos(distorted_uv.y * 15.0 + iTime * 1.5) * 0.2;

    // Mix base color and palette, weighted by flow
    vec3 final_color = mix(col_base, col_palette, flow * 0.7);

    // 6. Advanced R/G/B Sculpting (Mixing A's complexity and B's depth interaction)
    float radius = length(distorted_uv);
    float dist_factor = 1.0 - smoothstep(0.0, 0.3, radius * 4.0); 

    // Mix the wave color into the base, highly modulated by distortion depth
    final_color = mix(final_color, wave_color, dist_factor * 0.9);

    // R Channel complexity (High frequency displacement)
    float r_mod = sin(distorted_uv.x * 35.0 + iTime * 1.5) * 2.8;
    final_color.r = mix(final_color.r, r_mod, 0.95);

    // G Channel complexity (mixing wave interaction and radial distortion from B)
    float g_base = sin(distorted_uv.x * 40.0 + iTime * 1.8) * 0.9;
    float g_radial = cos(distorted_uv.y * 15.0 + iTime * 1.0) * dist_factor * 0.4;
    final_color.g = g_base * 0.7 + g_radial;

    // B Channel definition (using sharper contrast)
    float contrast_val = smoothstep(0.2, 0.4, abs(distorted_uv.x * 7.0 - distorted_uv.y * 5.0) * 1.5);
    final_color.b = 0.2 + contrast_val * 0.8;

    // Final texture application using noise combined with time offset
    float texture_val = noise(uv * 40.0 + iTime * 0.7).x * final_color.g * 1.8;

    // Introduce chromatic shift based on channel interactions
    float chromatic_mix = sin(abs(sin((final_color.g * final_color.r) * 120.0 + texture_val * 70.0)) / (final_color.g * 2.5 + final_color.r * 2.0)) * 0.6;
    final_color.b = 0.5 + chromatic_mix;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
