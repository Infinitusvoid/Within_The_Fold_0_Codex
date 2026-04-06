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
    return uv * 2.0 + vec2(
        sin(uv.x * 5.0 + iTime * 0.8) * 0.15,
        cos(uv.y * 4.0 - iTime * 0.6) * 0.18
    );
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 7.0 + iTime * 0.4), cos(uv.y * 5.5 - iTime * 0.3));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.7 + iTime * 0.4);
    float g = 0.4 + 0.6 * cos(t * 1.2 + iTime * 0.2);
    float b = 0.2 + 0.4 * sin(t * 1.5 - iTime * 0.1);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 0.8) * 0.5 + 0.5;
    float c = cos(t * 1.0) * 0.3 + 0.5;
    float shift = sin(uv.x * 10.0 + t * 0.15) * 0.2;
    float ripple = cos(uv.y * 10.0 - t * 0.2) * 0.15;
    return uv * vec2(s, c) + vec2(shift, ripple);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 6.0 + t * 0.2) * 0.5 + 0.5;
    float e = cos(uv.y * 7.0 - t * 0.3) * 0.5 + 0.5;
    float f = 0.2 + sin(uv.x * 3.5 + uv.y * 2.5 + t * 0.5) * 0.3;
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
    float time_factor = iTime * 0.3;
    float angle = sin(p.y * 0.6 + time_factor);
    p = rotate(p, angle * 0.7);
    p += vec2(sin(p.x * 4.5) * 0.15 + cos(p.y * 3.0) * 0.1,
               cos(p.x * 3.5) * 0.1 + sin(p.y * 2.0) * 0.1);
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
    float angle_base = iTime * 2.0;
    float angle_vortex = atan(uv.y, uv.x) * 8.0;

    mat2 rotationMatrix = mat2(cos(angle_base), -sin(angle_base), sin(angle_base), cos(angle_base));
    uv *= rotationMatrix;

    uv = rotate(uv, angle_vortex * 1.2);

    // Wave dynamics generation (Mixing A and B)
    vec2 wave_mix = mix(waveA(uv), waveB(uv), 0.3);
    uv = uv + wave_mix;

    // Color mapping using a dynamic time/position metric
    float t = (uv.x * 9.0 + uv.y * 5.0) * 1.2 + iTime * 2.5;
    vec3 col_palette = palette(t);

    // Flow and warp application
    float flow = sin(uv.x * 22.0 + iTime * 3.0) * 0.35;
    float warp = cos(uv.y * 8.0 + iTime * 1.5) * 0.15;

    // Apply base color and modulation
    vec3 col_base = colorFromUV(uv, iTime);
    vec3 mixed_color = mix(col_base, col_palette, flow * 0.5 + warp * 0.5);

    // Introduce final chromatic ripple
    vec3 final_color = mixed_color * (1.0 + sin(iTime * 4.0) * 0.1);

    // Advanced R/G/B Sculpting
    float radius = length(uv);

    float edge_mask = smoothstep(0.007, 0.15, radius * 3.0 + sin(iTime * 2.5)); 

    // R Channel complexity
    float r_wave = sin(uv.x * 30.0 + iTime * 4.0) * 0.95;
    final_color.r = mix(final_color.r, r_wave * edge_mask, 0.8);

    // G Channel complexity (using waveB influence)
    float g_shift = sin(uv.y * 15.0 + iTime * 1.3) * 0.7;
    final_color.g = sin(uv.x * 25.0 + iTime * 3.5) + g_shift * flow;

    // B Channel definition (using contrast based on UV difference)
    float contrast = smoothstep(0.35, 0.58, abs(uv.x * 5.0 - uv.y * 3.0));
    final_color.b = 0.3 + contrast * 0.8;

    // Final chromatic shift
    float complexity = abs(sin((final_color.g * final_color.r) * 150.0) / (1.0 + radius * 5.0));

    final_color.r = mix(final_color.r, 1.0 - complexity, 0.4);
    final_color.b = mix(final_color.b, complexity * 0.5, 0.5);

    // Apply channel separation based on time
    final_color.r *= 1.0 + sin(iTime * 2.0) * 0.08;
    final_color.g *= 1.0 - cos(iTime * 1.5) * 0.07;
    final_color.b *= 1.0 + sin(iTime * 3.0) * 0.05;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
