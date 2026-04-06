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
        sin(uv.x * 5.0 + uv.y * 2.0 + t),
        cos(uv.x * 3.0 - uv.y * 1.5 + t * 0.7)
    );
}

vec3 palette(float t) {
    return vec3(0.5 + 0.5*sin(t + iTime * 0.1), 0.5 + 0.5*sin(t + iTime * 0.2), 0.5 + 0.5*cos(t + iTime * 0.3));
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 0.8) * 0.4 + 0.6;
    float c = cos(t * 0.9) * 0.3 + 0.5;
    return uv * vec2(s, c) + vec2(sin(uv.x * 12.0 + t * 0.3), cos(uv.y * 18.0 - t * 0.6));
}

vec3 colorFromUV(vec2 uv, float t) {
    float a = sin(uv.x * 6.0 + t * 0.4);
    float b = cos(uv.y * 8.0 - t * 0.5);
    return vec3(a, b, cos(uv.x * uv.y * 4.0 + t * 0.7));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // Apply distortion
    uv = distort(uv, iTime);

    // Apply rotation based on complex time/space factors (from A)
    float angle1 = sin(iTime * 0.3) + uv.x * uv.y * 2.0;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv *= rotationMatrix;

    float angle2 = iTime * 0.5 + uv.x + uv.y * 0.4;
    uv = rotate(uv, angle2);

    // Introduce scaling and wave distortion (from A)
    uv *= 1.5;

    uv += vec2(
        sin(uv.x * 1.2 + iTime * 0.7) * 0.2,
        cos(uv.y * 1.5 + iTime * 0.6) * 0.3
    );

    uv = wave(uv);

    // Color generation based on UV and time (from B)
    vec3 col = colorFromUV(uv, iTime);

    // Apply complex time/space modulation (from A)
    col = 0.5 + 0.5 * sin(iTime * 0.5 + uv.xyx * 3.0 + vec3(1,2,3));

    // Final color mixing and complex equations (from A and B)

    float freq = uv.x * 1.5 + cos(iTime * 0.3);
    float offset = cos(freq * 12.0) * 0.05;
    float v = 0.5 + 0.5 * (uv.x - offset) * (uv.x - offset);

    col.r = v;

    col.g = cos(uv.y * 9.0 + iTime * 0.2 + sin(uv.x * 30.0 + iTime * 0.3));

    col.b = 0.3 + 0.4 * sin(uv.x * uv.y * 5.0 + iTime * 0.5 + col.g * col.r);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
