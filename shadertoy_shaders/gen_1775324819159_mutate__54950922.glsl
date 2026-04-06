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

vec2 wave(vec2 uv)
{
    float x = uv.x + 0.1 * sin(uv.x * 10.0 + iTime * 0.1);
    float y = uv.y + 0.1 * sin(uv.y * 15.0 + iTime * 0.2);
    return vec2(x, y);
}

vec3 gradient(float t)
{
    float r = 0.5 + 0.5 * sin(t + iTime * 0.1);
    float g = 0.5 + 0.5 * cos(t + iTime * 0.2);
    float b = 0.5 + 0.5 * sin(t + iTime * 0.3);
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Base distortion
    uv = wave(uv);

    // Rotation based on time and UV position
    float angle = iTime * 0.5 + sin(uv.x * 5.0 + iTime * 0.1) * 3.0 + uv.y * 10.0;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv *= rotationMatrix;

    // Time-dependent flow value
    float t = uv.x * uv.y * 8.0 + iTime * 0.3;
    vec3 base_col = gradient(t);

    // Complex secondary color generation
    float flow_speed = sin(uv.x * 15.0 + iTime * 0.5);
    float warp = sin(uv.y * 20.0 + iTime * 0.8);

    vec3 color = vec3(flow_speed, warp, 0.1 + 0.5 * sin(uv.x + uv.y * 3.0 + iTime));

    // Introduce smooth transitions based on frequency and position
    float freq = uv.x * 12.0 + sin(iTime * 0.8);
    float offset = sin(freq * 5.0) * 0.03;
    float v = smoothstep(0.4, 0.6, uv.y - offset * 2.0);

    color.r = v;

    // High frequency manipulation using complex time interactions
    float hue_shift = sin(uv.x * 50.0 + iTime * 1.5) * 10.0;
    float saturation_mod = cos(uv.y * 70.0 + iTime * 2.0) * 5.0;

    color.g = sin(uv.x * 10.0 + iTime + hue_shift);
    color.b = 0.5 + 0.5 * sin(uv.y * 10.0 + iTime * 1.2 + saturation_mod);

    // Final layer blending
    float contrast = 1.0 + sin(uv.x * 100.0 + iTime * 0.5) * 0.5;
    color = mix(color, vec3(0.0, 0.8, 0.0), contrast * 0.5);

    fragColor = vec4(color,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
