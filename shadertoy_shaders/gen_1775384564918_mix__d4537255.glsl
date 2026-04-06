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
        sin(uv.x * 6.0 + iTime * 1.2) * 0.15,
        cos(uv.y * 7.0 + iTime * 0.8) * 0.1
    );
}

vec2 flowB(vec2 uv)
{
    return vec2(
        sin(uv.x * 8.0 + iTime * 0.4) * 0.25,
        cos(uv.y * 5.0 + iTime * 0.6) * 0.2
    );
}

vec3 pal(float t)
{
    return 0.55 + 0.45*cos(6.28318*(vec3(0.02,0.28,0.6)+t));
}

mat2 rot(float a){ float c=cos(a), s=sin(a); return mat2(c,-s,s,c); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = uv * 2.0 - 1.0;
    p.x *= iResolution.x / iResolution.y;
    p *= rot(iTime * 0.5);

    // Apply flow distortion from B
    uv = flowB(p);

    // Apply secondary flow distortion from A
    uv = flowA(uv);

    // Polar coordinates setup derived from B
    // Center the coordinates for distance calculation
    vec2 center = vec2(0.5);
    vec2 centered_uv = uv - center;

    float r = length(centered_uv);
    float a = atan(centered_uv.y, centered_uv.x);

    // Calculate inverse distance/depth factor from B
    float z = 1.0 / (r * 1.5 + 0.5);

    // Flow and phase modulation based on angle and depth from B
    float angle_flow = sin(a * 20.0 + iTime * 3.0);
    float radial_shift = z * 1.2;

    float phase_a = 15.0*a + iTime * 1.2 + angle_flow;
    float phase_r = 20.0*r + radial_shift + iTime * 1.5;

    float f1 = sin(phase_a * 0.8);
    float f2 = cos(phase_r * 1.1);

    // Create complex density based on the interaction from B (Shader A logic adaptation)
    float density = abs(f1 * f2 * 2.5);
    float bands = smoothstep(0.5, 0.15, density);

    // Create dynamic, oscillating rings from B (Shader A logic adaptation)
    float ring = pow(sin(15.0*r + iTime * 6.0), 4.0);

    // Calculate palette input using flow/depth interactions (Shader A logic adaptation)
    float palette_t = 0.05*iTime + f1*0.7 + radial_shift*0.4;

    vec3 col = pal(palette_t);

    // Apply complexity driven by rings and bands
    col *= 0.1 + 4.0*bands + 2.0*ring;

    // Introduce a chromatic shift based on angle and time from B
    col += 0.3 * sin(a * 15.0 + iTime * 4.0);

    // Apply radial falloff emphasizing depth distortion from B
    col *= exp(-1.2*r * r * 0.7);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
