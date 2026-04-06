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

vec2 field_warp(vec2 uv, float scale_var, float time_var) {
    // Enhanced warping pattern from Shader A
    vec2 p = uv * scale_var;
    float offset_x = sin(p.y * 4.0 + time_var * 3.0) * 0.3;
    float offset_y = cos(p.x * 4.0 + time_var * 2.0) * 0.3;
    return vec2(p.x + offset_x, p.y + offset_y);
}

vec2 rotate(vec2 uv, float angle) {
    // Standard rotation
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 radial_grid(vec2 uv) {
    // Creates a structured, repeating grid pattern from Shader A
    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Modulation based on radius and angle
    float grid_scale = 10.0;
    float r_mod = sin(r * grid_scale + iTime * 0.5) * 0.1;
    float angle_mod = cos(angle * grid_scale * 0.8 - iTime * 0.3) * 0.1;

    return vec2(
        uv.x * (1.0 + r_mod) + angle_mod,
        uv.y * (1.0 + r_mod) - angle_mod
    );
}

vec3 color_field_mapping(vec2 uv, vec2 gridCoord, float timeVal) {
    // Color mapping from Shader A
    float d = length(uv - vec2(0.5));
    float base_intensity = 1.0 - pow(d, 2.0);

    // Calculate phase based on grid coordinates and time
    float p1 = gridCoord.x * 5.0 + timeVal * 0.7;
    float p2 = gridCoord.y * 4.0 + timeVal * 0.9;

    // Red channel driven by spatial frequency and time
    float R = sin(p1 * 1.2 + timeVal * 0.5) * 0.5 + 0.5 + base_intensity * 0.3;

    // Green channel driven by interplay of both coordinates
    float G = cos(p2 * 0.9 - timeVal * 0.4) * 0.5 + 0.5 + base_intensity * 0.3;

    // Blue channel driven by distance/central focus
    float B = sin(d * 10.0 + timeVal * 0.2) * 0.3 + 0.5;

    // Final blend and saturation
    vec3 col = vec3(R, G, B);
    return pow(col * base_intensity * 1.5, vec3(0.9));
}

vec2 waveA(vec2 uv)
{
    // Wave function from Shader B
    return uv + vec2(sin(uv.x * 3.0 + iTime * 0.5) * 0.7, cos(uv.y * 2.0 + iTime * 0.8) * 0.3);
}

vec2 waveB(vec2 uv)
{
    // Wave function from Shader B
    return vec2(sin(uv.x * 5.0 + iTime * 1.1) * 0.4, cos(uv.y * 4.0 + iTime * 0.9) * 0.6);
}

vec3 palette(float t)
{
    // Palette function from Shader B
    return vec3(0.1 + 0.8 * sin(t * 1.5 + iTime * 0.3), 0.5 + 0.4 * cos(t * 1.2 + iTime * 0.2), 0.8 + 0.2 * sin(t * 1.8 + iTime * 0.4));
}

vec2 distort(vec2 uv, float t) {
    // Distortion function from Shader B
    float s = sin(t * 0.7) * 0.4 + 0.6;
    float c = cos(t * 0.8) * 0.3 + 0.5;
    float shift = sin(uv.x * 14.0 + t * 0.2) * 0.15;
    float ripple = cos(uv.y * 16.0 - t * 0.4) * 0.1;
    return uv * vec2(s, c) + vec2(shift, ripple);
}

vec3 colorFromUV(vec2 uv, float t) {
    // Color retrieval from Shader B
    float d = sin(uv.x * 5.0 + t * 0.3) * 0.5 + 0.5;
    float e = cos(uv.y * 6.0 - t * 0.4) * 0.5 + 0.5;
    float f = 0.2 + sin(uv.x * 3.0 + uv.y * 2.0 + t * 0.5) * 0.3;
    return vec3(d, e, f);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Normalization and base adjustment
    uv = uv * 2.0 - 1.0;
    uv *= 1.0 + sin(iTime * 0.5) * 0.2;

    // 1. Combined Motion Baseline (Warping and Rotation)
    // Use field_warp (A) for primary movement
    vec2 warp_uv = field_warp(uv, 3.5, iTime * 1.8);

    float angle = iTime * 2.2 + sin(warp_uv.x * 4.0) * 0.5;
    mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 transformed_uv = rot * uv * 1.5;

    // 2. Secondary Distortion (using B's distort)
    vec2 distorted_uv = distort(transformed_uv, iTime);

    // 3. Chain Wave Patterns (using B's wave functions)
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // 4. Structure Modulation (using A's radial_grid)
    vec2 grid_effect = radial_grid(distorted_uv);

    // Combine distortions for final color mapping input
    vec2 final_uv = grid_effect * 0.8 + distorted_uv * 0.2;

    // 5. Color mapping (using A's color_field_mapping)
    vec3 col = color_field_mapping(final_uv, grid_effect, iTime * 0.5);

    // 6. Palette Application (using B's palette)
    float t = final_uv.x * final_uv.y * 4.0 + iTime * 1.2;
    vec3 col_palette = palette(t);

    // Mix base color and palette using time-based flow/warp
    float flow = sin(final_uv.x * 15.0 + iTime * 2.0) * 0.2;
    float warp = cos(final_uv.y * 8.0 + iTime * 1.3) * 0.15;

    vec3 mixed_color = mix(col, col_palette, flow * 0.5 + warp * 0.5);

    // Introduce strong time dependency via chromatic ripple
    vec3 final_color = mixed_color * (1.0 + sin(iTime * 3.0) * 0.1);

    // 7. Advanced R/G/B Sculpting based on distance and internal contrast (from B)
    float radius = length(final_uv);

    // Use the distance and time to define a sharper edge
    float edge_mask = smoothstep(0.01, 0.15, radius * 2.0 + sin(iTime * 1.5)); 

    // R Channel complexity
    float r_wave = sin(final_uv.x * 20.0 + iTime * 2.5) * 0.8;
    final_color.r = mix(final_color.r, r_wave * edge_mask, 0.6);

    // G Channel complexity
    float g_shift = sin(final_uv.y * 10.0 + iTime * 0.8) * 0.5;
    final_color.g = sin(final_uv.x * 22.0 + iTime * 1.5) + g_shift * flow;

    // B Channel definition (using modulated contrast)
    float contrast = smoothstep(0.4, 0.6, abs(final_uv.x * 3.0 - final_uv.y * 1.5));
    final_color.b = 0.4 + contrast * 0.6;

    // Final chromatic shift based on channel interaction and radius
    float complexity = abs(sin((final_color.g * final_color.r) * 150.0) / (1.0 + radius * 5.0));

    // Final manipulation: applying the complexity as a final filter
    final_color.r = mix(final_color.r, 1.0 - complexity, 0.5);
    final_color.b = mix(final_color.b, complexity * 0.5, 0.5);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
