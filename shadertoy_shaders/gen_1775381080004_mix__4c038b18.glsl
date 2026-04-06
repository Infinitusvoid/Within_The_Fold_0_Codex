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
    return vec2(sin(uv.x * 6.0 + iTime * 1.5), cos(uv.y * 6.0 + iTime * 1.8));
}

vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 4.0 + iTime * 0.6) * 0.3,
        cos(uv.y * 8.0 + iTime * 1.0) * 0.2
    );
}

vec3 pal(float t)
{
    return 0.55 + 0.45*cos(6.28318*(vec3(0.08,0.35,0.67)+t));
}

vec2 flow(vec2 uv)
{
    float t = iTime * 1.5;
    float x = uv.x * 30.0 + t * 15.0;
    float y = uv.y * 25.0 + t * 10.0;

    float flow_x = sin(x * 0.6 + uv.y * 2.0) * cos(y * 0.4 + t * 0.8);
    float flow_y = cos(x * 0.5 + uv.x * 1.5) * sin(y * 0.5 + t * 0.5);

    float flow_rot = atan(uv.y - uv.x * 0.5, uv.x + uv.y * 0.5) * 2.0;

    return uv + vec2(flow_x * 1.5, flow_y * 1.5) + vec2(sin(flow_rot * 0.5 + t) * 0.02, cos(flow_rot * 0.7 + t * 0.5) * 0.02);
}

vec3 color_flow(vec2 uv)
{
    float t = iTime * 3.0;
    float angle = atan(uv.y, uv.x) * 6.28;

    // Modulate saturation based on flow magnitude and time
    float saturation = 0.5 + 0.5 * sin(angle * 4.0 + t * 2.0);

    // Modulate value based on distance from center and time oscillation
    float value = 0.4 + 0.5 * abs(sin(angle * 2.5 + t * 1.5));

    // Hue shift based on position and time
    float hue = angle * 0.8 + uv.x * 0.5 + t * 0.2;

    return vec3(hue / 6.28, saturation, value);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    // Combine flow fields from A and B
    vec2 uv_flow = flowB(uv);
    uv_flow = flowA(uv_flow);

    // Use the complex flow calculation from B for the primary distortion
    vec2 f = flow(uv_flow);

    // Radial/Angular effects based on the combined flow
    vec2 uv_final = f;
    float r = length(uv_final);
    float a = atan(uv_final.y, uv_final.x);

    // Depth/Z calculation combining A's fractal style and dynamic time influence
    float t_shift = iTime * 0.5 + iFrame * 0.1;
    float z = floor((1.0/(r+0.15) + t_shift)*6.0)/6.0;

    // Flow-based variations derived from A's structure
    float f1 = sin(10.0*a + 3.0*z - 2.0*iTime);
    float f2 = sin(16.0*a - 4.0*z + 1.7*iTime);

    // Ring calculation based on flow magnitude (from A)
    float ring = smoothstep(0.2, 0.0, abs(sin(10.0*r - 3.0*iTime)));

    // Bands calculation based on flow variations
    float bands = smoothstep(0.25, 0.0, abs(f1 * f2));

    // Palette calculation using A's refined function structure
    float t = 0.08*iTime + 0.08*z + 0.15*f1;
    vec3 col = pal(t);

    // Apply dynamic color modulation using B's flow logic
    vec3 flow_color = color_flow(f * 1.5);

    // Combine modulation factors and apply falloff (from A/B mix)
    col *= 0.2 + 1.6*bands + 0.6*ring;

    // Apply radial falloff (from A)
    col *= exp(-0.8*r);

    // Introduce final dynamic color shift (from A) based on B's phase
    float phase = f.x * 12.0 + f.y * 6.0 + iTime * 3.0;
    col += flow_color * (0.3 + 0.7 * cos(phase * 4.0));

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
