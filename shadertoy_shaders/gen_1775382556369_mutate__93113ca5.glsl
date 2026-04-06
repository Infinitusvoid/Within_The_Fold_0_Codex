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
        cos(uv.x * 6.0 + iTime * 0.8) * 0.15,
        sin(uv.y * 5.0 + iTime * 1.2) * 0.10
    );
}

vec2 flowB(vec2 uv)
{
    return vec2(
        sin(uv.x * 8.0 + iTime * 1.5) * 0.25,
        cos(uv.y * 7.0 + iTime * 0.9) * 0.20
    );
}

vec3 palette(float t)
{
    return vec3(
        0.15 + 0.7*sin(t * 3.0 + iTime * 0.4),
        0.4 + 0.5*cos(t * 1.8 + iTime * 0.7),
        0.8 + 0.2*sin(t * 4.5 + iTime * 1.1)
    );
}

vec3 pal(float t)
{
    return 0.3 + 0.6 * sin(6.28318 * t * 4.0 + 3.14159 * vec3(0.1, 0.5, 0.9));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    // Apply initial flow distortion
    uv = flowB(uv);

    // Polar coordinates setup
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float a = atan(p.y, p.x);

    // Calculate depth/distance factor
    float z = 1.0 / (r * 1.5 + 0.3);

    // Flow and phase modulation based on angle and depth
    float angle_flow = sin(a * 40.0 + iTime * 3.5);
    float radial_shift = z * 3.0;

    float phase_a = 15.0*a + iTime * 2.8 + angle_flow;
    float phase_r = 45.0*r + radial_shift + iTime * 2.0;

    float f1 = sin(phase_a * 0.8);
    float f2 = cos(phase_r * 1.5);

    // Create complex density based on the interaction
    float density = abs(f1 * f2 * 2.0);
    float bands = smoothstep(0.5, 0.2, density);

    // Create dynamic, oscillating rings based on rotation
    float ring = pow(sin(30.0*r + iTime * 10.0), 6.0);

    // Calculate palette input using flow/depth interactions
    float palette_t = 0.02*iTime + f1*0.6 + radial_shift*0.7;

    vec3 col = pal(palette_t);

    // Apply complexity driven by rings and bands
    col *= 0.03 + 8.0*bands + 4.0*ring;

    // Introduce a chromatic shift based on angle and time
    col += 0.5 * sin(a * 30.0 + iTime * 6.0);

    // Apply radial falloff emphasizing depth distortion
    col *= exp(-2.0*r * r * 1.0);

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
