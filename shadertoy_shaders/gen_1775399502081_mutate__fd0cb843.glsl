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

    // 2. Polar coordinate conversion
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float theta = atan(p.y, p.x);

    // 3. Flow and Phase calculation (Modified interaction)
    float time = iTime * 2.5;

    // New flow calculation focusing on rotational complexity
    float flow_r = sin(r * 10.0 + time * 1.5);
    float flow_theta = cos(theta * 8.0 + time * 2.0);

    // Phase calculation based on radial/angular differences
    float phase_r = 50.0 * r + flow_r * 10.0; 
    float phase_theta = 10.0 * theta + time * 3.0; 

    float f1 = sin(phase_theta) * 0.5 + flow_theta * 0.5; 
    float f2 = cos(phase_r * 0.5 + time * 1.0); 

    // 4. Ring/Band generation
    float density = abs(f1 * f2 * 3.0);
    float bands = smoothstep(0.25, 0.1, density);

    // Ring calculation based on radius and flow
    float ring = pow(sin(12.0*r + phase_theta * 0.8) * flow_r, 8.0) * 4.0;

    // 5. Radial Line/Fill generation (Modified)
    float angle_dist = theta * 20.0 + time * 0.8;
    float radius_mod = sin(r * 6.0 + angle_dist * 4.0) * 0.5 + 0.5;

    // Use radial modulation to define shape boundaries
    float d = r - (0.5 + 0.3 * radius_mod);
    float fill = smoothstep(0.01, 0.0, d);
    float line = smoothstep(0.07, 0.0, abs(d * 5.0));

    // 6. Color calculation
    // Palette influenced by the phase
    float palette_t = 0.03*iTime + f1*0.5 + flow_theta*0.5;

    vec3 col = pal(palette_t);

    // Apply complexity (Bands/Ring)
    col *= 0.1 + 8.0*bands + ring * 2.0;

    // Apply radial line/fill influence, making lines more dominant
    col *= (0.1 * fill + 1.5 * line) * 0.5 + 0.5;

    // Chromatic shift based on angular flow
    col += sin(theta * 20.0 + iTime * 8.0) * f2 * 0.8;

    // Apply radial falloff, focusing on depth
    col *= exp(-1.8*r * r * 0.6);

    // Final noise layer based on polar coordinates, emphasizing structure
    float noise_val = noise(p * 15.0 + iTime * 5.0).x;
    col += noise_val * 0.15;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
