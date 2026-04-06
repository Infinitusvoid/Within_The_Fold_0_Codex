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

mat2 rot(float a){ float c=cos(a), s=sin(a); return mat2(c,-s,s,c); }
vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.0,0.33,0.65)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;
    vec2 p = uv * 10.0;

    // Apply rotation and increased spatial distortion
    p *= rot(0.8*iTime + 0.1);

    // Calculate complex spatial and temporal values based on shifted coordinates
    float t1 = p.x * 12.0 + p.y * 6.0 + iTime * 1.5;
    float t2 = p.x * 4.0 - p.y * 3.0 + iTime * 2.5;

    // Calculate amplitude and phase modulation using high frequency
    float a = sin(50.0 * t1);
    float b = cos(20.0 * t2);
    float d = sin(t1 * 0.5 + t2 * 0.7);

    // Combine the values using a density map approach with heavier weighting
    float m = 0.5 + 0.3 * a + 0.5 * b + 0.4 * d;

    // Apply palette modulation based on evolving time and derived value
    vec3 col = pal(t1 * 0.5 + iTime * 0.02) * (0.15 + 0.8 * m);

    // Add a subtractive contrast based on high oscillations
    col *= (1.0 - 0.3 * abs(a * 0.8 + b * 0.5));

    // Final color adjustment based on time
    col += vec3(sin(iTime * 1.5) * 0.1) * m;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
