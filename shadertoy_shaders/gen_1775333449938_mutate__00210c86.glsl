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
    float eff_x = sin(uv.x * 6.0 + t * 4.0); 
    float eff_y = cos(uv.y * 5.0 + t * 3.5); 
    return uv + vec2(eff_x * 0.2, eff_y * 0.15);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // Base warping and distortion introduced by pulsing flow modulation
    vec2 distorted_uv = pulse(uv);

    // Introduction of a radial wave based on time
    float r = length(distorted_uv);
    float wave_scale = 2.0 + 1.5 * sin(iTime * 3.0);
    float wave_source = sin(r * 5.0 * wave_scale + iTime * 1.2);

    // Apply distortion based on radial distance
    vec2 final_uv = distorted_uv * (1.0 + wave_source * 0.2);

    // Complex rotation based on time and flow
    float angleA = iTime * 0.6 + final_uv.x * 8.0;
    mat2 rotA = mat2(cos(angleA), -sin(angleA), sin(angleA), cos(angleA));
    vec2 rotated_uv = rotA * final_uv;

    float angleB = iTime * 0.8 + final_uv.y * 6.0;
    mat2 rotB = mat2(cos(angleB), -sin(angleB), sin(angleB), cos(angleB));
    vec2 rotated_uv_final = rotB * rotated_uv;

    // Wave generation focusing on interaction between coordinates and evolved time flow
    float wave_flow = sin(rotated_uv_final.x * 10.0 + iTime * 1.3) * cos(rotated_uv_final.y * 8.0 + iTime * 1.7) * 2.5;

    // Color establishment based on high frequency interactions
    vec3 color_base = vec3(
        sin(iTime * 15.0 + rotated_uv_final.x * 3.0 + wave_flow * 2.5),
        cos(iTime * 11.0 + rotated_uv_final.y * 5.0 - wave_flow * 1.5),
        sin(iTime * 13.0 + rotated_uv_final.x * 7.0 + rotated_uv_final.y * 6.0)
    );

    // Spatial flow injection
    vec2 flow_adj = pulse(rotated_uv_final * 0.9);

    // Modulation: mix structure color with time-based amplitude shift
    float flow_mix = flow_adj.x * 1.5 + abs(flow_adj.y) * 1.0;
    color_base *= 0.6 * (1.0 + 0.7 * sin(iTime * 3.5)) + flow_mix;

    // Palette Modulation for final vibrance shifts
    float p = fract(iTime * 20.0 + rotated_uv_final.x * 5.0 + rotated_uv_final.y * 4.0) * 6.0;
    float palette_val = 0.05 + 0.8 * sin(p * 45.0);

    // Final color output using saturation variation
    vec3 final_color = mix(color_base * 0.5, vec3(palette_val * 1.5, palette_val * 0.5, palette_val * 0.5), palette_val);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
