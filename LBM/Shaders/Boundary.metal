#include <metal_stdlib>
using namespace metal;

#include "Common.h"
#include "Kernel.h"

kernel void boundary(device float* distributionIn [[buffer(DistributionInBuffer)]],
                    device float* distributionOut [[buffer(DistributionOutBuffer)]],
                                        device float* speedNorm [[buffer(SpeedNormBuffer)]],
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

    // Boundary only
    if (!(x==0 || y==0 || x == mesh.Nx-1 || y == mesh.Ny-1)) return;

    uint baseIndex = id * Nl;

    float fIn[Nl];
    for (uint k = 0; k < Nl; ++k) {
        fIn[k] = distributionIn[baseIndex + k];
    }

    // Walls bounce-back
    if (y == 0) {
        // reflect south-going populations: 7, 4, 8
        fIn[5] = fIn[7];
        fIn[2] = fIn[4];
        fIn[6] = fIn[8];

        // Streaming
        if (!(x == mesh.Nx-1)) {
            fIn[3] = distributionIn[(x + 1) * Nl + 1];
        }
        if (!(x == 0)) {
            fIn[1] = distributionIn[(x - 1) * Nl + 3];
        }
    } else if (y == mesh.Ny-1) {
        // reflect north-going populations: 6, 2, 5
        fIn[8] = fIn[6];
        fIn[4] = fIn[2];
        fIn[7] = fIn[5];

        // Streaming
        if (!(x == mesh.Nx-1)) {
            fIn[3] = distributionIn[(x + 1 + y * mesh.Nx) * Nl + 1];
        }
        if (!(x == 0)) {
            fIn[1] = distributionIn[(x - 1 + y * mesh.Nx) * Nl + 3];
        }
    }
    // Inlet/Outlet (Zou/He)
    if (x == 0 && !(y == 0 || y == mesh.Ny-1)) {
        // velocity inlet: ux=Uin, uy=0
        float ux = params.Ma * cs;

        float f0 = fIn[0];
        float f2 = fIn[2];
        float f3 = fIn[3];
        float f4 = fIn[4];
        float f6 = fIn[6];
        float f7 = fIn[7];

        float rho_bc = (f0 + f2 + f4 + 2.0f*(f3 + f6 + f7)) / (1.0f - ux);

        // unknown: 1, 5, 8
        fIn[1] = f3 + (2.0f/3.0f) * rho_bc * ux;
        fIn[5] = f7 - 0.5f * (f2 - f4) + (1.0f/6.0f) * rho_bc * ux;
        fIn[8] = f6 - 0.5f * (f2 - f4) + (1.0f/6.0f) * rho_bc * ux;

        // Streaming
        if (!(y == mesh.Nx-1)) {
            fIn[2] = distributionIn[(x + (y-1) * mesh.Nx)* Nl + 2];
        }
        if (!(y == 0)) {
            fIn[4] = distributionIn[(x + (y+1) * mesh.Nx) * Nl + 4];
        }
    }
    else if (x == mesh.Nx-1 && !(y == 0 || y == mesh.Ny-1)) {
        // pressure outlet: rho=0.99 * rho0, uy=0
        float rho_bc = 0.99 * rho0;

        float f0 = fIn[0];
        float f2 = fIn[2];
        float f1 = fIn[1];
        float f4 = fIn[4];
        float f8 = fIn[8];
        float f5 = fIn[5];

        float ux = 1.0f - (f0 + f2 + f4 + 2.0f*(f1 + f8 + f5)) / rho_bc;

        // unknown: 3, 7, 6
        fIn[3] = f1 + (2.0f/3.0f) * rho_bc * ux;
        fIn[7] = f5 - 0.5f * (f4 - f2) + (1.0f/6.0f) * rho_bc * ux;
        fIn[6] = f8 - 0.5f * (f4 - f2) + (1.0f/6.0f) * rho_bc * ux;

        // Streaming
        if (!(y == mesh.Nx-1)) {
            fIn[2] = distributionIn[(x + (y-1) * mesh.Nx)* Nl + 2];
        }
        if (!(y == 0)) {
            fIn[4] = distributionIn[(x + (y+1) * mesh.Nx) * Nl + 4];
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
    for (uint k = 0; k < Nl; ++k) {
        distributionOut[baseIndex + k] = fIn[k];
    }
}
