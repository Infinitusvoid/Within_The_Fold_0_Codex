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
    return uv * 1.5 + vec2(sin(uv.x * 4.0 + iTime * 0.4) * tan(uv.y * 1.0 + iTime * 0.6), 
                          cos(uv.y * 3.0 + iTime * 0.7) * sin(uv.x * 2.0 + iTime * 0.5));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Map coordinates space
    uv = uv * 3.0 - 1.5;

    // Apply spatial distortion flow field
    float flowX = cos(uv.y * 5.0 + iTime * 0.8) * 0.5;
    float flowY = sin(uv.x * 5.0 + iTime * 1.0) * 0.5;
    uv.x += flowX;
    uv.y += flowY;

    // Apply wave distortion based on flow
    uv = wave(uv);

    // Core modulation calculation at shifted coordinates
    float f1 = sin(uv.x * 6.0 + iTime * 1.4);
    float f2 = cos(uv.y * 9.0 + iTime * 0.9);
    float amplitude = pow(sin(uv.x * 8.0 - uv.y * 4.5 + iTime * 1.1), 2.5);

    // Calculate color components based on modulated coordinates
    float g = f1 * 0.5 + f2 * 0.5;
    float r = 1.0 - 0.5 * amplitude;
    float b = abs(f1 * amplitude);

    vec3 col = vec3(r, g + 0.5, b);

    // Effect adjustment based on frame count iteration and texture scaling
    float temporal_scale = 2.0 + sin(iFrame * 0.2) * 0.5;

    col.r *= temporal_scale;
    col.g *= 1.5 - f2;
    col.b *= 1.0 + iFrame * 0.02;

    // Fine detail scattering
    float distortion = sin(uv.x + uv.y * 3.5 + iTime * 1.2);
    float contrast_boost = smoothstep(0.5, 1.0, distortion);

    col.r = mix(col.r, contrast_boost, 0.6);
    col.g = mix(col.g * 0.8, 1.0, 0.2);
    col.b = mix(col.b, 0.9, 0.5);


    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
