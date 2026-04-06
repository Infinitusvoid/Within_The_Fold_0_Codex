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
    float wave_scale = 1.5 + 3.0 * sin(iTime * 1.5); // Increased wave scale dynamism
    float wave_source = sin(r * 5.0 * wave_scale + iTime * 3.0); // Changed wave interaction

    // Apply distortion based on radial distance
    vec2 final_uv = distorted_uv * (1.0 + wave_source * 0.4); // Increased distortion intensity

    // Complex rotation based on time and flow
    float angleA = iTime * 0.8 + final_uv.x * 10.0; // Increased rotation rate
    mat2 rotA = mat2(cos(angleA), -sin(angleA), sin(angleA), cos(angleA));
    vec2 rotated_uv = rotA * final_uv;

    float angleB = iTime * 1.0 + final_uv.y * 8.0; // Increased rotation rate
    mat2 rotB = mat2(cos(angleB), -sin(angleB), sin(angleB), cos(angleB));
    vec2 rotated_uv_final = rotB * rotated_uv;

    // Wave generation focusing on interaction between coordinates and evolved time flow
    float wave_flow = sin(rotated_uv_final.x * 15.0 + iTime * 2.5) * cos(rotated_uv_final.y * 11.0 + iTime * 2.8) * 3.5; // Intensified flow wave

    // Color establishment based on high frequency interactions
    vec3 color_base = vec3(
        sin(iTime * 20.0 + rotated_uv_final.x * 5.0 + wave_flow * 2.5), // Shifted phase
        cos(iTime * 15.0 + rotated_uv_final.y * 7.0 - wave_flow * 2.0), // Shifted phase
        sin(iTime * 18.0 + rotated_uv_final.x * 10.0 + rotated_uv_final.y * 8.0)
    );

    // Spatial flow injection
    vec2 flow_adj = pulse(rotated_uv_final * 0.7);

    // Modulation: mix structure color with time-based amplitude shift
    float flow_mix = flow_adj.x * 2.5 + abs(flow_adj.y) * 1.5;
    color_base *= 0.4 * (1.0 + 0.7 * sin(iTime * 5.0)) + flow_mix * 0.5; // Adjusted mixing weights

    // Palette Modulation for final vibrance shifts
    float p = fract(iTime * 24.0 + rotated_uv_final.x * 7.0 + rotated_uv_final.y * 6.0) * 6.0;
    float palette_val = 0.05 + 0.95 * sin(p * 66.0); // Adjusted palette range and frequency

    // Final color output using dynamic mixing
    vec3 final_color = mix(color_base * 0.3, vec3(palette_val * 2.0, palette_val * 0.7, palette_val * 1.2), palette_val * 0.6);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
