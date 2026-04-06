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
    return uv + vec2(sin(uv.x * 3.0 + iTime * 0.4) * cos(uv.y * 1.5 + iTime * 0.6), cos(uv.y * 2.5 + iTime * 0.7) * sin(uv.x * 1.2 + iTime * 0.5));
}

vec2 waveB(vec2 uv)
{
    return vec2(cos(uv.x * 4.0 + iTime * 0.2) * sin(uv.y * 2.5 + iTime * 0.4), sin(uv.x * 3.0 + iTime * 0.1) * cos(uv.y * 2.0 + iTime * 0.3));
}

vec3 palette(float t)
{
    return vec3(0.3 + 0.7 * sin(t + iTime * 0.1), 0.4 + 0.6 * cos(t + iTime * 0.2), 0.5 + 0.5 * sin(t + iTime * 0.3));
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

vec2 w_wave(vec2 uv) {
    float t = iTime * 0.5;
    return vec2(
        sin(uv.x * 5.0 + uv.y * 2.0 + t),
        cos(uv.x * 3.0 - uv.y * 1.5 + t * 0.7)
    );
}

vec3 colorFromWave(vec2 w) {
    float r = 0.5 + 0.5 * sin(w.x * 12.0 + iTime * 0.5);
    float g = 0.5 + 0.5 * cos(w.y * 10.0 - iTime * 0.4);
    float b = 0.3 + 0.7 * sin(w.x * 3.0 + w.y * 2.0 + iTime * 0.6);
    return vec3(r, g, b);
}

vec2 flow(vec2 uv)
{
    float speed = 0.5;
    float frequency = 8.0;
    float time_offset = iTime * speed;

    float val1 = sin(uv.x * frequency + time_offset);
    float val2 = cos(uv.y * frequency * 1.5 - time_offset * 0.5);

    float warp_x = val1 * 0.6 + val2 * 0.4;
    float warp_y = cos(uv.x * frequency + val1 * 1.5) * 0.2 + val2 * 1.2;

    return vec2(warp_x, uv.y + warp_y);
}

vec3 modulate(float input, float time)
{
    vec3 c1 = vec3(0.1 * sin(input * 5.0 + time * 1.5), 0.5 + 0.5 * cos(input * 3.0 + time * 1.0), 0.9);
    vec3 c2 = vec3(0.9, 0.1 * cos(input * 7.0 + time * 2.0), 0.55);

    vec3 final_color = mix(c1, c2, fract(input * 3.7));
    return final_color;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Normalize and base inversion setup
    uv = uv * 2.0 - 1.0;

    // Apply initial timing modulation and structure smoothing
    uv *= 1.0 + sin(iTime * 0.5) * 0.2;

    // 1. Complex Motion Baseline (Rotation based)
    float angle1 = sin(iTime * 0.3) + uv.x * uv.y * 2.0;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv = rotationMatrix * uv;

    float angle2 = iTime * 0.5 + uv.x + uv.y * 0.4;
    uv = rotate(uv, angle2);

    // 2. Distortion (Combined based on A concepts)
    vec2 distorted_uv = distort(uv, iTime);

    // 3. Chain Wave Patterns (A layered variation)
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // 4. Material Data Retrieval (A's color mapping + B's wave input color struct)
    vec3 col_base = colorFromUV(distorted_uv, iTime);

    // 5. Dynamic Variable Generation ? Palette Application
    float t = distorted_uv.x * distorted_uv.y * 2.0 + iTime * 0.5;
    vec3 col_palette = palette(t);

    // Apply variation flows
    float flow_weight = sin(distorted_uv.x * 10.0 + iTime * 1.5) * 0.1;
    float warp_weight = cos(distorted_uv.y * 5.0 + iTime * 0.8) * 0.15;

    // Mix base color and palette
    vec3 final_color = mix(col_base, col_palette, flow_weight * 0.5 + warp_weight * 0.5);

    // Introducing further structured motion/complexity from B: modulating texture scale
    float modulated_texture = mod(iTime * 3.0 + distorted_uv.x + distorted_uv.y, 8.0) * 0.15;

    // Introduce final temporal modification
    final_color.b = mix(final_color.b, sin(iTime * 2.0 * 0.3), 0.2);

    // 6. Advanced R/G/B Sculpting (Using detailed sculpting mix)
    float radius = length(distorted_uv);
    float dist = 1.0 - smoothstep(0.0, 0.5, radius * 2.0 + modulated_texture);

    vec3 color = final_color;

    // Complex Layered Filtering
    color.r = mix(color.r, sin(distorted_uv.x * 15.0 + iTime * 0.5), cos(uv.y * iTime * 0.5) * 0.1) + (1.0 - dist) * 0.7;
    color.g = 0.5 + 0.3 * sin(color.r * 1.5 + distorted_uv.y * 4.0);
    color.b = 0.2 + 0.5 * sin(distorted_uv.y * 6.0 + iTime * 0.6);

    // Final Color Correction ? Modulation specific blend
    color.r = pow(color.r, 1.5);
    color.g = 0.5 + color.g * 0.5 - iTime * 0.3;
    color.b = sin(color.r * 0.7 + 2.0) * 0.5 + 0.3;

    fragColor = vec4(color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
