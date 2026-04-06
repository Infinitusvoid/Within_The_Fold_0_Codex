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
    // More intense flow modulation
    float t = iTime * 2.5;
    float eff_x = sin(uv.x * 10.0 + t * 7.0); 
    float eff_y = cos(uv.y * 12.0 + t * 6.5); 
    return uv + vec2(eff_x * 0.4, eff_y * 0.3);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // 1. Flow field setup
    vec2 flow = pulse(uv * 2.0);

    // 2. Coordinate Warping and Rotation
    vec2 warped_uv = uv + flow * 0.5;

    float angle = warped_uv.x * 8.0 + iTime * 2.0;
    mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 rotated_uv = rot * warped_uv;

    // 3. Geometric Shape setup
    // Adjust shape parameters for a different feel
    float d1 = circle(rotated_uv, vec2(-iTime * 0.4, 0.0), 0.2);
    float d2 = circle(rotated_uv, vec2(iTime * 0.4, 0.0), 0.2);
    float d = smin(d1, d2, 0.1);

    // Create a shape mask based on distance
    float shape = smoothstep(0.001, 0.0, d);

    // 4. Wave generation (Increased interaction)
    float wave_flow = sin(rotated_uv.x * 15.0 + iTime * 4.0) * cos(rotated_uv.y * 15.0 + iTime * 4.1) * 4.0;

    // 5. Color establishment (Focusing on depth and flow interaction)
    vec3 color_base = vec3(
        sin(iTime * 45.0 + rotated_uv.x * 10.0 + wave_flow * 3.0),
        cos(iTime * 60.0 + rotated_uv.y * 8.0 - wave_flow * 2.0),
        sin(iTime * 30.0 + rotated_uv.x * 9.0 + rotated_uv.y * 5.0)
    );

    // Apply shape modulation, making shapes more defining
    color_base *= shape * 10.0;

    // Spatial shift and flow modulation
    vec2 flow_adj = pulse(rotated_uv * 2.5);

    // Modulation: mix base color with time-based amplitude shift
    float flow_mix = flow_adj.x * 1.2 + flow_adj.y * 0.9;
    color_base *= 0.5 * (1.0 + 0.6 * sin(iTime * 2.0)) + flow_mix;

    // Palette Modulation using faster oscillation
    float p = fract(iTime * 80.0 + rotated_uv.x * 20.0 + rotated_uv.y * 10.0) * 10.0;
    float palette_val = 0.15 + 0.8 * sin(p * 120.0);

    // Final color output
    vec3 final_color = color_base * (0.4 + palette_val * 0.5);

    // Introduce chromatic shift based on flow
    final_color.r += flow_adj.x * 0.9;
    final_color.g += flow_adj.y * 0.7;
    final_color.b += (1.0 - flow_adj.x - flow_adj.y) * 0.2;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
