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

vec2 flow(vec2 uv)
{
    float t = iTime * 2.0;

    // Base flow structure
    vec2 p = uv * 10.0;

    // Introduce complex trigonometric flow
    float flow_x = sin(p.x * 1.5 + t * 0.8) * cos(p.y * 0.5 + t * 1.2);
    float flow_y = cos(p.x * 0.7 + t * 1.5) * sin(p.y * 1.1 + t * 0.5);

    // Return the warped coordinates
    return uv + vec2(flow_x * 1.5, flow_y * 1.5);
}

vec3 color_flow(vec2 uv)
{
    float t = iTime * 3.0;
    float angle = atan(uv.y, uv.x) * 6.28;

    // Calculate saturation based on flow magnitude and time
    float flow_mag = length(uv);
    float saturation = 0.5 + 0.5 * sin(angle * 4.0 + t);

    // Calculate value based on position and time modulation
    float value = 0.3 + 0.7 * abs(sin(angle * 2.0 + t * 0.5));

    // Calculate hue based on the angle and a noise component
    float hue = angle + (flow_mag * 1.5) * 3.14159;

    // Apply a time-based shift to the color space
    hue += sin(t * 0.5) * 0.5;

    return vec3(hue / 6.28, saturation, value);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Define base coordinates and movement
    vec2 uv_base = uv * vec2(22.0, 22.0) - vec2(11.0, 11.0);

    // Apply Flow warping
    vec2 f = flow(uv_base);

    // Apply Color modulation based on flow
    vec3 c = color_flow(f * 0.9);

    // Introduce radial distance distortion and ripple
    float dist = length(f);
    float ripple_freq = 20.0;
    float ripple = sin(dist * ripple_freq + iTime * 5.0) * 0.2;

    // Color shift based on flow magnitude and ripple
    vec3 flow_color = c * (1.0 + ripple * 2.0);

    // Coordinate shift based on dynamic flow components
    vec2 shift = vec2(sin(iTime * 1.2) * 0.04, cos(iTime * 0.9) * 0.04);
    vec2 shifted_uv = uv * 0.8 + shift;

    // Final color integration based on phase and flow magnitude
    float phase = f.x * 7.0 + f.y * 3.0 + iTime * 1.5;
    vec3 final_c = flow_color * (0.6 + 0.4 * cos(phase * 4.0));

    fragColor = vec4(final_c, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
