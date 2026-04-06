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

    // 1. Dynamic Noise Flow Field
    float flow_t = iTime * 1.2;
    vec2 flow = vec2(
        sin(uv.x * 6.0 + flow_t),
        cos(uv.y * 5.0 - flow_t * 0.5)
    );
    uv += flow * 0.5;

    // 2. Time-based warping and rotation
    float angle = iTime * 0.4;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv = rotationMatrix * uv;

    // 3. Complex wave distortion
    uv = wave(uv);

    // 4. Fractal detail warping (new modification)
    float noise_scale = 10.0;
    vec2 noise_uv = uv * noise_scale;
    float detail = sin(noise_uv.x * 20.0 + iTime * 1.0) * cos(noise_uv.y * 20.0 - iTime * 1.0);
    uv += detail * 0.1;

    // 5. Radial repulsion/attraction effect
    vec2 center = vec2(0.0);
    float dist = length(uv - center);
    uv = uv / (dist * 0.8 + 1.0);

    // 6. Final color calculation
    float t = (uv.x * 7.0 + uv.y * 7.0) * 0.5 + iTime * 0.6;
    vec3 col = palette(t);

    // 7. Intensity modulation based on deviation
    float intensity = 0.5 + 0.5 * pow(length(uv) * 1.5, 0.5);
    col *= intensity;

    // 8. Channel complexity driven by rotation history
    float angle_val = atan(uv.y, uv.x) + iTime * 0.5;
    col.r = sin(angle_val * 5.0) * 0.5 + 0.5;
    col.g = cos(angle_val * 4.0) * 0.5 + 0.5;
    col.b = sin(uv.x * 3.0 + iTime) * 0.5 + 0.5;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
