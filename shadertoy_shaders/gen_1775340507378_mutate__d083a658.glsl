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
    float t = iTime * 1.5;
    float x = uv.x * 20.0 + t * 10.0;
    float y = uv.y * 15.0 + t * 7.5;

    float flow_x = sin(x * 0.4 + uv.y * 1.2) * cos(y * 0.3 + t * 0.6);
    float flow_y = cos(x * 0.5 + uv.x * 1.1) * sin(y * 0.5 + t * 0.5);

    return uv + vec2(flow_x * 1.8, flow_y * 1.8);
}

vec3 color_flow(vec2 uv)
{
    float t = iTime * 2.5;
    float angle = atan(uv.y, uv.x) * 6.28;

    // Use time and position to modulate saturation and value
    float saturation = 0.5 + 0.5 * sin(angle * 3.0 + t * 1.5);
    float value = 0.4 + 0.6 * abs(sin(angle * 2.5 + t));

    // Shift hue based on the flow direction and position
    float hue = angle + (uv.x * 0.8 + uv.y * 0.8) * 3.14159;

    return vec3(hue / 6.28, saturation, value);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Define base coordinates and movement
    vec2 uv_base = uv * vec2(18.0, 18.0) - vec2(9.0, 9.0);

    // Apply Flow warping
    vec2 f = flow(uv_base);

    // Apply Color modulation based on flow
    vec3 c = color_flow(f * 1.1);

    // Introduce radial distance distortion and ripple
    float dist = length(f);
    float ripple_freq = 15.0;
    float ripple = sin(dist * ripple_freq + iTime * 4.0) * 0.15;

    // Color shift based on flow magnitude
    vec3 flow_color = c * (1.0 + ripple * 1.5);

    // Coordinate shift based on dynamic flow components
    vec2 shift = vec2(sin(iTime * 1.1) * 0.03, cos(iTime * 0.8) * 0.03);
    vec2 shifted_uv = uv * 0.9 + shift;

    // Final color integration based on phase and flow magnitude
    float phase = f.x * 10.0 + f.y * 5.0 + iTime * 2.0;
    vec3 final_c = flow_color * (0.5 + 0.5 * cos(phase * 3.0));

    fragColor = vec4(final_c, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
