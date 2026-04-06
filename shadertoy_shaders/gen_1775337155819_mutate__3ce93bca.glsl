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
    // Modifying wave to emphasize swirling patterns and parallax
    float w1 = sin(uv.x * 10.0 + t * 1.5) * 0.5;
    float w2 = cos(uv.y * 8.0 + t * 1.2) * 0.4;
    float w3 = sin(length(uv) * 4.0 + t * 2.0) * 0.3;
    return vec2(w1 * 0.7 + w3 * 0.3, w2 * 0.6 + w3 * 0.4);
}

vec3 palette(float t) {
    // A dynamic, highly contrast palette based on layered periodic functions
    float a = sin(t * 0.4) * 0.5 + 0.5;
    float b = cos(t * 0.6) * 0.5 + 0.5;
    float c = sin(t * 1.0) * 0.5 + 0.5;
    return vec3(a, b, c);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // 1. Primary spatial scaling and animation
    float flow_speed = 2.0 + sin(iTime * 0.3) * 0.5;
    uv *= flow_speed;

    // 2. Rotational offset based on screen position
    float angle1 = uv.x * 6.0 + iTime * 0.5;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv *= rotationMatrix;

    // 3. Apply rotation based on time for overall swirl
    float angle2 = iTime * 0.9;
    uv = rotate(uv, angle2);

    // 4. Vortex distortion (pulling towards the center based on distance)
    vec2 center = vec2(0.0);
    float dist = length(uv);
    // Enhanced pulling effect
    uv = uv * (1.0 - dist * 0.6);

    // 5. Wave distortion input
    uv = wave(uv);

    // 6. Color mapping based on accumulated distortion
    float t = (uv.x * 7.0 + uv.y * 7.0) * 0.7 + iTime * 1.5;
    vec3 col = palette(t);

    // 7. Radial intensity based on phase shift (using polar coordinates)
    float r = length(uv);
    float intensity = 0.5 + 0.5 * sin(r * 6.0 + iTime * 1.2);
    col *= intensity;

    // 8. Introduce strong chromatic shift based on angle
    float angle = atan(uv.y, uv.x);
    col.r = sin(angle * 5.0 + iTime * 1.0) * 0.5 + 0.5;
    col.g = cos(angle * 4.5 + iTime * 0.7) * 0.5 + 0.5;

    // 9. Final contrast and saturation adjustment
    float contrast = smoothstep(0.0, 0.9, abs(uv.x + uv.y) * 1.5);
    col = mix(col, vec3(0.1, 0.7, 0.9), contrast);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
