#include <metal_stdlib>
using namespace metal;

#include "Common.h"
#include "ShaderDefs.h"

constant float4 black = float4(0.0, 0.0, 0.0, 1.0);

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant Mesh& mesh [[buffer(MeshBuffer)]],
                              constant SimParams& params [[buffer(SimParamsBuffer)]],
                              device bool* solidMask [[buffer(SolidMaskBuffer)]],
                              device float* speedNorm [[buffer(SpeedNormBuffer)]],
                              texture2d<float> gradientTexture [[texture(0)]],
                              sampler textureSampler [[sampler(0)]])
{
    uint x = min(uint(in.texCoord.x * mesh.Nx), mesh.Nx - 1);
    uint y = min(uint(in.texCoord.y * mesh.Ny), mesh.Ny - 1);
    uint idx = x + y * mesh.Nx;

    bool is_SOLID = solidMask[idx];

    float speed = sqrt(speedNorm[idx]) / max(params.speedMax, 1e-6f);
    float t = clamp(speed, 0.0, 1.0);
    float3 color = gradientTexture.sample(textureSampler, float2(t, 0.5)).rgb;

    return select(float4(color, 1.0), black, is_SOLID);
}
