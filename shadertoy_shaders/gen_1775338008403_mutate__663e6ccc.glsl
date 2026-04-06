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
    // Slightly adjusted pulse for faster, more intense flow modulation
    float t = iTime * 2.5;
    float eff_x = sin(uv.x * 7.0 + t * 5.0); 
    float eff_y = cos(uv.y * 5.0 + t * 4.0); 
    return uv + vec2(eff_x * 0.15, eff_y * 0.1);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // Base warping and distortion introduced by pulsing flow modulation
    vec2 distorted_uv = pulse(uv);

    // Introduction of a radial wave based on time and position
    float r = length(distorted_uv);
    float wave_scale = 1.5 + 2.5 * sin(iTime * 2.0);
    float wave_source = sin(r * 6.0 * wave_scale + iTime * 1.5);

    // Apply distortion based on radial distance
    vec2 final_uv = distorted_uv * (1.0 + wave_source * 0.3);

    // Complex rotation based on time and flow
    float angleA = iTime * 0.7 + final_uv.x * 9.0;
    mat2 rotA = mat2(cos(angleA), -sin(angleA), sin(angleA), cos(angleA));
    vec2 rotated_uv = rotA * final_uv;

    float angleB = iTime * 0.9 + final_uv.y * 7.0;
    mat2 rotB = mat2(cos(angleB), -sin(angleB), sin(angleB), cos(angleB));
    vec2 rotated_uv_final = rotB * rotated_uv;

    // Wave generation focusing on interaction between coordinates and evolved time flow
    float wave_flow = sin(rotated_uv_final.x * 12.0 + iTime * 2.0) * cos(rotated_uv_final.y * 9.0 + iTime * 2.5) * 2.8;

    // Color establishment based on high frequency interactions
    vec3 color_base = vec3(
        sin(iTime * 18.0 + rotated_uv_final.x * 4.0 + wave_flow * 3.0),
        cos(iTime * 14.0 + rotated_uv_final.y * 6.0 - wave_flow * 2.0),
        sin(iTime * 16.0 + rotated_uv_final.x * 8.0 + rotated_uv_final.y * 7.0)
    );

    // Spatial flow injection
    vec2 flow_adj = pulse(rotated_uv_final * 0.8);

    // Modulation: mix structure color with time-based amplitude shift
    float flow_mix = flow_adj.x * 2.0 + abs(flow_adj.y) * 1.2;
    color_base *= 0.5 * (1.0 + 0.6 * sin(iTime * 4.0)) + flow_mix;

    // Palette Modulation for final vibrance shifts
    float p = fract(iTime * 22.0 + rotated_uv_final.x * 6.0 + rotated_uv_final.y * 5.0) * 7.0;
    float palette_val = 0.1 + 0.9 * sin(p * 55.0);

    // Final color output using dynamic mixing
    vec3 final_color = mix(color_base * 0.4, vec3(palette_val * 1.8, palette_val * 0.6, palette_val * 1.0), palette_val * 0.5);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
