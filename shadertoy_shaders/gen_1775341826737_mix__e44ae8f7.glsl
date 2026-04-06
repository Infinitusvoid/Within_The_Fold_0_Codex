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

float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float circle(vec2 p, vec2 c, float r)
{
    return length(p - c) - r;
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.8 + iTime * 0.5);
    float g = 0.3 + 0.7 * sin(t * 1.3 + iTime * 0.3);
    float b = 0.1 + 0.6 * cos(t * 1.5 - iTime * 0.2);
    return vec3(r, g, b);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 ripple(vec2 uv) {
    float t = iTime * 2.0;
    float r = length(uv);
    float phase = r * 10.0 + t * 1.5;
    return uv * (1.0 + 0.1 * sin(phase)) + vec2(sin(phase * 0.5), cos(phase * 0.7));
}

vec2 waveA(vec2 uv)
{
    float t = iTime * 0.5;
    return uv + vec2(sin(uv.x * 3.0 + t) * 0.7, cos(uv.y * 2.0 + t) * 0.3);
}

vec2 waveB(vec2 uv)
{
    float t = iTime * 0.5;
    return vec2(sin(uv.x * 5.0 + t * 2.0) * 0.4, cos(uv.y * 4.0 + t * 1.5) * 0.6);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 5.0 + t * 0.3) * 0.5 + 0.5;
    float e = cos(uv.y * 6.0 - t * 0.4) * 0.5 + 0.5;
    float f = 0.2 + sin(uv.x * 3.0 + uv.y * 2.0 + t * 0.5) * 0.3;
    return vec3(d, e, f);
}

vec2 distort_B(vec2 uv, float t) {
    float s = sin(t * 0.7) * 0.4 + 0.6;
    float c = cos(t * 0.8) * 0.3 + 0.5;
    float shift = sin(uv.x * 14.0 + t * 0.2) * 0.15;
    float ripple = cos(uv.y * 16.0 - t * 0.4) * 0.1;
    return uv * vec2(s, c) + vec2(shift, ripple);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Normalize and center coordinates
    uv = uv * 2.0 - 1.0;

    // Time-based initial flow/scaling
    float flow_scale = 1.0 + sin(iTime * 1.5) * 0.5;
    uv *= flow_scale;

    // Complex spatial deformation based on polar coordinates and time (B)
    float angle = atan(uv.y, uv.x) * 3.0 + iTime * 0.5;
    float radius = length(uv);

    // Rotation
    vec2 rotated_uv = rotate(uv, angle);

    // Apply ripple transformation (B)
    vec2 distorted_uv = ripple(rotated_uv);

    // Apply complex distortion chain (A/B blend)
    distorted_uv = distort_B(distorted_uv, iTime);
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // Final radial scaling and shearing (B)
    distorted_uv *= (1.0 + radius * 0.5);
    float shear = radius * 10.0;
    distorted_uv.x += shear;

    // Time-based fluctuation
    distorted_uv.x += sin(iTime * 2.0) * 0.3;
    distorted_uv.y += cos(iTime * 1.8) * 0.3;

    // Material Data Retrieval (B)
    vec3 col_base = colorFromUV(distorted_uv, iTime);

    // Dynamic Palette Application (A/B blend)
    float t = distorted_uv.x * 5.0 + distorted_uv.y * 4.0 + iTime * 1.5;
    vec3 col_palette = palette(t * 0.8);

    // Mix base color and palette using flow/warp as modulation (A)
    float flow = sin(distorted_uv.x * 18.0 + iTime * 3.0) * 0.3;
    float warp = cos(distorted_uv.y * 12.0 + iTime * 2.0) * 0.1;

    vec3 mixed_color = mix(col_base, col_palette, flow * 0.6 + warp * 0.4);

    // Introduce strong time dependency via chromatic ripple (A)
    vec3 final_color = mixed_color * (1.0 + sin(iTime * 4.0) * 0.15);

    // Advanced R/G/B Sculpting based on distance and internal contrast (A)
    float radius_final = length(distorted_uv);

    // Use the distance and time to define a sharper edge
    float edge_mask = smoothstep(0.005, 0.1, radius_final * 3.0 + sin(iTime * 2.0)); 

    // R Channel complexity
    float r_wave = sin(distorted_uv.x * 25.0 + iTime * 2.8) * 0.9;
    final_color.r = mix(final_color.r, r_wave * edge_mask, 0.7);

    // G Channel complexity
    float g_shift = sin(distorted_uv.y * 11.0 + iTime * 1.0) * 0.6;
    final_color.g = sin(distorted_uv.x * 24.0 + iTime * 2.0) + g_shift * flow;

    // B Channel definition (using modulated contrast)
    float contrast = smoothstep(0.35, 0.55, abs(distorted_uv.x * 4.0 - distorted_uv.y * 2.0));
    final_color.b = 0.5 + contrast * 0.5;

    // Final chromatic shift based on channel interaction and radius
    float complexity = abs(sin((final_color.g * final_color.r) * 180.0) / (1.0 + radius_final * 6.0));

    // Final manipulation: applying the complexity as a final filter
    final_color.r = mix(final_color.r, 1.0 - complexity, 0.6);
    final_color.b = mix(final_color.b, complexity * 0.7, 0.5);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
