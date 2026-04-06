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

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 pulse(vec2 uv) {
    // Faster, more intense flow modulation
    float t = iTime * 2.0;
    float eff_x = sin(uv.x * 10.0 + t * 8.0); 
    float eff_y = cos(uv.y * 12.0 + t * 6.5); 
    return uv + vec2(eff_x * 0.5, eff_y * 0.3);
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 8.0 + iTime * 1.2), cos(uv.y * 9.0 - iTime * 0.9));
}

vec2 waveA(vec2 uv)
{
    return uv * 2.5 + vec2(
        sin(uv.x * 5.0 + iTime * 0.8) * 0.2,
        cos(uv.y * 6.0 - iTime * 0.7) * 0.25
    );
}

vec3 palette(float t)
{
    return 0.05 + 0.9 * sin(6.28318 * t * 3.0 + 3.14159 * vec3(0.1, 0.5, 0.9));
}

vec3 pal(float t)
{
    return 0.05 + 0.9 * sin(6.28318 * t * 3.0 + 3.14159 * vec3(0.1, 0.5, 0.9));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // --- Base Flow and Warping (Combining B and A) ---

    // B's pulse flow definition
    vec2 flow = pulse(uv * 2.5);

    // Apply B's initial warping
    vec2 warped_uv = uv + flow * 0.4;

    // Apply A's wave modulation
    warped_uv = waveB(warped_uv * 1.5);
    warped_uv = waveA(warped_uv * 1.2);

    // --- Rotational Dynamics (From B) ---

    float angle = warped_uv.x * 8.0 + iTime * 3.0;
    mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 rotated_uv = rot * warped_uv;

    // --- Geometric Shape Filtering (From A/B) ---

    // Calculate distance for masking
    float d1 = circle(rotated_uv, vec2(-iTime * 0.3, 0.0), 0.20);
    float d2 = circle(rotated_uv, vec2(iTime * 0.3, 0.0), 0.20);
    float d = smin(d1, d2, 0.25);

    // Create a shape mask based on distance
    float shape = smoothstep(0.002, 0.0, d);

    // --- Color and Depth Calculation (From B) ---

    // Flow/Wave interaction for color modulation
    float wave_flow = sin(rotated_uv.x * 12.0 + iTime * 3.5) * cos(rotated_uv.y * 10.0 + iTime * 4.0) * 3.0;

    // Depth/Z modulation based on distance
    float z = 1.0 / (d * 3.0 + 1.0 + 0.2 * sin(rotated_uv.x * 12.0));

    // Dynamic palette input
    float palette_t = 0.1 * iTime + sin(z * 5.0) * 0.4;

    vec3 col1 = pal(palette_t);

    // Core Color establishment
    vec3 color_base = vec3(
        sin(iTime * 20.0 + rotated_uv.x * 8.0 + wave_flow * 2.5),
        cos(iTime * 25.0 + rotated_uv.y * 7.0 - wave_flow * 1.0),
        sin(iTime * 30.0 + rotated_uv.x * 9.0 + rotated_uv.y * 7.5)
    );

    // Apply shape modulation
    color_base *= shape * 8.0;

    // Spatial shift and flow modulation
    vec2 flow_adj = pulse(rotated_uv * 1.5);

    // Modulation: mix base color with time-based amplitude shift
    float flow_mix = flow_adj.x * 3.0 + abs(flow_adj.y) * 2.0;
    color_base *= 0.6 * (1.0 + 0.7 * sin(iTime * 3.0)) + flow_mix;

    // Palette Modulation
    float p = fract(iTime * 80.0 + rotated_uv.x * 15.0 + rotated_uv.y * 8.0) * 6.0;
    float palette_val = 0.1 + 0.9 * sin(p * 100.0);

    // Final color output
    vec3 final_color = color_base * (0.3 + palette_val * 0.7);

    // Introduce chromatic shift based on flow
    final_color.r += flow_adj.x * 0.7;
    final_color.g += flow_adj.y * 0.5;
    final_color.b += (1.0 - flow_adj.x - flow_adj.y) * 0.3;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
