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
        sin(uv.x * 7.0 + iTime * 0.8) * 0.2,
        cos(uv.y * 5.5 - iTime * 0.9) * 0.2
    );
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 10.0 + iTime * 1.2), cos(uv.y * 7.0 - iTime * 1.0));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.7 + iTime * 0.5);
    float g = 0.3 + 0.7 * cos(t * 1.5 - iTime * 0.3);
    float b = 0.1 + 0.5 * sin(t * 2.5 + iTime * 0.1);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 1.4) * 0.5 + 0.5;
    float c = cos(t * 1.7) * 0.5 + 0.5;
    float shift = sin(uv.x * 20.0 + t * 0.3) * 0.25;
    float ripple = cos(uv.y * 15.0 - t * 0.5) * 0.15;
    return uv * vec2(s, c) + vec2(shift, ripple);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 4.5 + t * 0.4) * 0.5 + 0.5;
    float e = cos(uv.y * 6.5 - t * 0.5) * 0.5 + 0.5;
    float f = 0.2 + sin(uv.x * 5.0 + uv.y * 4.0 + t * 0.6) * 0.3;
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
    uv *= 1.0 + sin(iTime * 0.8) * 0.2;

    // 1. Core Flow Rotation (Increased complexity)
    float angle1 = sin(iTime * 0.5) + uv.x * uv.y * 3.0;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv = rotationMatrix * uv;

    float angle2 = iTime * 1.2 + uv.x * 0.4 + uv.y * 0.5;
    uv = rotate(uv, angle2);

    // 2. Distortion and Wave Patterns
    vec2 distorted_uv = distort(uv, iTime * 0.5);
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // 3. Material Data Retrieval
    vec3 col_base = colorFromUV(distorted_uv, iTime);

    // 4. Dynamic Variable Generation
    float t = distorted_uv.x * 8.0 + distorted_uv.y * 6.0 + iTime * 2.0;
    vec3 col_palette = palette(t);

    // Apply flow modulation
    float flow = sin(distorted_uv.x * 30.0 + iTime * 3.0) * 0.5;
    float warp = cos(distorted_uv.y * 10.0 + iTime * 2.5) * 0.3;

    // Mix base color and palette using flow/warp
    vec3 mixed_color = mix(col_base, col_palette, flow * 0.5 + warp * 0.5);

    // Apply strong chromatic ripple
    vec3 final_color = mixed_color * (1.0 + sin(iTime * 6.0) * 0.2);

    // 5. Advanced R/G/B Sculpting based on radial distance and flow
    float radius = length(distorted_uv);

    // Use distance for localized edge emphasis
    float edge_mask = smoothstep(0.003, 0.08, radius * 3.0 + sin(iTime * 4.0)); 

    // R Channel complexity (focused on horizontal flow)
    float r_wave = sin(distorted_uv.x * 40.0 + iTime * 5.0) * 0.85;
    final_color.r = mix(final_color.r, r_wave * edge_mask, 0.9);

    // G Channel shift (emphasizing vertical separation)
    float g_shift = sin(distorted_uv.y * 25.0 + iTime * 1.8) * 0.7;
    final_color.g = sin(distorted_uv.x * 35.0 + iTime * 5.5) + g_shift * flow * 0.8;

    // B Channel definition (based on inverted palette contrast)
    float contrast = smoothstep(0.25, 0.45, abs(distorted_uv.x * 7.0 - distorted_uv.y * 4.0));
    final_color.b = 0.35 + contrast * 0.95;

    // Final chromatic interaction
    float complexity = abs(sin((final_color.g * final_color.r) * 200.0) / (1.0 + radius * 7.0));

    // Final manipulation
    final_color.r = mix(final_color.r, 1.0 - complexity, 0.6);
    final_color.b = mix(final_color.b, complexity * 0.7, 0.65);

    // Time-based channel amplification
    final_color.r *= 1.0 + sin(iTime * 3.0) * 0.1;
    final_color.g *= 1.0 - cos(iTime * 2.0) * 0.12;
    final_color.b *= 1.0 + sin(iTime * 4.0) * 0.15;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
