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

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 1.1) * 0.4 + 0.5;
    float c = cos(t * 1.3) * 0.3 + 0.6;
    float shift = sin(uv.x * 9.0 + t * 0.3) * 0.15;
    float ripple = cos(uv.y * 14.0 - t * 0.6) * 0.1;
    return uv * vec2(s, c) + vec2(shift, ripple);
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

vec2 wave(vec2 uv) {
    float t = iTime * 0.7;
    return vec2(
        sin(uv.x * 12.0 + t * 4.0),
        cos(uv.y * 8.0 + t * 2.5)
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
    uv *= 1.0 + sin(iTime * 0.7) * 0.25;

    // 1. Complex Motion Baseline (Rotation based on A structure)
    float angle1 = sin(iTime * 0.5) + uv.x * uv.y * 2.0;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv = rotationMatrix * uv;

    float angle2 = iTime * 0.8 + uv.x * 1.5;
    uv = rotate(uv, angle2);

    // 2. Distortion (Combined A/B distortion)
    vec2 distorted_uv = distort(uv, iTime * 1.5);

    // 3. Chain Wave Patterns (Using A's specific waves)
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // 4. Material Data Retrieval (Combining A and B color derivation)
    vec3 col_base = colorFromUV(distorted_uv, iTime);
    vec2 w = waveB(distorted_uv);
    vec3 wave_color = colorFromWave(w);

    // 5. Dynamic Variable Generation ? Palette Application
    float t = distorted_uv.x * 4.0 + distorted_uv.y * 5.0 + iTime * 0.5;
    vec3 col_palette = colorFromUV(distorted_uv, t); // Use A's palette structure

    // Apply variation flows from B
    float flow = sin(distorted_uv.x * 20.0 + iTime * 2.5) * 0.1;
    float warp = cos(distorted_uv.y * 10.0 + iTime * 1.2) * 0.1;

    // Mix base color and palette, weighted by flow
    vec3 final_color = mix(col_base, col_palette, flow * 0.6);

    // 6. Advanced R/G/B Sculpting (Mixing A's complexity and B's depth interaction)
    float radius = length(distorted_uv);
    float dist = 1.0 - smoothstep(0.0, 0.4, radius * 3.0); 

    // Mix the wave color into the base
    final_color = mix(final_color, wave_color, 0.3);

    // R Channel complexity (High frequency displacement from A)
    final_color.r = mix(final_color.r, sin(distorted_uv.x * 22.0 + iTime * 1.2) * 2.0, 0.8);

    // G Channel complexity (mixing wave interaction and radial distortion from B)
    final_color.g = sin(distorted_uv.x * 30.0 + iTime * 1.8) * 0.8 + cos(distorted_uv.y * 11.0 + iTime * 1.0) * dist * 0.4;

    // B Channel definition (using contrast from A and depth from B)
    float contrast = smoothstep(0.25, 0.4, abs(distorted_uv.x * 5.0 - distorted_uv.y * 3.0) * 2.0);
    final_color.b = 0.2 + contrast * 0.8;

    // Final texture application using B's noise
    float texture_val = noise(uv * 20.0 + iTime * 0.5).x * final_color.b;

    // Introduce chromatic shift based on channel interactions
    final_color.b = 0.5 + 0.4 * abs(sin(abs(sin((final_color.g * final_color.r) * 120.0 + texture_val * 60.0)) / (final_color.g * 3.0 + final_color.r * 2.5)) * 0.5);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
