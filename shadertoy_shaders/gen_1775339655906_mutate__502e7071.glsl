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
    float t = iTime * 1.2;
    float x = uv.x * 18.0 + t * 8.0;
    float y = uv.y * 14.0 + t * 6.0;
    float flow_x = sin(x * 0.5) * cos(y * 0.4 + t * 0.5);
    float flow_y = cos(x * 0.6 + t * 0.3) * sin(y * 0.7);
    return uv + vec2(flow_x * 1.5, flow_y * 1.5);
}

vec3 color_flow(vec2 uv)
{
    float t = iTime * 2.0;
    float angle = atan(uv.y, uv.x) * 6.28;
    float saturation = 0.5 + 0.5 * sin(angle * 3.0 + t);
    float value = 0.5 + 0.5 * cos(t * 1.5);

    // Shift hue based on the flow direction
    float hue = angle + (uv.x * 0.5 + uv.y * 0.5) * 3.14159;

    return vec3(hue / 6.28, saturation, value);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Define base coordinates and movement
    vec2 uv_base = uv * vec2(12.0, 12.0) - vec2(6.0, 6.0);

    // Apply Flow warping
    vec2 f = flow(uv_base);

    // Apply Color modulation based on flow
    vec3 c = color_flow(f * 1.2);

    // Introduce radial distance distortion
    float dist = length(f);
    float ripple = sin(dist * 10.0 + iTime * 5.0) * 0.1;

    // Adjust color based on the ripple intensity
    c *= (1.0 + ripple);

    // Coordinate shift based on time and flow direction
    vec2 shifted_uv = uv * 1.0 + vec2(sin(iTime * 0.7) * 0.04, cos(iTime * 0.5) * 0.04);

    // Final color integration based on phase
    float phase = f.x * 15.0 + f.y * 7.0 + iTime * 3.0;
    vec3 final_c = c * (0.5 + 0.5 * cos(phase * 2.5));

    fragColor = vec4(final_c, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
