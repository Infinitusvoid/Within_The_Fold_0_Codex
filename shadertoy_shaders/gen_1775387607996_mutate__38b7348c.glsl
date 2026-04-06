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
    return vec2(sin(uv.x * 10.0 + iTime * 1.5), cos(uv.y * 8.0 + iTime * 1.0));
}

vec2 flow2(vec2 uv)
{
    return uv * 1.1 + vec2(
        sin(uv.x * 5.0 + iTime * 0.7),
        cos(uv.y * 10.0 + iTime * 0.5)
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

    // Flow calculation
    vec2 flow = flow(uv);

    // Radial distortion based on distance (from B)
    float distSq = dot(p, p);
    float scale = 1.0 + 4.0 * distSq; 

    // Dynamic density and depth modulation
    float density = sin(a * 8.0 + iTime * 3.0) * exp(-r * r * 1.5);
    float z = 1.0 / (r * 2.0 + 0.5);

    // Flow phase calculation
    float flow_phase = dot(flow, vec2(1.0, 1.0)) * 0.6 + sin(a * 12.0 + iTime * 2.0) * 0.4;

    // Palette input calculation
    // t calculation uses r and a for radial/angular input
    float t = (r * 5.0 + a * 5.5) * 7.0 + iTime * 1.3;

    // Final modulation factor
    float palette_t = flow_phase * 5.0 + z * 0.3 + density * 0.6;

    vec3 col = pal(palette_t);

    // Apply strong angular and radial modulation
    float angular_effect = sin(a * 20.0 + iTime * 8.0);
    float radial_emphasis = cos(r * 7.0 + iTime * 4.0) * 0.5;

    // Apply high frequency wave modulation
    float wave_shift = sin(uv.x * 15.0 + iTime * 0.9) * 1.8;
    wave_shift += cos(uv.y * 18.0 + iTime * 0.6) * 0.6;
    wave_shift += sin(uv.x * uv.y * 12.0) * 0.3;

    col += wave_shift;

    // Apply distortion and density scaling
    col *= 1.1 + 3.5 * density;
    col += angular_effect * 0.4;
    col += radial_emphasis * 0.3;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
