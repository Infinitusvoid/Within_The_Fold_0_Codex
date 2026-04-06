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

vec2 noise(vec2 uv)
{
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return vec2(sin(6.28318 * (i.x + u.x)), cos(6.28318 * (i.y + u.y)));
}

vec2 wave(vec2 uv)
{
    float t = iTime * 1.2;
    return vec2(sin(uv.x * 6.0 + t * 3.0), cos(uv.y * 4.5 - t * 2.5));
}

vec3 colorFromWave(vec2 w)
{
    float r = 0.5 + 0.5 * sin(w.x * 12.0 + iTime * 0.5);
    float g = 0.5 + 0.5 * cos(w.y * 10.0 - iTime * 0.4);
    float b = 0.3 + 0.7 * sin(w.x * 3.0 + w.y * 2.0 + iTime * 0.6);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.6;
    float scale = 2.2;
    uv *= scale;
    uv.x += sin(uv.y * 8.0 + t * 3.0) * 0.18;
    uv.y += cos(uv.x * 6.0 + t * 1.5) * 0.15;
    return uv;
}

mat2 rotate(float a)
{
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 fractal_displace(vec2 uv) {
    vec2 p = uv;
    float time_factor = iTime * 0.3;
    float angle = sin(p.y * 0.7 + time_factor);
    p = rotate(p, angle * 0.8);
    p += vec2(sin(p.x * 5.0) * 0.15 + cos(p.y * 4.0) * 0.1,
               sin(p.x * 3.5) * 0.1 + cos(p.y * 2.5) * 0.1);
    return p;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // 1. Apply Fractal Displacement
    uv = fractal_displace(uv);

    // 2. Apply Global Distortion
    uv = distort(uv);

    // Calculate wave coordinates
    vec2 w = wave(uv);

    // Use UV for final modulation
    vec2 p = uv * 0.6 + 0.5;

    // 3. Layered Color Calculation 

    // R channel: Driven by wave, shifted by fractal structure
    float r_wave = sin(p.x * 18.0 + iTime * 1.6);
    float r_fractal = cos(p.y * 10.0 + iTime * 0.7);
    float r_base = 0.5 + r_wave * 0.5 + r_fractal * 0.5;
    r_base = pow(r_base, 1.1);

    // G channel: Driven by wave and complex frequency
    float g_wave = cos(p.y * 14.0 - iTime * 1.1);
    float g_fractal = sin(p.x * 7.0 + iTime * 0.5);
    float g_base = 0.5 + g_wave * 0.5 + g_fractal * 0.3;
    g_base = smoothstep(0.1, 0.6, g_base);

    // B channel: High frequency pattern based on UV coordinates
    float b_base = sin(p.x * 4.0 + p.y * 4.0 + iTime * 0.4) * 0.5 + 0.5;
    b_base = pow(b_base, 0.7);

    vec3 col = vec3(r_base, g_base, b_base);

    // 4. Final Complex Transformation (Focus on spectral blending)

    // Introduce a secondary noise influence
    float flow = sin(uv.x * 30.0 + iTime * 1.3) * 0.25;

    // Modulation based on the combined color
    float intensity = sin(col.r * 4.0 + col.g * 3.0 + iTime * 0.5);

    // Apply dynamic color shifts and offsets
    col.r = mix(col.r, flow * 0.5, uv.x * 3.0);
    col.g = mix(col.g, 1.0 - intensity, uv.y * 4.0);
    col.b = 0.2 + col.r * 0.3 + col.g * 0.5;

    // Final complex transformation using a strong sin/cos blend
    col.r = sin(col.g * 9.0 + iTime * 0.6) * 0.5 + 0.5;
    col.g = cos(col.r * 7.0 - uv.y * 5.0 + iTime * 0.5) * 0.5 + 0.5;
    col.b = 0.4 + sin(uv.x * 12.0 + uv.y * 8.0 + iTime * 0.7) * 0.3;

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
