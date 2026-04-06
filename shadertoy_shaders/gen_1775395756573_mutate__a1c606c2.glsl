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
vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.0,0.33,0.67)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;
    uv *= rot(0.1*iTime);

    // Calculate radial and angular properties
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float a = atan(p.y, p.x);

    // Calculate a complex flow based on time and position (Ripple effect)
    float flow = r * 3.0 + a * 4.0 + sin(uv.x * 10.0 + iTime * 2.0) * 1.5;

    // Apply distortion based on flow and angle
    float flow_a = a + flow * 0.5;
    float flow_r = r * 0.5 + flow * 0.1;

    // Warping the UVs using a flow-driven spiral
    vec2 warped_uv = vec2(cos(flow_a) * r, sin(flow_a) * r);

    // Introduce flow-based noise and subtle detail (More dynamic noise)
    float noise_x = sin(uv.x * 30.0 + iTime * 8.0) * cos(uv.y * 18.0 + iTime * 12.0);
    float noise_y = sin(uv.x * 15.0 + iTime * 3.0) * cos(uv.y * 20.0 + iTime * 5.0);

    // Calculate a factor based on distance and flow
    float color_shift = r * 6.0 + flow * 0.4;

    // Use the shift to modulate the palette input
    vec3 base_color = pal(color_shift * 0.7);

    // Apply flow-dependent noise to shift hue and saturation
    vec3 final_color = base_color * (1.0 + noise_x * 0.15 + noise_y * 0.1);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
