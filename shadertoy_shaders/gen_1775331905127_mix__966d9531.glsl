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
    float t = iTime * 0.5;
    return vec2(
        sin(uv.x * 5.0 + t * 1.5 + uv.y * 2.5),
        cos(uv.y * 4.0 + t * 0.8 + uv.x * 1.2)
    );
}

vec3 pattern(vec2 uv, float t)
{
    float g = sin(uv.x * 8.0 + t);
    float h = cos(uv.y * 6.0 + t * 0.5);
    float index = (uv.x + uv.y) * 15.0 - iTime * 0.1 * t;
    float v = fract(sin(index) * 28.0);
    return vec3(g, h, 0.5 + 0.5 * sin(v + t));
}

vec2 curl(vec2 uv)
{
    float angle = iTime * 0.3 + sin(uv.x) * cos(uv.y) * 0.5;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    return rotationMatrix * uv;
}

float palette(float t) {
    t = fract(t * 3.14159);
    return 0.5 + 0.5 * sin(t * 20.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0; // Normalized coordinates [-1, 1]

    // --- Flow Field Generation (Shader B influence) ---
    float flow_time = iTime * 1.5;
    float flow_mod = flow_time / iResolution.y;

    vec2 uv_offset = uv * 6.0;
    uv_offset.x += sin(uv.y * 11.0 + flow_time * 0.8) * flow_mod * 1.5;
    uv_offset.y += cos(uv.x * 7.0 + flow_time * 0.5) * flow_mod * 0.7;

    vec2 finalUV = uv_offset;

    // --- Field Warping (Shader A influence) ---
    vec2 f = curl(finalUV);
    f = curl(f); // Apply second curl warp

    // Apply Wave distortion based on warped coordinates
    vec2 w = wave(f);

    // --- Dynamic Metrics and Color Base (Shader B influence) ---

    // Calculate dynamic base variables influenced by displacement
    float density = sin(finalUV.x * 10.0 + flow_time * 2.0);
    float contrast = abs(sin(finalUV.y * 9.0 - flow_time * 1.1));
    float depth = 1.0 - abs(finalUV.x * 0.5);

    // Use density/contrast to modulate flow complexity and luminosity
    float flow_stress = density * contrast * 1.8;
    float time_weight = flow_time * 0.4 + uv.x * 0.15;

    // Primary color generation based on interaction (Shader A complexity)
    vec3 base_color = vec3(
        sin(iTime * 7.0 + f.x * 4.0 + w.x * 1.8),
        cos(iTime * 9.0 + f.y * 5.0 + w.y * 1.5),
        sin(f.x * 8.0 + f.y * 6.0 + time_weight * 12.0)
    );

    // Generate final color by applying palette influenced by depth and stress
    float p = palette(iTime * 2.5 + f.x * 1.0);

    // Mix base color with a color derived from palette and stress
    vec3 modulated_color = mix(base_color, vec3(p * 1.5 - contrast * 0.2), flow_stress);

    // Apply depth modulation based on spatial position
    modulated_color *= depth * 1.5;

    // Final output
    fragColor = vec4(modulated_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
