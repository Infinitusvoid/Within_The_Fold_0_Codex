#pragma once

#include <algorithm>
#include <array>
#include <filesystem>
#include <sstream>
#include <string>
#include <vector>

#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifdef APIENTRY
#pragma push_macro("APIENTRY")
#undef APIENTRY
#define EDITABLE_SHADERS_RESTORE_APIENTRY
#endif
#include <Windows.h>
#ifdef EDITABLE_SHADERS_RESTORE_APIENTRY
#pragma pop_macro("APIENTRY")
#undef EDITABLE_SHADERS_RESTORE_APIENTRY
#endif
#endif

#include "CppCommponents\File.h"
#include "CppCommponents\Folder.h"

namespace EditableShaders_
{
    inline const std::filesystem::path& executable_directory_path()
    {
        static const std::filesystem::path directory = []
        {
#ifdef _WIN32
            std::vector<char> buffer(MAX_PATH, '\0');

            while (true)
            {
                const DWORD size = GetModuleFileNameA(nullptr, buffer.data(), static_cast<DWORD>(buffer.size()));
                if (size == 0)
                {
                    return std::filesystem::current_path();
                }

                if (size < buffer.size() - 1)
                {
                    return std::filesystem::path(std::string(buffer.data(), size)).parent_path();
                }

                buffer.resize(buffer.size() * 2, '\0');
            }
#else
            return std::filesystem::current_path();
#endif
        }();

        return directory;
    }

    inline std::vector<std::filesystem::path> raymarching_shader_folder_candidates()
    {
        std::vector<std::filesystem::path> candidates;
        candidates.push_back(executable_directory_path() / "raymarching_3d_shaders");

        const std::filesystem::path repo_style_candidate =
            executable_directory_path().parent_path().parent_path() / "raymarching_3d_shaders";

        if (repo_style_candidate != candidates.front())
        {
            candidates.push_back(repo_style_candidate);
        }

        return candidates;
    }

    inline std::vector<std::filesystem::path> shadertoy_shader_folder_candidates()
    {
        std::vector<std::filesystem::path> candidates;
        candidates.push_back(executable_directory_path() / "shadertoy_shaders");

        const std::filesystem::path repo_style_candidate =
            executable_directory_path().parent_path().parent_path() / "shadertoy_shaders";

        if (repo_style_candidate != candidates.front())
        {
            candidates.push_back(repo_style_candidate);
        }

        return candidates;
    }

    inline const std::filesystem::path& raymarching_shader_folder_path()
    {
        static const std::filesystem::path folder = []
        {
            for (const std::filesystem::path& candidate : raymarching_shader_folder_candidates())
            {
                std::error_code error;
                if (std::filesystem::exists(candidate, error) && std::filesystem::is_directory(candidate, error))
                {
                    return candidate;
                }
            }

            return raymarching_shader_folder_candidates().front();
        }();

        return folder;
    }

    inline const std::filesystem::path& shadertoy_shader_folder_path()
    {
        static const std::filesystem::path folder = []
        {
            for (const std::filesystem::path& candidate : shadertoy_shader_folder_candidates())
            {
                std::error_code error;
                if (std::filesystem::exists(candidate, error) && std::filesystem::is_directory(candidate, error))
                {
                    return candidate;
                }
            }

            return shadertoy_shader_folder_candidates().front();
        }();

        return folder;
    }

    inline const std::string& raymarching_shader_folder()
    {
        static const std::string folder = raymarching_shader_folder_path().string();
        return folder;
    }

    inline const std::string& shadertoy_shader_folder()
    {
        static const std::string folder = shadertoy_shader_folder_path().string();
        return folder;
    }

    inline const std::string& default_vertex_shader_path()
    {
        static const std::string filepath = raymarching_shader_folder() + "/default_vertex.glsl";
        return filepath;
    }

    inline std::string trim_copy(const std::string& value)
    {
        const std::string whitespace = " \t\r\n";
        const size_t begin = value.find_first_not_of(whitespace);
        if (begin == std::string::npos)
        {
            return "";
        }

        const size_t end = value.find_last_not_of(whitespace);
        return value.substr(begin, end - begin + 1);
    }

    inline bool starts_with(const std::string& value, const std::string& prefix)
    {
        return value.rfind(prefix, 0) == 0;
    }

