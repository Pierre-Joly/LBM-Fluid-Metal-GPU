#include <metal_stdlib>
using namespace metal;

#include "Common.h"
#include "Kernel.h"

kernel void solid_mask(device bool* solidMask [[buffer(SolidMaskBuffer)]],
                        constant SimParams& params [[buffer(SimParamsBuffer)]],
                        constant Mesh& mesh [[buffer(MeshBuffer)]],
                        uint id [[thread_position_in_grid]])
{
    uint cellCount = mesh.Nx * mesh.Ny;
    if (id >= cellCount) {
        return;
    }

    uint x = id % mesh.Nx;
    uint y = id / mesh.Nx;

    // Symmetric NACA 00xx airfoil mask (default 0012).
    float chord = float(mesh.Nx) * params.chordRatio;
    float x0 = float(mesh.Nx) * 0.2f;
    float y0 = float(mesh.Ny) * 0.5f;
    float t = 0.12f;

    // Rotate points into airfoil frame for angle of attack.
    float aoaDeg = params.aoaDeg;
    float aoa = aoaDeg * 0.01745329252f;
    float ca = cos(aoa);
    float sa = sin(aoa);

    float px = float(x) - x0;
    float py = float(y) - y0;
    float xr =  px * ca - py * sa;
    float yr =  px * sa + py * ca;

    bool inChord = (xr >= 0.0f && xr <= chord);
    float xc = clamp(xr / chord, 0.0f, 1.0f);
    float yt = 5.0f * t * chord
        * (0.2969f * sqrt(xc)
           - 0.1260f * xc
           - 0.3516f * xc * xc
           + 0.2843f * xc * xc * xc
           - 0.1015f * xc * xc * xc * xc);

    float dy = fabs(yr);
    bool condition = inChord && (dy <= yt);

    solidMask[id] = condition;
}
