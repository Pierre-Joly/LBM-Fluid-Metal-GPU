#ifndef KERNEL_H
#define KERNEL_H

#include <metal_stdlib>
using namespace metal;

#include "Common.h"

constant float rho0 = 1.0f;
constant uint Nl = 9;

constant float cs2 = 1.0f / 3.0f;
constant float cs = 0.57735026f;
constant float cs4 = cs2 * cs2;

constant int2 c[Nl] = {
    int2( 0, 0),
    int2( 1, 0),
    int2( 0, 1),
    int2(-1, 0),
    int2( 0,-1),
    int2( 1, 1),
    int2(-1, 1),
    int2(-1,-1),
    int2( 1,-1)
};

constant uint opp[Nl] = { 0, 3, 4, 1, 2, 7, 8, 5, 6 };

constant float weights[Nl] = {4.0/9.0,
    1.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/9.0,
    1.0/36.0, 1.0/36.0, 1.0/36.0, 1.0/36.0
};

// feq_i = w_i * rho * [1 + cu/cs2 + (cu^2)/(2 cs4) - u^2/(2 cs2)]
inline float FeqKernel(float cu, float rho, float u2, uint k)
{
    float feq = weights[k] * rho * ( 1.0f
                + (cu / cs2)
                + (0.5f * (cu * cu) / cs4)
                - (0.5f * u2 / cs2));
    return feq;
}
#endif /* KERNEL_H */
