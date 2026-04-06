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
    return vec2(sin(uv.x * 10.0 + iTime * 0.5), cos(uv.y * 10.0 + iTime * 0.3));
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 3.0 + iTime * 0.8) * 0.1,
        cos(uv.y * 5.0 + iTime * 0.4) * 0.2
    );
}

vec3 palette(float t)
{
    return vec3(0.1 + 0.4*sin(t + iTime * 0.2), 0.4 + 0.4*cos(t + iTime * 0.1), 0.7 + 0.3*sin(t + iTime * 0.3));
}

vec2 wave(vec2 uv)
{
    // Merged complex wave formula derived from A influences applied via structure.
    return uv + vec2(
        sin(uv.x * 3.0 + iTime * 0.4) * tan(uv.y * 1.5 + iTime * 0.6),
        cos(uv.y * 2.5 + iTime * 0.7) * sin(uv.x * 1.2 + iTime * 0.5)
    );
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Map uv to [0, 1] then shift (Stage B refinement based on context mapping style, applied generally)
    uv = uv * vec2(2.0, 1.0) - vec2(0.5, 0.0);

    // Base Warp/Wave setup (Applying primary WaveB style shaping)
    uv = waveB(uv);

    // Apply rotational orientation based on spatio-temporal patterns
    float angle = iTime * 1.5 + uv.x * 2.0 + uv.y * 1.5;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv *= rotationMatrix;

    // Secondary Distortion incorporating WaveA type patterning
    uv = waveA(uv);

    // Integrate Wave calculation
    uv = wave(uv);


    // Color field extraction
    float s = sin(uv.x * 12.0 + iTime * 0.7);
    float t = cos(uv.y * 18.0 + iTime * 0.3);
    vec3 col = vec3(s, t, 0.5 + 0.5 * sin(uv.x + uv.y + iTime * 0.5));

    float freq = uv.y * 2.0 + sin(iTime * 0.6);
    float offset = sin(freq * 15.0) * 0.05;
    float v = smoothstep(0.3, 0.7, uv.x - offset);

    // Introduce complex channel modulation effects mimicking B's specific color logic
    col.r = v;

    col.g = sin(uv.x * 12.0 + (iTime + 0.2 * sin(uv.y * 42.42 + iTime)*sin(uv.y * 100.0 + iTime)));
    col.r = sin(col.g + iTime + 0.42 * sin(iTime * 0.2 + uv.x * 10.0));

    col.b = 0.3 + 0.2 * abs(sin(abs(sin((col.g * col.r) * 20.0)) / sin((sin(col.g) / sin(col.r)) * sin(uv.x * iTime * cos(uv.y * iTime * 1.24)) * 10.0)));

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
