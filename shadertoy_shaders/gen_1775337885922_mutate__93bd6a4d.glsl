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
    // Modifying wave to emphasize smooth, flowing, layered patterns
    float w1 = sin(uv.x * 15.0 + t * 1.5) * 0.3;
    float w2 = cos(uv.y * 10.0 + t * 1.2) * 0.3;
    float w3 = sin(length(uv) * 5.0 + t * 2.0) * 0.2;
    return vec2(w1, w2 + w3);
}

vec3 palette(float t) {
    // A dynamic, layered color palette based on time
    float c1 = sin(t * 0.5) * 0.5 + 0.5;
    float c2 = cos(t * 0.7) * 0.5 + 0.5;
    float c3 = sin(t * 1.2) * 0.5 + 0.5;
    return vec3(c1, c2, c3);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // 1. Primary flow and panning
    float flow_speed = 2.5 + sin(iTime * 0.4) * 0.8;
    uv *= flow_speed;

    // 2. Screen translation based on time
    uv.x += iTime * 0.5;
    uv.y += iTime * 0.3;

    // 3. Rotational warp based on position
    float angle1 = uv.x * 7.0 + iTime * 0.3;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv *= rotationMatrix;

    // 4. Apply rotational swirly effect
    float angle2 = iTime * 1.1;
    uv = rotate(uv, angle2);

    // 5. Refractive wave distortion
    uv = wave(uv);

    // 6. Color mapping based on complex flow accumulation
    float t = (uv.x * 5.0 + uv.y * 5.0) * 0.5 + iTime * 1.0;
    vec3 col = palette(t);

    // 7. Radial intensity based on distance (focusing the flow)
    float r = length(uv);
    float intensity = 0.5 + 0.5 * sin(r * 5.0 + iTime * 1.5);
    col *= intensity;

    // 8. Chromatic shift based on local angle
    float angle = atan(uv.y, uv.x);
    col.r = sin(angle * 6.0 + iTime * 1.0) * 0.5 + 0.5;
    col.g = cos(angle * 5.5 + iTime * 0.8) * 0.5 + 0.5;

    // 9. Final noise/detail layer
    float detail = sin(uv.x * 30.0 + iTime * 3.0) * 0.1;
    col += detail * 0.5;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
