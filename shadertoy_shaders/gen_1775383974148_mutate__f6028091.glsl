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
        sin(uv.x * 5.0 + iTime * 0.5) * 0.15,
        cos(uv.y * 6.0 - iTime * 0.7) * 0.10
    );
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 10.0 + iTime * 1.2), cos(uv.y * 7.0 - iTime * 0.5));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 1.0 + iTime * 0.4);
    float g = 0.1 + 0.5 * sin(t * 0.7 + iTime * 0.2);
    float b = 0.8 + 0.1 * cos(t * 1.5 - iTime * 0.1);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 1.2) * 0.4 + 0.6;
    float c = cos(t * 1.0) * 0.5 + 0.5;
    float shift = sin(uv.x * 20.0 + t * 0.15) * 0.08;
    float ripple = cos(uv.y * 15.0 - t * 0.2) * 0.12;
    return uv * vec2(s, c) + vec2(shift, ripple);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 8.0 + t * 0.1) * 0.5 + 0.5;
    float e = cos(uv.y * 9.0 - t * 0.15) * 0.5 + 0.5;
    float f = 0.4 + sin(uv.x * 5.0 + uv.y * 4.0 + t * 0.8) * 0.3;
    return vec3(d, e, f);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.7;
    return vec2(
        sin(uv.x * 15.0 + t * 1.8),
        cos(uv.y * 10.0 + t * 1.5)
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Normalize and base inversion setup
    uv = uv * 2.0 - 1.0;

    // Apply initial timing modulation and structure smoothing
    uv *= 1.0 + sin(iTime * 1.0) * 0.2;

    // 1. Complex Motion Baseline (Modified rotation)
    float angle1 = sin(iTime * 0.8) * 2.0 + uv.x * uv.y * 3.5;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv = rotationMatrix * uv;

    float angle2 = iTime * 1.1 + uv.x * 1.5 + uv.y * 0.8;
    uv = rotate(uv, angle2);

    // 2. Distortion (using modified parameters)
    vec2 distorted_uv = distort(uv, iTime * 1.0);

    // 3. Chain Wave Patterns (Mixing A and B)
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // 4. Material Data Retrieval
    vec3 col_base = colorFromUV(distorted_uv, iTime);

    // 5. Dynamic Variable Generation ? Palette Application
    float t = distorted_uv.x * distorted_uv.y * 6.0 + iTime * 2.0;
    vec3 col_palette = palette(t);

    // Apply flow and warp for mixing
    float flow = sin(distorted_uv.x * 12.0 + iTime * 3.0) * 0.25;
    float warp = cos(distorted_uv.y * 9.0 + iTime * 1.5) * 0.20;

    // Mix base color and palette using flow/warp as modulation
    vec3 mixed_color = mix(col_base, col_palette, flow * 0.7 + warp * 0.3);

    // Introduce strong time dependency via chromatic ripple
    vec3 final_color = mixed_color * (1.0 + sin(iTime * 5.0) * 0.1);

    // 6. Advanced R/G/B Sculpting based on distance and internal contrast
    float radius = length(distorted_uv);

    // Use the distance and time to define a sharper edge
    float edge_mask = smoothstep(0.01, 0.05, radius * 2.5 + sin(iTime * 2.2)); 

    // R Channel complexity (denser wave interaction)
    float r_wave = sin(distorted_uv.x * 30.0 + iTime * 3.5) * 1.0;
    final_color.r = mix(final_color.r, r_wave * edge_mask, 0.8);

    // G Channel complexity (enhanced vertical shift based on flow)
    float g_shift = sin(distorted_uv.y * 15.0 + iTime * 1.0) * 0.7;
    final_color.g = sin(distorted_uv.x * 35.0 + iTime * 2.5) + g_shift * flow;

    // B Channel definition (using modulated contrast)
    float contrast = smoothstep(0.4, 0.6, abs(distorted_uv.x * 5.0 - distorted_uv.y * 3.5));
    final_color.b = 0.1 + contrast * 0.7;

    // Final chromatic shift based on channel interaction and radius
    float complexity = abs(sin((final_color.g * final_color.r) * 200.0) / (1.0 + radius * 5.0));

    // Final manipulation: applying the complexity as a final filter
    final_color.r = mix(final_color.r, 1.0 - complexity * 0.5, 0.5);
    final_color.b = mix(final_color.b, complexity * 0.8, 0.5);

    // Apply contrast boosting
    final_color.r = pow(final_color.r, 1.15);
    final_color.g = pow(final_color.g, 1.15);
    final_color.b = pow(final_color.b, 1.15);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
