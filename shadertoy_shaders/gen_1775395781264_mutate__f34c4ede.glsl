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
    float angle = sin(p.y * 0.5 + time_factor * 0.5);
    p = rotateMatrix(angle * 0.6) * p;
    p += vec2(sin(p.x * 4.0) * 0.15 + cos(p.y * 3.0) * 0.1,
               cos(p.x * 3.5) * 0.1 + sin(p.y * 2.5) * 0.1);
    return p;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // 1. Initial geometric deformation
    uv = uv * 2.5 - 1.25; 
    uv = fractal_displace(uv);
    uv = distort(uv);

    // 2. Polar coordinate conversion and centering
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float theta = atan(p.y, p.x);

    // 3. Radial and Angular flow calculation
    float z = 1.0 / (r * 1.5 + 0.2); // Adjusted depth calculation

    float angle_flow = sin(theta * 50.0 + iTime * 5.0); // Increased angular speed and influence
    float radial_shift = z * 5.0; // Increased radial shift magnitude

    // Combined phase modulation
    float phase_a = 100.0*theta + iTime * 10.0 + angle_flow * 2.0; // Changed phase_a calculation
    float phase_r = 60.0*r + radial_shift * 1.5 + iTime * 8.0; // Changed phase_r calculation

    // Flow factors
    float flow_r = sin(phase_r * 0.8 + iTime * 2.0); // Modified flow_r
    float f1 = cos(phase_a * 2.5); // Changed f1 source
    float f2 = sin(r * 8.0 + iTime * 4.0); // Changed f2 source

    // Density and Ring generation
    float density = abs(f1 * f2 * 3.0);
    float bands = smoothstep(0.2, 0.05, density * 1.5); // Sharper, tighter bands

    // Ring calculation emphasized by radial distortion
    float ring = pow(sin(50.0*r + phase_a * 0.5) * flow_r * 1.5, 12.0) * 5.0; // Enhanced ring effect

    // Palette Input
    float palette_t = 0.03*iTime + f1*0.7 + radial_shift*0.5 + flow_r*0.4;

    // Apply core color
    vec3 col = pal(palette_t);

    // Apply complexity driven by rings and bands
    col *= 0.02 + 10.0*bands + ring * 1.5; // Increased effect

    // Chromatic shift modulated by radial position
    col += 0.8 * sin(theta * 20.0 + iTime * 12.0) * f2;

    // Apply radial falloff based on r^2
    col *= exp(-4.0*r * r * 0.5);

    // Final noise layer based on distorted coordinates
    float noise_val = noise(p * 15.0 + iTime * 5.0).x;
    col += noise_val * 0.08;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
