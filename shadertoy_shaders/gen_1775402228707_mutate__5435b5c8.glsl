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

float smin(float a,float b,float k){ float h=clamp(0.5+0.5*(b-a)/k,0.0,1.0); return mix(b,a,h)-k*h*(1.0-h); }
vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.02,0.38,0.68)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;
    float t = iTime * 0.7;

    // Define radial and polar components
    vec2 center = vec2(0.5);
    vec2 v = uv - center;
    float r = length(v);
    float theta = atan(v.y, v.x);

    // Introduce flow calculations based on polar coordinates and time
    float flow_r = sin(r * 20.0 + t * 1.5);
    float flow_theta = cos(theta * 8.0 + t * 1.2);

    // Generate radial deviation field
    float flow_field = r * flow_r + sin(theta * 5.0 + t * 2.0);

    // Use smin iteratively for complex field generation
    flow_field = smin(flow_field, flow_field + 0.4, 0.2);

    // Use calculated flow_field for coloring
    float influence = flow_field * 1.5;

    // Calculate color based on time and flow
    vec3 color_base = pal(t * 0.5 + flow_field * 10.0);

    // Introduce spatial blending factor
    float spatial_bias = smoothstep(0.3, 0.7, r / 1.5);

    vec3 final_col = mix(color_base, pal(t * 0.7 + spatial_bias), influence);

    fragColor = vec4(final_col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
