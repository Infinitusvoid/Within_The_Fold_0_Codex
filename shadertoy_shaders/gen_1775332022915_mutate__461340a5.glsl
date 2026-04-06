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

mat2 rotateMatrix(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 noise(vec2 uv)
{
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return vec2(sin(6.28318 * (i.x + u.x)), cos(6.28318 * (i.y + u.y)));
}

vec2 fractal_displace(vec2 uv) {
    vec2 p = uv;
    float time_factor = iTime * 0.2;
    float angle = sin(p.y * 0.5 + time_factor);
    p = rotateMatrix(angle * 0.5) * p;
    p += vec2(sin(p.x * 3.0) * 0.1 + cos(p.y * 2.0) * 0.1,
               cos(p.x * 2.5) * 0.1 + sin(p.y * 1.5) * 0.1);
    return p;
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.8;
    return vec2(sin(uv.x * 7.0 + t * 1.5), cos(uv.y * 5.0 - t * 1.0));
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Initial spatial setup using fractal displacement and distortion
    uv = uv * 2.0 - 1.0;
    uv = fractal_displace(uv);
    uv = distort(uv);

    // Apply controlled rotation using fractal displacement result
    float angle = iTime * 0.7 + sin(uv.x * 5.0 + uv.y * 3.0) * 0.2;
    mat2 rot = rotateMatrix(angle);
    uv = rot * uv;

    // Wave dynamics generation
    vec2 w = waveA(uv); 

    // Fundamental Interaction Bases 
    vec2 p = uv * 0.5 + 0.5;

    // R channel base (Noise and Wave interaction)
    float r_flow = sin(p.x * 10.0 + iTime * 2.0) * 0.5 + 0.5;
    float r_wave = cos(w.x * 5.0 + uv.y * 4.0 + iTime * 0.5) * 0.4;
    float r_base = r_flow * (1.0 + r_wave);

    // G channel base (Complex frequency interaction)
    float g_wave_interaction = sin(p.x * 18.0 + p.y * 15.0 + iTime * 1.5);
    float g_base = g_wave_interaction * 0.5 + 0.5;

    // B channel (Fractal noise influence)
    float b_noise = noise(uv * 3.0 + iTime * 0.5).x * 0.5 + 0.5;
    float b_base = b_noise;

    vec3 col = vec3(r_base, g_base, b_base);

    // Complex Painting and Flow Integration

    // Applying modulation based on wave output
    float flow_mod = sin(w.x * 3.0 + uv.y * 5.0 + iTime * 0.4) * 0.5;

    col.r = smoothstep(0.3, 0.6, uv.x * 3.0 + flow_mod * 4.0);
    col.g = smoothstep(0.2, 0.5, uv.y * 4.5 + iTime * 0.3);

    // Interdependence calculation (Mixing result through wave structure)
    float mix_factor = sin(col.r * 2.0 + col.g * 2.0 + iTime * 0.6);
    col.b = mix_factor * 0.5 + 0.5;

    // Final Contrast Tweak
    col.r = pow(col.r, 1.2) * 0.9;
    col.g = sin(col.r * 8.0 + uv.x * 10.0 + iTime * 0.5) * 0.5 + 0.5;
    col.b = col.b + cos(uv.y * 8.0 + iTime * 0.7) * 0.1;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
