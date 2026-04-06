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

    // 1. Initial geometric deformation (Shift focus from radial to angular flow)
    uv = uv * 3.5 - 1.5; // Adjusted initial warp
    uv = fractal_displace(uv);
    uv = distort(uv);

    // 2. Polar coordinate conversion and centering
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float theta = atan(p.y, p.x);

    // 3. Angular and Radial flow calculation
    float t = iTime;
    float r_flow = r * 1.5;
    float theta_flow = theta * 30.0 + t * 5.0; // Stronger angular flow

    // Combined phase modulation
    float phase_a = 100.0*theta + t * 15.0; // Primary phase driven by angle
    float phase_r = 50.0*r_flow + t * 10.0; // Radial phase

    // Flow factors
    float flow_a = sin(theta_flow * 1.5); // Angular flow driver
    float flow_r_factor = cos(phase_r * 0.5); // Radial oscillation

    // Complex interference
    float wave_effect = wave(uv).x;
    float ring_intensity = pow(sin(50.0 * r + phase_a * 0.5) * flow_a, 7.0) * 1.5; // Ring based on angular flow

    // Palette Input based on angular complexity
    float palette_t = 0.01 * t + wave_effect * 0.5 + flow_r_factor * 0.5;

    // Apply core color
    vec3 col = pal(palette_t);

    // Apply complexity driven by rings and waves
    col *= 0.04 + 15.0*wave_effect + ring_intensity; // Increased wave and ring effect

    // Chromatic shift based on radial flow and time
    col += 0.5 * sin(theta_flow * 25.0 + t * 15.0) * flow_r_factor;

    // Apply radial falloff using sine/cosine interference
    col *= smoothstep(0.0, 1.0, abs(cos(r * 8.0 + t * 4.0)));

    // Final noise layer driven by position and time
    float noise_val = noise(p * 20.0 + t * 10.0).x;
    col += noise_val * 0.2;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
