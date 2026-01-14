#include <metal_stdlib>
using namespace metal;

#include "Common.h"
#include "Kernel.h"

kernel void initialize(device float* distribution [[buffer(DistributionInBuffer)]],
                       constant SimParams& params [[buffer(SimParamsBuffer)]],
                       constant Mesh& mesh [[buffer(MeshBuffer)]],
                       uint id [[thread_position_in_grid]])
{
    uint cellCount = mesh.Nx * mesh.Ny;
    if (id >= cellCount) {
        return;
    }

    // Uniform left->right initial velocity
    float U = params.Ma * cs;
    float2 u = float2(U, 0.0f);

    float u2 = dot(u, u);

    uint baseIndex = id * Nl;

    for (uint k = 0; k < Nl; ++k) {
        float2 ck = float2(c[k]);
        float  cu = dot(ck, u); 

        float feq = FeqKernel(cu, rho0, u2, k);

        distribution[baseIndex + k] = feq;
    }
}
