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

vec3 pal(float t)
{
    return 0.05 + 0.9 * sin(6.28318 * t * 3.0 + 3.14159 * vec3(0.1, 0.5, 0.9));
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.8;
    float w1 = sin(uv.x * 10.0 + t * 1.5) * 0.5;
    float w2 = cos(uv.y * 8.0 + t * 1.2) * 0.4;
    float w3 = sin(length(uv) * 4.0 + t * 2.0) * 0.3;
    return vec2(w1 * 0.7 + w3 * 0.3, w2 * 0.6 + w3 * 0.4);
}

vec3 palette(float t) {
    float a = sin(t * 0.4) * 0.5 + 0.5;
    float b = cos(t * 0.6) * 0.5 + 0.5;
    float c = sin(t * 1.0) * 0.5 + 0.5;
    return vec3(a, b, c);
}

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 4.0 + iTime * 0.7) * 0.15,
        cos(uv.y * 3.5 - iTime * 0.5) * 0.18
    );
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 6.0 + iTime * 0.5), cos(uv.y * 7.0 - iTime * 0.4));
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

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // 1. Base Noise and Inversion (from B)
    vec2 uv_base = uv * 2.0 - 1.0;

    // Apply base timing modulation
    uv_base *= 1.0 + sin(iTime * 0.5) * 0.2;

    // 2. Rotational Motion (from B)
    float angle1 = sin(iTime * 0.5) + uv_base.x * uv_base.y * 3.0;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv_base = rotationMatrix * uv_base;

    float angle2 = iTime * 0.8 + uv_base.x * 0.5 + uv_base.y * 0.3;
    uv_base = rotate(uv_base, angle2);

    // 3. Wave Distortion (Mixing A and B)
    uv_base = waveA(uv_base);
    uv_base = waveB(uv_base);

    // 4. Ripple Distortion (from B)
    vec2 distorted_uv = distort(uv_base, iTime);

    // 5. Material Data Retrieval (from B)
    vec3 col_base = colorFromUV(distorted_uv, iTime);

    // 6. Flow and Sculpting Calculation (from A)
    // Polar coordinates based on distorted UV
    vec2 center = vec2(0.5);
    vec2 p = distorted_uv - center;
    float r = length(p);
    float a = atan(p.y, p.x);

    // Flow calculation: Emphasizing spirals
    float flow = r * 2.0 + a * 5.0 + iTime * 3.0;

    // Density calculation: Radial falloff combined with angular structure
    float density = sin(a * 15.0 + iTime * 5.0) * exp(-r * r * 2.5);

    // Dynamic palette input modulated by flow and depth
    float palette_t = 0.15 * iTime + sin(flow * 8.0) * 0.35 + 0.1 * r;

    vec3 col_palette = pal(palette_t);

    // 7. Mixing Color based on Flow and Density
    vec3 mixed_color = mix(col_base, col_palette, flow * 0.3 + density * 0.7);

    // 8. Final Chromatic Adjustment (from A)
    float angular_effect = sin(a * 20.0 + iTime * 10.0);
    float radial_emphasis = cos(r * 6.0 + iTime * 5.0) * 0.4;

    // Apply angular and radial effects
    mixed_color *= 1.2 + 4.0 * density;
    mixed_color += angular_effect * 0.5;
    mixed_color += radial_emphasis * 0.5;

    fragColor = vec4(mixed_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
