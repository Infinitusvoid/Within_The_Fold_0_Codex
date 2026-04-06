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
        sin(uv.x * 8.0 + iTime * 1.5),
        cos(uv.y * 4.0 + iTime * 2.0)
    );
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 15.0 + iTime * 3.0), cos(uv.y * 10.0 - iTime * 1.5));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.8 + iTime * 0.6);
    float g = 0.5 + 0.5 * cos(t * 1.3 + iTime * 0.4);
    float b = 0.3 + 0.4 * sin(t * 2.5 - iTime * 0.2);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 1.3) * 0.7 + 0.3;
    float c = cos(t * 1.7) * 0.6 + 0.4;
    float shift = sin(uv.x * 30.0 + t * 0.5) * 0.2;
    float ripple = cos(uv.y * 20.0 - t * 0.3) * 0.15;
    return uv * vec2(s, c) + vec2(shift * 0.3, ripple * 0.3);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 9.0 + t * 0.4) * 0.5 + 0.5;
    float e = cos(uv.y * 12.0 - t * 0.6) * 0.5 + 0.5;
    float f = 0.2 + sin(uv.x * 6.0 + uv.y * 6.0 + t * 0.8) * 0.4;
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

    // Normalize and initial time warp
    uv = uv * 5.0 - 2.5;
    uv *= 1.0 + sin(iTime * 0.7) * 0.1;

    // 1. Complex Swirl Distortion
    float time_warp = iTime * 1.5;
    vec2 twisted_uv = distort(uv, time_warp);

    // 2. Motion Baseline (Swirling Rotation)
    float angle_base = sin(time_warp * 2.5) + twisted_uv.x * twisted_uv.y * 5.0;
    vec2 rotated_uv = rotate(twisted_uv, angle_base);

    // 3. Apply Wave Patterns (Mixing A and B)
    vec2 waved_uv = waveA(rotated_uv);
    waved_uv = waveB(waved_uv);

    // 4. Material Data Retrieval
    vec3 col_base = colorFromUV(waved_uv, iTime * 0.5);

    // 5. Dynamic Variable Generation ? Palette
    float t_palette = waved_uv.x * 15.0 + waved_uv.y * 7.0 + iTime * 2.0;
    vec3 col_palette = palette(t_palette);

    // Apply dynamic flow and warp based on the structure
    float flow = sin(waved_uv.x * 40.0 + iTime * 5.0) * 0.4;
    float warp = cos(waved_uv.y * 15.0 + iTime * 3.0) * 0.35;

    // Mix base color and palette using flow/warp as modulation
    vec3 mixed_color = mix(col_base, col_palette, flow * 0.6 + warp * 0.4);

    // Introduce fractal noise
    float noise = fract(sin(t_palette * 20.0 + length(waved_uv) * 60.0) * 43758.5453);

    // Apply polar/distance modulation (B's influence)
    vec2 center = vec2(0.5);
    vec2 p = waved_uv - center;
    float r = length(p);
    float theta = atan(p.y, p.x);

    // Inverse distance calculation (modified)
    float dist_factor = 1.0 / (r * 2.5 + 0.3);

    // Modulation based on polar coordinates and time (more complex mix)
    float r_mod = sin(t_palette * 7.0 + theta * 12.0) * 0.5 + 0.5;
    float g_mod = cos(t_palette * 5.5 + r * 10.0) * 0.5 + 0.5;
    float b_mod = sin(t_palette * 9.0 + theta * 18.0) * 0.5 + 0.5;

    // Mix color using the calculated modulation
    vec3 modulated_palette = col_palette * r_mod * 0.7 + col_palette * g_mod * 0.25 + col_palette * b_mod * 0.05;
    vec3 final_color = mix(mixed_color, modulated_palette, 0.65);

    // Apply noise shift
    final_color += noise * 0.15;

    // Final ambient lighting based on distance and time
    float ambient = 0.015 + dist_factor * 1.5;
    final_color *= ambient * (1.0 + sin(t_palette * 4.0));

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
