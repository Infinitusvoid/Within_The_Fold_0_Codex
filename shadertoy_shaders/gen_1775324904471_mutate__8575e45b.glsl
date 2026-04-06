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

vec2 waveC(vec2 uv)
{
    return vec2(sin(uv.x * 5.0 + iTime * 1.5) * cos(uv.y * 3.0 + iTime * 0.8), cos(uv.x * 1.8 + iTime * 0.3) * sin(uv.y * 4.5 + iTime * 1.0));
}

vec2 waveD(vec2 uv)
{
    return vec2(sin(uv.x * 1.0 + iTime * 0.5) * sin(uv.y * 2.0 + iTime * 0.7), cos(uv.x * 2.5 + iTime * 0.9) * tan(uv.y * 1.5 + iTime * 0.5));
}

vec3 palette(float t)
{
    return vec3(0.1 + 0.9 * sin(t * 0.5 + iTime * 0.15), 0.5 + 0.5 * cos(t * 0.7 + iTime * 0.2), 0.2 + 0.8 * sin(t * 0.3 + iTime * 0.4));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Apply offset and scale
    uv = uv * vec2(4.0, 3.0) - vec2(0.5, 0.5);

    // Calculate rotation angle based on time and position
    float angle = iTime * 0.8 + sin(uv.x * 4.0 + iTime * 0.3) * cos(uv.y * 1.5 + iTime * 0.5);
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv = rotationMatrix * uv;

    // Apply complex waves
    uv = waveC(uv);
    uv = waveD(uv);

    // Determine color based on combined state
    float t = uv.x * 1.5 + uv.y * 0.5 + iTime * 1.2;
    vec3 col = palette(t);

    // Add final modulation layer
    float modulation1 = sin(uv.x * 15.0 + iTime * 1.0);
    float modulation2 = cos(uv.y * 10.0 + iTime * 0.6);

    col = vec3(modulation1, modulation2, 0.5 + 0.5 * sin(uv.x + uv.y * 2.0 + iTime * 0.7));

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
