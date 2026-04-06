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
    // Subtle alteration in oscillation speed and scale for flow
    float t = iTime * 0.5;
    float eff_x = sin(uv.x * 5.5 + t * 3.1); // Increased freq / oscillation control
    float eff_y = cos(uv.y * 4.5 + t * 2.4); // Stronger y rotation effect
    return uv + vec2(eff_x * 0.15, eff_y * 0.1);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // Base warping and distortion introduced by pulsing flow modulation
    vec2 distorted_uv = pulse(uv);

    // Define rotation angles based on time and the newly flowed UV coordinates
    float angleA = iTime * 0.35 + distorted_uv.x * 4.0;
    mat2 rotA = mat2(cos(angleA), -sin(angleA), sin(angleA), cos(angleA));
    vec2 rotated_uv = rotA * distorted_uv;

    float angleB = iTime * 0.6 + distorted_uv.y * 3.0;
    mat2 rotB = mat2(cos(angleB), -sin(angleB), sin(angleB), cos(angleB));
    vec2 final_uv = rotB * rotated_uv;

    // Wave generation focusing on interaction between coordinates and evolved time flow
    float wave_source = sin(final_uv.x * 10.0 + iTime * 0.9) * cos(final_uv.y * 5.5 + iTime * 1.3) * 1.5;

    // Color establishment deeply utilizing trigonometric wave input
    vec3 color_base = vec3(
        sin(iTime * 8.0 + final_uv.x * 4.5 + wave_source * 2.0),
        cos(iTime * 5.5 + final_uv.y * 3.5 - wave_source * 0.8),
        sin(iTime * 9.0 + final_uv.x * 6.0 + final_uv.y * 4.5)
    );

    // Spatial and temporal flow injection
    vec2 flow_adj = pulse(final_uv * 1.2); // Applied flow distortion influence

    // Modulation: mix structure color with pulse scale modulated effect
    float flow_mix = flow_adj.x * 1.5 + abs(flow_adj.y) * 0.5;
    color_base *= 0.5 * (1.0 + 0.5 * sin(iTime * 2.0)) + flow_mix;

    // Palette Modulation for final vibrance changes
    float p = fract(iTime * 12.7 + final_uv.x * 4.0 + final_uv.y * 5.5) * 3.0;
    float palette_val = 0.2 + 0.6 * sin(p * 25.0);

    // Final additive/subtractive blending via variation in saturation shift
    vec3 final_color = mix(color_base * 0.8, vec3(palette_val * 1.5, palette_val * 0.5, palette_val * 0.6), palette_val);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
