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
    // A combination style influenced pattern generator
    float t = iTime * 0.7;
    float eff_x = sin(uv.x * 6.5 + t * 2.0);
    float eff_y = cos(uv.y * 4.0 - t * 1.5);
    return uv + vec2(eff_x * 0.1, eff_y * 0.1);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // Base warping and movement
    vec2 distorted_uv = pulse(uv);

    // Complex layer of rotation applied based on evolving coordinates
    float angleA = iTime * 0.3 + distorted_uv.x * 3.0;
    mat2 rotA = mat2(cos(angleA), -sin(angleA), sin(angleA), cos(angleA));
    vec2 rotated_uv = rotA * distorted_uv;

    float angleB = iTime * 0.5 + distorted_uv.y * 2.0;
    mat2 rotB = mat2(cos(angleB), -sin(angleB), sin(angleB), cos(angleB));
    vec2 final_uv = rotB * rotated_uv;

    // Structure generation (using combined wave/temporal input philosophy)
    float wave_source = sin(final_uv.x * 8.0 + iTime * 1.1) * cos(final_uv.y * 6.0 + iTime * 0.9);

    // Color establishment derived through structured calculation
    vec3 color_base = vec3(
        sin(iTime * 5.0 + final_uv.x * 3.0 + wave_source * 1.5),
        cos(iTime * 6.0 + final_uv.y * 4.0 - wave_source * 1.0),
        sin(iTime * 7.0 + final_uv.x * 2.5 + final_uv.y * 2.0)
    );

    // Apply secondary scaling distortion based on inherent flow modulation
    vec2 flow_adj = pulse(final_uv); // Reprocessing distortion
    color_base *= (0.5 + 0.4 * flow_adj.x);

    // Palette Modulation for final shading variation (Inspired by Shader A/B structure)
    float p = fract(iTime * 6.6 + final_uv.x * 3.2);
    float palette_val = 0.5 + 0.5 * sin(p * 18.0);

    vec3 final_color = mix(color_base, vec3(palette_val, palette_val * 0.8, 0.3 * palette_val), palette_val * 0.7);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
