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
    float t = iTime * 2.5;
    float x = uv.x * 40.0 + t * 10.0;
    float y = uv.y * 30.0 + t * 7.0;

    float flow_x = sin(x * 0.3 + uv.y * 1.8) * cos(y * 0.5 + t * 1.2);
    float flow_y = cos(x * 0.6 + uv.x * 1.5) * sin(y * 0.4 + t * 0.9);

    return uv + vec2(flow_x * 1.5, flow_y * 1.5);
}

vec3 color_flow(vec2 uv)
{
    float t = iTime * 3.0;
    float angle = atan(uv.y, uv.x) * 6.28;

    float saturation = 0.2 + 0.8 * sin(angle * 5.0 + t * 2.0);
    float value = 0.5 + 0.5 * abs(sin(angle * 4.5 + t * 1.5));

    float hue = angle * 0.8 + (uv.x + uv.y) * 2.0;

    return vec3(hue / 6.28, saturation, value);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 1.8;
    return vec2(
        sin(uv.x * 7.0 + t * 5.0),
        cos(uv.y * 9.0 + t * 6.0)
    );
}

float palette(float t) {
    t = fract(t * 1.3);
    return 0.05 + 0.9 * sin(t * 35.0 + 2.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // 1. Core Flow setup
    vec2 uv_base = uv * vec2(20.0, 20.0) - vec2(10.0, 10.0);
    vec2 f = flow(uv_base);

    // 2. Rotational/Wave Distortion setup
    float flow_angle = atan(f.y, f.x);
    float rotation_speed = iTime * 2.0 + flow_angle * 2.0;

    vec2 rotatedUV = rotate(uv, rotation_speed);
    rotatedUV = rotate(rotatedUV, iTime * 0.8 + flow_angle * 0.5);

    vec2 w = wave(rotatedUV * 0.5);

    // 3. Flow Interaction and Color Base

    // Use flow magnitude to control displacement and color intensity
    float flow_magnitude = length(f);

    // Displacement factor
    vec2 displacement = f * flow_magnitude * 0.5;

    // Apply base color flow
    vec3 c = color_flow(f * 0.7);

    // Use wave results to modulate color structure
    float modulation = w.x * 0.5 + w.y * 0.5;

    // Introduce palette-based color shift based on flow direction
    float p = palette(iTime + f.x * 1.2);

    // Combine flow color and palette modulation
    vec3 flow_color = c * (1.0 + flow_magnitude * 0.7);
    vec3 modulated_color = mix(flow_color, vec3(p * 0.5 + 0.1), modulation * 0.8);

    // Final output based on phase and displacement
    float phase = f.x * 25.0 + f.y * 15.0 + iTime * 3.0;

    vec3 final_c = modulated_color * (0.4 + 0.6 * cos(phase * 5.0));

    // Apply displacement to the final coordinates
    vec2 final_uv = rotatedUV + displacement * 0.5;

    fragColor = vec4(final_c, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
