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

vec2 floatRotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave_geom(vec2 uv) {
    float t = iTime * 0.5;
    return vec2(
        sin(uv.x * 7.0 + t * 0.5),
        cos(uv.y * 5.0 - t * 0.7)
    );
}

vec3 palette_util(float t) {
    // Shift the palette based on the time and influence
    vec3 c = vec3(0.1 + 0.5*sin(t * 3.0 + iTime * 0.1), 0.1 + 0.5*cos(t * 2.5 + iTime * 0.2), 0.1 + 0.5*sin(t * 1.8 + iTime * 0.3));
    return c * 0.5 + 0.5;
}

vec2 noise(vec2 uv)
{
    // More chaotic noise behavior
    return vec2(sin(uv.x * 8.0 + iTime * 0.5), cos(uv.y * 6.5 - iTime * 0.3));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // --- Geometric Distortion and Rotation Setup ---

    float t = iTime * 0.8;
    vec2 plane_uv = uv;

    // Apply initial noise distortion
    vec2 pos = uv * 3.0 + iTime * 0.6;
    vec2 distortion = noise(pos * 2.5);
    plane_uv += distortion * 0.15;

    // Modified UV scaling based on T
    float scale = 1.5 + sin(iTime * 2.5) * 0.5;
    plane_uv *= scale;

    // Rotation Layer 1 
    float angle1 = sin(iTime * 0.4) + plane_uv.x * plane_uv.y * 5.0;
    plane_uv = floatRotate(plane_uv, angle1);

    // Rotation Layer 2 
    float angle2 = iTime * 0.6 + plane_uv.x * 3.5 + plane_uv.y * 2.0;
    plane_uv = floatRotate(plane_uv, angle2);

    // Introduce Strong Stretching
    plane_uv *= 1.8;

    // Base Distortion mixing
    plane_uv += vec2(
        sin(plane_uv.x * 1.2 + iTime * 1.1),
        cos(plane_uv.y * 2.0 + iTime * 0.9) * 0.7
    );

    // --- Wave Pattern Calculation ---

    vec2 w = wave_geom(plane_uv);

    // --- Core Color Shaping ---

    float t_color = (plane_uv.x * 15.0 + plane_uv.y * 10.0) * 0.6 + iTime * 0.5;
    vec3 col = palette_util(t_color);

    // Time interaction in the base color layering components
    col += 0.8 * sin(iTime * 0.18 + plane_uv.x * 9.0 + plane_uv.y * 5.5);

    // Fine aesthetic separation and flow
    float layer1 = sin(plane_uv.x * 7.0 + iTime * 1.5) * plane_uv.y * 1.2;
    float layer2 = cos(plane_uv.y * 10.0 - iTime * 0.8) * plane_uv.x * 0.8;

    // Re-weight R modulation
    float modulated_r = 0.5 + 0.25 * layer1 + 0.35 * layer2;

    // Set final R temporarily
    col.r = modulated_r;

    // Enhance G component flow aggressively
    col.g = sin(plane_uv.x * 16.0 + iTime * 0.7) + cos(plane_uv.y * 8.5 + iTime * 0.5);

    // Cross-Channel Mixing
    col.r = mix(col.r, col.g * 0.5, 0.7 + iTime * 0.1);

    // Introduce sharper contrast using plane position variance
    float contrast_mask = abs(plane_uv.x - plane_uv.y * 1.5) * 5.0;
    float edge_layer = smoothstep(0.4, 0.65, contrast_mask);

    // Determine B base
    col.b = 0.6 + layer2 * 0.6 + edge_layer * 0.4;

    // Final advanced layering
    float texture_val = sin(plane_uv.x * 200.0 + iTime * 10.0);

    // Complex modulated noise addition to B
    float deep_sub_expression = sin(abs(sin((col.g * col.r) * 60.0)) / (col.g + col.r * 0.6)) * texture_val * 0.6;

    col.b = 0.85 + deep_sub_expression;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
