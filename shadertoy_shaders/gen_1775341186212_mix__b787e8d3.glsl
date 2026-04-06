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

vec2 wave(vec2 uv)
{
    return vec2(sin(uv.x * 6.0 + iTime * 0.5), cos(uv.y * 6.0 - iTime * 0.8));
}

vec3 colorFromWave(vec2 w)
{
    float r = 0.15 + 0.8 * sin(w.x * 4.0 + iTime * 0.15);
    float g = 0.3 + 0.7 * cos(w.y * 5.0 + iTime * 0.2);
    float b = 0.5;
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.2;
    float scale = 2.0 + 1.5 * sin(t + uv.x * 30.0);
    float shift = 2.0 + 1.5 * cos(t + uv.y * 25.0);
    uv.x *= scale;
    uv.y *= shift;
    return uv;
}

mat2 rotate(float a)
{
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 wave_B(vec2 uv)
{
    return uv + vec2(sin(uv.x * 7.0 + iTime * 0.6) * tan(uv.y * 1.8 + iTime * 0.9), cos(uv.y * 4.0 + iTime * 1.0) * sin(uv.x * 2.0 + iTime * 0.5));
}

vec3 pattern(vec2 uv, float t)
{
    float g = sin(uv.x * 10.0 + t * 0.7);
    float h = cos(uv.y * 10.0 + t * 0.9);
    float index = (uv.x * 5.0 + uv.y * 5.0) * 15.0 - iTime * 0.04 * t;
    float v = fract(sin(index * 3.0) * 40.0);
    return vec3(g * 0.6, h * 0.4, 0.1 + 0.5 * sin(v + t * 3.0));
}

vec2 curl(vec2 uv)
{
    float angle = iTime * 0.3 + sin(uv.x * 2.0) * cos(uv.y * 2.0);
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    return rotationMatrix * uv;
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
    p = rotate(angle * 0.5) * p;
    p += vec2(sin(p.x * 3.0) * 0.1 + cos(p.y * 2.0) * 0.1,
               cos(p.x * 2.5) * 0.1 + sin(p.y * 1.5) * 0.1);
    return p;
}

vec2 ripple(vec2 uv)
{
    float r = sin(uv.x * 5.0 + iTime * 1.5);
    float g = cos(uv.y * 6.0 + iTime * 2.0);
    return vec2(r * 0.5 + 0.5, g * 0.5 + 0.5);
}

vec3 palette(float t) {
    float a = sin(t + iTime * 0.1) * 0.5 + 0.5;
    float b = cos(t + iTime * 0.2) * 0.5 + 0.5;
    float c = pow(abs(sin(t + iTime * 0.3)), 2.0) * 0.8 + 0.2;
    return vec3(a, b, c);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // 1. Initial setup using fractal displacement and ripple (from B)
    uv = uv * 2.0 - 1.0;
    uv = fractal_displace(uv);
    uv = ripple(uv);

    // 2. Apply flow generation (from A)
    vec2 flow = uv * vec2(8.0, 4.0) - vec2(0.3, 0.2);

    // Apply Curl warping multiple times for dense swirling effect
    vec2 f = curl(flow);
    f = curl(f);
    f = curl(f);

    // 3. Apply wave distortion
    f = distort(f);

    // 4. Generate primary and secondary pattern colors
    vec3 col1 = pattern(f * 1.5, iTime * 2.2);
    vec3 col2 = pattern(f * 0.7 + iTime * 0.8, iTime * 1.7);

    // 5. Calculate dynamic field dependency
    float f_sum = f.x * 1.5 + f.y * 2.0;
    float d = sin(f_sum * 4.0 + iTime * 2.0) + cos(f.x * 9.0 + iTime * 1.5);

    vec3 finalCol = col1 * 0.6 + col2 * 0.4;

    // 6. Introduce subtle color shifts based on the warped coordinates
    finalCol.r = colorFromWave(f * 2.5).r * 0.6 + 0.3;
    finalCol.g = colorFromWave(f * 1.8).g * 0.7 + 0.1;
    finalCol.b = colorFromWave(f * 3.5).b * 0.85;

    // 7. Modulate colors using the field influence 'd' and time
    finalCol *= (0.4 + 0.6 * sin(d * 2.0 + iTime * 0.5));

    // 8. Apply final time and frame influence
    finalCol.r += sin(iTime * 4.0) * 0.15;
    finalCol.g += cos(iTime * 3.5) * 0.07;
    finalCol.b += sin(iFrame * 2.5) * 0.2;

    fragColor = vec4(finalCol, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
