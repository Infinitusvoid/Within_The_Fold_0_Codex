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

vec2 waveA(vec2 uv)
{
    return uv + vec2(sin(uv.x * 8.0 + iTime * 1.0) * 0.4, cos(uv.y * 7.0 + iTime * 0.5) * 0.3);
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 5.0 + iTime * 1.5) * cos(uv.y * 4.0), cos(uv.y * 8.0 + iTime * 0.8) * sin(uv.x * 3.0));
}

float palette(float t)
{
    return 0.5 + 0.5 * sin(t * 3.0);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.4;
    // Integrate motion and scale effects from B
    float scale = 1.0 + 0.05 * sin(t + uv.x * 10.0);
    float shift = 1.0 + 0.04 * cos(t + uv.y * 8.0);
    uv.x *= scale;
    uv.y *= shift;
    // Add coupling derived from A's distortion structure
    uv.x += sin(uv.y * 6.0 + t * 4.0) * 0.2;
    uv.y += cos(uv.x * 7.0 + t * 1.8) * 0.15;
    return uv;
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 6.5 + t * 0.4) * 0.5 + 0.5;
    float e = cos(uv.y * 9.5 - t * 0.5) * 0.4 + 0.5;
    float f = 0.2 + sin(uv.x * 4.5 + uv.y * 3.5 + t * 0.6) * 0.3;
    return vec3(d, e, f);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 noise(vec2 uv)
{
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return vec2(sin(6.28318 * (i.x + u.x)), cos(6.28318 * (i.y + u.y)));
}

vec3 colorFromWave(vec2 w)
{
    // Mix modulation styles from B
    float r = 0.1 + 0.6 * sin(w.x * 25.0 + iTime * 0.5);
    float g = 0.4 + 0.5 * cos(w.y * 10.0 - iTime * 0.7);
    float b = 0.3 + 0.3 * sin(w.x * 8.0 + w.y * 4.0 + iTime * 0.2);
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Initialize with strong time-based offset and inversion
    uv = uv * 2.0 - 1.0;
    uv *= 1.0 + sin(iTime * 1.5) * 0.3;

    // 1. Extreme rotational warp based on UV interaction
    float angle1 = iTime * 0.6 + uv.x * uv.y * 4.0;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv = rotationMatrix * uv;

    // 2. Complex radial expansion and compression
    vec2 center = vec2(0.5);
    vec2 dir = uv - center;
    float dist = length(dir);
    float scale_factor = 1.5 + sin(iTime * 2.0) * 0.5;
    uv = center + dir * dist * scale_factor;

    // 3. Deep layered distortion (using A structure)
    uv = distort(uv);

    // 4. Input into wave system
    vec2 w = waveB(uv * 3.0);

    // 5. Derive base and wave colors
    vec3 col_base = colorFromUV(uv * 1.5, iTime * 0.5);
    vec3 wave_color = colorFromWave(w);

    // 6. Depth and glow effects
    float glow = 1.0 - smoothstep(0.0, 0.15, dist);

    // Mix base color and wave color, heavily influenced by glow
    vec3 final_color = mix(col_base, wave_color, glow * 0.9);

    // R/G/B dynamic pulsing based on positional coordinates
    float r_pulse = sin(uv.x * 15.0 + iTime * 3.0) * 0.5;
    float g_pulse = cos(uv.y * 15.0 + iTime * 4.0) * 0.5;

    final_color.r = mix(final_color.r, r_pulse, 0.7);
    final_color.g = mix(final_color.g, g_pulse, 0.7);

    // Final chromatic shift using noise for high frequency detail
    float noise_val = noise(uv * 50.0 + iTime * 5.0).x;
    final_color.b = 0.5 + noise_val * 0.5;

    // Apply glow selectively
    final_color = mix(final_color, vec3(1.0), glow * 0.5);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
