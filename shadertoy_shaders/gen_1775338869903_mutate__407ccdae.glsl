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

vec2 ripple(vec2 uv) {
    float t = iTime * 1.2;
    // Layered ripples using different frequencies and offsets
    float r1 = sin(uv.x * 12.0 + t * 2.0) * 0.25;
    float r2 = cos(uv.y * 9.0 - t * 1.5) * 0.18;
    float r3 = sin(length(uv) * 6.0 + t * 0.7) * 0.35;
    return vec2(r1, r2) + vec2(r3, 0.0);
}

vec3 palette(float t) {
    // A palette based on highly oscillating trigonometric functions
    float a = sin(t * 3.0) * 0.4 + 0.6;
    float b = cos(t * 4.5) * 0.3 + 0.7;
    float c = sin(t * 6.0) * 0.5 + 0.5;
    return vec3(a, b, c);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // 1. Primary flow based on time and spatial complexity
    float flow_speed = 1.5 + sin(iTime * 0.6) * 1.0;
    float time_scale = iTime * 2.5;
    uv *= flow_speed;

    // 2. Complex rotational setup
    float angle_offset = uv.x * 10.0 + time_scale * 0.5;
    vec2 rotated_uv = rotate(uv, angle_offset);

    // 3. Apply ripple distortion
    uv = ripple(rotated_uv);

    // 4. Introduce flow interaction based on coordinates
    float dist = length(uv);
    uv *= (1.0 + dist * 0.15);

    // 5. Phase shift for layering and additional flow
    float phase = iTime * 7.0;
    uv.x += sin(uv.y * 7.0 + phase * 0.3) * 0.15;
    uv.y += cos(uv.x * 7.0 + phase * 0.4) * 0.1;

    // 6. Color mapping based on accumulated complexity
    float t = (uv.x * 5.0 + uv.y * 5.0) * 0.5 + iTime * 2.0;
    vec3 col = palette(t);

    // 7. Radial intensity based on position
    float intensity = 0.5 + 0.5 * sin(dist * 5.0 + iTime * 1.2);
    col *= intensity;

    // 8. Introduce chromatic shift based on angle
    float angle = atan(uv.y, uv.x);
    col.r = sin(angle * 5.0 + iTime * 1.5) * 0.6 + 0.4;
    col.g = cos(angle * 3.0 + iTime * 0.9) * 0.5 + 0.5;

    // 9. Final blending based on position extrema
    float contrast = smoothstep(0.0, 1.0, abs(uv.x * 2.0 - uv.y * 1.5) * 1.8);
    col = mix(col, vec3(0.1, 0.4, 0.8), contrast);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
