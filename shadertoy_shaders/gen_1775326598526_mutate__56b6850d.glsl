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

vec2 flow(vec2 uv) {
    float t = iTime * 0.5;
    return uv + vec2(sin(uv.x * 5.0 + t), cos(uv.y * 4.0 + t * 2.0)) * 0.5;
}

float palette(float t) {
    t = fract(t * 3.14159);
    return 0.5 + 0.5 * sin(t * 18.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // Apply dynamic distortion based on time and coordinates
    vec2 distorted_uv = flow(uv);

    // Introduce complex rotation effects
    float angleA = iTime * 0.3 + distorted_uv.x * 3.0;
    mat2 rotA = mat2(cos(angleA), -sin(angleA), sin(angleA), cos(angleA));
    vec2 rotated_uv = rotA * distorted_uv;

    float angleB = iTime * 0.5 + distorted_uv.y * 2.0;
    mat2 rotB = mat2(cos(angleB), -sin(angleB), sin(angleB), cos(angleB));
    vec2 final_uv = rotB * rotated_uv;

    // Create secondary wave modulation
    float wave_val = sin(final_uv.x * 8.0 + iTime * 1.2) * cos(final_uv.y * 5.0 + iTime * 0.8);

    // Use wave to define contrast or hue shift
    float intensity = smoothstep(0.3, 0.7, wave_val * 0.5 + 0.5);

    // Base color calculation using time and complex coordinates
    vec3 color = vec3(
        sin(iTime * 5.0 + final_uv.x * 3.0 + wave_val * 2.0),
        cos(iTime * 6.0 + final_uv.y * 4.0 + wave_val * 1.5),
        sin(iTime * 7.0 + final_uv.x * 2.5 + final_uv.y * 2.0)
    );

    // Apply palette modulation
    float p = palette(iTime + final_uv.x * 4.0);
    color = mix(color, vec3(p * 0.8, p * 0.3, 0.1), 0.7);

    fragColor = vec4(color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
