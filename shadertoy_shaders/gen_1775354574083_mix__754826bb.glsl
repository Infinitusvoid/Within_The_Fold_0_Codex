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
        sin(uv.x * 5.0 + iTime * 1.2) * 0.12,
        cos(uv.y * 4.5 - iTime * 0.8) * 0.14
    );
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 8.0 + iTime * 0.6), cos(uv.y * 6.5 - iTime * 0.3));
}

vec3 palette(float t)
{
    float r = 0.1 + 0.7 * sin(t * 0.7 + iTime * 0.4);
    float g = 0.9 * sin(t * 1.5 + iTime * 0.2);
    float b = 0.3 + 0.5 * cos(t * 2.0 - iTime * 0.1);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 0.6) * 0.5 + 0.5;
    float c = cos(t * 0.7) * 0.5 + 0.5;
    float shift = sin(uv.x * 10.0 + t * 0.3) * 0.2;
    float ripple = cos(uv.y * 8.0 - t * 0.5) * 0.15;
    return uv * vec2(s, c) + vec2(shift * 0.5, ripple);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 4.5 + t * 0.5) * 0.4 + 0.3;
    float e = cos(uv.y * 5.5 - t * 0.6) * 0.4 + 0.3;
    float f = 0.5 + sin(uv.x * 2.5 + uv.y * 1.5 + t * 0.6) * 0.2;
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
        sin(uv.x * 6.0 + iTime * 1.2) * 0.15,
        cos(uv.y * 7.0 + iTime * 0.8) * 0.1
    );
}

vec2 flowB(vec2 uv)
{
    return vec2(
        sin(uv.x * 8.0 + iTime * 0.4) * 0.25,
        cos(uv.y * 5.0 + iTime * 0.6) * 0.2
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Initial flow distortion (B)
    uv = flowB(uv);

    // Phase shifting based on position and time
    float phase = uv.x * 4.0 + uv.y * 3.0 + iTime * 1.5;
    uv = uv + vec2(
        sin(phase * 0.5) * 0.2,
        cos(phase * 0.5) * 0.1
    );

    // Time-based rotation (A style rotation)
    float angle = iTime * 1.2 + uv.x * 1.5 + uv.y * 1.2;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv *= rotationMatrix;

    // Distortion (A style distortion)
    vec2 distorted_uv = distort(uv, iTime);

    // Chain Wave Patterns (Mixing A and B)
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // Material Data Retrieval
    vec3 col_base = colorFromUV(distorted_uv, iTime);

    // Dynamic Variable Generation ? Palette Application (B style input)
    float t = (distorted_uv.x * 5.0 + distorted_uv.y) * 12.0 + iTime * 0.7;
    vec3 col_palette = palette(t);

    // Mix base color and palette using wave modulation
    float flow = sin(distorted_uv.x * 15.0 + iTime * 3.0) * 0.2;
    float warp = cos(distorted_uv.y * 6.0 + iTime * 1.5) * 0.15;

    vec3 mixed_color = mix(col_base, col_palette, flow * 0.5 + warp * 0.5);

    // Introduce strong time dependency
    vec3 final_color = mixed_color * (1.0 + sin(iTime * 4.0) * 0.1);

    // Advanced R/G/B Sculpting (A style complexity)
    float radius = length(distorted_uv);
    float edge_mask = smoothstep(0.003, 0.1, radius * 3.0 + sin(iTime * 3.0)); 

    // R Channel complexity
    float r_wave = sin(distorted_uv.x * 30.0 + iTime * 4.0) * 1.1;
    final_color.r = mix(final_color.r, r_wave * edge_mask, 0.8);

    // G Channel complexity (enhanced vertical shift based on flow)
    float g_shift = sin(distorted_uv.y * 15.0 + iTime * 2.5) * 0.7;
    final_color.g = sin(distorted_uv.x * 25.0 + iTime * 3.0) + g_shift * flow;

    // B Channel definition (using modulated contrast)
    float contrast = smoothstep(0.25, 0.45, abs(distorted_uv.x * 5.0 - distorted_uv.y * 3.0));
    final_color.b = 0.1 + contrast * 0.8;

    // Final chromatic shift based on channel interaction and radius
    float complexity = abs(sin((final_color.g * final_color.r) * 150.0) / (1.0 + radius * 5.0));

    // Final manipulation
    final_color.r = mix(final_color.r, 1.0 - complexity * 0.8, 0.5);
    final_color.b = mix(final_color.b, complexity * 0.5, 0.5);

    // Apply channel separation based on time
    final_color.r *= 1.0 + sin(iTime * 2.5) * 0.08;
    final_color.g *= 1.0 - cos(iTime * 1.3) * 0.07;
    final_color.b *= 1.0 + sin(iTime * 3.0) * 0.06;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
