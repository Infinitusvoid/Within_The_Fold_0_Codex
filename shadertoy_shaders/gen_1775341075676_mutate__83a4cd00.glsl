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
    float t = iTime * 1.5;
    // Modifying wave to introduce vertical and horizontal separation based on time
    float w1 = sin(uv.x * 10.0 + t * 3.0) * 0.4;
    float w2 = cos(uv.y * 8.0 + t * 2.5) * 0.3;
    float w3 = sin(length(uv) * 7.0 + t * 1.0) * 0.3;
    return vec2(w1, w2 + w3);
}

vec3 palette(float t) {
    // A dynamic, chromatic palette based on layered time cycles
    float c1 = sin(t * 0.8) * 0.5 + 0.5;
    float c2 = cos(t * 1.1) * 0.5 + 0.5;
    float c3 = sin(t * 1.5) * 0.5 + 0.5;
    return vec3(c1, c2, c3);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // 1. Primary flow and panning (Increased complexity in flow speed)
    float flow_speed = 3.0 + sin(iTime * 0.6) * 1.2;
    uv *= flow_speed;

    // 2. Screen translation based on time
    uv.x += iTime * 0.7;
    uv.y += iTime * 0.5;

    // 3. Rotational warp based on position (More aggressive rotation)
    float angle1 = uv.x * 5.0 + iTime * 0.4;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv *= rotationMatrix;

    // 4. Apply rotational swirly effect
    float angle2 = iTime * 2.0;
    uv = rotate(uv, angle2);

    // 5. Refractive wave distortion
    uv = wave(uv);

    // 6. Color mapping based on complex flow accumulation
    float t = (uv.x * 6.0 + uv.y * 6.0) * 0.4 + iTime * 1.2;
    vec3 col = palette(t);

    // 7. Radial intensity based on distance (Focusing the flow)
    float r = length(uv);
    float intensity = 0.5 + 0.5 * sin(r * 4.0 + iTime * 2.0);
    col *= intensity * 1.5; // Increased intensity scale

    // 8. Chromatic shift based on local angle
    float angle = atan(uv.y, uv.x);
    col.r = sin(angle * 7.0 + iTime * 0.7) * 0.5 + 0.5;
    col.g = cos(angle * 6.5 + iTime * 0.9) * 0.5 + 0.5;

    // 9. Final detail layer (Using higher frequency noise)
    float detail = sin(uv.x * 45.0 + iTime * 4.0) * 0.08;
    col += detail * 0.8;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
