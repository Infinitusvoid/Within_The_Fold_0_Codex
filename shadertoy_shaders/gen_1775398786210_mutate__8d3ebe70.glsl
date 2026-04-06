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

vec3 pal(float t){ return 0.5 + 0.5 * sin(6.28318*(vec3(0.1,0.3,0.7)+t)); }

vec2 wave(vec2 uv) {
    float t = iTime * 0.6;
    float w1 = sin(uv.x * 7.0 + t * 0.5) * 0.5;
    float w2 = cos(uv.y * 5.0 + t * 0.3) * 0.5;
    float w3 = sin(length(uv) * 1.5 + t * 0.8) * 0.3;
    return vec2(w1 + w3 * 0.5, w2 + w3 * 0.5);
}

vec2 distort(vec2 uv) {
    float t = iTime * 0.5;
    uv *= vec2(1.0 + 0.03 * sin(t + uv.x * 10.0), 1.0 + 0.03 * sin(t + uv.y * 15.0));
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
    float angle = sin(p.y * 0.5 + time_factor);
    p = rotateMatrix(angle * 0.5) * p;
    p += vec2(sin(p.x * 3.0) * 0.1 + cos(p.y * 2.0) * 0.1,
               cos(p.x * 2.5) * 0.1 + sin(p.y * 1.5) * 0.1);
    return p;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // 1. Initial geometric deformation
    uv = uv * 2.0 - 1.0;
    uv = fractal_displace(uv);
    uv = distort(uv);

    // 2. Polar coordinate conversion and centering
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float theta = atan(p.y, p.x);

    // 3. Time and position modulation
    float t = iTime * 1.5;

    // 4. Wave dynamics generation
    vec2 wave_offset = wave(uv * 3.0);
    p += wave_offset * 0.5;

    // 5. Radial and angular focus calculation
    float radial_flow = r * 4.0;
    float angular_flow = theta * 3.0;

    // 6. Color modulation based on polar rotation
    float r_mod = sin(t * 10.0 + theta * 40.0) * 0.5 + 0.5;
    float g_mod = cos(t * 8.0 + r * 20.0) * 0.5 + 0.5;
    float b_mod = sin(t * 12.0 + theta * 50.0) * 0.5 + 0.5;

    // 7. Base palette input and fractal noise
    float dist_factor = 1.0 / (r * 2.5 + 0.2);
    float p_input = dist_factor * 4.0 + t * 0.5;

    float noise_val = noise(p * 12.0 + iTime * 2.0).x;

    // 8. Final color calculation based on combined effects
    vec3 color = pal(p_input) * r_mod;
    color += pal(p_input + 0.2) * g_mod;
    color += pal(p_input + 0.4) * b_mod;

    // Apply flow and contrast
    float flow_intensity = sin(uv.x * 10.0 + iTime * 1.5) * 0.8 + 0.2;
    color *= flow_intensity * 1.5;

    // Apply noise mixing and radial depth
    color += noise_val * 0.15 * r;

    // Final ambient scaling based on radial distance
    float ambient = 0.03 + dist_factor * 1.0;
    color *= ambient * (1.0 + sin(t * 7.0));

    fragColor = vec4(color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
