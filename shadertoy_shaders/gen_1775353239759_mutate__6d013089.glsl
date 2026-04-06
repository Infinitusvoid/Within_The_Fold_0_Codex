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
    vec2 p = uv * 5.0;

    // Apply time-dependent rotation and distortion
    p *= rot(0.4*iTime + 0.2);

    // Calculate complex spatial and temporal values based on shifted coordinates
    float t1 = p.x * 8.0 + p.y * 4.0 + iTime * 1.2;
    float t2 = p.x * 6.0 - p.y * 2.0 + iTime * 2.0;

    // Calculate amplitude and phase modulation
    float a = sin(30.0 * t1);
    float b = cos(10.0 * t2);
    float d = sin(t1 * 0.4 + t2 * 0.6); // New term for complexity

    // Combine the values using a density map approach
    float m = 0.5 + 0.2 * a + 0.4 * b + 0.3 * d;

    // Apply palette modulation based on evolving time and derived value
    vec3 col = pal(t1 * 0.6 + iTime * 0.05) * (0.1 + 0.9 * m);

    // Add a subtle glow based on the highest oscillation
    col += vec3(m * 0.1) * 0.5;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
