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

    // Apply rotation and time flow
    uv *= rot(0.1*iTime + 0.05);

    // Calculate radial and angular properties
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float a = atan(p.y, p.x);

    // Apply flow-driven spiral warping
    float flow = r * 5.0 + iTime * 2.0;
    float flow_a = a + flow * 0.4;

    vec2 warped_uv = vec2(cos(flow_a) * r, sin(flow_a) * r);

    // Introduce a new distortion factor based on flow and time
    float distortion = sin(flow * 15.0) * 0.5;

    // Calculate a dynamic grid/position shift based on angle and time
    float x_shift = a / 3.14159;
    // Introduce positional shift based on inverse radius and time, modulated by the distortion
    float y_shift = 0.2 / max(r, 0.005) + iTime * 4.0 + distortion;

    // Grid pattern calculation using sine wave modulated by radial distance
    float grid = 0.5 + 0.8 * sin(50.0 * y_shift * r + 20.0 * iTime);

    // Combine flow distortion and grid structure
    float final_flow_val = flow + grid * 0.3;

    // Calculate base color shift using the flow and radius
    float color_shift = r * 3.0 + iTime * 1.0;

    // Use the shift to modulate the palette input
    vec3 base_color = pal(color_shift * 0.7);

    // Apply radial modulation based on flow and grid interaction
    float radial_factor = 1.0 - r * 0.6;

    // Color mixing based on grid pattern, introducing blue shift
    vec3 dark_color = vec3(0.05, 0.05, 0.15);
    vec3 col = mix(base_color, dark_color, grid * 0.5 + 0.2);

    // Apply flow distortion and radial fading
    col *= radial_factor * (1.0 + sin(flow * 8.0));

    // Introduce a subtle color shift based on radial position
    col += vec3(r * 0.05);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
