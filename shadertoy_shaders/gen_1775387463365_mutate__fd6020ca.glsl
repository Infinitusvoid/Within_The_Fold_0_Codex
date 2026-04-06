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
    return uv + vec2(
        sin(uv.x * 7.0 + iTime * 0.9),
        cos(uv.y * 5.0 - iTime * 0.7)
    );
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 10.0 + iTime * 1.5), cos(uv.y * 6.0 - iTime * 0.8));
}

vec3 palette(float t)
{
    float r = 0.1 + 0.8 * sin(t * 1.5 + iTime * 0.5);
    float g = 0.3 + 0.7 * cos(t * 1.3 + iTime * 0.3);
    float b = 0.2 + 0.5 * sin(t * 2.0 - iTime * 0.2);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 1.2) * 0.6 + 0.4;
    float c = cos(t * 1.6) * 0.5 + 0.5;
    float shift = sin(uv.x * 15.0 + t * 0.4) * 0.2;
    float ripple = cos(uv.y * 11.0 - t * 0.6) * 0.15;
    return uv * vec2(s, c) + vec2(shift, ripple);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 7.0 + t * 0.5) * 0.5 + 0.5;
    float e = cos(uv.y * 8.0 - t * 0.5) * 0.5 + 0.5;
    float f = 0.1 + sin(uv.x * 4.0 + uv.y * 3.0 + t * 0.7) * 0.4;
    return vec3(d, e, f);
}

float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float circle(vec2 p, vec2 c, float r)
{
    return length(p - c) - r;
}

vec2 pulse(vec2 uv) {
    float t = iTime * 2.8;
    float eff_x = sin(uv.x * 20.0 + t * 8.0); 
    float eff_y = cos(uv.y * 14.0 + t * 7.5); 
    return uv + vec2(eff_x * 0.5, eff_y * 0.4);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Normalize and base inversion setup
    uv = uv * 2.0 - 1.0;

    // 1. Flow field setup
    vec2 flow = pulse(uv * 2.5);

    // 2. Coordinate Warping and Rotation
    vec2 warped_uv = uv + flow * 0.7;

    float angle = warped_uv.x * 5.0 + iTime * 3.0;
    mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 rotated_uv = rot * warped_uv;

    // 3. Geometric Shape setup
    float d1 = circle(rotated_uv, vec2(-iTime * 0.4, 0.0), 0.20);
    float d2 = circle(rotated_uv, vec2(iTime * 0.4, 0.0), 0.20);
    float d = smin(d1, d2, 0.25);

    // Create a shape mask
    float shape = smoothstep(0.0, 0.02, d);

    // 4. Wave generation
    vec2 wave_input = rotated_uv;

    // Apply distortion
    vec2 distorted_uv = distort(wave_input, iTime);

    // Chain Wave Patterns
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // 5. Color establishment
    vec3 col_base = colorFromUV(distorted_uv, iTime);

    // Apply shape modulation
    col_base *= shape * 10.0; 

    // Spatial shift and flow modulation
    vec2 flow_adj = pulse(rotated_uv * 0.8);

    // Modulation
    float flow_mix = flow_adj.x * 2.2 + abs(flow_adj.y) * 0.9;
    col_base *= 0.6 * (1.0 + 0.7 * sin(iTime * 4.0)) + flow_mix;

    // Palette Modulation
    float p = fract(iTime * 80.0 + rotated_uv.x * 16.0 + rotated_uv.y * 8.0) * 10.0;
    float palette_val = 0.05 + 0.9 * sin(p * 100.0);

    // Final color output
    vec3 final_color = col_base * (0.5 + palette_val * 0.5);

    // Introduce chromatic shift based on flow
    final_color.r += flow_adj.x * 0.7;
    final_color.g += flow_adj.y * 0.6;
    final_color.b += (1.0 - flow_adj.x - flow_adj.y) * 0.15;

    // Introduce complexity and radial depth filtering
    vec2 center_uv = vec2(0.5);
    vec2 delta = distorted_uv - center_uv;
    float distance = length(delta);

    float z = 1.0 / (distance * 0.8 + 0.1) + iTime * 2.0;

    float y1 = 0.25 * sin(5.0 * z + iTime);
    float y2 = 0.25 * sin(5.0 * z + iTime + 3.14159);
    float l1 = smoothstep(0.08, 0.0, abs(distorted_uv.y - y1));
    float l2 = smoothstep(0.08, 0.0, abs(distorted_uv.y - y2));

    vec3 radial_color = palette(0.05 * z) * l1 + palette(0.05 * z + 0.5) * l2;
    radial_color *= 0.8 / (1.0 + 3.0 * distance);

    // R Channel complexity
    float r_wave = sin(distorted_uv.x * 30.0 + iTime * 3.0) * 0.85;

    // G Channel complexity
    float g_shift = sin(distorted_uv.y * 15.0 + iTime * 1.5) * 0.7;

    // Mix the radial effect with the flow-based color
    vec3 final_color_raw = mix(radial_color, final_color, 0.45);

    final_color_raw.r = mix(final_color_raw.r, r_wave * l1, 0.65);
    final_color_raw.g = mix(final_color_raw.g, sin(distorted_uv.x * 25.0 + iTime * 2.0) + g_shift * flow_mix, 0.5);
    final_color_raw.b = final_color_raw.b; 

    // Final chromatic shift
    float complexity = abs(sin((final_color_raw.g * final_color_raw.r) * 180.0) / (1.0 + distance * 5.0));

    // Apply complexity filter
    final_color_raw.r = mix(final_color_raw.r, 1.0 - complexity, 0.5);
    final_color_raw.b = mix(final_color_raw.b, complexity * 0.45, 0.5);

    // Apply final time-based channel separation
    final_color_raw.r *= 1.0 + sin(iTime * 2.0) * 0.1;
    final_color_raw.g *= 1.0 - cos(iTime * 1.3) * 0.1;
    final_color_raw.b *= 1.0 + sin(iTime * 3.0) * 0.1;

    fragColor = vec4(final_color_raw, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
