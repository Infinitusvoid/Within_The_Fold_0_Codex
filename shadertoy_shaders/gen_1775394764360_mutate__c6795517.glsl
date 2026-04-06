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

vec3 palette(float t) {
    float a = sin(t * 0.5 + iTime * 0.1) * 0.5 + 0.5;
    float b = cos(t * 0.6 + iTime * 0.2) * 0.5 + 0.5;
    float c = pow(abs(sin(t * 1.5 + iTime * 0.3)), 2.0) * 0.8 + 0.2;
    return vec3(a, b, c);
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.6;
    float w1 = sin(uv.x * 8.0 + t * 0.5) * 0.4;
    float w2 = cos(uv.y * 7.0 + t * 0.3) * 0.3;
    float w3 = sin(length(uv) * 2.0 + t * 0.8) * 0.3;
    return vec2(w1, w2 + w3);
}

vec2 distort(vec2 uv) {
    float t = iTime * 0.5;
    uv *= vec2(1.0 + 0.04 * sin(t + uv.x * 12.0), 1.0 + 0.04 * sin(t + uv.y * 18.0));
    return uv;
}

mat2 rotateMatrix(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return vec2(sin(6.28318 * (i.x + u.x)), cos(6.28318 * (i.y + u.y)));
}

vec2 fractal_displace(vec2 uv) {
    vec2 p = uv;
    float time_factor = iTime * 0.2;
    float angle = sin(p.y * 0.5 + time_factor * 1.5);
    p = rotateMatrix(angle * 0.7) * p;
    p += vec2(sin(p.x * 5.0) * 0.15 + cos(p.y * 3.0) * 0.08,
               cos(p.x * 4.0) * 0.1 + sin(p.y * 2.5) * 0.12);
    return p;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // 1. Initial geometric deformation
    uv = uv * 3.0 - 1.0;
    uv = fractal_displace(uv);
    uv = distort(uv);

    // 2. Rotational setup
    float angle_base = iTime * 1.5;
    float angle_vortex = atan(uv.y, uv.x) * 5.0;

    mat2 rotationMatrix = mat2(cos(angle_base), -sin(angle_base), sin(angle_base), cos(angle_base));
    uv *= rotationMatrix;

    uv = rotate(uv, angle_vortex * 0.3);

    // 3. Vortex/Gravitational pull distortion
    vec2 center = vec2(0.0);
    float dist = length(uv - center);
    uv -= center;
    // Stronger influence from closer points, modulated by time
    uv /= (dist * 0.7 + 0.05 * sin(iTime * 2.0)); 

    // 4. Wave dynamics generation
    vec2 wave_offset = wave(uv * 2.0);
    uv += wave_offset * 0.4;

    // 5. Color mapping
    // Use a complex metric for the base color time
    float t = (uv.x * 15.0 + uv.y * 8.0) * 1.3 + iTime * 2.0;
    vec3 col = palette(t);

    // 6. Flow and contrast application (Increased complexity)
    float flow_intensity = sin(uv.x * 7.0 + iTime * 1.2) * 1.2 + 0.2;

    col.r *= flow_intensity * 2.0;
    col.g *= (1.0 + sin(uv.y * 5.0) * 0.6);
    col.b *= (0.5 + 0.5 * cos(uv.x * 3.0));

    // 7. Final feedback loop using noise
    float noise_val = noise(uv * 10.0 + iTime * 0.5).x;

    // Apply noise for texture and glow
    col.r = mix(col.r, noise_val * 0.25, 0.4);
    col.g = mix(col.g, noise_val * 0.18, 0.5);
    col.b = mix(col.b, noise_val * 0.12, 0.6);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
