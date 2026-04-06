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

vec2 wave(vec2 uv) {
    float t = iTime * 0.8;
    return vec2(
        sin(uv.x * 7.0 + t * 1.5),
        cos(uv.y * 5.0 - t * 1.0)
    );
}

float palette(float t) {
    t = fract(t * 3.14159);
    return 0.5 + 0.5 * sin(t * 20.0);
}

vec3 colorFromWave(vec2 w) {
    float r = 0.5 + 0.5 * sin(w.x * 12.0 + iTime * 0.5) * 1.2;
    float g = 0.5 + 0.4 * cos(w.y * 10.0 - iTime * 0.4);
    float b = 0.3 + 0.7 * sin(w.x * 3.0 + w.y * 2.0 + iTime * 0.6);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv) {
    float t = iTime * 0.5;
    float scale = 2.5;
    uv *= scale;
    uv.x += sin(uv.y * 8.0 + t * 2.0) * 0.15; 
    uv.y += cos(uv.x * 6.0 + t) * 0.15; 
    return uv;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Flow and position setup
    float flow_time = iTime * 2.0;
    float flow_mod = flow_time / iResolution.y;

    vec2 uv_offset = uv * 5.0;
    uv_offset.x += sin(uv.y * 10.0 + flow_time * 1.2) * flow_mod * 2.0;
    uv_offset.y += cos(uv.x * 8.0 + flow_time * 0.9) * flow_mod * 1.3;

    vec2 visual_coord = uv_offset; 

    // Dynamic context calculations
    float flow_density = sin(visual_coord.x * 8.0 + flow_time * 3.0);
    float flow_contrast = abs(sin(visual_coord.y * 11.0 - flow_time * 1.5));

    // Texture definitions based on flow constraints
    float flow_stress = flow_density * flow_contrast * 2.0;

    // Distortion (applying structure distortion)
    visual_coord = distort(visual_coord * 1.5 + 0.5);

    // Wave field calculation
    vec2 w = wave(visual_coord * 2.0);

    // Base Volumetric Color
    vec3 color_base = colorFromWave(w);

    // Spatial mixing/mask definition
    float r_mask = mix(0.1, 1.0, smoothstep(0.0, 0.6, visual_coord.x * 15.0 + flow_stress * 4.0));
    float g_mask = mix(0.4, 1.0, smoothstep(0.0, 0.7, visual_coord.y * 14.0 + flow_contrast * 1.8));
    float b_mask = mix(0.2, 1.0, pow(r_mask * g_mask + visual_coord.y * 5.0 * (1.0 - flow_density), 1.2));

    // Apply flow result modification and explicit noise weighting
    vec3 final_color = color_base * 0.7 + vec3(r_mask, g_mask, b_mask) * 0.3;

    // Final time and spatial modulation feedback loop
    final_color.r = sin(final_color.g * 1.1 + visual_coord.y * 4.5) * 0.5 + 0.25;
    final_color.g = cos(final_color.r * 6.0 + visual_coord.x * 7.0 * (1.0 - flow_density) + iTime * 0.2) * 0.4 + 0.15;
    final_color.b = sin(visual_coord.x * 9.0 + visual_coord.y * 9.0 + flow_time * 1.2) * 0.7 + 0.3;

    // Introduce subtle fractal noise modulation based on flow
    float noise_scale = 10.0 + flow_stress * 15.0;
    float noise_val = fract(sin(visual_coord.x * noise_scale + iTime * 1.5));
    final_color += vec3(noise_val * 0.1);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
