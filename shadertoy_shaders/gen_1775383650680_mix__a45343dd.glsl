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

vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 6.0 + iTime * 1.2) * 0.2,
        cos(uv.y * 7.0 + iTime * 0.8) * 0.2
    );
}

vec2 flowB(vec2 uv)
{
    return vec2(
        sin(uv.x * 8.0 + iTime * 0.4) * 0.3,
        cos(uv.y * 5.0 + iTime * 0.6) * 0.15
    );
}

vec3 palette(float t)
{
    return 0.5 + 0.5 * sin(6.28318 * t * 3.0 + 3.14159 * vec3(0.1, 0.5, 0.9));
}

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;

    // Apply flow distortion
    uv = flowA(uv);

    // Radial distortion focusing on frequency interaction (from B)
    vec2 center = vec2(0.5);
    vec2 delta = uv - center;
    float distSq = dot(delta, delta);
    float scale = 1.0 + 3.0 * distSq; 
    uv = uv * scale;

    // Secondary flow (from B)
    uv = flowB(uv);

    // Calculate polar coordinates
    vec2 offset = uv - vec2(0.5);
    float r = length(offset);
    float a = atan(offset.y, offset.x);

    // Depth factor modulation (from A)
    float z = 1.0 / (r * 1.3 + 0.4);

    // Phase and radial flow modulation
    float phase_a = 10.0*a + iTime * 2.5;
    float phase_r = 15.0*r + iTime * 3.5;

    // Calculate core features (from A)
    float f1 = sin(phase_a);
    float f2 = cos(phase_r);

    // Create sharp ring structure based on radius (from A)
    float ring = pow(sin(r * 10.0 + iTime * 5.0), 5.0);

    // Introduce density based on depth interaction (from A)
    float density = abs(z * 2.0 - 0.5);
    float bands = smoothstep(0.5, 0.2, density);

    // Geometric ripple based on angle and flow (from A)
    float ripple = sin(a * 15.0 + iTime * 4.0) * 0.1 + f2 * 0.2;

    // Use exponential falloff tied to radius (from A)
    float dist_falloff = exp(-1.0*r * r * 1.5);

    // Angular banding (from A)
    float band = sin(a * 12.0 + iTime * 2.0) * 0.15;

    // Combine modulation factors
    float modulation = ripple * 1.8 + band * 0.5;

    // Base palette value driven by phase interaction (from A)
    float palette_t = 0.05 + f1*0.5 + f2*0.3;

    vec3 col = palette(palette_t);

    // Apply modulation to create structured color shifts (from A)
    col = mix(col, vec3(1.0, 0.0, 0.0), bands * 1.5); 
    col = mix(col, vec3(0.0, 1.0, 0.0), modulation * 0.5); 

    // Apply ring influence as high-contrast masking (from A)
    col = mix(col, vec3(0.0, 0.0, 1.0), ring * 0.5); 

    // Apply noise influence directly to the intensity (from A)
    float n = noise(uv * 15.0 + iTime * 0.5);
    col *= (0.5 + n * 0.5);

    // Apply final falloff and overall refinement (from A)
    col *= dist_falloff;

    // Final contrast based on radial flow (from A)
    float contrast = pow(r, 2.5);
    col += contrast * 0.1;

    // Apply chromatic shift based on angle (from A)
    col += 0.2 * sin(a * 20.0 + iTime * 5.0);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
