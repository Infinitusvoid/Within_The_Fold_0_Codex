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
    return uv + vec2(sin(uv.x * 3.0 + iTime * 0.5) * 0.7, cos(uv.y * 2.0 + iTime * 0.8) * 0.3);
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 5.0 + iTime * 1.1) * 0.4, cos(uv.y * 4.0 + iTime * 0.9) * 0.6);
}

vec3 palette(float t)
{
    return vec3(0.1 + 0.8 * sin(t * 1.5 + iTime * 0.3), 0.5 + 0.4 * cos(t * 1.2 + iTime * 0.2), 0.8 + 0.2 * sin(t * 1.8 + iTime * 0.4));
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 0.7) * 0.4 + 0.6;
    float c = cos(t * 0.8) * 0.3 + 0.5;
    float shift = sin(uv.x * 14.0 + t * 0.2) * 0.15;
    float ripple = cos(uv.y * 16.0 - t * 0.4) * 0.1;
    return uv * vec2(s, c) + vec2(shift, ripple);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 5.0 + t * 0.3) * 0.5 + 0.5;
    float e = cos(uv.y * 6.0 - t * 0.4) * 0.5 + 0.5;
    float f = 0.2 + sin(uv.x * 3.0 + uv.y * 2.0 + t * 0.5) * 0.3;
    return vec3(d, e, f);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.5;
    return vec2(
        sin(uv.x * 10.0 + t * 2.0),
        cos(uv.y * 6.0 + t * 1.5)
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Normalize and base inversion setup
    uv = uv * 2.0 - 1.0;

    // Apply initial timing modulation and structure smoothing
    uv *= 1.0 + sin(iTime * 0.5) * 0.2;

    // 1. Complex Motion Baseline (Modified rotation)
    float angle1 = sin(iTime * 0.4) + uv.x * uv.y * 3.0;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv = rotationMatrix * uv;

    float angle2 = iTime * 0.7 + uv.x * 0.8 + uv.y * 0.5;
    uv = rotate(uv, angle2);

    // 2. Distortion
    vec2 distorted_uv = distort(uv, iTime);

    // 3. Chain Wave Patterns
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // 4. Material Data Retrieval
    vec3 col_base = colorFromUV(distorted_uv, iTime);

    // 5. Dynamic Variable Generation ? Palette Application
    float t = distorted_uv.x * distorted_uv.y * 4.0 + iTime * 1.2;
    vec3 col_palette = palette(t);

    // Apply flow and warp for mixing
    float flow = sin(distorted_uv.x * 15.0 + iTime * 2.0) * 0.2;
    float warp = cos(distorted_uv.y * 8.0 + iTime * 1.3) * 0.15;

    // Mix base color and palette using flow/warp as modulation
    vec3 mixed_color = mix(col_base, col_palette, flow * 0.5 + warp * 0.5);

    // Introduce strong time dependency via chromatic ripple
    vec3 final_color = mixed_color * (1.0 + sin(iTime * 3.0) * 0.1);

    // 6. Advanced R/G/B Sculpting based on distance and internal contrast
    float radius = length(distorted_uv);

    // Use the distance and time to define a sharper edge
    float edge_mask = smoothstep(0.01, 0.15, radius * 2.0 + sin(iTime * 1.5)); 

    // R Channel complexity (denser wave interaction)
    float r_wave = sin(distorted_uv.x * 20.0 + iTime * 2.5) * 0.8;
    final_color.r = mix(final_color.r, r_wave * edge_mask, 0.6);

    // G Channel complexity (enhanced vertical shift based on flow)
    float g_shift = sin(distorted_uv.y * 10.0 + iTime * 0.8) * 0.5;
    final_color.g = sin(distorted_uv.x * 22.0 + iTime * 1.5) + g_shift * flow;

    // B Channel definition (using modulated contrast and inverted palette tone)
    float contrast = smoothstep(0.4, 0.6, abs(distorted_uv.x * 3.0 - distorted_uv.y * 1.5));
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
