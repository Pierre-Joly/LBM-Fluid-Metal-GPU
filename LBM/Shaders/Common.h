#ifndef Common_h
#define Common_h

#include <simd/simd.h>

#if defined(__METAL_VERSION__)
typedef uint u32;
#else
#include <stdint.h>
typedef uint32_t u32;
#endif

typedef enum BufferIndices {
    VertexBuffer = 0,
    UniformsBuffer = 1,
    MeshBuffer = 2,
    DistributionInBuffer = 3,
    DistributionOutBuffer = 4,
    SpeedNormBuffer = 5,
    SolidMaskBuffer = 6,
    SimParamsBuffer = 7
} BufferIndices;

typedef struct {
    u32 Nx;
    u32 Ny;
} Mesh;

typedef struct {
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
} Uniforms;

typedef struct {
    float tau;
    float Ma;
    float aoaDeg;
    float chordRatio;
    float speedMax;
} SimParams;

#endif /* Common_h */
