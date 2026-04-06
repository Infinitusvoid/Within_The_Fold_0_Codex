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

vec3 palette(float t)
{
    float r = 0.1 + 0.8 * sin(t * 1.5 + iTime * 0.5);
    float g = 0.2 + 0.7 * cos(t * 1.1 - iTime * 0.3);
    float b = 0.5 + 0.4 * sin(t * 2.0 + iTime * 0.8);
    return vec3(r, g, b);
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 10.0 + iTime * 2.0), cos(uv.y * 8.0 - iTime * 1.5));
}

vec2 waveA(vec2 uv)
{
    return uv * 3.0 + vec2(
        sin(uv.x * 6.0 + iTime * 1.0) * 0.3,
        cos(uv.y * 5.0 - iTime * 0.7) * 0.3
    );
}

vec2 ripple(vec2 uv)
{
    float r = sin(uv.x * 5.0 + iTime * 1.5);
    float g = cos(uv.y * 6.0 + iTime * 2.0);
    return vec2(r * 0.5 + 0.5, g * 0.5 + 0.5);
}

mat2 rotateMatrix(float a) {
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
    p = rotateMatrix(angle * 0.5) * p;
    p += vec2(sin(p.x * 3.0) * 0.1 + cos(p.y * 2.0) * 0.1,
               cos(p.x * 2.5) * 0.1 + sin(p.y * 1.5) * 0.1);
    return p;
}

vec2 distort(vec2 uv) {
    float t = iTime * 0.5;
    uv *= vec2(1.0 + 0.03 * sin(t + uv.x * 10.0), 1.0 + 0.03 * sin(t + uv.y * 15.0));
    return uv;
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.6;
    float w1 = sin(uv.x * 7.0 + t * 0.5) * 0.5;
    float w2 = cos(uv.y * 5.0 + t * 0.3) * 0.5;
    float w3 = sin(length(uv) * 1.5 + t * 0.8) * 0.3;
    return vec2(w1 + w3 * 0.5, w2 + w3 * 0.5);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    float time = iTime;

    // --- 1. Initial Spatial Setup (Flow and Distortion from B) ---
    uv = uv * 2.0 - 1.0;
    uv = fractal_displace(uv);
    uv = distort(uv);

    // --- 2. Rotational setup (A/B blend) ---
    float angle_base = time * 1.8;
    float angle_vortex = atan(uv.y, uv.x) * 5.0;

    mat2 rotationMatrix = mat2(cos(angle_base), -sin(angle_base), sin(angle_base), cos(angle_base));
    uv *= rotationMatrix;

    uv = rotate(uv, angle_vortex * 0.8);

    // --- 3. Vortex/Gravitational pull distortion (A concept applied dynamically) ---
    vec2 center = vec2(0.0);
    float dist = length(uv - center);
    uv -= center;
    uv /= (dist * 0.5 + 1.0); 

    // --- 4. Wave dynamics generation (B) ---
    vec2 w = waveB(uv * 1.5);
    uv = mix(uv, w, 0.3);

    // --- 5. Polar Coordinate Setup (B) ---
    vec2 center_b = vec2(0.5);
    vec2 p = uv - center_b;
    float r = length(p);
    float theta = atan(p.y, p.x);

    // --- 6. Geometric Masking (A) ---
    float x = 0.25 * sin(time * 1.5);
    float d1 = circle(uv, vec2(-x * 0.5, 0.0), 0.25);
    float d2 = circle(uv, vec2( x * 0.5, 0.0), 0.25);
    float d = smin(d1, d2, 0.1);
    float shape_mask = smoothstep(0.005, 0.0, d);

    // --- 7. Chromatic Flow Calculation ---

    // Calculate flow based on polar coordinates and time
    float flow_r = r * 3.0 + time * 0.5;
    float flow_theta = theta * 4.0 + time * 1.0;

    // Introduce complex wave interaction
    float wave_phase = sin(flow_r * 1.5 + flow_theta * 0.8) * 0.5 + 0.5;

    // Map flow to color channels
    float r_val = sin(flow_r * 2.0 + flow_theta * 3.0) * 0.5 + 0.5;
    float g_val = cos(flow_r * 1.8 + flow_theta * 2.5) * 0.5 + 0.5;
    float b_val = sin(flow_r * 3.5 + flow_theta * 3.5) * 0.5 + 0.5;

    // Apply hue modulation based on distance and mask
    float intensity = 0.1 + dist * 1.5;

    vec3 final_color = vec3(r_val, g_val, b_val);

    // Use wave phase to add a dynamic shift
    final_color = mix(final_color, vec3(r_val * 0.7, g_val * 0.7, b_val * 0.7), wave_phase * 0.3);

    // Apply geometric mask and ambient influence
    final_color *= shape_mask * intensity * (1.0 + sin(flow_theta * 2.0));

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
