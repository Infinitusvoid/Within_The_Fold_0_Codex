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
    float t = iTime * 0.6;
    // Combining multiple frequency waves for a more intricate texture
    float w1 = sin(uv.x * 7.0 + t * 0.5) * 0.5;
    float w2 = cos(uv.y * 5.0 + t * 0.3) * 0.5;
    float w3 = sin(length(uv) * 1.5 + t * 0.8) * 0.3;
    return vec2(w1 + w3 * 0.5, w2 + w3 * 0.5);
}

vec3 palette(float t) {
    // Gradient based on power and frequency mixing
    float a = pow(sin(t * 2.0 + iTime * 0.1), 1.5) * 0.6 + 0.4;
    float b = cos(t * 2.5 + iTime * 0.2) * 0.5 + 0.5;
    float c = sin(t * 3.0 + iTime * 0.3) * 0.3 + 0.3;
    return vec3(a, b, c);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // 1. Flow Field based displacement
    float flow_t = iTime * 0.8;
    vec2 flow = vec2(
        sin(uv.x * 5.0 + flow_t * 1.5),
        cos(uv.y * 4.0 - flow_t * 0.8)
    );
    uv += flow * 0.5;

    // 2. Time-based warping and rotation
    float angle = iTime * 0.5;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv = rotationMatrix * uv;

    // 3. Complex wave distortion
    uv = wave(uv);

    // 4. Radial repulsion/attraction effect
    vec2 center = vec2(0.0);
    float dist = length(uv - center);
    uv = uv / (dist * 0.7 + 1.0);

    // 5. Final color calculation
    float t = (uv.x * 6.0 + uv.y * 6.0) * 0.7 + iTime * 0.4;
    vec3 col = palette(t);

    // 6. Intensity modulation based on deviation
    float intensity = 0.5 + 0.5 * pow(length(uv) * 1.5, 0.5);
    col *= intensity;

    // 7. Channel complexity driven by rotation history
    float angle_val = atan(uv.y, uv.x) + iTime * 0.3;
    col.r = sin(angle_val * 4.0) * 0.5 + 0.5;
    col.g = cos(angle_val * 3.0) * 0.5 + 0.5;
    col.b = abs(uv.x + uv.y) * 0.5;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
