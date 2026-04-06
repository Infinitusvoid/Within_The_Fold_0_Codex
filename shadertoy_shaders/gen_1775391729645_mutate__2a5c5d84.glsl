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
        sin(uv.x * 7.0 + iTime * 1.5),
        cos(uv.y * 5.5 + iTime * 1.0)
    );
}

vec2 flowB(vec2 uv)
{
    return vec2(
        sin(uv.x * 9.0 + iTime * 0.7),
        cos(uv.y * 6.0 + iTime * 0.9)
    );
}

vec3 palette(float t)
{
    return vec3(
        0.05 + 0.9*sin(t * 10.0 + iTime * 0.5),
        0.2 + 0.7*cos(t * 12.0 + iTime * 0.3),
        0.6 + 0.3*sin(t * 8.0 + iTime * 0.7)
    );
}

vec3 pal(float t)
{
    return 0.1 + 0.9 * sin(6.28318 * t * 3.0 + 3.14159 * vec3(0.1, 0.5, 0.9));
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

    // Apply initial flow distortion from B
    uv = flowB(uv);

    // Calculate polar coordinates
    vec2 center_uv = vec2(0.5);
    vec2 offset = uv - center_uv;
    float r = length(offset);
    float a = atan(offset.y, offset.x);

    // Depth factor based on curvature
    float z = 1.0 / (r * 2.5 + 0.4);

    // Flow and phase modulation based on A's geometric setup
    float angle_flow = sin(a * 18.0 + iTime * 5.0);
    float radial_shift = z * 2.0;

    float phase_a = 30.0*a + iTime * 3.0 + angle_flow;
    float phase_r = 35.0*r + radial_shift + iTime * 1.5;

    float f1 = sin(phase_a * 0.5);
    float f2 = cos(phase_r * 1.5);

    // Create complex density based on interaction
    float density = abs(f1 * f2 * 4.0);
    float bands = smoothstep(0.7, 0.05, density);

    // Create dynamic, oscillating rings
    float ring = pow(sin(30.0*r + iTime * 10.0), 4.0);

    // Ripple effect from B, stronger influence
    float ripple = sin(r * 15.0 + a * 8.0 + iTime * 5.0) * 0.3;

    // Use exponential falloff tied to radial position
    float dist_falloff = exp(-2.0 * r * r * 1.2);

    // Introduce angular banding based on flow
    float band = sin(a * 15.0 + iTime * 6.0) * 0.2;

    // Modulation factor based on the ripple and angular complexity
    float modulation = ripple * 3.0 + band * 1.5;

    // Base palette value driven by radius, flow, and depth interaction
    float palette_t = 0.005*iTime + f1*1.2 + radial_shift*0.7;

    vec3 col = pal(palette_t);

    // Apply complexity driven by rings and bands
    col *= 0.01 + 8.0*bands + 4.0*ring;

    // Apply noise using B's noise function with increased frequency
    float n = noise(uv * 15.0 + iTime * 1.0);

    // Introduce the ripple/band modulation into the color intensity
    col *= (1.0 + modulation * 0.7);

    // Contrast applied by flow state
    float m = smoothstep(0.15, 0.03, abs(f2));

    // Final color calculation combining falloff and noise modulation
    col *= dist_falloff;
    col += n * 0.7;

    // Apply chromatic shift based on angle and time
    col += 0.5 * sin(a * 30.0 + iTime * 7.0);

    // Final refinement using flowA
    uv = flowA(uv);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
