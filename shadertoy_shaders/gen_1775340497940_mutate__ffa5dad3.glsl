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
    // Modified wave focusing on radial and angular components
    float w1 = sin(uv.x * 10.0 + t * 1.5) * 0.6;
    float w2 = cos(uv.y * 8.0 + t * 0.3) * 0.4;
    float w3 = sin(length(uv) * 4.0 + t * 0.5) * 0.3;
    return vec2(w1, w2) + vec2(w3 * 0.5);
}

vec3 palette(float t) {
    // Dynamic, high-contrast palette based on layered sine/cosine waves
    float a = sin(t * 0.5) * 0.5 + 0.5;
    float b = cos(t * 0.7) * 0.5 + 0.5;
    float c = abs(sin(t * 1.2)) * 0.8 + 0.2;
    return vec3(a, b, c);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // 1. Time-based flow and overall speed
    float flow_speed = 2.0 + sin(iTime * 0.3) * 0.5;
    uv *= flow_speed;

    // 2. Complex rotational displacement
    float angle1 = uv.x * 8.0 + iTime * 0.5;
    float angle2 = uv.y * 6.0 + iTime * 0.4;

    // Apply separate rotations
    vec2 rotated_uv = rotate(uv, angle1);
    uv = rotate(rotated_uv, angle2);

    // 3. Vortex distortion (focusing effect)
    float dist = length(uv);
    // Stronger inward pull
    uv = uv * (1.0 - dist * 0.4);

    // 4. Wave distortion input
    uv = wave(uv);

    // 5. Color mapping based on overall position and time
    float t = (uv.x * 7.0 + uv.y * 7.0) * 0.6 + iTime * 1.5;
    vec3 col = palette(t);

    // 6. Intensity modulation based on distance and time
    float intensity = 0.5 + 0.5 * sin(dist * 4.0 + iTime * 0.7);
    col *= intensity;

    // 7. Chromatic shift based on angle
    float angle = atan(uv.y, uv.x);
    col.r = sin(angle * 5.0 + iTime * 1.0) * 0.5 + 0.5;
    col.g = cos(angle * 4.5 + iTime * 0.8) * 0.5 + 0.5;
    col.b = sin(angle * 3.5 + iTime * 0.6) * 0.5 + 0.5;

    // 8. Final contrast and edge enhancement
    float contrast_edge = smoothstep(0.0, 0.1, abs(uv.x + uv.y) * 1.5);
    col = mix(col, vec3(0.1, 0.5, 0.8), contrast_edge);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
