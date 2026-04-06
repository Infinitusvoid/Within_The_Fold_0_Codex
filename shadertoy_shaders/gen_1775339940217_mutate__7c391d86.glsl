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
    return uv * 1.5 + vec2(sin(uv.x * 10.0 + iTime * 2.0) * 0.5, cos(uv.y * 12.0 + iTime * 1.5) * 0.4);
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 6.0 + iTime * 3.0) * cos(uv.y * 5.0), cos(uv.y * 9.0 + iTime * 1.0) * sin(uv.x * 5.0));
}

float palette(float t)
{
    return 0.5 + 0.5 * sin(t * 4.0);
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 1.2) * 0.5 + 0.5;
    float c = cos(t * 1.1) * 0.4 + 0.5;
    float shift = sin(uv.x * 8.0 + t * 0.2) * 0.1;
    float ripple = cos(uv.y * 16.0 - t * 0.7) * 0.15;
    return uv * vec2(s, c) + vec2(shift, ripple);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 5.5 + t * 0.5) * 0.5 + 0.5;
    float e = cos(uv.y * 10.5 - t * 0.6) * 0.4 + 0.5;
    float f = 0.1 + sin(uv.x * 4.0 + uv.y * 3.0 + t * 0.7) * 0.3;
    return vec3(d, e, f);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.8;
    return vec2(
        sin(uv.x * 15.0 + t * 5.0),
        cos(uv.y * 10.0 + t * 3.0)
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
    float r = 0.2 + 0.6 * sin(w.x * 25.0 + iTime * 0.5);
    float g = 0.5 + 0.5 * cos(w.y * 10.0 - iTime * 0.7);
    float b = 0.1 + 0.4 * sin(w.x * 8.0 + w.y * 4.0 + iTime * 0.2);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.35;
    // Scale and shift interaction
    float scale = 1.0 + 0.06 * sin(t + uv.x * 12.0);
    float shift = 1.0 + 0.05 * cos(t + uv.y * 10.0);
    uv.x *= scale;
    uv.y *= shift;
    // Enhanced coupling
    uv.x += sin(uv.y * 7.0 + t * 5.0) * 0.3;
    uv.y += cos(uv.x * 8.0 + t * 2.0) * 0.2;
    return uv;
}

mat2 rotate(float a)
{
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Normalize and base inversion setup
    uv = uv * 2.0 - 1.0;

    // Apply initial timing modulation and structure smoothing
    uv *= 1.0 + sin(iTime * 0.6) * 0.2;

    // 1. Complex Motion Baseline (Modified Rotation)
    float angle1 = sin(iTime * 0.5) + uv.x * uv.y * 1.5;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv = rotationMatrix * uv;

    float angle2 = iTime * 1.2 + uv.x * 2.5;
    uv = rotate(uv, angle2);

    // 2. Distortion (More aggressive interaction)
    vec2 distorted_uv = distort(uv);

    // 3. Chain Wave Patterns (Using B's modified waves)
    distorted_uv = waveB(distorted_uv);
    distorted_uv = waveA(distorted_uv);

    // 4. Material Data Retrieval
    vec3 col_base = colorFromUV(distorted_uv, iTime * 0.5);
    vec2 w = waveB(distorted_uv);
    vec3 wave_color = colorFromWave(w);

    // 5. Dynamic Variable Generation ? Palette Application
    float t = distorted_uv.x * 4.0 + distorted_uv.y * 5.0 + iTime * 0.4;
    vec3 col_palette = colorFromUV(distorted_uv, t); 

    // Apply variation flows from B
    float flow = sin(distorted_uv.x * 20.0 + iTime * 2.5) * 0.1;
    float warp = cos(distorted_uv.y * 15.0 + iTime * 1.5) * 0.15;

    // Mix base color and palette, weighted by flow
    vec3 final_color = mix(col_base, col_palette, flow * 0.8);

    // 6. Advanced R/G/B Sculpting (New interaction logic focusing on phase)
    float radius = length(distorted_uv);
    float dist_factor = smoothstep(0.0, 0.4, radius * 3.0); 

    // Mix the wave color into the base
    final_color = mix(final_color, wave_color, 0.35);

    // R Channel complexity (Focusing on combined phases)
    final_color.r = sin(distorted_uv.x * 30.0 + iTime * 1.8) * 1.5 + cos(distorted_uv.y * 10.0 + iTime * 0.5) * 0.5;

    // G Channel complexity (Mixing distortion and wave interaction)
    final_color.g = sin(distorted_uv.x * 50.0 + iTime * 2.0) * 0.8 + cos(distorted_uv.y * 30.0 + iTime * 1.0) * 0.2;

    // B Channel definition (Using contrast derived from wave interaction)
    float contrast = smoothstep(0.0, 0.6, abs(sin(distorted_uv.x * 10.0 + iTime * 1.0) + distorted_uv.y * 5.0) * 2.0);
    final_color.b = 0.1 + contrast * 0.8;

    // Final texture application using noise interaction
    float texture_val = noise(uv * 40.0 + iTime * 1.0).x * final_color.b;

    // Introduce chromatic shift based on channel interactions (High frequency modulation)
    final_color.b = 0.5 + 0.4 * abs(sin(abs(sin(final_color.r * 5.0 + texture_val * 100.0)) / (final_color.g * 3.0 + final_color.r * 2.5)) * 0.5);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
