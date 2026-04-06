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
        sin(uv.x * 8.0 + t * 1.5),
        cos(uv.y * 6.0 - t * 0.8)
    );
}

vec3 palette(float t) {
    // Using a slightly more complex trigonometric relationship for richer color cycling
    float r = 0.5 + 0.5 * sin(t * 1.5 + iTime * 0.2);
    float g = 0.5 + 0.5 * sin(t * 1.2 + iTime * 0.3);
    float b = 0.5 + 0.5 * sin(t * 2.0 + iTime * 0.1);
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // Base distortion scaling, made more dynamic
    float scale = 1.5 + sin(iTime * 2.0) * 0.5;
    uv *= scale;

    // Complex spatial deformation based on time and UV interaction
    float angle = iTime * 0.5 + uv.x * 15.0;
    vec2 rotated_uv = rotate(uv, angle);

    // Apply wave transformation
    vec2 distorted_uv = wave(rotated_uv);

    // Introduce radial flow based on distance from center
    float dist = length(distorted_uv);
    distorted_uv *= 1.5 + 0.5 * dist;

    // Time-based pulsing and shearing
    float shear = uv.y * 8.0;
    distorted_uv.x += shear;

    distorted_uv.x += sin(iTime * 3.0) * 0.4;
    distorted_uv.y += cos(iTime * 2.5) * 0.5;

    // Final color mapping
    float t = (distorted_uv.x * 10.0 + distorted_uv.y * 8.0) * 0.7 + iTime * 0.5;
    vec3 col = palette(t);

    // Introduce chromatic shift
    float color_shift = sin(distorted_uv.x * 15.0 + distorted_uv.y * 10.0) * 0.7;

    col.r = mix(col.r, 0.9 + color_shift * 0.5, 0.4);
    col.g = mix(col.g, 0.7 + color_shift * 0.6, 0.4);
    col.b = mix(col.b, 0.5 + color_shift * 0.3, 0.5);

    // Add high frequency detail using modulo and time
    col.r += sin(distorted_uv.x * 60.0 + iTime * 4.0) * 0.15;
    col.g += cos(distorted_uv.y * 50.0 + iTime * 3.5) * 0.2;
    col.b += sin(distorted_uv.x * 90.0 + iTime * 2.0) * 0.1;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
