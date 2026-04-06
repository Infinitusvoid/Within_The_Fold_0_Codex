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
        sin(uv.x * 4.5 + t * 1.6),
        cos(uv.y * 3.5 + t * 0.9)
    );
}

vec3 colorFromWave(vec2 w) {
    float r = 0.75 * sin(w.x * 12.0 + iTime * 0.3);
    float g = 0.5 + 0.4 * cos(w.y * 7.0 - iTime * 0.2);
    float b = 0.1 + 0.5 * sin(w.x * 6.0 + w.y * 4.0 + iTime * 0.5);
    return vec3(r, g, b);
}

vec2 smoothDistort(vec2 uv, float distortionNoiseMultiplier)
{
    float t = iTime * 0.6;
    float scale = 2.0;
    uv *= scale;
    uv.x += sin(uv.y * 7.0 + t * distortionNoiseMultiplier) * 0.08;
    uv.y += cos(uv.x * 5.0 + t) * 0.08;
    return uv;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Start position shift and distortion influence
    uv = smoothDistort(uv, 1.5 + sin(iTime * 0.5));

    // Base dynamic time warp 
    uv = iTime * 0.5 + uv * 1.2;

    vec2 pos = uv;

    // Rotational terms based on derived noise
    float flow_sig = sin(pos.x * 7.5 + iTime * 2.0);
    float flare_sig = cos(pos.y * 9.0 - iTime * 1.8);

    // Determine different rotation dynamics derived from flow interactions
    float angleWarp = flow_sig * 0.7;
    float axisShift = flare_sig * 0.5;

    mat2 rotR = mat2(cos(angleWarp * 0.8), -sin(angleWarp * 0.8), sin(angleWarp * 0.8), cos(angleWarp * 0.8));
    mat2 rotL = mat2(cos(axisShift * 0.9), -sin(axisShift * 0.9), sin(axisShift * 0.9), cos(axisShift * 0.9));

    vec2 rotated_uv = rotR * pos;
    rotated_uv = rotL * rotated_uv;

    // Calculate wave patterns and base color structure utilizing rotational data intensely
    vec2 w = wave(rotated_uv);
    vec3 color = colorFromWave(w);

    // Inject enhanced dynamic feedback based on rotation structure
    float pressure = cos(w.x * 4.0) * 0.5 + sin(w.y * 3.0) * 0.5;

    // Layer flow calculations, strongly weighted by spatial variance and time
    float flow = sin(rotated_uv.x * 18.0 + iTime * 1.1) * pressure * 5.0;
    float pulse = cos(rotated_uv.y * 10.0 + iTime * 0.8);

    // Apply smoothstep modulation dynamically influenced by rotations and wave energy
    color.r = smoothstep(0.1, 0.7, rotated_uv.x * 4.5 + flow * 2.5);
    color.g = smoothstep(0.2, 0.65, rotated_uv.y * 5.0 + pulse * 3.0);

    // Sophisticated reflective/correlated adjustment
    color.b = 0.3 * sin(color.r * 2.0 + rotated_uv.x * 6.0 + iTime * 1.0);

    // Final coloration step incorporating diagonal complexity
    color.r = sin(color.g * 12.0 + rotated_uv.y * 5.5 + iTime * 0.9) * 0.5 + 0.3;
    color.g = cos(color.r * 8.0 - rotated_uv.x * 7.0 + iTime * 0.6) * 0.6 + 0.4;
    color.b = 0.6 + 0.4 * sin(iTime * 1.2 + rotated_uv.x * 2.0 + rotated_uv.y * 2.0);

    fragColor = vec4(color,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
