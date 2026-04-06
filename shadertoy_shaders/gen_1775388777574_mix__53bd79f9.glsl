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
    float r = 0.5 + 0.5 * sin(t * 0.8 + iTime * 0.5);
    float g = 0.3 + 0.7 * sin(t * 1.3 + iTime * 0.3);
    float b = 0.1 + 0.6 * cos(t * 1.5 - iTime * 0.2);
    return vec3(r, g, b);
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 9.0 + iTime * 2.0), cos(uv.y * 7.0 - iTime * 3.0));
}

vec2 waveA(vec2 uv)
{
    return uv * 5.0 + vec2(
        sin(uv.x * 11.0 + iTime * 0.8) * 0.2,
        cos(uv.y * 9.0 - iTime * 1.1) * 0.4
    );
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

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.05,0.35,0.75)+t)); }

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.5;
    float scale = 1.0 + 0.03 * sin(t + uv.x * 12.0);
    float shift = 1.0 + 0.05 * cos(t + uv.y * 10.0);
    uv.x *= scale;
    uv.y *= shift;
    uv.x += sin(uv.y * 5.0 + t * 3.0) * 0.15;
    uv.y += cos(uv.x * 9.0 + t * 1.8) * 0.1;
    return uv;
}

vec3 colorFromWave(vec2 w)
{
    // Mix modulation styles
    float r = 0.3 + 0.6 * sin(w.x * 20.0 + iTime * 0.5);
    float g = 0.6 + 0.4 * cos(w.y * 12.0 - iTime * 0.7);
    float b = 0.2 + 0.3 * sin(w.x * 5.0 + w.y * 3.0 + iTime * 0.3);
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // --- Shader A components (Geometric filtering and warping setup) ---
    // Calculate subtle distance effect
    float x_offset = 0.25 * sin(iTime * 1.5);
    float d1 = circle(uv, vec2(-x_offset, 0.0), 0.20);
    float d2 = circle(uv, vec2( x_offset, 0.0), 0.20);
    float d = smin(d1, d2, 0.15);
    float shape_mask = smoothstep(0.01, 0.0, d);

    // --- Shader B components (Polar flow and distortion) ---

    // Calculate polar coordinates
    vec2 center_uv = vec2(0.5);
    vec2 offset = uv - center_uv;
    float r = length(offset);
    float a = atan(offset.y, offset.x);

    // Flow calculations based on angle and radius
    float flow_speed = 2.0 + iTime * 1.5;
    float z = floor((1.0/(r+0.1) + iTime*3.0)*8.0)/8.0;

    // Phase calculation based on angular flow
    float phase = a * 20.0 + r * 5.0 + iTime * 1.0 + a * 10.0;
    float f = sin(phase * flow_speed);

    // Ripple effect based on distance and angular position
    float ripple = sin(r * 25.0 + iTime * 5.0) * 0.2 * (1.0 + abs(a));

    // Modulate color input based on radial position and time flow
    float palette_input = r * 1.5 + ripple * 0.7 + iTime * 0.8;

    // Contrast modulation
    float m = smoothstep(0.2, 0.1, abs(f * 2.0));

    // Noise input
    float n = noise(uv * 12.0 + iTime * 0.3);

    // Falloff (sharper falloff)
    float dist_falloff = exp(-r * r * 2.0);

    // --- Integration ---

    // Use B's complex UV distortion
    vec2 distorted_uv = distort(uv);

    // Apply wave structure (B: waveB then A: waveA)
    vec2 base_wave = waveB(distorted_uv);
    vec2 wave_A_shift = waveA(base_wave);

    // Apply spatial flow based on time and position (B flow structure)
    float flow_x = iTime * 0.5 + distorted_uv.x * 3.0;
    float flow_y = iTime * 0.3 + distorted_uv.y * 4.0;

    // Rotational flow based on time and position (Mixed A/B rotation structure)
    float t = iTime * 3.0;
    float rot_angle = t * 1.2 + sin(distorted_uv.y * 15.0) * 1.0;

    vec2 rotated_uv = rotate(distorted_uv, rot_angle);

    // Generate dynamic value based on complex interaction
    float depth = rotated_uv.y * 5.0 + flow_x * 10.0;

    // Intensity modulation based on wave and depth interaction
    float intensity = 1.0 - abs(sin(base_wave.x * 25.0 + depth * 5.0 + t * 0.7)) * 0.45;

    // Calculate refracted colors and applying flow complexity
    vec3 base_color = colorFromWave(wave_A_shift);

    vec3 refracted_color = base_color * (0.5 + 0.5 * flow_x);

    // Subtle depth visualization offset
    float shift = sin(depth * 8.0) * 0.4;
    refracted_color.r += shift * 1.1;
    refracted_color.g -= shift * 1.5;
    refracted_color.b += 0.3 * sin(rotated_uv.x * 12.0);

    // Final color mixing and enhancement
    vec3 final_col = refracted_color;

    // Final trigonometric mapping
    final_col.r = sin(final_col.g * 2.2 + iTime * 1.0);
    final_col.g = cos(final_col.r * 2.8 + rotated_uv.y * 12.0 + t * 0.7);
    final_col.b = 0.4 + 0.6 * sin(base_wave.x * 1.8 + depth / 6.0 + iTime * 0.4);

    // Apply dynamic layering scale
    final_col = final_col * intensity;

    // Apply geometric shape mask (from A)
    final_col *= (1.0 - shape_mask) * 0.5 + shape_mask * 1.5;

    // Apply noise modulation (from A)
    final_col = mix(final_col, vec3(noise(distorted_uv * 12.0 + iTime * 0.3) * 0.6 + 0.3), 0.4);

    // Apply radial falloff (from B)
    final_col *= dist_falloff * (1.0 + r * 0.6);

    // Final intensity adjustment
    final_col *= 1.5;

    fragColor = vec4(final_col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
