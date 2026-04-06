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

vec2 wave(vec2 uv) {
    float t = iTime * 0.8;
    return vec2(
        sin(uv.x * 6.0 + t * 1.5),
        cos(uv.y * 5.0 + t * 0.7)
    );
}

vec3 colorFromWave(vec2 w) {
    float r = 0.5 * sin(w.x * 10.0 + iTime * 0.4);
    float g = 0.3 + 0.5 * cos(w.y * 8.0 - iTime * 0.3);
    float b = 0.7 * sin(w.x * 4.0 + w.y * 2.0 + iTime * 1.0);
    return vec3(r, g, b);
}

vec2 smoothDistort(vec2 uv, float distortionNoiseMultiplier)
{
    float t = iTime * 0.6;
    float scale = 2.5;
    uv *= scale;
    uv.x += sin(uv.y * 6.0 + t * distortionNoiseMultiplier) * 0.15;
    uv.y += cos(uv.x * 4.5 + t * 0.5) * 0.15;
    return uv;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Start position shift and distortion influence
    uv = smoothDistort(uv, 1.8 + sin(iTime * 0.7));

    // Base dynamic time warp 
    uv = iTime * 0.4 + uv * 1.1;

    vec2 pos = uv;

    // Rotational terms based on derived noise
    float flow_sig = sin(pos.x * 8.0 + iTime * 2.5);
    float flare_sig = cos(pos.y * 7.0 - iTime * 1.5);

    // Determine different rotation dynamics derived from flow interactions
    float angleWarp = flow_sig * 1.5;
    float axisShift = flare_sig * 0.9;

    mat2 rotR = mat2(cos(angleWarp * 0.8), -sin(angleWarp * 0.8), sin(angleWarp * 0.8), cos(angleWarp * 0.8));
    mat2 rotL = mat2(cos(axisShift * 1.2), -sin(axisShift * 1.2), sin(axisShift * 1.2), cos(axisShift * 1.2));

    vec2 rotated_uv = rotR * pos;
    rotated_uv = rotL * rotated_uv;

    // Calculate wave patterns and base color structure utilizing rotational data intensely
    vec2 w = wave(rotated_uv);
    vec3 color = colorFromWave(w);

    // Introduce a secondary rotational offset based on the opposite direction
    float reverse_flow = sin(pos.x * 12.0 + iTime * 1.8);
    float reflection_angle = cos(pos.y * 6.0 + iTime * 0.6);

    // Layer flow calculations, strongly weighted by spatial variance and time
    float flow = sin(rotated_uv.x * 25.0 + iTime * 2.0) * reflection_angle * 5.0;
    float pulse = sin(rotated_uv.y * 15.0 + iTime * 0.9);

    // Apply smoothstep modulation dynamically influenced by rotations and wave energy
    color.r = smoothstep(0.0, 0.9, rotated_uv.x * 3.5 + flow * 2.0);
    color.g = smoothstep(0.1, 0.8, rotated_uv.y * 4.5 + pulse * 2.5);

    // Sophisticated reflective/correlated adjustment using the inverse rotation structure
    color.b = 0.6 * sin(color.r * 1.2 + rotated_uv.x * 10.0 + reverse_flow * 1.5);

    // Final coloration step incorporating diagonal complexity and inversion
    color.r = sin(color.g * 18.0 + rotated_uv.y * 7.0 + iTime * 1.2) * 0.55 + 0.4;
    color.g = cos(color.r * 10.0 - rotated_uv.x * 8.5 + iTime * 0.8) * 0.5 + 0.55;
    color.b = 0.75 + 0.2 * sin(iTime * 1.5 + rotated_uv.x * 3.0 + rotated_uv.y * 3.0);

    fragColor = vec4(color,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
