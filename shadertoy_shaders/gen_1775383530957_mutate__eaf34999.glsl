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
    float x = uv.x * 30.0 + t * 8.0;
    float y = uv.y * 20.0 + t * 5.0;

    float flow_x = sin(x * 0.4 + uv.y * 1.5) * cos(y * 0.3 + t * 1.0);
    float flow_y = cos(x * 0.5 + uv.x * 1.2) * sin(y * 0.5 + t * 0.8);

    return uv + vec2(flow_x * 2.5, flow_y * 2.5);
}

vec3 color_flow(vec2 uv)
{
    float t = iTime * 3.0;
    float angle = atan(uv.y, uv.x) * 6.28;

    float saturation = 0.3 + 0.7 * sin(angle * 4.0 + t * 2.0);
    float value = 0.5 + 0.5 * abs(sin(angle * 3.0 + t * 1.5));

    float hue = angle * 0.5 + (uv.x + uv.y) * 1.5;

    return vec3(hue / 6.28, saturation, value);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 1.5;
    return vec2(
        sin(uv.x * 5.0 + t * 3.0),
        cos(uv.y * 7.0 + t * 4.0)
    );
}

float palette(float t) {
    t = fract(t * 1.1);
    return 0.1 + 0.8 * sin(t * 30.0 + 4.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // 1. Core Flow setup
    vec2 uv_base = uv * vec2(15.0, 15.0) - vec2(7.5, 7.5);
    vec2 f = flow(uv_base);

    // 2. Rotational/Wave Distortion setup
    float flow_angle = f.x * 5.0 + f.y * 5.0;
    float rotation_speed = iTime * 1.5 + flow_angle * 0.2;

    vec2 rotatedUV = rotate(uv, rotation_speed);
    rotatedUV = rotate(rotatedUV, iTime * 0.5 + f.x * 0.5);

    vec2 w = wave(rotatedUV * 0.8);

    // 3. Flow Interaction and Color Base

    // Use flow magnitude to control color intensity and palette shift
    float flow_magnitude = length(f);
    float color_intensity = pow(flow_magnitude * 1.5, 1.5);

    // Apply base color flow
    vec3 c = color_flow(f * 0.8);

    // Use wave results to modulate the color structure
    float modulation = w.x * 0.4 + w.y * 0.6;

    // Introduce palette-based color shift based on flow direction
    float p = palette(iTime + f.x * 1.5);

    // Combine flow color and palette modulation
    vec3 flow_color = c * (1.0 + color_intensity * 0.5);
    vec3 modulated_color = mix(flow_color, vec3(p * 0.6 + 0.1), modulation * 0.9);

    // Final output based on phase
    float phase = f.x * 15.0 + f.y * 10.0 + iTime * 2.5;
    vec3 final_c = modulated_color * (0.3 + 0.7 * cos(phase * 4.0));

    fragColor = vec4(final_c, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
