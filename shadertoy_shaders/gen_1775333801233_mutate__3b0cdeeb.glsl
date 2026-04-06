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

mat2 rotate(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 wave(vec2 uv) {
    float t = iTime * 1.2;
    return vec2(sin(uv.x * 5.0 + t * 2.0), cos(uv.y * 5.0 - t * 3.0));
}

vec3 colorFromWave(vec2 w) {
    float r = 0.5 + 0.5 * sin(w.x * 12.0 + iTime * 0.5);
    float g = 0.5 + 0.5 * cos(w.y * 10.0 - iTime * 0.4);
    float b = 0.3 + 0.7 * sin(w.x * 3.0 + w.y * 2.0 + iTime * 0.6);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv) {
    float t = iTime * 0.6;
    float scale = 3.0; // Increased scale for more distortion
    uv *= scale;
    uv.x += sin(uv.y * 8.0 + t * 3.0) * 0.3;
    uv.y += cos(uv.x * 6.0 + t * 1.5) * 0.4;
    return uv;
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
    float time_factor = iTime * 0.4;
    float angle = sin(p.y * 0.7 + time_factor * 1.5);
    p = rotate(p, angle * 1.0);
    p += vec2(sin(p.x * 7.0) * 0.15 + cos(p.y * 5.0) * 0.2,
               sin(p.x * 4.0) * 0.1 + cos(p.y * 3.0) * 0.25);
    return p;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 5.0 - 2.5; // Wider initial UV range

    // Apply Fractal Displacement and Global Distortion
    uv = fractal_displace(uv);
    uv = distort(uv);

    // Calculate wave coordinates
    vec2 w = wave(uv);

    // Use UV for base positioning
    vec2 p = uv * 0.4 + 0.5; // Adjusted base offset

    // 3. Layered Color Calculation 

    // R channel: Driven by wave pattern and spatial flow, amplified by distortion
    float r_wave = sin(p.x * 25.0 + w.x * 18.0 + iTime * 4.0); // Stronger wave interaction
    float r_flow = cos(p.y * 10.0 + iTime * 1.5);
    float r_base = 0.4 + r_wave * 0.6 + r_flow * 0.4;
    r_base = pow(r_base, 1.3); // Sharper mapping

    // G channel: Driven by complex interaction of position and time
    float g_wave = sin(p.y * 20.0 - iTime * 3.0);
    float g_freq = cos(p.x * 12.0 + iTime * 0.9);
    float g_base = 0.5 + g_wave * 0.7 + g_freq * 0.3;
    g_base = smoothstep(0.02, 0.8, g_base);

    // B channel: High frequency pattern based on noise and flow
    float b_noise = noise(p * 10.0 + iTime * 5.0).x; // More dynamic noise input
    float b_base = sin(p.x * 15.0 + p.y * 10.0 + iTime * 1.1) * 0.5 + 0.5;
    b_base = b_base * (1.0 - b_noise * 0.6); // Stronger noise reduction

    vec3 col = vec3(r_base, g_base, b_base);

    // 4. Final Complex Transformation (Spectral blending)

    // Introduce secondary flow influence based on texture variation
    float flow = sin(uv.x * 80.0 + iTime * 5.0) * 0.3;

    // Modulation based on combined color
    float intensity = pow(col.r * 1.5 + col.g * 1.0, 1.8); // Intensified base

    // Apply dynamic color shifts and offsets
    col.r = mix(col.r, flow * 0.6, uv.x * 4.0);
    col.g = mix(col.g, 1.0 - intensity * 0.4, uv.y * 6.0);
    col.b = 0.2 + col.r * 0.4 + col.g * 0.3;

    // Final complex transformation using layered sinusoidal shifts
    col.r = sin(col.g * 18.0 + iTime * 1.3) * 0.5 + 0.5;
    col.g = cos(col.r * 13.0 - uv.y * 10.0 + iTime * 1.0) * 0.5 + 0.5;
    col.b = 0.5 + sin(uv.x * 30.0 + uv.y * 20.0 + iTime * 1.6) * 0.2;

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
