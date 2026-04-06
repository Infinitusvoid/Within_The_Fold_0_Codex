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

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.08,0.36,0.66)+t)); }

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 pulse(vec2 uv) {
    // Modified pulse function for sharper, faster flow modulation
    float t = iTime * 1.5;
    float eff_x = sin(uv.x * 10.0 + t * 6.0); 
    float eff_y = cos(uv.y * 8.0 + t * 5.0); 
    return uv + vec2(eff_x * 0.25, eff_y * 0.15);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // Base warping and distortion introduced by pulsing flow modulation
    vec2 distorted_uv = pulse(uv);

    // Introduction of a dynamic radial ripple
    float r = length(distorted_uv);
    float wave_scale = 10.0 + 2.0 * sin(iTime * 3.0);
    float wave_source = sin(r * 20.0 * wave_scale + iTime * 5.0);

    // Apply distortion based on radial distance
    vec2 final_uv = distorted_uv * (1.0 + wave_source * 0.4);

    // Complex rotation based on time and flow
    float angleA = iTime * 1.2 + final_uv.x * 15.0;
    mat2 rotA = mat2(cos(angleA), -sin(angleA), sin(angleA), cos(angleA));
    vec2 rotated_uv = rotA * final_uv;

    float angleB = iTime * 1.5 + final_uv.y * 12.0;
    mat2 rotB = mat2(cos(angleB), -sin(angleB), sin(angleB), cos(angleB));
    vec2 rotated_uv_final = rotB * rotated_uv;

    // Wave generation focusing on interaction between coordinates and evolved time flow
    float wave_flow = sin(rotated_uv_final.x * 20.0 + iTime * 4.5) * cos(rotated_uv_final.y * 15.0 + iTime * 3.5) * 7.0;

    // Color establishment based on high frequency interactions
    vec3 color_base = vec3(
        sin(iTime * 40.0 + rotated_uv_final.x * 7.0 + wave_flow * 3.0),
        cos(iTime * 35.0 + rotated_uv_final.y * 9.0 - wave_flow * 2.0),
        sin(iTime * 33.0 + rotated_uv_final.x * 13.0 + rotated_uv_final.y * 11.0)
    );

    // Spatial flow injection (enhanced)
    vec2 flow_adj = pulse(rotated_uv_final * 0.8);

    // Palette Modulation using rapid oscillation
    float p = fract(iTime * 80.0 + rotated_uv_final.x * 10.0 + rotated_uv_final.y * 8.0) * 15.0;
    float palette_val = 0.2 + 0.9 * sin(p * 120.0);

    // Apply Palette function
    vec3 pal_color = pal(iTime * 1.2 + palette_val * 0.3);

    // Final color output using hue shifting based on flow
    vec3 final_color = color_base * (0.7 + palette_val * 0.3) * pal_color;

    // Introduce chromatic shift based on flow vectors
    final_color.r += flow_adj.x * 1.2;
    final_color.g += flow_adj.y * 0.9;
    final_color.b += (1.0 - flow_adj.x - flow_adj.y) * 0.05;

    // Introduce an additional layer of localized noise distortion
    float noise_scale = 30.0 + sin(iTime * 1.2) * 15.0;
    vec2 noise_uv = rotated_uv_final * noise_scale;
    float noise_val = sin(noise_uv.x * 11.0 + iTime * 10.0) * cos(noise_uv.y * 10.0 + iTime * 11.0) * 0.35;

    final_color += vec3(noise_val * 0.5, 0.05, -noise_val * 0.3);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
