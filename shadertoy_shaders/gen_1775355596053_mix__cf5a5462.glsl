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

vec2 flowB(vec2 uv)
{
    return vec2(sin(uv.x * 5.0 + iTime * 2.0), cos(uv.y * 5.0 + iTime * 3.0));
}

vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 8.0 + iTime * 1.2) * 0.4,
        sin(uv.y * 4.0 + iTime * 0.8) * 0.3
    );
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

vec3 pal(float t)
{
    return 0.5 + 0.5*sin(6.28318*(vec3(0.1, 0.3, 0.7) + t));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    // Polar coordinates centered at (0,0)
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float a = atan(p.y, p.x);

    // Flow calculation (Combining A's flow style and B's spiral emphasis)
    vec2 flow_combined = flowB(uv);
    flow_combined = flowA(flow_combined);

    // Depth calculation (Based on A's structure, slightly modified)
    float t_shift = iTime * 0.3 + iFrame * 0.1;
    float z = floor((1.0/(r+0.2) + t_shift)*5.0)/5.0;

    // Flow-based variations and Wave calculation
    float f1 = sin(12.0*a + 3.0*z - 1.5*iTime);
    float f2 = cos(8.0*r + 2.0*a + 1.0*iTime);

    float wave = sin(r * 4.0 + iTime * 1.5) * cos(a * 5.0);

    // Ring calculation
    float ring = smoothstep(0.2, 0.0, abs(sin(15.0*r - 4.0*iTime)));

    // Bands calculation
    float bands = smoothstep(0.25, 0.0, abs(f1 * f2));

    // Density calculation (From B, strong radial falloff)
    float density = sin(a * 15.0 + iTime * 5.0) * exp(-r * r * 2.5);

    // Phase modulation (Combining flow and wave)
    float phase = flow_combined.x * 0.5 + wave * 0.5 * (1.0 - r * 0.4);

    // Palette calculation (Using A's palette structure)
    float t = 0.08*iTime + 0.05*z + 0.1*f1;
    vec3 col = pal(t);

    // Combine modulation factors and apply falloff (Mixing A's structure with B's density)
    col *= 0.3 + 1.2*bands + 0.5*ring;
    col *= 1.2 + 4.0 * density;

    // Introduce final dynamic color shift (From A) and angular/radial emphasis (From B)
    col += vec3(sin(iTime*0.8 + a*2.0) * 0.2) * 0.6;
    col += sin(a * 20.0 + iTime * 10.0) * 0.5;
    col += cos(r * 6.0 + iTime * 5.0) * 0.4;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
