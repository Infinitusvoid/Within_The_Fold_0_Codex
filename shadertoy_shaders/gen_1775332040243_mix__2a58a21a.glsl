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


vec2 waveA(vec2 uv) {
    uv += vec2(sin(uv.x * 5.0 + iTime * 0.5), sin(uv.y * 3.0 + iTime * 0.3));
    uv += vec2(sin(uv.x * 4.0 + iTime * 0.6), sin(uv.y * 2.5 + iTime * 0.4));
    uv = vec2(cos(uv.x * 3.0 + iTime * 0.4), sin(uv.y * 1.2 + iTime * 0.6));
    uv = vec2(cos(uv.x * 2.0 + iTime * 0.3), sin(uv.y * 1.5 + iTime * 0.7));
    uv += vec2(tan(uv.x * (3.0 + sin(iTime * 0.4))) * 0.15, tan(uv.y * (3.0 + sin(iTime * 0.4))) * 0.1);
    return uv;
}

vec2 waveB(vec2 uv) {
    return vec2(sin(uv.x * 4.0 + uv.y * 1.5 + iTime * 0.3), cos(uv.x * 1.2 - uv.y * 0.8 + iTime * 0.6));
}

vec3 palette(float t) {
    return vec3(0.5 + 0.5*sin(t + iTime * 0.1), 0.5 + 0.5*cos(t + iTime * 0.2), 0.5 + 0.5*sin(t + iTime * 0.3));
}

vec3 colorFromWave(vec2 w) {
    float r = cos(w.x * 1.8 + iTime * 0.4) * 0.5 + 0.5;
    float g = sin(w.y * 1.6 - iTime * 0.3) * 0.5 + 0.5;
    float b = 0.5 + 0.5 * sin(w.x * 3.0 - w.y * 2.5 + iTime * 0.7);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv) {
    float t = iTime * 0.5;
    uv *= vec2(1.0 + 0.03 * sin(t + uv.x * 10.0), 1.0 + 0.03 * sin(t + uv.y * 15.0));
    return uv;
}

mat2 rotate(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 flow(vec2 uv)
{
    float a = iTime * 0.5;
    float b = iTime * 0.3;
    float flow_x = sin(uv.x * 5.0 + a) * cos(uv.y * 3.0 + b);
    float flow_y = cos(uv.y * 4.0 + a) * sin(uv.x * 2.0 + b);
    return uv + vec2(flow_x * 0.5, flow_y * 0.5);
}

vec3 ripple(vec2 uv)
{
    float time_factor = iTime * 1.8;
    float val = sin(uv.x * 12.0 + time_factor) * cos(uv.y * 8.0 - time_factor * 0.5);
    return vec3(val, 1.0 - val, 0.5);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // Apply Flow warping based on UV space
    vec2 uv_base = uv * vec2(5.0, 3.0) - vec2(1.0, 1.5);
    vec2 flow_offset = flow(uv_base);

    // Apply Ripple distortion
    vec3 ripple_color = ripple(flow_offset * 1.5);

    // Combine Wave effects
    vec2 uv_wave = flow_offset;
    uv_wave = waveA(uv_wave);
    uv_wave = waveB(uv_wave);

    vec2 w = uv_wave;
    vec3 col = colorFromWave(w);

    // Use palette based on complex wave coordinates
    float t = w.x * w.y * 8.0 + iTime * 0.4;
    vec3 paletteCol = palette(t);
    col = mix(col, paletteCol, 0.5);

    // Apply wave based variations for color modulation
    float freq = w.x * 2.0 + cos(iTime * 0.5);
    float offset = cos(freq * 20.0) * 0.05;
    float v = smoothstep(0.4, 0.6, w.y - offset);
    col.g = v;

    // Apply Ripple color components
    col = mix(col, ripple_color, 0.3);

    // Final dynamic adjustments based on flow geometry
    float depth_mod = sin(flow_offset.x * 10.0 + iTime * 0.8) * cos(flow_offset.y * 5.0 + iTime * 1.2);
    col.r += depth_mod * 0.5;
    col.g -= depth_mod * 0.2;
    col.b += depth_mod * 0.3;

    // Final exposure based on frame and time (from Shader B)
    col *= (1.0 + sin(iTime * 0.5) * 0.2);
    col *= (1.0 + cos(iTime * 0.3) * 0.1);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
