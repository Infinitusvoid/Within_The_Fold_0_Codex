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
    float t = iTime * 4.0;
    float x = uv.x * 50.0 + t * 15.0;
    float y = uv.y * 50.0 + t * 10.0;

    float flow_x = sin(x * 0.4 + uv.y * 2.0) * cos(y * 0.5 + t * 1.0);
    float flow_y = cos(x * 0.6 + uv.x * 2.5) * sin(y * 0.4 + t * 1.2);

    return uv + vec2(flow_x * 1.8, flow_y * 1.8);
}

vec3 color_flow(vec2 uv)
{
    float t = iTime * 3.5;
    float angle = atan(uv.y, uv.x) * 6.28;

    float saturation = 0.1 + 0.9 * sin(angle * 8.0 + t * 2.5);
    float value = 0.4 + 0.6 * abs(sin(angle * 6.0 + t * 1.5));

    float hue = angle * 0.8 + (uv.x + uv.y) * 3.0;

    return vec3(hue / 6.28, saturation, value);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 2.2;
    return vec2(
        sin(uv.x * 10.0 + t * 5.0),
        cos(uv.y * 10.0 + t * 6.0)
    );
}

float palette(float t) {
    t = fract(t * 2.6);
    return 0.0 + 0.9 * sin(t * 40.0 + 3.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // 1. Core Flow setup
    vec2 uv_base = uv * vec2(15.0, 15.0) - vec2(7.5, 7.5);
    vec2 f = flow(uv_base);

    // 2. Rotational/Wave Distortion setup
    float flow_angle = atan(f.y, f.x);
    float rotation_speed = iTime * 2.5 + flow_angle * 1.5;

    vec2 rotatedUV = rotate(uv, rotation_speed);
    rotatedUV = rotate(rotatedUV, iTime * 1.0 + flow_angle * 0.7);

    vec2 w = wave(rotatedUV * 0.6);

    // 3. Flow Interaction and Color Base

    float flow_magnitude = length(f);

    // Displacement factor, amplified
    vec2 displacement = f * flow_magnitude * 1.0;

    // Apply base color flow
    vec3 c = color_flow(f * 0.5);

    // Use wave results to modulate color structure
    float modulation = w.x * 0.3 + w.y * 0.7;

    // Introduce palette-based color shift based on flow direction
    float p = palette(iTime + f.x * 2.0);

    // Combine flow color and palette modulation
    vec3 flow_color = c * (1.0 + flow_magnitude * 0.8);
    vec3 modulated_color = mix(flow_color, vec3(p * 0.3 + 0.1), modulation * 1.2);

    // Final output based on phase and displacement
    float phase = f.x * 30.0 + f.y * 20.0 + iTime * 5.0;

    vec3 final_c = modulated_color * (0.3 + 0.7 * cos(phase * 8.0));

    // Apply displacement to the final coordinates
    vec2 final_uv = rotatedUV + displacement * 0.7;

    // Apply screen warping based on time
    final_uv.x += sin(iTime * 1.5) * 0.05;
    final_uv.y += cos(iTime * 1.5) * 0.05;

    fragColor = vec4(final_c, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
