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

float palette(float t) {
    t = fract(t * 3.14159);
    return 0.5 + 0.5 * sin(t * 12.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // Introduce subtle noise based warping
    float noiseScale = 5.0;
    float timeOffset = iTime * 0.8;

    // Apply time-based distortion to UV
    vec2 distortedUV = uv;
    distortedUV.x += sin(uv.y * 10.0 + timeOffset) * 0.1;
    distortedUV.y += cos(uv.x * 8.0 + timeOffset * 0.5) * 0.1;

    // Apply wave function to introduce subtle contrast shifts
    vec2 w = wave(distortedUV);

    // Use distorted UV for primary calculation
    vec2 finalUV = distortedUV;

    vec3 color = vec3(
        sin(iTime * 5.0 + finalUV.x * 3.0 + w.x * 1.2),
        cos(iTime * 4.0 + finalUV.y * 4.5 + w.y * 0.8),
        sin(iTime * 6.0 + finalUV.x * 1.8 + finalUV.y * 2.5)
    );

    // Apply complex palette modulation using time and UV derivatives
    float p = palette(iTime * 1.5 + finalUV.x * 0.5);
    color = mix(color, vec3(p * 0.4 + 0.1), 0.7);

    fragColor = vec4(color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
