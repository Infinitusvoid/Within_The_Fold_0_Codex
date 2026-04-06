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

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 pulse(vec2 uv) {
    // Modified pulse function for sharper, faster flow modulation
    float t = iTime * 1.5;
    float eff_x = sin(uv.x * 8.0 + t * 5.0); 
    float eff_y = cos(uv.y * 7.0 + t * 4.5); 
    return uv + vec2(eff_x * 0.3, eff_y * 0.2); // Increased intensity
}

vec2 flowB(vec2 uv)
{
    return vec2(sin(uv.x * 5.0 + iTime * 2.0), cos(uv.y * 5.0 + iTime * 3.0));
}

vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 8.0 + iTime * 1.2) * 0.4,
        sin(uv.y * 4.0 + iTime * 0.8) * 0.3
    );
}

vec3 pal(float t)
{
    return 0.5 + 0.5*sin(6.28318*(vec3(0.1, 0.3, 0.7) + t));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // Combined Flow and Distortion (from B)
    uv = flowB(uv);
    uv = flowA(uv);

    // Apply pulse distortion (from A)
    vec2 distorted_uv = pulse(uv);

    // Radial/Angular Effects (from B)
    vec2 uv_final = distorted_uv;
    float r = length(uv_final);
    float a = atan(uv_final.y, uv_final.x);

    // Depth/Z calculation (from B)
    float t_shift = iTime * 0.3 + iFrame * 0.1;
    float z = floor((1.0/(r+0.2) + t_shift)*5.0)/5.0;

    // Flow-based variations (from B)
    float f1 = sin(12.0*a + 3.0*z - 1.5*iTime);
    float f2 = cos(8.0*r + 2.0*a + 1.0*iTime);

    // Ring calculation (from B)
    float ring = smoothstep(0.2, 0.0, abs(sin(15.0*r - 4.0*iTime)));

    // Bands calculation (from B)
    float bands = smoothstep(0.25, 0.0, abs(f1 * f2));

    // Complex Rotation and Wave generation (from A)

    // Introduction of a dynamic radial ripple with time scaling
    float wave_scale = 4.0 + 3.0 * sin(iTime * 3.0);
    float wave_source = sin(r * 5.0 * wave_scale + iTime * 2.5);

    // Apply radial distortion
    vec2 warped_uv = uv_final * (1.0 + wave_source * 0.25);

    // Complex rotation based on time and flow (from A)
    float angleA = iTime * 1.5 + warped_uv.x * 15.0;
    mat2 rotA = mat2(cos(angleA), -sin(angleA), sin(angleA), cos(angleA));
    vec2 rotated_uv = rotA * warped_uv;

    float angleB = iTime * 1.8 + warped_uv.y * 18.0;
    mat2 rotB = mat2(cos(angleB), -sin(angleB), sin(angleB), cos(angleB));
    vec2 rotated_uv_final = rotB * rotated_uv;

    // Wave generation focusing on interaction between coordinates and evolved time flow (from A)
    float wave_flow = sin(rotated_uv_final.x * 15.0 + iTime * 3.0) * cos(rotated_uv_final.y * 12.0 + iTime * 2.8) * 2.5;

    // Color establishment based on high frequency interactions (from A)
    vec3 color_base = vec3(
        sin(iTime * 25.0 + rotated_uv_final.x * 5.0 + wave_flow * 1.5),
        cos(iTime * 20.0 + rotated_uv_final.y * 6.0 - wave_flow * 0.8),
        sin(iTime * 30.0 + rotated_uv_final.x * 8.0 + rotated_uv_final.y * 7.0)
    );

    // Spatial flow injection (from A)
    vec2 flow_adj = pulse(rotated_uv_final * 1.0);

    // Modulation: mix structure color with time-based amplitude shift
    float flow_mix = flow_adj.x * 2.5 + abs(flow_adj.y) * 1.5;
    color_base *= 0.5 * (1.0 + 0.7 * sin(iTime * 2.5)) + flow_mix;

    // Palette Modulation using a smooth oscillation (from B)
    float t_palette = 0.08*iTime + 0.05*z + 0.1*f1;
    vec3 palette_color = pal(t_palette);

    // Final color output
    vec3 final_color = color_base * (0.5 + palette_color.x * 0.5);

    // Introduce chromatic shift based on flow (from A)
    final_color.r += flow_adj.x * 0.6;
    final_color.g += flow_adj.y * 0.4;
    final_color.b += (1.0 - flow_adj.x - flow_adj.y) * 0.3;

    // Combine effects (from B)
    final_color *= 0.3 + 1.2*bands + 0.5*ring;

    // Apply radial falloff (from B)
    final_color *= exp(-1.0*r * 1.5);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
