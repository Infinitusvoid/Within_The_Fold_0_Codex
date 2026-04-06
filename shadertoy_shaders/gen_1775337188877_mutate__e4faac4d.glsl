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
    vec2 p = uv * 3.0;

    // Apply time-dependent rotation and distortion
    p *= rot(0.5*iTime + 0.1);

    // Calculate complex spatial and temporal values
    float t1 = p.x * 10.0 + p.y * 5.0 + iTime * 0.8;
    float t2 = p.x * 12.0 - p.y * 3.0 + iTime * 1.5;

    float a = sin(15.0 * t1);
    float b = cos(8.0 * t2);
    float c = sin(t1 * 0.5 + t2 * 0.3);

    // Combine the values
    float m = 0.5 + 0.3 * a + 0.4 * b + 0.3 * c;

    // Apply palette modulation
    vec3 col = pal(t1 * 0.5 + iTime * 0.1) * (0.1 + 0.9 * m);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
