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

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 15.0 + iTime * 1.0), cos(uv.y * 18.0 - iTime * 0.8));
}

vec2 flow(vec2 uv, float t)
{
    float angle = uv.x * 15.0 + uv.y * 15.0 + t * 1.5;
    float radius = length(uv - 0.5);
    float flow_val = sin(angle * 3.0 + radius * 5.0) * 0.5 + 0.5;
    return uv + flow_val * 0.05;
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 5.0 + iTime * 0.7) * 0.1,
        cos(uv.y * 4.0 - iTime * 0.5) * 0.15
    );
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.6 + iTime * 1.5);
    float g = 0.3 + 0.6 * sin(t * 1.3 + iTime * 0.9);
    float b = 0.1 + 0.7 * cos(t * 2.0 + iTime * 0.5);
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Apply flow distortion
    uv = flow(uv, iTime);

    // Apply wave distortion
    uv = waveB(uv);

    // Rotation and Secondary Distortion
    float angle = iTime * 2.0 + uv.x * 4.0 + uv.y * 4.0;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv *= rotationMatrix;

    uv = waveA(uv);

    // Palette calculation based on shifted position and time
    float t = (uv.x * 5.0 + uv.y * 3.0) * 8.0 + iTime * 0.6;
    vec3 col = palette(t);

    // Complex color mixing emphasizing flow
    col += 0.6 * sin(iTime * 0.4 + uv.x * 6.0 + uv.y * 8.0);
    col += 0.4 * sin(uv.x * 10.0 + iTime * 0.2);
    col += 0.2 * cos(uv.y * 7.0 + iTime * 0.1);

    // Introduce complex fractal noise based on coordinate interaction
    float noise_factor = sin(uv.x * 8.0 + uv.y * 5.0 + iTime * 3.0) * cos(uv.y * 11.0 - iTime * 0.7);

    // Modulate color based on dynamic spatial shifts and noise
    col = mix(col, vec3(0.0, 0.6, 1.0), noise_factor * 0.5);

    // Apply a stronger hue shift based on time
    col = col * (1.0 + 0.3 * sin(iTime * 4.0));

    // Final intensity boost using a different exponent
    col = pow(col, vec3(1.1));

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
