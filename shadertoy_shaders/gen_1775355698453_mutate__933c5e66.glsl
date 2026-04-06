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

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 15.0 + iTime * 2.0), cos(uv.y * 12.0 - iTime * 2.5));
}

vec2 waveA(vec2 uv)
{
    return uv * 2.5 + vec2(
        sin(uv.x * 9.0 + iTime * 1.1) * 0.4,
        cos(uv.y * 8.0 - iTime * 1.5) * 0.3
    );
}

vec3 palette(float t)
{
    float r = 0.1 + 0.6 * sin(t * 0.8 + iTime * 0.5);
    float g = 0.3 + 0.7 * cos(t * 1.3 + iTime * 0.3);
    float b = 0.1 + 0.4 * sin(t * 1.5 - iTime * 0.2);
    return vec3(r, g, b);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave_B(vec2 uv) {
    float t = iTime * 1.2;
    // Combine timing shifts
    return vec2(sin(uv.x * 11.0 + t * 2.0), cos(uv.y * 9.0 - t * 1.5));
}

vec3 colorFromWave(vec2 w)
{
    // Mix modulation styles
    float r = 0.2 + 0.5 * sin(w.x * 30.0 + iTime * 0.5);
    float g = 0.5 + 0.3 * cos(w.y * 15.0 - iTime * 0.7);
    float b = 0.1 + 0.5 * sin(w.x * 10.0 + w.y * 5.0 + iTime * 0.2);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.5;
    // Combine motion and scale effects
    float scale = 1.0 + 0.03 * sin(t + uv.x * 12.0);
    float shift = 1.0 + 0.05 * cos(t + uv.y * 9.0);
    uv.x *= scale;
    uv.y *= shift;
    // Add coupling derived from waveA
    uv.x += sin(uv.y * 10.0 + t * 3.0) * 0.15;
    uv.y += cos(uv.x * 7.0 + t * 2.0) * 0.1;
    return uv;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // 1. Calculate base wave structure
    vec2 base_wave = waveB(uv);
    vec2 wave_A_shift = waveA(base_wave);

    // 2. Apply distortion
    uv = distort(uv);

    // 3. Rotational flow based on time and position
    float t = iTime * 3.5;
    float flow_field = sin(uv.x * 40.0 + t * 3.0) * 0.6;
    float rot_angle = t * 1.2 + sin(uv.y * 20.0) * 1.0;

    vec2 rotated_uv = rotate(uv, rot_angle);

    // 4. Color generation based on wave structure
    vec3 base_color = colorFromWave(wave_A_shift);

    // 5. Layered modulation and depth calculation
    float depth = rotated_uv.y * 5.0 + flow_field * 10.0;

    // Intensity modulation based on wave and depth interaction
    float intensity = 1.0 - abs(sin(base_wave.x * 20.0 + depth * 2.5 + t * 0.5)) * 0.5;

    // Calculate refracted colors and applying flow complexity
    vec3 refracted_color = base_color * (0.5 + 0.5 * flow_field);

    // Subtle depth visualization offset
    float shift = sin(depth * 5.0) * 0.4;
    refracted_color.r += shift * 1.0;
    refracted_color.g -= shift * 1.5;
    refracted_color.b += cos(rotated_uv.x * 11.0) * 0.3;

    // 6. Final color mixing and enhancement
    vec3 final_col = refracted_color;

    // Final trigonometric mapping
    final_col.r = sin(final_col.g * 2.5 + iTime * 1.0);
    final_col.g = cos(final_col.r * 3.0 + rotated_uv.y * 15.0 + t * 0.7);
    final_col.b = 0.5 + 0.5 * sin(base_wave.x * 10.0 + depth / 5.0 + iTime * 0.4);

    // Apply dynamic layering scale
    final_col = final_col * intensity;

    fragColor = vec4(final_col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
