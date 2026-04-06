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

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.8;
    return vec2(sin(uv.x * 7.0 + t * 1.5), cos(uv.y * 5.0 - t * 1.0));
}

vec3 colorFromWave(vec2 w) {
    float r = 0.5 + 0.5 * sin(w.x * 12.0 + iTime * 0.5);
    float g = 0.5 + 0.5 * cos(w.y * 10.0 - iTime * 0.4);
    float b = 0.3 + 0.7 * sin(w.x * 3.0 + w.y * 2.0 + iTime * 0.6);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv) {
    float t = iTime * 0.5;
    float scale = 2.5;
    uv *= scale;
    uv.x += sin(uv.y * 8.0 + t * 2.0) * 0.1;
    uv.y += cos(uv.x * 6.0 + t) * 0.1;
    return uv;
}

mat2 rotate(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 noise(vec2 uv)
{
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return vec2(sin(6.28318 * (i.x + u.x)), cos(6.28318 * (i.y + u.y)));
}

vec2 fractal_displace(vec2 uv) {
    vec2 p = uv;
    float time_factor = iTime * 0.2;
    float angle = sin(p.y * 0.5 + time_factor);
    p = rotate(p, angle * 0.5);
    p += vec2(sin(p.x * 3.0) * 0.1 + cos(p.y * 2.0) * 0.1,
               cos(p.x * 2.5) * 0.1 + sin(p.y * 1.5) * 0.1);
    return p;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // 1. Apply Fractal Displacement (B)
    uv = fractal_displace(uv);

    // 2. Apply Global Distortion (A)
    uv = distort(uv);

    // Calculate wave coordinates (A)
    vec2 w = wave(uv);

    // Use UV for final modulation (B)
    vec2 p = uv * 0.5 + 0.5;

    // 3. Layered Color Calculation (Blending B's structure with A's wave depth)

    // R channel: Horizontal wave interaction + fractal layer
    float r_base = sin(p.x * 15.0 + iTime * 1.5) * 0.5 + 0.5;
    r_base *= (1.0 + sin(p.y * 3.0 + iTime * 0.5) * 0.5);

    // G channel: Vertical wave interaction + fractal layer
    float g_base = sin(p.y * 12.0 + iTime * 2.0) * 0.5 + 0.5;
    g_base *= (1.0 + cos(p.x * 2.5 + iTime * 0.8) * 0.4);

    // B channel: High frequency pattern based on UV coordinates (from B)
    float b_base = sin(p.x * 5.0 + p.y * 5.0 + iTime * 0.3) * 0.5 + 0.5;
    b_base = pow(b_base, 0.8);

    vec3 col = vec3(r_base, g_base, b_base);

    // 4. Final Complex Transformation (from A's complexity)

    // Apply Flow/Pulse modulation from A
    float flow = sin(uv.x * 20.0 + iTime * 1.2) * 0.2;
    float pulse = sin(uv.y * 15.0 + iTime * 0.9);

    // Modulation
    float intensity = 0.5 + 0.5 * sin(uv.x * 8.0 + iTime * 0.3);

    col.r = smoothstep(0.3, 0.6, uv.x * 2.5 + flow * 6.0);
    col.g = smoothstep(0.2, 0.5, uv.y * 3.5 + pulse * 5.0);
    col.b = 0.1 + 0.4 * sin(col.r * 1.8 + col.g * 1.8 + iTime * 0.5);

    // Apply flow and pulse as offsets
    col.r += flow * 0.8;
    col.g += pulse * 0.7;
    col.b += 0.25 * sin(uv.x * 10.0 + iTime * 0.4);

    // Final transformation using cosine/sine blends
    col.r = cos(col.g * 10.0 + iTime * 0.5) * 0.5 + 0.5;
    col.g = sin(col.r * 8.0 - uv.y * 6.0 + iTime * 0.4) * 0.5 + 0.5;
    col.b = 0.5 + 0.5 * sin(uv.x * 7.0 + uv.y * 7.0 + iTime * 0.7);

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