    inline int count_char(const std::string& value, char target)
    {
        return static_cast<int>(std::count(value.begin(), value.end(), target));
    }

    inline std::string default_vertex_shader_source()
    {
        return R"GLSL(#version 330 core
layout(location = 0) in vec3 aPos;
layout(location = 1) in vec2 aTexCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

out vec2 TexCoord;
out vec3 WorldPos;
out vec3 LocalPos;

void main()
{
    vec4 worldPosition = model * vec4(aPos, 1.0);
    WorldPos = worldPosition.xyz;
    LocalPos = aPos;
    TexCoord = aTexCoord;
    gl_Position = projection * view * worldPosition;
}
)GLSL";
    }

    inline std::string raymarching_shader_player_pulse()
    {
        return R"GLSL(#version 330 core
in vec2 TexCoord;
in vec3 WorldPos;
in vec3 LocalPos;

out vec4 FragColor;

uniform sampler2D texture1;
uniform sampler2D texture2;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

uniform vec3 uColor;
uniform float time;
uniform float iTime;
uniform float iTimeDelta;
uniform int iFrame;
uniform vec4 iMouse;

uniform vec3 uCamPos;
uniform vec3 iPlayerPos;
uniform vec3 uPlayerPos;
uniform vec3 uCubePos;

uniform vec2 uResolution;
uniform vec3 iResolution;
uniform vec3 iChannelResolution[4];
uniform float iChannelTime[4];

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

float sdSphere(vec3 p, float r)
{
    return length(p) - r;
}

float sdRoundBox(vec3 p, vec3 b, float r)
{
    vec3 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

mat2 rot2(float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

vec3 triPlanar(sampler2D texA, sampler2D texB, vec3 p, vec3 n)
{
    vec3 blend = pow(abs(n), vec3(4.0));
    blend /= max(dot(blend, vec3(1.0)), 0.0001);

    vec3 xColor = mix(texture(texA, p.yz * 1.8).rgb, texture(texB, p.yz * 0.9).rgb, 0.45);
    vec3 yColor = mix(texture(texA, p.xz * 1.8).rgb, texture(texB, p.xz * 1.2).rgb, 0.55);
    vec3 zColor = mix(texture(texA, p.xy * 1.8).rgb, texture(texB, p.xy * 0.8).rgb, 0.35);
    return xColor * blend.x + yColor * blend.y + zColor * blend.z;
}

float mapScene(vec3 p)
{
    vec3 cubeCenter = model[3].xyz + vec3(0.5);
    vec3 q = p - cubeCenter;

    vec3 playerDir = normalize((uPlayerPos - cubeCenter) + vec3(0.001));
    float pulse = 0.18 + 0.06 * sin(iTime * 2.0 + dot(uCubePos, vec3(3.1, 2.7, 1.9)));

    vec3 orbOffset = playerDir * (0.10 + 0.05 * sin(iTime * 1.1 + q.y * 6.0));
    float orb = sdSphere(q - orbOffset, pulse);

    q.xz *= rot2(iTime * 0.6 + uCubePos.x * 0.4);
    q.xy *= rot2(iTime * 0.25 + uCubePos.z * 0.2);
    float shell = sdRoundBox(q, vec3(0.37), 0.08);

    return min(orb, shell);
}

vec3 calcNormal(vec3 p)
{
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        mapScene(p + e.xyy) - mapScene(p - e.xyy),
        mapScene(p + e.yxy) - mapScene(p - e.yxy),
        mapScene(p + e.yyx) - mapScene(p - e.yyx)
    ));
}

void main()
{
    vec3 ro = uCamPos;
    vec3 rd = normalize(WorldPos - ro);

    float t = 0.0;
    float d = 0.0;
    bool hit = false;

    for (int i = 0; i < 96; ++i)
    {
        vec3 p = ro + rd * t;
        d = mapScene(p);

        if (d < 0.001)
        {
            hit = true;
            break;
        }

        t += d * 0.85;
        if (t > 12.0)
        {
            break;
        }
    }

    vec3 color = vec3(0.02, 0.03, 0.05);

    if (hit)
    {
        vec3 p = ro + rd * t;
        vec3 n = calcNormal(p);

        vec3 lightDir = normalize((iPlayerPos - p) + vec3(0.4, 0.8, -0.3));
        float diffuse = max(dot(n, lightDir), 0.0);
        float rim = pow(1.0 - max(dot(n, -rd), 0.0), 3.0);

        vec3 surface = triPlanar(iChannel0, iChannel1, p - (uCubePos + 0.5), n);
        vec3 accent = 0.4 + 0.6 * abs(sin(vec3(0.3, 0.8, 1.2) * iTime + uCubePos));

        color = surface * (0.22 + 0.85 * diffuse);
        color *= mix(vec3(1.0), accent * max(uColor, vec3(0.15)), 0.55);
        color += rim * accent;
    }
    else
    {
        vec2 uv = gl_FragCoord.xy / max(iResolution.xy, vec2(1.0));
        float scan = 0.5 + 0.5 * sin(uv.y * 120.0 + float(iFrame) * 0.05);
        float focal = clamp(projection[1][1] * 0.15, 0.0, 1.0);
        color = mix(color, vec3(0.08, 0.15, 0.22) * (0.5 + 0.5 * scan), focal);
    }

    FragColor = vec4(sqrt(max(color, vec3(0.0))), 1.0);
}
)GLSL";
    }

    inline std::string raymarching_shader_maze_echo()
    {
        return R"GLSL(#version 330 core
in vec2 TexCoord;
in vec3 WorldPos;
in vec3 LocalPos;

out vec4 FragColor;

uniform sampler2D texture1;
uniform sampler2D texture2;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;

uniform vec3 uColor;
uniform float time;
uniform float iTime;
uniform vec3 uCamPos;
uniform vec3 uCubePos;
uniform vec3 iPlayerPos;
uniform vec3 iResolution;
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

mat2 rot2(float a)
{
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float sdBox(vec3 p, vec3 b)
{
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdTorus(vec3 p, vec2 t)
{
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float mapScene(vec3 p)
{
    vec3 cubeCenter = model[3].xyz + vec3(0.5);
    vec3 q = p - cubeCenter;

    vec3 cameraForward = normalize(vec3(-view[0][2], -view[1][2], -view[2][2]));
    q.xz *= rot2(iTime * 0.35 + dot(cameraForward.xz, vec2(1.0, -1.0)));
    q.yz *= rot2(iTime * 0.55 + uCubePos.y * 0.7);

    float torus = sdTorus(q, vec2(0.22 + 0.04 * sin(iTime + uCubePos.x), 0.06));
    float prism = sdBox(q, vec3(0.18, 0.34, 0.18));
    float cage = sdBox(q, vec3(0.40)) - 0.02;

    return min(min(torus, prism), max(cage, -sdBox(q, vec3(0.32))));
}

vec3 calcNormal(vec3 p)
{
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        mapScene(p + e.xyy) - mapScene(p - e.xyy),
        mapScene(p + e.yxy) - mapScene(p - e.yxy),
        mapScene(p + e.yyx) - mapScene(p - e.yyx)
    ));
}

void main()
{
    vec3 ro = uCamPos;
    vec3 rd = normalize(WorldPos - ro);

    float t = 0.0;
    bool hit = false;
    for (int i = 0; i < 90; ++i)
    {
        vec3 p = ro + rd * t;
        float d = mapScene(p);
        if (d < 0.001)
        {
            hit = true;
            break;
        }

        t += d * 0.9;
        if (t > 10.0)
        {
            break;
        }
    }

    vec3 color = vec3(0.01, 0.015, 0.03);

    if (hit)
    {
        vec3 p = ro + rd * t;
        vec3 n = calcNormal(p);
        vec3 lightDir = normalize(iPlayerPos - p + vec3(0.0, 1.2, 0.2));
        float diffuse = max(dot(n, lightDir), 0.0);
        float fresnel = pow(1.0 - max(dot(-rd, n), 0.0), 4.0);

        vec3 uvw = p - (uCubePos + 0.5);
        vec3 waveA = texture(iChannel0, uvw.xz * 1.5 + iTime * 0.05).rgb;
        vec3 waveB = texture(iChannel1, uvw.yx * 1.1 - iTime * 0.03).rgb;

        vec3 tint = mix(waveA, waveB, 0.5 + 0.5 * sin(iTime + uvw.y * 8.0));
        tint *= mix(vec3(0.2, 0.5, 1.0), max(uColor, vec3(0.18)), 0.4);

        float pulse = 0.45 + 0.55 * sin(iTime * 1.7 + length(uvw) * 18.0);
        color = tint * (0.25 + diffuse * 0.9);
        color += fresnel * mix(vec3(0.4, 0.7, 1.0), tint, pulse);
    }
    else
    {
        vec2 uv = gl_FragCoord.xy / max(iResolution.xy, vec2(1.0));
        float beam = abs(sin((uv.x + uv.y) * 12.0 + iTime * 0.8));
        color += vec3(0.03, 0.08, 0.14) * beam * clamp(projection[1][1] * 0.2, 0.0, 1.0);
    }

    FragColor = vec4(sqrt(max(color, vec3(0.0))), 1.0);
}
)GLSL";
    }

    inline std::string raymarching_shader_signal_lattice()
    {
        return R"GLSL(#version 330 core
in vec2 TexCoord;
in vec3 WorldPos;
in vec3 LocalPos;

out vec4 FragColor;

uniform sampler2D texture1;
uniform sampler2D texture2;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

uniform float time;
uniform float iTime;
uniform float iTimeDelta;
uniform int iFrame;
uniform vec3 iResolution;
uniform vec3 iPlayerPos;
uniform vec3 uCamPos;
uniform vec3 uCubePos;
uniform vec3 uColor;
uniform mat4 model;

float sdSphere(vec3 p, float r)
{
    return length(p) - r;
}

float sdBox(vec3 p, vec3 b)
{
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float mapScene(vec3 p)
{
    vec3 cubeCenter = model[3].xyz + vec3(0.5);
    vec3 q = p - cubeCenter;

    vec3 tiled = fract(q * 3.0 + 1.5) - 0.5;
    float node = sdSphere(tiled, 0.12 + 0.02 * sin(iTime * 2.0 + dot(uCubePos, vec3(7.0, 5.0, 3.0))));
    float spine = sdBox(q, vec3(0.42, 0.04, 0.04));
    spine = min(spine, sdBox(q.zxy, vec3(0.42, 0.04, 0.04)));
    spine = min(spine, sdBox(q.yzx, vec3(0.42, 0.04, 0.04)));

    return min(node, spine);
}

vec3 calcNormal(vec3 p)
{
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        mapScene(p + e.xyy) - mapScene(p - e.xyy),
        mapScene(p + e.yxy) - mapScene(p - e.yxy),
        mapScene(p + e.yyx) - mapScene(p - e.yyx)
    ));
}

