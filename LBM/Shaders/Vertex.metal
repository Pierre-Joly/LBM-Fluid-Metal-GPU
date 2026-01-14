#include <metal_stdlib>
using namespace metal;

#include "Common.h"
#include "ShaderDefs.h"

vertex VertexOut vertex_main(constant Uniforms& uniforms [[buffer(UniformsBuffer)]],
                            constant Mesh& mesh [[buffer(MeshBuffer)]],
                            uint vertexId [[vertex_id]])
{
    float ny = max(float(mesh.Ny), 1.0f);
    float width = float(mesh.Nx) / ny;
    float height = 1.0f;

    float2 positions[4] = {
        float2(-0.5 * width, -0.5 * height),
        float2( 0.5 * width, -0.5 * height),
        float2(-0.5 * width,  0.5 * height),
        float2( 0.5 * width,  0.5 * height)
    };

    float4 position = float4(positions[vertexId], 0.0, 1.0);

    float4 position_4D = uniforms.projectionMatrix * uniforms.viewMatrix * position;

    float2 uvs[4] = {
        float2(0.0, 0.0),
        float2(1.0, 0.0),
        float2(0.0, 1.0),
        float2(1.0, 1.0)
    };

    VertexOut out;
    out.position = position_4D;
    out.texCoord = uvs[vertexId];
    return out;
}
