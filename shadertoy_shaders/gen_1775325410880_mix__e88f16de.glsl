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

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv)
{
    vec2 v = uv;
    float time_scale = iTime * 0.5;
    float scale = 10.0;
    float freq = 5.0;

    float x = v.x * scale + time_scale * freq;
    float y = v.y * scale + time_scale * freq * 0.7;

    float s = sin(x) * cos(y * 2.0);
    float c = cos(x * 1.5 + y * 1.0);

    return vec2(s, c);
}

vec3 palette(float t)
{
    vec3 color = vec3(0.5);
    float a = 0.5 + 0.5 * sin(t * 1.5 + iTime * 0.5);
    float b = 0.5 + 0.5 * cos(t * 2.0 - iTime * 0.3);
    float c = 0.5 + 0.5 * sin(t * 3.0 + iTime * 0.1);

    color = mix(vec3(0.1, 0.8, 0.1), vec3(1.0, 0.1, 0.1), a);
    color = mix(color, vec3(0.1, 0.1, 0.8), b);
    color = mix(color, vec3(0.8, 0.8, 0.1), c);

    return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Apply initial coordinate adjustments and distortion
    uv = uv * 2.0 - 1.0;

    // Base distortion based on time
    uv *= 1.0 + sin(iTime * 0.5) * 0.15;

    // Complex rotation based on coordinate interaction (A/B blend)
    float angle1 = sin(iTime * 0.3) + uv.x * uv.y * 2.5;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv = rotationMatrix * uv;

    // Second rotation using a time-driven angle
    float angle2 = iTime * 0.6 + uv.x * 1.5 + uv.y * 0.5;
    uv = rotate(uv, angle2);

    // Apply complex waves (A blend)
    uv = waveC(uv);
    uv = waveD(uv);

    // Introduce a stronger, independent wave distortion (B)
    uv = wave(uv * 1.2);

    // Introduce spatial scaling
    uv *= 1.8;

    // New, more complex coordinate interaction for initial mixing (B)
    float mix_factor = sin(uv.x * 1.5 + iTime * 0.8) * 0.5 + uv.y * 0.5;

    // Flow variable calculation
    float t = (uv.x + uv.y) * 10.0 + iTime * 0.5;
    vec3 col = palette(t);

    // Modify mixing based on the new spatial factor
    col += mix_factor * 0.8;

    // Introduce temporal noise modulation (B)
    col += 0.7 * sin(iTime * 0.4 + uv.xyx * 4.5 + vec3(0.2, 0.5, 0.8));

    // Second complex modulation term (B)
    col += 0.5 * sin(uv.y * 11.0 + (iTime + 0.1 * sin(uv.x * 42.42 + iTime)*sin(uv.x * 100.0 + iTime)));

    // Introduce subtle background shifting based on time (B)
    float freq = uv.x * 2.5 + sin(iTime * 0.5);
    float offset = sin(freq * 12.0) * 0.03;

    // Use a different smoothstep range based on the wave result (B)
    float v = smoothstep(0.40, 0.50, uv.y - offset * 0.5);

    col.r = v;

    // Increase complexity in G channel based on a unique interaction (B)
    col.g = sin(uv.x * 12.0 + (iTime + 0.15 * sin(uv.y * 42.42 + iTime)*sin(uv.y * 100.0 + iTime))) * 1.6;

    // Final R calculation modification (B)
    col.r = sin(col.g * 1.1 + iTime * 0.6 + 0.4 * sin(iTime * 0.2 + uv.x * 12.0));

    // Introduce a high frequency texture interaction into the B channel calculation (B)
    float texture_val = sin(uv.x * 150.0 + iTime * 8.0);
    col.b = 0.5 + 0.35 * abs(sin(abs(sin((col.g * col.r) * 40.0)) / sin((sin(col.g) / sin(col.r)) * sin(uv.x * iTime * cos(uv.y * iTime * 1.24)) * 12.0)) * texture_val);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
