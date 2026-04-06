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
        sin(uv.x * 10.0 + iTime * 2.0) * 0.15,
        cos(uv.y * 12.0 - iTime * 1.5) * 0.1
    );
}

vec2 waveB(vec2 uv)
{
    return vec2(
        sin(uv.x * 14.0 + iTime * 0.9) * 0.2,
        cos(uv.y * 7.5 - iTime * 0.5) * 0.25
    );
}

vec3 palette(float t)
{
    float r = 0.2 + 0.7 * sin(t * 1.1 + iTime * 0.5);
    float g = 0.8 * cos(t * 1.8 - iTime * 0.3);
    float b = 0.1 + 0.6 * sin(t * 2.5 + iTime * 0.8);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 0.8) * 0.6 + 0.4;
    float c = cos(t * 0.9) * 0.5 + 0.5;
    float shift = sin(uv.x * 15.0 + t * 0.4) * 0.3;
    float ripple = cos(uv.y * 9.0 - t * 0.6) * 0.2;
    return uv * vec2(s, c) + vec2(shift * 0.6, ripple);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 6.0 + t * 0.3) * 0.5 + 0.4;
    float e = cos(uv.y * 8.0 - t * 0.5) * 0.5 + 0.4;
    float f = 0.5 + sin(uv.x * 3.0 + uv.y * 3.5 + t * 0.7) * 0.2;
    return vec3(d, e, f);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 5.5 + iTime * 1.5) * 0.1,
        cos(uv.y * 6.5 + iTime * 1.0) * 0.15
    );
}

vec2 flowB(vec2 uv)
{
    return vec2(
        sin(uv.x * 7.0 + iTime * 1.0) * 0.3,
        cos(uv.y * 8.0 + iTime * 0.8) * 0.25
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Flow distortion (B style)
    uv = flowB(uv);

    // High frequency phase shifting
    float phase = uv.x * 6.0 + uv.y * 8.0 + iTime * 2.0;
    uv = uv + vec2(
        sin(phase * 0.3) * 0.25,
        cos(phase * 0.3) * 0.15
    );

    // Time-based rotation
    float angle = iTime * 3.0 + uv.x * 2.0 + uv.y * 2.0;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv *= rotationMatrix;

    // Aggressive Distortion
    vec2 distorted_uv = distort(uv, iTime * 1.5);

    // Chain Wave Patterns (Mixing A and B)
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // Material Data Retrieval
    vec3 col_base = colorFromUV(distorted_uv, iTime);

    // Dynamic Palette Generation
    float t = (distorted_uv.x * 8.0 + distorted_uv.y) * 15.0 + iTime * 1.0;
    vec3 col_palette = palette(t);

    // Mix base color and palette using flow modulation
    float flow_mix = sin(distorted_uv.x * 20.0 + iTime * 3.5) * 0.3;
    float warp_mix = cos(distorted_uv.y * 10.0 + iTime * 2.0) * 0.2;

    vec3 mixed_color = mix(col_base, col_palette, flow_mix * 0.7 + warp_mix * 0.3);

    // Introduce strong time dependency
    vec3 final_color = mixed_color * (1.0 + sin(iTime * 5.0) * 0.2);

    // Advanced R/G/B Sculpting (High contrast edge detection)
    float radius = length(distorted_uv);
    float edge_mask = smoothstep(0.002, 0.05, radius * 4.0 + sin(iTime * 4.0)); 

    // R Channel complexity
    float r_wave = sin(distorted_uv.x * 40.0 + iTime * 5.0) * 1.2;
    final_color.r = mix(final_color.r, r_wave * edge_mask, 0.9);

    // G Channel complexity (enhanced vertical shift)
    float g_shift = sin(distorted_uv.y * 20.0 + iTime * 3.0) * 0.8;
    final_color.g = sin(distorted_uv.x * 35.0 + iTime * 4.0) + g_shift * flow_mix;

    // B Channel definition (using complex contrast)
    float contrast = smoothstep(0.2, 0.4, abs(distorted_uv.x * 7.0 - distorted_uv.y * 5.0));
    final_color.b = 0.05 + contrast * 0.9;

    // Final chromatic shift based on channel interaction
    float complexity = abs(sin((final_color.r * 2.0 + final_color.g) * 180.0) / (1.0 + radius * 6.0));

    // Final manipulation
    final_color.r = mix(final_color.r, 1.0 - complexity * 0.9, 0.6);
    final_color.b = mix(final_color.b, complexity * 0.4, 0.5);

    // Apply vertical channel modulation
    final_color.r *= 1.0 + sin(iTime * 2.8) * 0.15;
    final_color.g *= 1.0 - cos(iTime * 1.5) * 0.12;
    final_color.b *= 1.0 + sin(iTime * 3.2) * 0.1;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
