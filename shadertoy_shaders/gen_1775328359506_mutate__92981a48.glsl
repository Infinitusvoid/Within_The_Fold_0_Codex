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
        sin(uv.x * 5.0 + t * 1.5),
        cos(uv.y * 4.0 + t * 0.8)
    );
}

vec3 colorFromWave(vec2 w) {
    float r = 0.5 + 0.5 * sin(w.x * 10.0 + iTime * 0.5);
    float g = 0.5 + 0.5 * cos(w.y * 8.0 - iTime * 0.4);
    float b = 0.3 + 0.7 * sin(w.x * 3.0 + w.y * 2.0 + iTime * 0.6);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.6;
    float scale = 1.5;
    uv *= scale;
    uv.x += sin(uv.y * 5.0 + t) * 0.05;
    uv.y += cos(uv.x * 5.0 + t) * 0.05;
    return uv;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Apply distortion from B
    uv = distort(uv);

    // Primary time/scale warping (A original source)
    uv = uv * 2.0 - 1.0;
    uv *= 1.0 + sin(iTime * 1.5) * 0.3;

    // Calculate rotation patterns based on refined deformation
    float angleA = iTime * 0.5 + uv.x * uv.y * 2.5;
    mat2 rotA = mat2(cos(angleA), -sin(angleA), sin(angleA), cos(angleA));

    float angleB = sin(iTime * 0.7) + uv.x * uv.y * 1.5;
    mat2 rotB = mat2(cos(angleB), -sin(angleB), sin(angleB), cos(angleB));

    // Apply rotations recursively to UV space
    uv = rotA * uv;
    uv = rotB * uv;

    // Intermediate flow calculations layered on screen
    float pulseBase = sin(iTime * 10.0);

    // Calculate wave patterns
    vec2 w = wave(uv);

    // Color set 1 based purely on pattern
    vec3 coreColor = colorFromWave(w);

    // Introduce flow (less pronounced static flow, more interactive offset)
    float flowOffset = sin(uv.x * 20.0 + iTime * 1.2) * 0.05;
    float intensityMod = cos(uv.y * 10.0 - iTime * 0.9) * 0.1;

    // Modulation adjustments
    // R becomes wave color influenced by positional flow
    float r_modulation = flowOffset + intensityMod;

    // Introduce density wave using rotated coordinates
    float density = sin(uv.x * 5.0 + iTime) * cos(uv.y * 5.0 + iTime / 3.0);
    coreColor.r *= (0.7 + density * 0.3);
    coreColor.b *= (0.5 + density * 0.2);

    // Final output color based on rotations and complex feedback mixing
    // Apply angular reflection heavily filtered by flow noise
    float modulated_r = mix(coreColor.r, 0.1 + 0.5 * sin(angleA * 2.0), abs(flowOffset * 5.0));
    float modulated_g = mix(coreColor.g, -0.5 + 0.5 * cos(angleB * 1.5), 1.0 - abs(intensityMod));
    float modulated_b = coreColor.b + iTime * 0.5 + density;

    fragColor = vec4(modulated_r + 0.1, modulated_g + 0.3, modulated_b, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
