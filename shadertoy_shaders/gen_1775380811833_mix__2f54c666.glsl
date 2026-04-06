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
vec3 pal(float t)
{
    return 0.1 + 0.9 * sin(6.28318 * t * 3.0 + 3.14159 * vec3(0.1, 0.5, 0.9));
}

vec2 flow1(vec2 uv)
{
    return vec2(sin(uv.x * 8.0 + iTime), cos(uv.y * 7.0 + iTime * 1.5));
}

vec2 flow2(vec2 uv)
{
    return uv * 1.2 + vec2(
        sin(uv.x * 5.0 + iTime * 0.8),
        cos(uv.y * 9.0 + iTime * 0.4)
    );
}

vec2 flow(vec2 uv)
{
    return flow1(uv) + flow2(uv);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    // Polar coordinates
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float a = atan(p.y, p.x);

    // Flow calculation (from B)
    vec2 flow = flow(uv);

    // Radial distortion based on distance (from B)
    float distSq = dot(p, p);
    float scale = 1.0 + 3.0 * distSq; 

    // Dynamic density and depth modulation (from B)
    float density = sin(a * 7.0 + iTime * 2.5) * exp(-r * r * 2.0);
    float z = 1.0 / (r * 1.5 + 0.2);

    // Flow phase calculation (from B)
    float flow_phase = dot(flow, vec2(1.0, 1.0)) * 0.5 + sin(a * 10.0 + iTime * 1.1) * 0.5;

    // Palette input calculation (merging A's structure with B's flow/depth)
    // t calculation uses r and a for radial/angular input
    float t = (r * 6.0 + a * 4.5) * 8.0 + iTime * 1.1;

    // Final modulation factor (merging A's wave interaction with B's spatial data)
    float palette_t = flow_phase * 4.0 + z * 0.2 + density * 0.5;

    // Base color calculation using A's palette function driven by B's data
    vec3 col = pal(palette_t);

    // Apply strong angular and radial modulation (from B)
    float angular_effect = cos(a * 15.0 + iTime * 6.0);
    float radial_emphasis = sin(r * 6.0 + iTime * 3.0) * 0.5;

    // Apply high frequency wave modulation (from A)
    float wave_shift = sin(uv.x * 10.0 + iTime * 0.7) * 1.5;
    wave_shift += cos(uv.y * 12.0 + iTime * 0.5) * 0.7;
    wave_shift += sin(uv.x + uv.y) * 0.4;

    col += wave_shift;

    // Apply distortion and density scaling
    col *= 1.2 + 3.0 * density;
    col += angular_effect * 0.5;
    col += radial_emphasis * 0.3;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
