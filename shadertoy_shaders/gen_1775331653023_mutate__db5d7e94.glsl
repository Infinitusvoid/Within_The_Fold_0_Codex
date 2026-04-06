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

vec2 distortion(vec2 uv)
{
    float n = iTime * 0.5;
    float dx = 10.0;
    float dy = 15.0;
    float freq = 3.0 + sin(uv.x * 5.0 + n) * 2.0;
    float amp = 2.0 + cos(uv.y * 3.0 + n * 0.5) * 1.5;
    return uv + vec2(sin(uv.x * freq * dx) * amp, cos(uv.y * freq * dy));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Map coordinates to center and scale them
    uv = uv * 2.0 - 1.0;

    // Apply time-based rotation and translation
    float angle = iTime * 0.5 + sin(uv.x * 3.0 + iTime * 0.3) * cos(uv.y * 4.0 + iTime * 0.1);
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv = rotationMatrix * uv;

    // Apply complex distortion
    uv = distortion(uv);

    // Calculate color channels using modulated coordinates
    float r = sin(uv.x * 12.0 + iTime * 1.1);
    float g = cos(uv.y * 18.0 + iTime * 0.9);
    float b = sin(uv.x * 7.0 + uv.y * 5.0 + iTime * 1.3);

    // Introduce a depth/intensity factor based on fractal behavior
    float depth = pow(r * 0.5 + g * 0.5 + b * 0.5, 1.5);

    // Base color modulation
    vec3 col = vec3(r, g, b * 0.8);

    // Apply frame and time specific shifts
    col.r = pow(r, 2.5);
    col.g = cos(uv.y * 10.0 + iTime * 0.4) * 0.5 + 0.5;
    col.b = sin(uv.x * 8.0 + iTime * 0.6) * 0.5 + 0.5;

    // Final intensity based on depth and noise interaction
    float noise = sin(uv.x * 6.0 + uv.y * 5.0 + iTime * 1.0);
    float intensity = smoothstep(0.1, 1.0, depth * 2.0 + noise * 0.5);

    col *= intensity;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
