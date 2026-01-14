#include <metal_stdlib>
using namespace metal;

#include "Common.h"
#include "Kernel.h"

kernel void collide_stream(device float* const distributionIn [[buffer(DistributionInBuffer)]],
                        device float* distributionOut [[buffer(DistributionOutBuffer)]],
                        device float* speedNorm [[buffer(SpeedNormBuffer)]],
                        device const bool* solidMask [[buffer(SolidMaskBuffer)]],
                        constant SimParams& params [[buffer(SimParamsBuffer)]],
                        constant Mesh& mesh [[buffer(MeshBuffer)]],
                        uint id [[thread_position_in_grid]])
{
    uint cellCount = mesh.Nx * mesh.Ny;
    if (id >= cellCount) return;

    uint x = id % mesh.Nx;
    uint y = id / mesh.Nx;

    // Interior only
    if (x==0 || y==0 || x == mesh.Nx-1 || y == mesh.Ny-1) return;

    uint baseIndex = id * Nl;

    bool is_SOLID = solidMask[id];

    if (is_SOLID) {
        speedNorm[id] = 0.0f;
        for (uint k = 0; k < Nl; ++k) {
            distributionOut[baseIndex + k] = distributionIn[baseIndex + opp[k]];
        }
        return;
    }

    // Stream
    float fIn[Nl];

    for (uint k = 0; k < Nl; ++k) {
        int nx = int(x) - c[k].x;
        int ny = int(y) - c[k].y;
        uint neighbor = uint(nx) + uint(ny) * mesh.Nx;
        uint sourceIndex = neighbor * Nl;

        if (is_SOLID) {
            // neighbor is solid -> bounce back along this link
            fIn[k] = distributionIn[baseIndex + opp[k]];
        } else {
            fIn[k] = distributionIn[sourceIndex + k];
        }
    }

    // Moment
    float rho = 0.0f;
    float2 j  = float2(0.0f);

    for (uint k = 0; k < Nl; ++k) {
        rho += fIn[k];
        j   += fIn[k] * float2(c[k]);
    }

    float2 u = j / rho;
    
    // Get the norm
    float u2 = dot(u, u);
    speedNorm[id] = sqrt(u2);

    // Collide
    float invTau = 1.0f / params.tau;
    for (uint k = 0; k < Nl; ++k) {
        float2 ck = float2(c[k]);
        float  cu = dot(ck, u); 

        float feq = FeqKernel(cu, rho, u2, k);

        distributionOut[baseIndex + k] = fIn[k] - invTau * (fIn[k] - feq);
    }
}
