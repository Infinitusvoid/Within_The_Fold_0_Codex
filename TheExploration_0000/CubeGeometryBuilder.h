#pragma once

#include <vector>
#include <array>

struct CubeGeometryBuilder
{
    enum class CubeFace
    {
        Front,   // +Z
        Back,    // -Z
        Left,    // -X
        Right,   // +X
        Top,     // +Y
        Bottom   // -Y
    };

    /// Generates 6 vertices (two triangles) for the given face of a unit cube,
    /// each vertex having (x,y,z,u,v)
    static std::vector<float> generate(const CubeFace face)
    {
        std::vector<float> verts;
        verts.reserve(6 * 5); // 6 vertices × (3 pos + 2 uv)

        const float hs = 0.5f; // half–size of cube

        // 1) positions of the 4 corners in CCW order (as seen from outside)
        std::array<std::array<float, 3>, 4> pos;
        switch (face)
        {
        case CubeFace::Front:   // +Z
            pos = { {
                {{ -hs, -hs, +hs }},
                {{ +hs, -hs, +hs }},
                {{ +hs, +hs, +hs }},
                {{ -hs, +hs, +hs }}
            } };
            break;
        case CubeFace::Back:    // -Z
            pos = { {
                {{ +hs, -hs, -hs }},
                {{ -hs, -hs, -hs }},
                {{ -hs, +hs, -hs }},
                {{ +hs, +hs, -hs }}
            } };
            break;
        case CubeFace::Left:    // -X
            pos = { {
                {{ -hs, -hs, -hs }},
                {{ -hs, -hs, +hs }},
                {{ -hs, +hs, +hs }},
                {{ -hs, +hs, -hs }}
            } };
            break;
        case CubeFace::Right:   // +X
            pos = { {
                {{ +hs, -hs, +hs }},
                {{ +hs, -hs, -hs }},
                {{ +hs, +hs, -hs }},
                {{ +hs, +hs, +hs }}
            } };
            break;
        case CubeFace::Top:     // +Y
            pos = { {
                {{ -hs, +hs, +hs }},
                {{ +hs, +hs, +hs }},
                {{ +hs, +hs, -hs }},
                {{ -hs, +hs, -hs }}
            } };
            break;
        case CubeFace::Bottom:  // -Y
            pos = { {
                {{ -hs, -hs, -hs }},
                {{ +hs, -hs, -hs }},
                {{ +hs, -hs, +hs }},
                {{ -hs, -hs, +hs }}
            } };
            break;
        }

        // 2) UV coords for those corners: (0,0),(1,0),(1,1),(0,1)
        //    Matches the example, so lower-left (0,0), lower-right (1,0), etc.
        static constexpr std::array<std::array<float, 2>, 4> uv = { {
            {{ 0.0f, 0.0f }},
            {{ 1.0f, 0.0f }},
            {{ 1.0f, 1.0f }},
            {{ 0.0f, 1.0f }}
        } };

        // 3) Helper to emit one full vertex: x,y,z,u,v
        auto emit = [&](int idx) {
            verts.push_back(pos[idx][0]);
            verts.push_back(pos[idx][1]);
            verts.push_back(pos[idx][2]);
            verts.push_back(uv[idx][0]);
            verts.push_back(uv[idx][1]);
            };

        // 4) Two triangles: (0,1,2) and (0,2,3)
        emit(0);
        emit(1);
        emit(2);

        emit(0);
        emit(2);
        emit(3);

        return verts;
    }

    /// New: generate all 6 faces in one go (180 floats total)
    static std::vector<float> generateAll()
    {
        std::vector<float> allVerts;
        allVerts.reserve(6 * 6 * 5); // 6 faces × 6 verts × 5 floats

        // Loop over every face, append its data
        for (CubeFace f : { CubeFace::Front, CubeFace::Back,
            CubeFace::Left, CubeFace::Right,
            CubeFace::Top, CubeFace::Bottom })
        {
            auto faceData = generate(f);
            allVerts.insert(allVerts.end(),
                faceData.begin(), faceData.end());
        }

        return allVerts;
    }
};