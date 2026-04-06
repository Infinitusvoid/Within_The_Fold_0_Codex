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
    return vec2(sin(uv.x * 15.0 + iTime * 1.5), cos(uv.y * 10.0 - iTime * 0.8));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.8 + iTime * 0.5);
    float g = 0.3 + 0.7 * cos(t * 1.3 - iTime * 0.4);
    float b = 0.1 + 0.6 * sin(t * 1.0 + iTime * 0.6);
    return vec3(r, g, b);
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 4.0 + iTime * 1.0) * 0.05,
        cos(uv.y * 7.0 - iTime * 0.5) * 0.15
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Apply primary wavy distortion
    uv = waveB(uv);

    // Apply dynamic rotation based on position and time
    float angle = uv.x * 5.0 + iTime * 0.8;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    uv *= rotationMatrix;

    // Apply secondary wave distortion
    uv = waveA(uv);

    // Generate flow factor based on combined spatial frequencies
    float t = (uv.x * 6.0 + uv.y * 8.0) * 1.5 + iTime * 0.5;
    vec3 col = palette(t);

    // Create strong contrast modulation based on time and flow
    float flow_mod = sin(uv.x * 8.0 + iTime * 1.2) * cos(uv.y * 5.0 - iTime * 0.6);
    col = mix(col, vec3(1.0, 0.1, 0.1), flow_mod * 0.5);

    // Introduce complex noise interaction using different spatial frequencies
    float noise_factor = sin(uv.x * 12.0 + iTime * 0.3) * cos(uv.y * 11.0 - iTime * 0.4);

    // Blend the color with a vibrant blue tone based on noise intensity
    col = mix(col, vec3(0.0, 0.5, 1.0), noise_factor * 0.7);

    // Final intensity boost and contrast adjustment
    col = pow(col, vec3(1.1));

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
