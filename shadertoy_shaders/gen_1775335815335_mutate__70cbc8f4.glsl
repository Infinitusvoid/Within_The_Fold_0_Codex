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
    // Enhanced warping pattern
    vec2 p = uv * scale_var;
    float offset_x = sin(p.y * 4.0 + time_var * 3.0) * 0.3;
    float offset_y = cos(p.x * 4.0 + time_var * 2.0) * 0.3;
    return vec2(p.x + offset_x, p.y + offset_y);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 radial_grid(vec2 uv) {
    // Creates a structured, repeating grid pattern
    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Modulation based on radius and angle
    float grid_scale = 10.0;
    float r_mod = sin(r * grid_scale + iTime * 0.5) * 0.1;
    float angle_mod = cos(angle * grid_scale * 0.8 - iTime * 0.3) * 0.1;

    return vec2(
        uv.x * (1.0 + r_mod * 1.5) + angle_mod * 0.5,
        uv.y * (1.0 + r_mod * 1.5) - angle_mod * 0.5
    );
}

vec3 color_field_mapping(vec2 uv, vec2 gridCoord, float timeVal) {
    // Use trigonometric mixing for color depth and shifting
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
    return pow(col * base_intensity * 1.5, vec3(0.8)); // Adjusted exponent for contrast
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // 1. Primary Warp/Distortion (increased base scale)
    vec2 warp_uv = field_warp(uv, 4.0, iTime * 2.0);

    // 2. Time-based rotation and stretching
    float angle = iTime * 2.2 + sin(warp_uv.x * 5.0) * 0.8; // Increased sensitivity

    mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 transformed_uv = rot * uv * 1.6; // Increased rotation scale

    // 3. Secondary distortion (grid effect based on warped coordinates)
    vec2 grid_effect = radial_grid(transformed_uv);

    // Combine distortions, using grid_effect more heavily for structure
    vec2 final_uv = transformed_uv * 0.7 + grid_effect * 0.3;

    // 4. Color mapping
    vec3 col = color_field_mapping(final_uv, grid_effect, iTime * 0.5);

    // 5. Final scaling and contrast based on frame cycle
    float contrast_factor = 1.0 + sin(iFrame * 0.15) * 0.3;
    col *= contrast_factor * 1.8;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
