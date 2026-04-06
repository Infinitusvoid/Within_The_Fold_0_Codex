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
    return uv + vec2(
        sin(uv.x * 4.0 + iTime * 0.7),
        cos(uv.y * 3.5 - iTime * 0.5)
    );
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 6.0 + iTime * 0.5), cos(uv.y * 7.0 - iTime * 0.4));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.6 + iTime * 0.3);
    float g = 0.4 + 0.6 * sin(t * 1.1 + iTime * 0.2);
    float b = 0.2 + 0.4 * cos(t * 1.5 - iTime * 0.1);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 0.7) * 0.4 + 0.6;
    float c = cos(t * 0.8) * 0.3 + 0.5;
    float shift = sin(uv.x * 14.0 + t * 0.2) * 0.15;
    float ripple = cos(uv.y * 16.0 - t * 0.4) * 0.1;
    return uv * vec2(s, c) + vec2(shift, ripple);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 5.0 + t * 0.3) * 0.5 + 0.5;
    float e = cos(uv.y * 6.0 - t * 0.4) * 0.5 + 0.5;
    float f = 0.2 + sin(uv.x * 3.0 + uv.y * 2.0 + t * 0.5) * 0.3;
    return vec3(d, e, f);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.1,0.4,0.7)+t)); }

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Normalize and base inversion setup
    uv = uv * 2.0 - 1.0;

    // Apply initial timing modulation and structure smoothing
    uv *= 1.0 + sin(iTime * 0.5) * 0.2;

    // 1. Complex Motion Baseline (Rotation)
    float angle1 = sin(iTime * 0.5 + uv.x * 5.0) + uv.y * 2.0;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv = rotationMatrix * uv;

    float angle2 = iTime * 0.6 + uv.x * 1.5 + uv.y * 0.4;
    uv = rotate(uv, angle2);

    // 2. Distortion (Enhanced feedback)
    vec2 distorted_uv = distort(uv, iTime * 0.7);

    // 3. Chain Wave Patterns (Reversed/Mixed)
    vec2 flow_uv = waveB(distorted_uv);
    distorted_uv = waveA(flow_uv);

    // 4. Material Data Retrieval (A)
    vec3 col_base = colorFromUV(distorted_uv, iTime);

    // 5. Dynamic Variable Generation and Repulsion (New approach)
    float t = distorted_uv.x * 8.0 + distorted_uv.y * 4.0 + iTime * 2.0;
    vec3 col_palette = palette(t);

    // Apply repulsion based on distance from center
    float dist_center = length(distorted_uv);
    float repulsion = 1.0 - smoothstep(0.0, 0.1, dist_center);

    // Mix base color and palette using repulsion as modulation
    vec3 mixed_color = mix(col_base, col_palette, repulsion * 0.5 + 0.5);

    // Introduce strong chromatic shift
    vec3 final_color = mixed_color * (1.0 + sin(iTime * 4.0) * 0.1);

    // 6. Radial Depth and Smoothstep Masking (A refined)
    float depth = 1.0 / (dist_center * 1.5 + 0.5) + iTime * 0.5;

    // Use A's smin/circle logic for organic shaping
    float x_offset = 0.5 * sin(iTime * 1.2);
    float d1 = circle(distorted_uv, vec2(x_offset, 0.0), 0.25);
    float d2 = circle(distorted_uv, vec2(-x_offset, 0.0), 0.25);
    float d = smin(d1, d2, 0.1);
    float shape = smoothstep(0.01, 0.0, d);

    // Apply radial color gradient based on depth and shape
    vec3 radial_color = pal(depth * 2.0) * shape;

    // 7. Final Sculpting based on flow and detail

    // R Channel modulation based on flow
    float r_wave = sin(distorted_uv.x * 30.0 + iTime * 3.0) * 0.8;

    // G Channel modulation based on vertical shift and time
    float g_shift = cos(distorted_uv.y * 15.0 + iTime * 1.5) * 0.5;

    // Mix radial effect with base color
    vec3 mixed_color_final = mix(radial_color, final_color, 0.6);

    mixed_color_final.r = mix(mixed_color_final.r, r_wave, 0.7);
    mixed_color_final.g = mix(mixed_color_final.g, g_shift, 0.5);
    mixed_color_final.b = mix(mixed_color_final.b, 1.0 - g_shift, 0.3);

    // Final chromatic complexity based on distance and flow
    float complexity = abs(sin(uv.x * 10.0 + uv.y * 5.0 + iTime) * 2.0) / (1.0 + dist_center * 3.0);

    // Apply complexity filter
    mixed_color_final.r = mix(mixed_color_final.r, 1.0 - complexity, 0.5);
    mixed_color_final.b = mix(mixed_color_final.b, complexity * 0.5, 0.5);

    // Apply final time-based glow
    mixed_color_final *= (1.0 + sin(iTime * 2.0) * 0.15);

    fragColor = vec4(mixed_color_final, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
