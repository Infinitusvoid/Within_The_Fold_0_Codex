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
        sin(uv.x * 3.0 + uv.y * 4.0 + t) * cos(uv.x * 1.5 + t * 0.4),
        cos(uv.x * 1.0 - uv.y * 2.0 + t * 0.7) + sin(uv.y * 6.0 + t)
    );
}

float palette(float t) {
    t = fract(t * 0.5);
    return 0.5 + 0.5 * sin(6.28319 * t);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv *= 1.0 + sin(iTime * 1.5) * 0.1;

    // Apply dynamic rotational distortion based on frame and time
    float angleA = iTime * 0.5 + uv.x * uv.y * 2.0 + float(iFrame) * 0.1;
    mat2 rotA = mat2(cos(angleA), -sin(angleA), sin(angleA), cos(angleA));
    uv = rotA * uv;

    float angleB = iTime * 0.8 + uv.x * uv.y * 1.5;
    mat2 rotB = mat2(cos(angleB), -sin(angleB), sin(angleB), cos(angleB));
    uv = rotB * uv;

    vec2 w = wave(uv * 3.0);

    // Use the wave output to modulate rotation and color
    float distortion = w.x * 1.5 + w.y * 0.5;

    // Calculate new UV based on distortion
    uv.x += distortion * 0.5;
    uv.y += distortion * 0.3;

    // Color calculation using the modulated UVs
    float r = 0.5 + 0.5 * sin(uv.x * 7.0 + iTime * 1.2);
    float g = 0.5 + 0.5 * sin(uv.y * 5.0 + iTime * 1.1);
    float b = 0.5 + 0.5 * sin(uv.x * 4.5 + uv.y * 6.0 + iTime * 0.9);

    // Introduce a subtle, time-based chromatic shift
    float shift = sin(iTime * 0.5) * 0.1;
    r += shift;
    g -= shift * 0.5;
    b += shift * 0.8;

    fragColor = vec4(r, g, b, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
