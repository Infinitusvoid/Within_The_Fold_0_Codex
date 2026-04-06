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
        sin(uv.x * 5.0 + iTime * 0.8) * 0.12,
        cos(uv.y * 4.5 - iTime * 0.6) * 0.16
    );
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 8.0 + iTime * 1.2), cos(uv.y * 5.5 - iTime * 0.7));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.5 + iTime * 0.4);
    float g = 0.4 + 0.6 * cos(t * 1.3 + iTime * 0.25);
    float b = 0.2 + 0.4 * sin(t * 1.8 - iTime * 0.15);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 1.1) * 0.5 + 0.5;
    float c = cos(t * 1.5) * 0.4 + 0.6;
    float shift = sin(uv.x * 12.0 + t * 0.3) * 0.18;
    float ripple = cos(uv.y * 10.0 - t * 0.5) * 0.12;
    return uv * vec2(s, c) + vec2(shift, ripple);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 6.5 + t * 0.4) * 0.5 + 0.5;
    float e = cos(uv.y * 7.5 - t * 0.5) * 0.5 + 0.5;
    float f = 0.2 + sin(uv.x * 3.5 + uv.y * 2.5 + t * 0.6) * 0.35;
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
    vec2 uv = fragCoord/iResolution.xy;

    // Normalize and base inversion setup
    uv = uv * 2.0 - 1.0;

    // Apply initial timing modulation and structure smoothing
    uv *= 1.0 + sin(iTime * 0.6) * 0.15;

    // 1. Complex Motion Baseline (Modified rotation derived from A)
    float angle1 = sin(iTime * 0.5) + uv.x * uv.y * 2.5;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv = rotationMatrix * uv;

    float angle2 = iTime * 0.9 + uv.x * 0.6 + uv.y * 0.4;
    uv = rotate(uv, angle2);

    // 2. Distortion (from A)
    vec2 distorted_uv = distort(uv, iTime);

    // 3. Chain Wave Patterns (Mixing A and B)
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // 4. Material Data Retrieval
    vec3 col_base = colorFromUV(distorted_uv, iTime);

    // 5. Dynamic Variable Generation ? Palette Application
    float t = distorted_uv.x * 8.0 + distorted_uv.y * 4.0 + iTime * 2.0;
    vec3 col_palette = palette(t);

    // Apply flow and warp for mixing (from A)
    float flow = sin(distorted_uv.x * 20.0 + iTime * 3.0) * 0.3;
    float warp = cos(distorted_uv.y * 9.0 + iTime * 1.5) * 0.15;

    // Mix base color and palette using flow/warp as modulation (from A)
    vec3 mixed_color = mix(col_base, col_palette, flow * 0.35 + warp * 0.65);

    // Introduce strong time dependency via chromatic ripple (from A)
    vec3 final_color = mixed_color * (1.0 + sin(iTime * 4.0) * 0.2);

    // 6. Advanced R/G/B Sculpting based on distance and internal contrast (from A)
    float radius = length(distorted_uv);

    // Use the distance and time to define a sharper edge
    float edge_mask = smoothstep(0.004, 0.11, radius * 2.0 + sin(iTime * 2.5)); 

    // R Channel complexity (denser wave interaction)
    float r_wave = sin(distorted_uv.x * 30.0 + iTime * 3.5) * 0.95;
    final_color.r = mix(final_color.r, r_wave * edge_mask, 0.8);

    // G Channel complexity (enhanced vertical shift based on flow)
    float g_shift = sin(distorted_uv.y * 15.0 + iTime * 1.3) * 0.7;
    final_color.g = sin(distorted_uv.x * 25.0 + iTime * 3.0) + g_shift * flow * 0.8;

    // B Channel definition (using modulated contrast and inverted palette tone)
    float contrast = smoothstep(0.35, 0.5, abs(distorted_uv.x * 5.0 - distorted_uv.y * 2.5));
    final_color.b = 0.35 + contrast * 0.8;

    // Final chromatic shift based on channel interaction and radius
    float complexity = abs(sin((final_color.g * final_color.r) * 150.0) / (1.0 + radius * 5.0));

    // Final manipulation: applying the complexity as a final filter
    final_color.r = mix(final_color.r, 1.0 - complexity, 0.5);
    final_color.b = mix(final_color.b, complexity * 0.5, 0.55);

    // Apply channel separation based on time
    final_color.r *= 1.0 + sin(iTime * 2.0) * 0.07;
    final_color.g *= 1.0 - cos(iTime * 1.4) * 0.06;
    final_color.b *= 1.0 + sin(iTime * 3.0) * 0.05;

    // New addition: Introduce a high-frequency Fresnel effect based on time and distance
    float fresnel = pow(1.0 - length(distorted_uv), 5.0) * 5.0;
    final_color *= (1.0 + fresnel * 0.5);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
