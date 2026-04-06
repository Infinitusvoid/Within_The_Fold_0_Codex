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
        sin(uv.x * 10.0 + t * 2.0),
        cos(uv.y * 5.0 - t * 1.0)
    );
}

vec3 palette(float t) {
    // Tighter color cycling based on higher frequency modulation
    float r = 0.1 + 0.8 * sin(t * 10.0 + iTime * 0.5);
    float g = 0.2 + 0.8 * sin(t * 12.0 + iTime * 0.3);
    float b = 0.3 + 0.8 * sin(t * 8.0 + iTime * 0.1);
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // Base flow driven by time
    float flow_time = iTime * 0.8;

    // Apply complex rotation and wave interaction
    float angle = uv.x * 12.0 + flow_time * 2.0;
    vec2 rotated_uv = rotate(uv, angle);

    vec2 distorted_uv = wave(rotated_uv);

    // Radial expansion and distance modulation
    float dist = length(distorted_uv);
    distorted_uv *= 1.5 + 0.5 * dist;

    // Introduce fractal/spiral movement
    float spiral_flow = flow_time * 1.5;
    distorted_uv.x += spiral_flow * 0.1;
    distorted_uv.y += spiral_flow * 0.1;

    // Heavy shearing based on time
    distorted_uv.x += sin(iTime * 5.0) * 0.3;
    distorted_uv.y += cos(iTime * 3.0) * 0.2;

    // Final color mapping derived from accumulated flow
    float final_t = (distorted_uv.x * 5.0 + distorted_uv.y * 7.0) * 0.6 + flow_time;
    vec3 col = palette(final_t);

    // Chromatic shift and high frequency modulation
    float color_shift = sin(distorted_uv.x * 20.0 + distorted_uv.y * 15.0) * 0.5;

    col.r = mix(col.r, 0.9 + color_shift * 0.6, 0.3);
    col.g = mix(col.g, 0.7 + color_shift * 0.5, 0.4);
    col.b = mix(col.b, 0.5 + color_shift * 0.3, 0.5);

    // High frequency detail layer
    col.r += sin(distorted_uv.x * 75.0 + iTime * 5.0) * 0.2;
    col.g += cos(distorted_uv.y * 65.0 + iTime * 4.0) * 0.25;
    col.b += sin(distorted_uv.x * 100.0 + iTime * 6.0) * 0.15;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
