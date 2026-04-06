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

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 4.0 + uv.y * 1.5 + iTime * 0.3), cos(uv.x * 1.2 - uv.y * 0.8 + iTime * 0.6));
}

vec2 waveA(vec2 uv) {
    uv += vec2(sin(uv.x * 5.0 + iTime * 0.5), sin(uv.y * 3.0 + iTime * 0.3));
    uv += vec2(sin(uv.x * 4.0 + iTime * 0.6), sin(uv.y * 2.5 + iTime * 0.4));
    uv = vec2(cos(uv.x * 3.0 + iTime * 0.4), sin(uv.y * 1.2 + iTime * 0.6));
    uv = vec2(cos(uv.x * 2.0 + iTime * 0.3), sin(uv.y * 1.5 + iTime * 0.7));
    uv += vec2(tan(uv.x * (3.0 + sin(iTime * 0.4))) * 0.15, tan(uv.y * (3.0 + sin(iTime * 0.4))) * 0.1);
    return uv;
}

vec2 ripple(vec2 uv)
{
    float r = sin(uv.x * 5.0 + iTime * 1.5);
    float g = cos(uv.y * 6.0 + iTime * 2.0);
    return vec2(r * 0.5 + 0.5, g * 0.5 + 0.5);
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

vec2 distort(vec2 uv) {
    float t = iTime * 0.5;
    uv *= vec2(1.0 + 0.03 * sin(t + uv.x * 10.0), 1.0 + 0.03 * sin(t + uv.y * 15.0));
    return uv;
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.6;
    float w1 = sin(uv.x * 7.0 + t * 0.5) * 0.5;
    float w2 = cos(uv.y * 5.0 + t * 0.3) * 0.5;
    float w3 = sin(length(uv) * 1.5 + t * 0.8) * 0.3;
    return vec2(w1 + w3 * 0.5, w2 + w3 * 0.5);
}

vec3 palette(float t) {
    float a = sin(t + iTime * 0.1) * 0.5 + 0.5;
    float b = cos(t + iTime * 0.2) * 0.5 + 0.5;
    float c = pow(abs(sin(t + iTime * 0.3)), 2.0) * 0.8 + 0.2;
    return vec3(a, b, c);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // 1. Initial spatial setup using fractal displacement and distortion
    uv = uv * 2.0 - 1.0;
    uv = fractal_displace(uv);
    uv = distort(uv);

    // 2. Rotational setup driven by time and position (Focus on complex rotation)
    float angle_base = iTime * 3.0;
    float angle_flow = atan(uv.y, uv.x) * 5.0;

    mat2 rotationMatrix = mat2(cos(angle_base), -sin(angle_base), sin(angle_base), cos(angle_base));
    uv *= rotationMatrix;

    uv = rotate(uv, angle_flow * 0.5);

    // 3. Vortex/Gravitational pull distortion (Inverse distance scaling)
    vec2 center = vec2(0.0);
    float dist = length(uv - center);

    // Apply an inverse square-like pull near the center
    float pull = 1.0 / (dist * dist + 0.1);
    uv = normalize(uv) * pull; 

    // 4. Wave dynamics generation (Using the ripple function for complex flow)
    uv = ripple(uv);

    // 5. Color mapping using a dynamic time/position metric
    float t = (uv.x * 8.0 + uv.y * 4.0) * 1.5 + iTime * 2.0;
    vec3 col = palette(t);

    // 6. Flow and contrast application (Using a different flow metric)
    float flow_strength = sin(uv.x * 4.0 + iTime * 1.2) * 0.5 + 0.5;

    col.r *= flow_strength * 2.0;
    col.g *= (1.0 + sin(uv.y * 7.0) * 0.4);
    col.b = pow(col.b, 1.5);

    // 7. Final feedback loop using noise for high-frequency detail
    float noise_val = noise(uv * 10.0 + iTime * 1.5).x;

    // Use noise to modulate contrast and hue shift
    col.r = mix(col.r, noise_val * 0.5, 0.6);
    col.g = mix(col.g, noise_val * 0.3, 0.5);
    col.b = mix(col.b, noise_val * 0.25, 0.4);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