void main()
{
    vec3 ro = uCamPos;
    vec3 rd = normalize(WorldPos - ro);

    float t = 0.0;
    bool hit = false;
    for (int i = 0; i < 88; ++i)
    {
        vec3 p = ro + rd * t;
        float d = mapScene(p);
        if (d < 0.001)
        {
            hit = true;
            break;
        }

        t += d * 0.92;
        if (t > 10.0)
        {
            break;
        }
    }

    vec3 color = vec3(0.005, 0.01, 0.02);

    if (hit)
    {
        vec3 p = ro + rd * t;
        vec3 n = calcNormal(p);
        vec3 lattice = p - (uCubePos + 0.5);

        vec3 tex0 = texture(iChannel0, lattice.xy * 1.6 + iTime * 0.04).rgb;
        vec3 tex1 = texture(iChannel1, lattice.zy * 1.4 - iTime * 0.03).rgb;
        vec3 tex2 = texture(iChannel2, lattice.xz * 1.2 + iTimeDelta * 6.0).rgb;
        vec3 tex3 = texture(iChannel3, TexCoord + float(iFrame) * 0.0008).rgb;

        float diffuse = max(dot(n, normalize(iPlayerPos - p)), 0.0);
        float grid = 0.5 + 0.5 * sin((lattice.x + lattice.y + lattice.z) * 18.0 + iTime * 3.0);
        vec3 tint = mix(tex0 + tex1, tex2 + tex3, grid) * 0.5;
        tint *= mix(vec3(0.2, 0.7, 0.9), max(uColor, vec3(0.18)), 0.5);

        color = tint * (0.15 + diffuse);
        color += pow(grid, 8.0) * vec3(0.4, 0.8, 1.0);
    }
    else
    {
        vec2 uv = gl_FragCoord.xy / max(iResolution.xy, vec2(1.0));
        float horizon = smoothstep(0.0, 1.0, 1.0 - uv.y);
        color += vec3(0.02, 0.04, 0.08) * horizon;
    }

    FragColor = vec4(sqrt(max(color, vec3(0.0))), 1.0);
}
)GLSL";
    }

    inline std::string shader_reference_text()
    {
        return R"TXT(# Editable Shader Contract

Files in this folder are loaded directly at runtime and hot reloaded when they change.
In a portable build, this folder lives next to the executable.

- `default_vertex.glsl` is the shared vertex shader used by every editable fragment shader.
- `*.glsl` files here are treated as full OpenGL fragment shaders.
- `shadertoy_shaders/*.toy` files from the sibling folder are wrapped automatically so `mainImage(out vec4, in vec2)` works in-game.

Common fragment inputs:

- `in vec2 TexCoord`
- `in vec3 WorldPos`
- `in vec3 LocalPos`

Common uniforms:

- `sampler2D texture1`, `texture2`
- `sampler2D iChannel0`, `iChannel1`, `iChannel2`, `iChannel3`
- `vec3 uColor`
- `float time`, `iTime`, `iTimeDelta`
- `int iFrame`
- `vec3 uCamPos`, `uPlayerPos`, `iPlayerPos`
- `vec3 uCubePos`
- `vec2 uResolution`
- `vec3 iResolution`
- `vec3 iChannelResolution[4]`
- `float iChannelTime[4]`
- `mat4 model`, `view`, `projection`

Shadertoy notes:

- `.toy` files should contain the shader body plus `mainImage`.
- `gl_FragCoord.xy` is passed through as `fragCoord`.
- The current player position is available as `uCamPos`, `uPlayerPos`, and `iPlayerPos`.
)TXT";
    }

    inline std::string shadertoy_reference_text()
    {
        return R"TXT(# Shadertoy Shader Folder

Files in this folder are loaded directly at runtime and hot reloaded when they change.
In a portable build, this folder lives next to the executable.

- Use `.toy` or `.glsl` files that define `mainImage(out vec4 fragColor, in vec2 fragCoord)`.
- The game wraps your file so you can use Shadertoy-style uniforms such as `iTime`, `iResolution`, and `iChannel0`.
- `fragCoord` uses the current cube face as a local surface instead of the whole window.
- Helper functions such as `getLocalCenteredPosition()` and `getWorldPosition()` are available in the wrapper.
)TXT";
    }

    inline std::string shadertoy_shader_starter()
    {
        return R"GLSL(void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / max(iResolution.y, 1.0);
    vec3 local = getLocalCenteredPosition();

    float rings = sin(length(local.xz) * 24.0 - iTime * 3.0);
    float bands = sin((uv.x + uv.y) * 10.0 + iTime * 1.4);
    float glow = 0.5 + 0.5 * sin(iTime * 2.0 + local.y * 12.0);

    vec3 base = 0.5 + 0.5 * cos(iTime + vec3(0.0, 2.0, 4.0) + length(local) * 8.0);
    vec3 color = base * (0.35 + 0.65 * glow);
    color += 0.15 * vec3(0.2, 0.8, 1.0) * rings;
    color += 0.10 * vec3(1.0, 0.4, 0.2) * bands;

    fragColor = vec4(color, 1.0);
}
)GLSL";
    }

    inline void ensure_editable_shader_files()
    {
        static bool already_ensured = false;
        if (already_ensured)
        {
            return;
        }

        already_ensured = true;

        if (!std::filesystem::exists(raymarching_shader_folder()))
        {
            Folder::create_folder_if_does_not_exist_already(raymarching_shader_folder());
        }

        if (!std::filesystem::exists(shadertoy_shader_folder()))
        {
            Folder::create_folder_if_does_not_exist_already(shadertoy_shader_folder());
        }

        const auto write_if_missing = [](const std::string& filepath, const std::string& content)
        {
            if (!std::filesystem::exists(filepath))
            {
                File::writeFileIfNotExists(filepath, content);
            }
        };

        write_if_missing(default_vertex_shader_path(), default_vertex_shader_source());
        write_if_missing(raymarching_shader_folder() + "/player_pulse.glsl", raymarching_shader_player_pulse());
        write_if_missing(raymarching_shader_folder() + "/maze_echo.glsl", raymarching_shader_maze_echo());
        write_if_missing(raymarching_shader_folder() + "/signal_lattice.glsl", raymarching_shader_signal_lattice());
        write_if_missing(raymarching_shader_folder() + "/README.md", shader_reference_text());
        write_if_missing(shadertoy_shader_folder() + "/starter.toy", shadertoy_shader_starter());
        write_if_missing(shadertoy_shader_folder() + "/README.md", shadertoy_reference_text());
    }

    inline bool is_supported_fragment_shader_file(const std::filesystem::path& path)
    {
        const std::string extension = path.extension().string();
        if (extension != ".glsl" && extension != ".toy")
        {
            return false;
        }

        if (path.filename() == "default_vertex.glsl")
        {
            return false;
        }

        return true;
    }

    inline std::vector<std::string> discover_fragment_shader_paths()
    {
        std::vector<std::string> filepaths;

        const std::array<std::string, 2> folders =
        {
            raymarching_shader_folder(),
            shadertoy_shader_folder()
        };

        for (const std::string& folder : folders)
        {
            for (const std::string& filepath : Folder::getFilePathsInFolder(folder))
            {
                if (is_supported_fragment_shader_file(std::filesystem::path(filepath)))
                {
                    filepaths.push_back(filepath);
                }
            }
        }

        std::sort(filepaths.begin(), filepaths.end());
        return filepaths;
    }

    inline bool is_path_inside_shadertoy_folder(const std::string& filepath)
    {
        const std::string file_string = std::filesystem::path(filepath).lexically_normal().generic_string();
        const std::string folder_string = std::filesystem::path(shadertoy_shader_folder()).lexically_normal().generic_string();
        return file_string.find(folder_string) != std::string::npos;
    }

    inline bool source_looks_like_shadertoy(const std::string& source)
    {
        return source.find("mainImage") != std::string::npos;
    }

    inline bool is_shadertoy_shader_path(const std::string& filepath, const std::string& source)
    {
        if (std::filesystem::path(filepath).extension() == ".toy")
        {
            return true;
        }

        return is_path_inside_shadertoy_folder(filepath) && source_looks_like_shadertoy(source);
    }

    inline bool should_strip_shadertoy_line(const std::string& line)
    {
        const std::string trimmed = trim_copy(line);

        if (trimmed.empty())
        {
            return false;
        }

        if (starts_with(trimmed, "#version"))
        {
            return true;
        }

        if (starts_with(trimmed, "precision "))
        {
            return true;
        }

        if
        (
            trimmed == "out vec4 fragColor;" ||
            trimmed == "out vec4 FragColor;"
        )
        {
            return true;
        }

        if (!starts_with(trimmed, "uniform"))
        {
            return false;
        }

        static const std::array<std::string, 14> shadertoy_symbols =
        {
            "iResolution",
            "iTime",
            "iTimeDelta",
            "iFrame",
            "iDate",
            "iMouse",
            "iChannel0",
            "iChannel1",
            "iChannel2",
            "iChannel3",
            "iChannelResolution",
            "iChannelTime",
            "uResolution",
            "uViewportSize"
        };

        for (const std::string& symbol : shadertoy_symbols)
        {
            if (trimmed.find(symbol) != std::string::npos)
            {
                return true;
            }
        }

        return false;
    }

    inline std::string sanitize_shadertoy_source(const std::string& source)
    {
        std::istringstream input(source);
        std::ostringstream output;
        std::string line;
        bool skipping_main_wrapper = false;
        bool waiting_for_main_brace = false;
        int main_brace_depth = 0;

        while (std::getline(input, line))
        {
            const std::string trimmed = trim_copy(line);

            if (!skipping_main_wrapper && starts_with(trimmed, "void main(") && !starts_with(trimmed, "void mainImage"))
            {
                skipping_main_wrapper = true;
                waiting_for_main_brace = (count_char(line, '{') == 0);
                main_brace_depth = count_char(line, '{') - count_char(line, '}');
                output << "\n";

                if (!waiting_for_main_brace && main_brace_depth <= 0)
                {
                    skipping_main_wrapper = false;
                    main_brace_depth = 0;
                }

                continue;
            }

            if (skipping_main_wrapper)
            {
                main_brace_depth += count_char(line, '{');
                main_brace_depth -= count_char(line, '}');
                output << "\n";

                if (waiting_for_main_brace)
                {
                    if (count_char(line, '{') > 0)
                    {
                        waiting_for_main_brace = false;
                    }
                }
                else if (main_brace_depth <= 0)
                {
                    skipping_main_wrapper = false;
                    main_brace_depth = 0;
                }

                continue;
            }

            if (should_strip_shadertoy_line(line))
            {
                output << "\n";
            }
            else
            {
                output << line << "\n";
            }
        }

        return output.str();
    }

    inline std::string wrap_shadertoy_fragment_source(const std::string& filepath, const std::string& original_source)
    {
        const std::string user_source = sanitize_shadertoy_source(original_source);

        return std::string(R"GLSL(#version 330 core
in vec2 TexCoord;
in vec3 WorldPos;
in vec3 LocalPos;

out vec4 FragColor;

uniform sampler2D texture1;
uniform sampler2D texture2;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

uniform vec3 uColor;
uniform float time;
uniform vec3 uCamPos;
uniform vec3 uCubePos;
uniform vec2 uViewportSize;
uniform vec2 uSurfaceResolution;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

uniform float iTime;
uniform float iTimeDelta;
uniform int iFrame;
uniform vec4 iDate;
uniform vec4 iMouse;
uniform vec3 iPlayerPos;
uniform vec3 uPlayerPos;
uniform vec3 iChannelResolution[4];
uniform float iChannelTime[4];

vec3 iResolution = vec3(1024.0, 1024.0, 1.0);

#define iWorldPos WorldPos
#define iObjectPos LocalPos
#define iLocalPos LocalPos
#define uResolution iResolution.xy

vec3 getPlayerPosition()
{
    return iPlayerPos;
}

vec3 getCubePosition()
{
    return uCubePos;
}

vec3 getWorldPosition()
{
    return WorldPos;
}

vec3 getLocalPosition()
{
    return LocalPos;
}

vec3 getLocalCenteredPosition()
{
    return LocalPos - vec3(0.5);
}

vec3 getWorldNormal()
{
    return normalize(cross(dFdx(WorldPos), dFdy(WorldPos)));
}

vec3 getLocalNormal()
{
    return normalize(cross(dFdx(LocalPos), dFdy(LocalPos)));
}

vec2 getObjectSurfaceUV()
{
    vec3 p = clamp(LocalPos, vec3(0.0), vec3(1.0));
    vec3 n = getLocalNormal();
    vec3 an = abs(n);

    if (an.x > an.y && an.x > an.z)
    {
        return (n.x >= 0.0) ? vec2(1.0 - p.z, p.y) : vec2(p.z, p.y);
    }

    if (an.y > an.z)
    {
        return (n.y >= 0.0) ? vec2(p.x, 1.0 - p.z) : vec2(p.x, p.z);
    }

    return (n.z >= 0.0) ? vec2(p.x, p.y) : vec2(1.0 - p.x, p.y);
}

#define iSurfaceUV getObjectSurfaceUV()
#define iWorldNormal getWorldNormal()
#define iObjectNormal getLocalNormal()
#define iLocalNormal getLocalNormal()

vec2 getScreenFragCoord()
{
    return gl_FragCoord.xy;
}

vec2 getSurfaceFragCoord()
{
    return getObjectSurfaceUV() * iResolution.xy;
}

vec2 getCenteredSurfaceCoord()
{
    return (getObjectSurfaceUV() - 0.5) * iResolution.xy;
}

vec2 getViewportResolution()
{
    return uViewportSize;
}

// Source file:
// )GLSL") + filepath + R"GLSL(

#line 1
)GLSL" + user_source + R"GLSL(

void main()
{
    iResolution = vec3(max(uSurfaceResolution, vec2(1.0)), 1.0);

    vec4 color = vec4(0.0);
    mainImage(color, getSurfaceFragCoord());
    FragColor = color;
}
)GLSL";
    }

    inline std::string load_vertex_shader_source(const std::string& filepath)
    {
        const std::string source = File::readFileToString(filepath);
        if (source.empty())
        {
            return default_vertex_shader_source();
        }

        return source;
    }

    inline std::string load_fragment_shader_source(const std::string& filepath)
    {
        const std::string source = File::readFileToString(filepath);
        if (is_shadertoy_shader_path(filepath, source))
        {
            return wrap_shadertoy_fragment_source(filepath, source);
        }

        return source;
    }
}
