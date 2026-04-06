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

    // Define rotation angles based on time and the newly flowed UV coordinates
    // Exaggerate dependence on flow for dynamic rotation
    float angleA = iTime * 0.5 + distorted_uv.x * 6.0;
    mat2 rotA = mat2(cos(angleA), -sin(angleA), sin(angleA), cos(angleA));
    vec2 rotated_uv = rotA * distorted_uv;

    float angleB = iTime * 0.8 + distorted_uv.y * 5.0;
    mat2 rotB = mat2(cos(angleB), -sin(angleB), sin(angleB), cos(angleB));
    vec2 final_uv = rotB * rotated_uv;

    // Wave generation focusing on interaction between coordinates and evolved time flow
    // Introduce a different frequency interaction
    float wave_source = sin(final_uv.x * 15.0 + iTime * 1.3) * cos(final_uv.y * 8.0 + iTime * 1.7) * 2.2;

    // Color establishment deeply utilizing trigonometric wave input
    // More aggressive phase shifting based on wave_source
    vec3 color_base = vec3(
        sin(iTime * 11.0 + final_uv.x * 5.5 + wave_source * 4.0),
        cos(iTime * 9.0 + final_uv.y * 6.0 - wave_source * 2.5),
        sin(iTime * 13.0 + final_uv.x * 8.5 + final_uv.y * 7.0)
    );

    // Spatial and temporal flow injection
    vec2 flow_adj = pulse(final_uv * 1.2); // Increased flow influence

    // Modulation: mix structure color with pulse scale modulated effect
    // Use flow_adj for stronger linear mixing
    float flow_mix = flow_adj.x * 3.0 + flow_adj.y * 1.5;
    color_base *= 0.3 * (1.0 + 0.7 * sin(iTime * 3.0)) + flow_mix;

    // Palette Modulation for final vibrance changes
    // Use time and flow for more dynamic color mapping
    float p = fract(iTime * 20.0 + final_uv.x * 7.0 + final_uv.y * 10.0) * 5.0;
    float palette_val = 0.05 + 0.8 * sin(p * 40.0);

    // Final additive/subtractive blending via color channel separation
    vec3 final_color = color_base * (0.5 + palette_val * 0.5) + vec3(palette_val * 1.5, 0.1, 0.1);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
