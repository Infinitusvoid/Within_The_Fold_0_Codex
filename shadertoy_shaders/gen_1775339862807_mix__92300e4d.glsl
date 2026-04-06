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
    return uv * 2.5 + vec2(sin(uv.x * 15.0 + iTime * 1.5) * 0.5, cos(uv.y * 20.0 + iTime * 2.0) * 0.4);
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 10.0 + iTime * 3.0) * cos(uv.y * 5.0), cos(uv.x * 12.0 + iTime * 1.0) * sin(uv.y * 6.0));
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

float palette(float t)
{
    return 0.5 + 0.5 * sin(t * 8.0 + 1.0);
}

vec3 palette_full(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.8 + iTime * 0.5);
    float g = 0.3 + 0.7 * sin(t * 1.3 + iTime * 0.3);
    float b = 0.1 + 0.6 * cos(t * 1.5 - iTime * 0.2);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.4;
    float scale = 1.0 + 0.05 * sin(t + uv.x * 15.0);
    float shift = 1.0 + 0.07 * cos(t + uv.y * 12.0);
    uv.x *= scale;
    uv.y *= shift;
    uv.x += sin(uv.y * 9.0 + t * 6.0) * 0.4;
    uv.y += cos(uv.x * 10.0 + t * 3.0) * 0.3;
    return uv;
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.6;
    return vec2(
        sin(uv.x * 20.0 + t * 7.0),
        cos(uv.y * 12.0 + t * 5.0)
    );
}

vec2 noise(vec2 uv)
{
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return vec2(sin(6.28318 * (i.x + u.x)), cos(6.28318 * (i.y + u.y)));
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 6.0 + t * 0.5) * 0.5 + 0.5;
    float e = cos(uv.y * 15.0 - t * 0.6) * 0.4 + 0.5;
    float f = 0.2 + sin(uv.x * 5.0 + uv.y * 7.0 + t * 0.7) * 0.3;
    return vec3(d, e, f);
}

vec3 colorFromWave(vec2 w)
{
    float r = 0.5 + 0.5 * sin(w.x * 30.0 + iTime * 0.3);
    float g = 0.05 + 0.9 * sin(w.y * 15.0 - iTime * 0.5);
    float b = 0.8 - 0.5 * cos(w.x * 10.0 + w.y * 5.0 + iTime * 0.1);
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // --- Shader A components (Geometric filtering) ---
    // Geometric shape mask based on circle distance
    float x_offset = 0.3 * sin(iTime * 1.8);
    float d1 = circle(uv, vec2(-x_offset, 0.0), 0.18);
    float d2 = circle(uv, vec2( x_offset, 0.0), 0.18);
    float d = smin(d1, d2, 0.12);
    float shape_mask = smoothstep(0.01, 0.0, d);

    // --- Shader B components (Waving, Flow, Palette) ---

    // Initial wave structure based on waveB
    vec2 warped_uv = waveB(uv * 1.5);

    // Apply rotational flow based on complex angle
    float angle = iTime * 0.3 + uv.x * 7.0;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    warped_uv = rotationMatrix * warped_uv;

    // Apply secondary wave structure based on waveA
    warped_uv = waveA(warped_uv * 1.1);

    // Apply spatial flow based on time and position
    float flow_x = iTime * 0.6 + uv.x * 4.5;
    float flow_y = iTime * 0.4 + uv.y * 6.0;

    // Use flow for positional shifting
    warped_uv.x += sin(flow_x * 0.8) * 0.10;
    warped_uv.y += cos(flow_y * 0.7) * 0.10;

    // Generate dynamic value based on complex interaction
    float t = sin(warped_uv.x * 6.0 + iTime * 2.0) * 0.5 + cos(warped_uv.y * 5.0 + iTime * 0.5) * 0.5;

    // Base color derived from complex time modulation
    vec3 col1 = palette_full(t * 2.0);

    // Introduce a secondary color influence based on flow
    float flow_influence = sin(flow_x * 1.5) * 0.3 + cos(flow_y * 1.2) * 0.2;
    vec3 col2 = palette_full(flow_influence + warped_uv.y * 0.4);

    // Blend colors based on flow interaction
    vec3 final_color = mix(col1, col2, flow_influence * 0.7);

    // Introduce a color shift based on UV position (chromatic aberration style)
    vec3 uv_shift = vec3(uv.x * 0.1, uv.y * 0.15, 0.0);
    final_color += uv_shift * 0.1;

    // Fractal noise based on high frequency interaction
    float noise_factor = sin(warped_uv.x * 12.0 + iTime * 2.5) * cos(warped_uv.y * 8.0 - iTime * 1.0);

    // --- Final Integration ---

    // Apply the geometric shape mask derived from Shader A
    final_color *= (1.0 - shape_mask) * 0.5 + shape_mask * 1.5;

    // Apply noise and contrast boost
    final_color = mix(final_color, vec3(0.1, 0.05, 0.0), noise_factor * 0.7);

    // Final intensity adjustment
    final_color *= 1.2;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
