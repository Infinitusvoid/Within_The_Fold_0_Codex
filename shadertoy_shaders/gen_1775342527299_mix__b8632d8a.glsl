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

vec2 wave(vec2 uv)
{
    return vec2(sin(uv.x * 6.0 + iTime * 0.5), cos(uv.y * 6.0 - iTime * 0.8));
}

vec3 colorFromWave(vec2 w)
{
    float r = 0.15 + 0.8 * sin(w.x * 4.0 + iTime * 0.15);
    float g = 0.3 + 0.7 * cos(w.y * 5.0 + iTime * 0.2);
    float b = 0.5;
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.2;
    float scale = 2.0 + 1.5 * sin(t + uv.x * 30.0);
    float shift = 2.0 + 1.5 * cos(t + uv.y * 25.0);
    uv.x *= scale;
    uv.y *= shift;
    return uv;
}

mat2 rotate(float a)
{
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 wave_B(vec2 uv)
{
    return uv + vec2(sin(uv.x * 7.0 + iTime * 0.6) * tan(uv.y * 1.8 + iTime * 0.9), cos(uv.y * 4.0 + iTime * 1.0) * sin(uv.x * 2.0 + iTime * 0.5));
}

vec3 pattern(vec2 uv, float t)
{
    float g = sin(uv.x * 10.0 + t * 0.7);
    float h = cos(uv.y * 10.0 + t * 0.9);
    float index = (uv.x * 5.0 + uv.y * 5.0) * 15.0 - iTime * 0.04 * t;
    float v = fract(sin(index * 3.0) * 40.0);
    return vec3(g * 0.6, h * 0.4, 0.1 + 0.5 * sin(v + t * 3.0));
}

vec2 curl(vec2 uv)
{
    float angle = iTime * 0.3 + sin(uv.x * 2.0) * cos(uv.y * 2.0);
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    return rotationMatrix * uv;
}

vec2 noise(vec2 uv)
{
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return vec2(sin(6.28318 * (i.x + u.x)), cos(6.28318 * (i.y + u.y)));
}

vec2 fractal_displace(vec2 uv) {
    vec2 p = uv;
    float time_factor = iTime * 0.2;
    float angle = sin(p.y * 0.5 + time_factor);
    p = rotate(angle * 0.5) * p;
    p += vec2(sin(p.x * 3.0) * 0.1 + cos(p.y * 2.0) * 0.1,
               cos(p.x * 2.5) * 0.1 + sin(p.y * 1.5) * 0.1);
    return p;
}

vec2 ripple(vec2 uv)
{
    float r = sin(uv.x * 5.0 + iTime * 1.5);
    float g = cos(uv.y * 6.0 + iTime * 2.0);
    return vec2(r * 0.5 + 0.5, g * 0.5 + 0.5);
}

float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(sin(uv.x * 8.0 + iTime * 1.0) * 0.4, cos(uv.y * 7.0 + iTime * 0.5) * 0.3);
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 5.0 + iTime * 1.5) * cos(uv.y * 4.0), cos(uv.y * 8.0 + iTime * 0.8) * sin(uv.x * 3.0));
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 6.5 + t * 0.4) * 0.5 + 0.5;
    float e = cos(uv.y * 9.5 - t * 0.5) * 0.4 + 0.5;
    float f = 0.2 + sin(uv.x * 4.5 + uv.y * 3.5 + t * 0.6) * 0.3;
    return vec3(d, e, f);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec3 colorFromWave_B(vec2 w)
{
    // Mix modulation styles from B
    float r = 0.1 + 0.6 * sin(w.x * 25.0 + iTime * 0.5);
    float g = 0.4 + 0.5 * cos(w.y * 10.0 - iTime * 0.7);
    float b = 0.3 + 0.3 * sin(w.x * 8.0 + w.y * 4.0 + iTime * 0.2);
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Normalization and initial fractal displacement setup (from A)
    uv = uv * 2.0 - 1.0;
    uv = fractal_displace(uv);
    uv = ripple(uv);

    // 1. Complex Motion Baseline (Rotation based on B structure)
    float angle1 = sin(iTime * 0.5) + uv.x * uv.y * 2.0;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv = rotationMatrix * uv;

    float angle2 = iTime * 0.8 + uv.x * 1.5;
    uv = rotate(uv, angle2);

    // 2. Distortion (Combined A/B distortion)
    vec2 distorted_uv = distort(uv);

    // 3. Chain Wave Patterns (Using A's specific waves combined with B's complex ones)
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // 4. Material Data Retrieval (Combining A and B color derivation)
    vec3 col_base = colorFromUV(distorted_uv, iTime);
    vec2 w = waveB(distorted_uv);
    vec3 wave_color = colorFromWave_B(w);

    // 5. Dynamic Variable Generation ? Flow Application (A's flow structure)
    float t = distorted_uv.x * 4.0 + distorted_uv.y * 5.0 + iTime * 0.5;
    vec3 col_palette = colorFromUV(distorted_uv, t); // Use A's palette structure

    // Apply flow modulation strongly
    float flow = sin(distorted_uv.x * 20.0 + iTime * 2.5) * 0.2;
    float warp = cos(distorted_uv.y * 10.0 + iTime * 1.2) * 0.15;

    // Mix base color and palette, weighted by flow
    vec3 final_color = mix(col_base, col_palette, flow * 0.8);

    // 6. Advanced R/G/B Sculpting (Mixing A's complexity and B's depth interaction)
    float radius = length(distorted_uv);
    float dist_factor = 1.0 - smoothstep(0.0, 0.3, radius * 3.0); 

    // Mix the wave color into the base, highly modulated by distortion depth
    final_color = mix(final_color, wave_color, dist_factor * 0.7);

    // R Channel complexity (High frequency displacement from A)
    float r_mod = sin(distorted_uv.x * 22.0 + iTime * 1.2) * 2.5;
    final_color.r = mix(final_color.r, r_mod, 0.9);

    // G Channel complexity (mixing wave interaction and radial distortion from B)
    float g_base = sin(distorted_uv.x * 30.0 + iTime * 1.8) * 0.8;
    float g_radial = cos(distorted_uv.y * 11.0 + iTime * 1.0) * dist_factor * 0.5;
    final_color.g = g_base + g_radial;

    // B Channel definition (using contrast from A and depth from B)
    float contrast_val = smin(abs(distorted_uv.x * 5.0 - distorted_uv.y * 3.0) * 2.0, 10.0, 3.0); // Using smin helper
    final_color.b = 0.1 + contrast_val * 0.9;

    // Final texture application using B's noise, influenced by G channel
    float texture_val = noise(uv * 20.0 + iTime * 0.5).x * final_color.g * 1.5;

    // Introduce chromatic shift based on channel interactions
    float chromatic_mix = sin(abs(sin((final_color.g * final_color.r) * 120.0 + texture_val * 60.0)) / (final_color.g * 3.0 + final_color.r * 2.5)) * 0.5;
    final_color.b = 0.5 + chromatic_mix;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
