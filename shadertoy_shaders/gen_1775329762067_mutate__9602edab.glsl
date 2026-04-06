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

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.6 + uv.x * 1.5;
    float scale_x = 1.0 + 0.1 * sin(t * 6.2 + uv.x * 30.0);
    float scale_y = 1.0 + 0.12 * cos(t * 5.8 + uv.y * 25.0);
    uv.x *= scale_x;
    uv.y *= scale_y;
    uv.x += iTime * 0.15;
    uv.y += iTime * 0.1;
    return uv;
}

vec2 wave(vec2 uv)
{
    float t = iTime * 0.5 + uv.x * 0.5;
    float t2 = iTime * 0.5 + uv.y * 1.0;
    float s = 10.0 + t;

    float r = sin(uv.x * s + t * 0.7);
    float g = cos(uv.y * s - t2 * 0.8);
    float b = sin(uv.x * 3.0 + uv.y * 2.0 + t * 1.0);

    return vec2(r, g);
}

vec3 colorFromWave(vec2 w)
{
    float r = 0.5 + 0.5 * sin(w.x * 4.0 + iTime * 1.0);
    float g = 0.5 + 0.5 * cos(w.y * 5.5 - iTime * 0.8);
    float b = 0.3 + 0.7 * sin(w.x * 3.0 + w.y * 2.5 + iTime * 0.4);
    return vec3(r, g, b);
}

vec2 flow_field(vec2 uv)
{
    float t = iTime * 1.2;
    float angle = uv.x * 15.0 + uv.y * 10.0;
    float flow_magnitude = sin(angle * 1.1 + t * 0.5) * 10.0;

    float dx = flow_magnitude * 0.5;
    float dy = flow_magnitude * 0.8;

    return vec2(dx, dy);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Apply initial distortions
    uv = distort(uv);

    // Calculate flow field
    vec2 flow = flow_field(uv);

    // Generalized motion based coordinate and rotation drivers
    float flow_time = iTime * 1.5;

    // Dynamic rotation based on flow
    float rotation_angle = flow.x * 5.0 + flow.y * 3.0 + flow_time * 0.5;
    mat2 rot = mat2(cos(rotation_angle), -sin(rotation_angle), sin(rotation_angle), cos(rotation_angle));

    // Apply rotations
    uv = rot * uv;

    // Calculate fundamental waves
    vec2 w = wave(uv);

    // Color generation based on wave
    vec3 color = colorFromWave(w);

    // Introduce ripple/feedback system based on flow
    float freq_x = uv.x * 10.0 + flow.x * 10.0;
    float freq_y = uv.y * 10.0 + flow.y * 10.0;

    float ripple = sin(freq_x * 20.0) * cos(freq_y * 18.0) * 0.1;

    // Apply flow-based screen effects
    float intensity = smoothstep(0.2, 0.8, uv.x * 2.5 + ripple * 1.2 + sin(flow_time * 8.0));

    // Manipulate colors
    color.r = intensity * 0.8 + 0.1;

    color.g = cos(color.r * 12.0 + flow_time * 3.0 + uv.y * 7.0);
    color.b = 0.4 + 0.6 * sin(freq_x * 5.0 + uv.y * 4.0 + iTime * 0.5);

    // Final swirling transformation
    color.r = sin(color.g * 10.0 + iTime * 0.7) * 0.5 + 0.5;
    color.g = cos(color.r * 13.0 - uv.y * 10.0 + iTime * 0.6) * 0.4 + 0.5;
    color.b = pow(sin(uv.x * 5.0 + uv.y * 5.0 + iTime * 1.5), 1.5) * 0.5;

    fragColor = vec4(color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
