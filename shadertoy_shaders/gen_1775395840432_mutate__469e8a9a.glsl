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

vec3 pal(float t)
{
    return 0.5 + 0.5 * sin(6.28318 * t * 3.0 + 3.14159 * vec3(0.1, 0.5, 0.9));
}

vec3 palette(float t) {
    float a = sin(t * 0.5 + iTime * 0.1) * 0.5 + 0.5;
    float b = cos(t * 0.6 + iTime * 0.2) * 0.5 + 0.5;
    float c = pow(abs(sin(t * 1.5 + iTime * 0.3)), 2.0) * 0.8 + 0.2;
    return vec3(a, b, c);
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.7;
    float w1 = sin(uv.x * 8.0 + t * 0.4) * 0.4;
    float w2 = cos(uv.y * 6.0 + t * 0.3) * 0.6;
    float w3 = sin(length(uv) * 2.0 + t * 1.0) * 0.2;
    return vec2(w1, w2 + w3);
}

vec2 distort(vec2 uv) {
    float t = iTime * 0.5;
    float scale_x = 1.0 + 0.02 * sin(t + uv.x * 12.0);
    float scale_y = 1.0 + 0.02 * cos(t + uv.y * 15.0);
    uv *= vec2(scale_x, scale_y);
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
    float time_factor = iTime * 0.3;
    float angle = sin(p.y * 0.5 + time_factor * 0.5);
    p = rotateMatrix(angle * 0.8) * p;
    p += vec2(sin(p.x * 4.0) * 0.05 + cos(p.y * 3.0) * 0.05,
               cos(p.x * 3.5) * 0.05 + sin(p.y * 2.5) * 0.05);
    return p;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // 1. Initial geometric deformation (Shader B influence)
    uv = uv * 2.0 - 1.0;
    uv = fractal_displace(uv);
    uv = distort(uv);

    // 2. Polar coordinate conversion and centering (Shader A influence)
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float a = atan(p.y, p.x);

    // 3. Time and position modulation
    float t = iTime * 1.0 + r * 5.0 + a * 8.0;

    // 4. Wave dynamics generation (Shader B influence)
    vec2 wave_offset = wave(uv * 3.0);
    p += wave_offset * 0.5;

    // 5. Radial effects (Shader A influence)
    // Inverse distance/depth factor, exaggerated
    float z = 1.0 / (r * 2.0 + 0.3);

    // Introduce strong angular flow modulated by time
    float angle_flow = sin(a * 20.0 + iTime * 5.0);

    // Introduce radial displacement based on depth
    float radial_shift = z * 3.0; // Increased shift

    // Modify the base time/angle input based on flow and shift
    float phase_a = 15.0*a + iTime * 3.5 + angle_flow * 1.5;
    float phase_r = 30.0*r + radial_shift * 1.3 + iTime * 4.5;

    float f1 = sin(phase_a * 1.2);
    float f2 = cos(phase_r * 0.8);

    // Create complex density based on the interaction
    float density = abs(f1 * f2 * 3.0); // Increased multiplier
    float bands = smoothstep(0.7, 0.3, density); // Sharper contrast

    // Create dynamic, oscillating rings based on angle and depth
    float ring = pow(sin(70.0*r + phase_a * 0.5), 5.0) * 2.5; // Changed power and multiplier

    // Use the interaction for palette input, emphasizing radial shift
    float palette_t = 0.01 * iTime + f1 * 0.8 + radial_shift * 0.5; // Adjusted base modulation

    // Apply combined palette functions
    vec3 col1 = pal(palette_t);
    vec3 col2 = palette(palette_t + 0.15);

    // Apply complexity driven by rings and bands
    col1 *= 0.2 + 8.0*bands + ring * 1.0;

    // Introduce chromatic shift based on flow and radial position
    col1 += 0.5 * sin(a * 20.0 + iTime * 7.0) * f2;

    // Mix colors using wave dynamics for secondary modulation
    vec3 final_color = mix(col1, col2, f2);

    // Apply radial falloff emphasizing depth distortion
    final_color *= exp(-2.0*r * r * 0.4); // Increased falloff steepness

    // Apply noise mixing (Shader B influence)
    float noise_val = noise(p * 18.0 + iTime * 2.5).x; // Adjusted noise input
    final_color += noise_val * 0.10; // Reduced noise influence

    // Final ambient scaling based on distance and time
    float ambient = 0.2 + z * 2.5;
    final_color *= ambient * (1.0 + sin(t * 5.5));

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
