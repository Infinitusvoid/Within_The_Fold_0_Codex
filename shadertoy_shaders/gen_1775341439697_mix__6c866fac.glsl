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

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 10.0 + iTime * 1.5), cos(uv.y * 8.0 - iTime * 1.1));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.8 + iTime * 0.5);
    float g = 0.3 + 0.7 * sin(t * 1.3 + iTime * 0.3);
    float b = 0.1 + 0.6 * cos(t * 1.5 - iTime * 0.2);
    return vec3(r, g, b);
}

vec2 waveA(vec2 uv)
{
    return uv * 3.5 + vec2(
        sin(uv.x * 7.0 + iTime * 1.0) * 0.15,
        cos(uv.y * 5.5 - iTime * 0.9) * 0.1
    );
}

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.02,0.28,0.6)+t)); }

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

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // --- Combined Wave and Flow Initialization ---

    // Apply wave structure derived from A
    vec2 warped_uv = waveB(uv);

    // Apply rotational flow based on complex angle (from A)
    float angle = iTime * 0.3 + uv.x * 5.5;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    warped_uv = rotationMatrix * warped_uv;

    // Apply secondary wave structure (from A)
    warped_uv = waveA(warped_uv);

    // Apply rotational flow and curl warping (from B)
    vec2 flow = uv * vec2(10.0, 5.0) - vec2(0.5, 0.5);
    vec2 f = curl(flow);
    f = curl(f);
    f = curl(f);

    // Introduce vertical shearing based on time (from B)
    f.x += iTime * 0.5;

    // Apply spatial distortion (from B)
    f = distort(f);

    // --- Distance and Glow Mechanism (from A) ---

    // Calculate polar coordinates and distance
    float a = atan(f.y, f.x);
    float r = length(f);

    float d = 1.0/(f.y + 1.15);
    float x_b = f.x * d * 4.0;
    float z_b = d + iTime * 2.0;

    // Glow calculation
    float lx = smoothstep(0.08, 0.0, abs(fract(x_b)-0.5));
    float lz = smoothstep(0.08, 0.0, abs(fract(z_b)-0.5));
    float glow = (lx + lz) * 0.6 / (1.0 + 0.15 * d * d);

    // --- Color Generation (Combining Pattern and Wave Colors) ---

    // Use dynamic time/position for pattern generation (from B)
    vec3 col1 = pattern(f * 1.8, iTime * 2.2);
    vec3 col2 = pattern(f * 0.8 + iTime * 0.5, iTime * 1.7);

    // Combine the palette modulation (A) with the wave flow interaction (B) and glow
    float t = sin(f.x * 7.0 + iTime * 2.0) + cos(f.y * 6.0 + iTime * 0.8);

    vec3 final_col = palette(t * 1.8);
    final_col = mix(final_col, vec3(0.03, 0.18, 0.04), glow * 0.5);

    // Introduce fractal noise based on high frequency interaction (A)
    float noise_factor = sin(f.x * 20.0 + iTime * 3.5) * cos(f.y * 12.0 - iTime * 1.0);

    // Apply color from wave interaction (B)
    final_col.r = colorFromWave(f * 2.5).r * 0.6 + 0.3 * sin(d * 0.5);
    final_col.g = colorFromWave(f * 1.8).g * 0.7 + 0.1 * cos(d * 0.5);
    final_col.b = colorFromWave(f * 3.5).b * 0.85 + 0.05;

    // Blend with pattern colors
    final_col = mix(final_col, col1 * 0.5 + col2 * 0.5, noise_factor * 0.5);

    // Introduce chromatic aberration based on UV position and flow (A)
    float aberration = abs(uv.x - 0.5) * 3.0;
    final_col.r += aberration * 0.15;
    final_col.b -= aberration * 0.15;

    // Intensity adjustment based on time variation (A)
    float intensity = 1.0 + 0.5 * sin(iTime * 0.5);
    final_col *= intensity;

    fragColor = vec4(final_col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
