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
    return uv + vec2(sin(uv.x * 5.0 + iTime * 0.3), cos(uv.y * 4.0 + iTime * 0.2));
}

vec2 planeWaveX(vec2 uv)
{
    return vec2(sin(uv.x * 8.0), cos(uv.y * 12.0));
}

vec3 paletteFactor(float t)
{
    vec3 c = vec3(0.2);
    c.r = 0.6 + sin(t * 1.8 + iTime * 0.5) * 0.4;
    c.g = 0.2 + cos(t * 2.5 - iTime * 0.4) * 0.3;
    c.b = smoothstep(0.5, 0.01, abs(sin(t * 5.0 - iTime * 0.2))) * 0.8;
    return c;
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Initial scaling and centering
    uv = uv * 3.0 - 1.0;

    float scale = 1.0 + sin(iTime * 1.5) * 0.5;
    uv *= scale;

    // Rotational Deformation
    float angle1 = sin(iTime * 2.0) + uv.x * uv.y * 6.0;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv *= rotationMatrix;

    // Secondary Rotation
    float angle2 = iTime * 0.8 + uv.x * 1.2 + uv.y * 0.8;
    uv = rotate(uv, angle2);

    // Wave Distortion
    uv = wave(uv);

    // Flow and Secondary Distortion
    uv *= 1.8;

    // Base distortion mixing
    uv += vec2(
        sin(uv.x * 3.0 + iTime * 0.7),
        cos(uv.y * 5.0 + iTime * 0.4) * 0.5
    );

    // Color base definition
    float t = (uv.x * 15.0 + uv.y * 10.0) * 0.8 + iTime * 0.5;
    vec3 col = paletteFactor(t * 4.0);

    // Primary color modulation
    col += 0.8 * sin(uv.x * 12.0 + iTime * 1.2) * col.r;

    // Complex layer 1: High frequency oscillation
    float layer1 = sin(uv.x * 22.0 + iTime * 1.5) * uv.y * 0.8;

    // Complex layer 2: Inverse cosine influence
    float layer2 = cos(uv.y * 12.0 - iTime * 1.0) * uv.x * 0.6;

    // R Channel complexity
    col.r = 0.5 + 0.4 * layer1 + 0.3 * layer2;

    // G Channel complexity
    col.g = sin(uv.x * 18.0 + iTime * 1.6) + cos(uv.y * 8.0 + iTime * 1.1);

    // Modify R based on G, adding a chromatic layer
    col.r = mix(col.r, col.g * 0.6 + 0.1, 0.5 + sin(iTime * 0.45));

    // Introduce a sharper contrast layer
    float contrast = smoothstep(0.4, 0.5, abs(uv.x * 3.0 - uv.y * 2.0) * 2.5);

    // B Channel definition
    col.b = 0.2 + contrast * 0.7;

    // Final texture application
    float texture_val = sin(uv.x * 250.0 + iTime * 10.0);
    col.b = 0.5 + 0.3 * abs(sin(abs(sin((col.g * col.r) * 100.0)) / sin(col.g * 3.0 + col.r * 2.0)) * texture_val);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
