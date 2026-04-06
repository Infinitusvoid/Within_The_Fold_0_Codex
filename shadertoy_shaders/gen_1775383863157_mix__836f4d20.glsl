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

float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float circle(vec2 p, vec2 c, float r)
{
    return length(p - c) - r;
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 pulse(vec2 uv) {
    // Faster, more intense flow modulation
    float t = iTime * 2.5;
    float eff_x = sin(uv.x * 18.0 + t * 7.0); 
    float eff_y = cos(uv.y * 12.0 + t * 6.5); 
    return uv + vec2(eff_x * 0.4, eff_y * 0.3);
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 6.0 + iTime * 0.7) * 0.15,
        cos(uv.y * 5.0 - iTime * 0.8) * 0.17
    );
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 9.5 + iTime * 1.1), cos(uv.y * 6.5 - iTime * 0.9));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.6 + iTime * 0.3);
    float g = 0.3 + 0.7 * cos(t * 1.2 - iTime * 0.2);
    float b = 0.1 + 0.5 * sin(t * 2.0 - iTime * 0.1);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 1.3) * 0.6 + 0.4;
    float c = cos(t * 1.8) * 0.3 + 0.7;
    float shift = sin(uv.x * 15.0 + t * 0.4) * 0.2;
    float ripple = sin(uv.y * 11.0 - t * 0.6) * 0.15;
    return uv * vec2(s, c) + vec2(shift, ripple);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 5.8 + t * 0.5) * 0.5 + 0.5;
    float e = cos(uv.y * 6.0 - t * 0.6) * 0.5 + 0.5;
    float f = 0.3 + sin(uv.x * 4.0 + uv.y * 3.0 + t * 0.7) * 0.3;
    return vec3(d, e, f);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Normalize and base inversion setup
    uv = uv * 2.0 - 1.0;

    // Apply initial timing modulation and structure smoothing
    uv *= 1.0 + sin(iTime * 0.7) * 0.18;

    // 1. Complex Motion Baseline (Rotation derived from A)
    float angle1 = sin(iTime * 0.6) + uv.x * uv.y * 2.8;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv = rotationMatrix * uv;

    float angle2 = iTime * 1.0 + uv.x * 0.5 + uv.y * 0.3;
    uv = rotate(uv, angle2);

    // 2. Distortion (from B)
    vec2 distorted_uv = distort(uv, iTime);

    // 3. Chain Wave Patterns (Mixing B)
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // 4. Material Data Retrieval
    vec3 col_base = colorFromUV(distorted_uv, iTime);

    // 5. Dynamic Variable Generation ? Palette Application
    float t = distorted_uv.x * 7.5 + distorted_uv.y * 5.0 + iTime * 1.5;
    vec3 col_palette = palette(t);

    // Apply flow and warp for mixing (from A)
    float flow = sin(distorted_uv.x * 25.0 + iTime * 4.0) * 0.4;
    float warp = cos(distorted_uv.y * 8.0 + iTime * 2.0) * 0.2;

    // Mix base color and palette using flow/warp as modulation (from A)
    vec3 mixed_color = mix(col_base, col_palette, flow * 0.4 + warp * 0.6);

    // Introduce strong time dependency via chromatic ripple (from A)
    vec3 final_color = mixed_color * (1.0 + sin(iTime * 5.0) * 0.25);

    // 6. Advanced R/G/B Sculpting based on distance and internal contrast (from A)
    float radius = length(distorted_uv);

    // Use the distance and time to define a sharper edge
    float edge_mask = smoothstep(0.005, 0.10, radius * 2.5 + sin(iTime * 3.0)); 

    // R Channel complexity (denser wave interaction)
    float r_wave = sin(distorted_uv.x * 35.0 + iTime * 4.0) * 0.9;
    final_color.r = mix(final_color.r, r_wave * edge_mask, 0.85);

    // G Channel complexity (enhanced vertical shift based on flow)
    float g_shift = sin(distorted_uv.y * 20.0 + iTime * 1.5) * 0.8;
    final_color.g = sin(distorted_uv.x * 30.0 + iTime * 4.5) + g_shift * flow * 0.9;

    // B Channel definition (using modulated contrast and inverted palette tone)
    float contrast = smoothstep(0.30, 0.4, abs(distorted_uv.x * 6.0 - distorted_uv.y * 3.0));
    final_color.b = 0.3 + contrast * 0.9;

    // Final chromatic shift based on channel interaction and radius
    float complexity = abs(sin((final_color.g * final_color.r) * 180.0) / (1.0 + radius * 6.0));

    // Final manipulation: applying the complexity as a final filter
    final_color.r = mix(final_color.r, 1.0 - complexity, 0.55);
    final_color.b = mix(final_color.b, complexity * 0.6, 0.52);

    // Apply channel separation based on time
    final_color.r *= 1.0 + sin(iTime * 2.5) * 0.08;
    final_color.g *= 1.0 - cos(iTime * 1.6) * 0.07;
    final_color.b *= 1.0 + sin(iTime * 3.5) * 0.06;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
