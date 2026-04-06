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

vec2 ripple(vec2 uv)
{
    float t = iTime * 2.0;
    float freq = 6.0 + sin(uv.x * 10.0 + t * 0.5) * 3.0;
    float amplitude = 1.0 + cos(uv.y * 8.0 + t * 0.3) * 0.5;
    float x = uv.x * freq * 1.2 + t * 0.8;
    float y = uv.y * freq * 0.9 + t * 0.5;
    float val = sin(x * 3.0) * amplitude + cos(y * 2.5);
    return uv * 1.5 + vec2(val * 0.2, val * 0.8);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.5;
    return vec2(
        sin(uv.x * 6.0 + t * 2.0),
        cos(uv.y * 8.0 + t * 1.2)
    );
}

float palette(float t) {
    t = fract(t * 1.1);
    return 0.5 + 0.5 * sin(t * 20.0 + 3.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    float timeOffset = iTime * 0.5;

    // Combine rotational movement
    float angleA = timeOffset * 0.7 + uv.x * 3.0;
    mat2 rotA = mat2(cos(angleA), -sin(angleA), sin(angleA), cos(angleA));
    vec2 rotatedUV = rotA * uv;

    float angleB = timeOffset * 0.5 + uv.y * 2.5;
    mat2 rotB = mat2(cos(angleB), -sin(angleB), sin(angleB), cos(angleB));
    rotatedUV = rotB * rotatedUV;

    // Apply ripple distortion based on rotated coordinates
    vec2 distortedUV = ripple(rotatedUV * 1.5);

    // Wave generation based on distorted coordinates
    vec2 w = wave(distortedUV);

    // Smooth transition based on wave interaction
    float flow = w.x + w.y * 0.8;
    float intensity = smoothstep(0.3, 0.7, flow);

    // Color calculation based on complex trigonometric sums (Shader B influence)
    float c1 = sin(timeOffset * 3.0 + rotatedUV.x * 5.0 + w.x * 1.5);
    float c2 = cos(timeOffset * 4.0 + rotatedUV.y * 4.0 + w.y * 1.0);
    float c3 = sin(timeOffset * 5.0 + rotatedUV.x * 2.0 + rotatedUV.y * 3.0);

    vec3 color = vec3(c1, c2, c3);

    // Apply dynamic palette modulation (Shader B influence)
    float p = palette(iTime * 0.5 + rotatedUV.x * 1.0);

    color = mix(color, vec3(p * 0.4 + 0.1), intensity);

    // Introduce non-linear depth and noise effects (Shader A influence)
    float depth = pow(sin(rotatedUV.x * 15.0 + rotatedUV.y * 10.0 + iTime * 0.5), 5.0);
    float noise_val = sin(rotatedUV.x * 10.0 + rotatedUV.y * 10.0 + iTime * 1.5);

    // Apply radial distortion based on depth
    float bloom = smoothstep(0.4, 1.0, depth * 1.8);

    // Apply a strong glow based on noise
    float glow = pow(noise_val, 3.0) * 1.5;

    // Final color mixing
    color *= bloom;
    color += vec3(0.0, 0.5, 1.0) * glow;

    fragColor = vec4(color,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
