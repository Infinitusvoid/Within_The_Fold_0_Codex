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
    return uv * 3.0 + vec2(
        sin(uv.x * 6.0 + iTime * 1.0) * 0.2,
        cos(uv.y * 4.5 - iTime * 0.7) * 0.2
    );
}

vec2 waveB(vec2 uv)
{
    return vec2(cos(uv.x * 8.0 + iTime * 0.5), sin(uv.y * 6.0 - iTime * 0.9));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 1.1 + iTime * 0.5);
    float g = 0.3 + 0.6 * cos(t * 1.4 - iTime * 0.3);
    float b = 0.1 + 0.5 * sin(t * 1.8 + iTime * 0.6);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 1.0) * 0.6 + 0.4;
    float c = cos(t * 1.2) * 0.3 + 0.4;
    float shift = sin(uv.x * 12.0 + t * 0.1) * 0.25;
    float ripple = cos(uv.y * 11.0 - t * 0.3) * 0.1;
    return uv * vec2(s, c) + vec2(shift, ripple);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 7.0 + t * 0.3) * 0.5 + 0.5;
    float e = cos(uv.y * 8.0 - t * 0.4) * 0.5 + 0.5;
    float f = 0.2 + sin(uv.x * 4.0 + uv.y * 3.0 + t * 0.6) * 0.3;
    return vec3(d, e, f);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
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
    float time_factor = iTime * 0.4;
    float angle = sin(p.y * 5.0 + time_factor * 0.8);
    p = rotate(p, angle * 0.8);
    p += vec2(sin(p.x * 5.5) * 0.1 + cos(p.y * 4.0) * 0.15,
               cos(p.x * 4.5) * 0.1 + sin(p.y * 3.5) * 0.1);
    return p;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Initial setup using fractal displacement and distortion
    uv = uv * 2.0 - 1.0;
    uv = fractal_displace(uv);
    uv = distort(uv, iTime);

    // Rotational setup
    float angle_base = iTime * 3.0;
    float angle_vortex = atan(uv.y, uv.x) * 10.0;

    mat2 rotationMatrix = mat2(cos(angle_base), -sin(angle_base), sin(angle_base), cos(angle_base));
    uv *= rotationMatrix;

    uv = rotate(uv, angle_vortex * 1.5);

    // Wave dynamics generation (Mixing A and B)
    vec2 wave_mix = mix(waveA(uv), waveB(uv), 0.5);
    uv = uv + wave_mix;

    // Color mapping using a dynamic time/position metric
    float t = (uv.x * 8.0 + uv.y * 5.0) * 1.5 + iTime * 3.0;
    vec3 col_palette = palette(t);

    // Flow and warp application
    float flow = sin(uv.x * 20.0 + iTime * 3.5) * 0.4;
    float warp = cos(uv.y * 10.0 + iTime * 2.0) * 0.18;

    // Apply base color and modulation
    vec3 col_base = colorFromUV(uv, iTime);
    vec3 mixed_color = mix(col_base, col_palette, flow * 0.6 + warp * 0.4);

    // Introduce final chromatic ripple
    vec3 final_color = mixed_color * (1.0 + sin(iTime * 5.0) * 0.15);

    // Advanced R/G/B Sculpting
    float radius = length(uv);

    float edge_mask = smoothstep(0.005, 0.12, radius * 4.0 + sin(iTime * 2.8)); 

    // R Channel complexity (Influenced by waveA)
    float r_wave = sin(uv.x * 35.0 + iTime * 5.0) * 0.9;
    final_color.r = mix(final_color.r, r_wave * edge_mask, 0.75);

    // G Channel complexity (using waveB influence and flow)
    float g_shift = sin(uv.y * 20.0 + iTime * 1.5) * 0.7;
    final_color.g = sin(uv.x * 25.0 + iTime * 4.0) + g_shift * flow * 0.8;

    // B Channel definition (using contrast based on rotation)
    float contrast = smoothstep(0.4, 0.6, abs(uv.x * 6.0 - uv.y * 4.0));
    final_color.b = 0.3 + contrast * 0.9;

    // Final chromatic shift based on complexity and radius
    float complexity = abs(sin((final_color.g * final_color.r) * 120.0) / (1.0 + radius * 6.0));

    final_color.r = mix(final_color.r, 1.0 - complexity, 0.35);
    final_color.b = mix(final_color.b, complexity * 0.6, 0.5);

    // Apply channel separation based on time
    final_color.r *= 1.0 + sin(iTime * 2.5) * 0.1;
    final_color.g *= 1.0 - cos(iTime * 2.0) * 0.12;
    final_color.b *= 1.0 + sin(iTime * 3.5) * 0.08;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
