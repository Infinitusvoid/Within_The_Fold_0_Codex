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
    return vec2(sin(uv.x * 7.0 + t * 1.5), cos(uv.y * 5.0 - t * 1.0));
}

vec3 colorFromWave(vec2 w) {
    float r = 0.5 + 0.5 * sin(w.x * 12.0 + iTime * 0.5);
    float g = 0.5 + 0.5 * cos(w.y * 10.0 - iTime * 0.4);
    float b = 0.3 + 0.7 * sin(w.x * 3.0 + w.y * 2.0 + iTime * 0.6);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv) {
    float t = iTime * 0.5;
    float scale = 1.8;
    uv *= scale;
    uv.x += sin(uv.y * 6.0 + t * 2.0) * 0.15;
    uv.y += cos(uv.x * 5.0 + t) * 0.1;
    return uv;
}

mat2 rotate(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Apply initial distortion
    uv = distort(uv);

    // Complex dynamic angle calculation and rotation
    float angle = iTime * 0.7 + sin(uv.x * 5.0 + uv.y * 3.5) * 0.4;
    mat2 rot = rotate(angle);
    uv = rot * uv;

    // Calculate wave structure
    vec2 w = wave(uv);

    // Get base color from wave coordinates
    vec3 col = colorFromWave(w);

    // Flow and Pulse calculation (based on A)
    float flow = sin(uv.x * 20.0 + iTime * 1.2) * 0.2;
    float pulse = sin(uv.y * 15.0 + iTime * 0.9);

    // Layered coloring and modulation (based on B)
    float freq_x = uv.x * 4.0 + iTime * 0.7;
    float freq_y = uv.y * 5.0 + iTime * 0.4;

    float ripple = cos(freq_y * 6.0) * 0.1;

    // Apply smoothstep based coloring
    float intensity = 0.5 + 0.5 * sin(uv.x * 8.0 + iTime * 0.3);

    // Combined R calculation using flow, ripple, and intensity
    col.r = smoothstep(0.3, 0.6, uv.x * 2.5 + flow * 6.0 + ripple * 0.5);

    // G calculation based on wave frequency and pulse
    col.g = sin(freq_x * 10.0 + iTime * 0.2) * 0.5 + 0.5;

    // B calculation based on wave structure and previous colors
    col.b = 0.1 + 0.4 * sin(col.r * 1.8 + col.g * 1.8 + iTime * 0.5);

    // Apply flow and pulse as offsets
    col.r += flow * 0.8;
    col.g += pulse * 0.7;
    col.b += 0.25 * sin(uv.x * 10.0 + iTime * 0.4);

    // Final complex transformation mixing rotation effects
    col.r = cos(col.g * 10.0 + iTime * 0.5) * 0.5 + 0.5;
    col.g = sin(col.r * 8.0 - uv.y * 6.0 + iTime * 0.4) * 0.5 + 0.5;
    col.b = 0.5 + 0.5 * sin(uv.x * 7.0 + uv.y * 7.0 + iTime * 0.7);

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
