//一个UnlitShader的hlsl
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
struct v2f
{
    float2 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
    
    //TBN
    float3 normal : TEXCOORD1;
    float3 tangent : TEXCOORD2;
    float3 binormal : TEXCOORD3;

    float3 positionWS : TEXCOORD4;
    float4 screenPos : TEXCOORD5;

    float3 vertexLight : TEXCOORD6;

    float3 vertexSH    : TEXCOORD7;

    #ifdef DEBUG
    float4 debugColor  : TEXCOORD8;
    #endif
    float4 shadowCoord : TEXCOORD9;
    
};

struct appdataUnlit
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
};
v2f vert_unlit (appdataUnlit v)
{
    v2f o;
    VertexPositionInputs positionInput = GetVertexPositionInputs(v.vertex);
    o.vertex = positionInput.positionCS;
    o.positionWS = positionInput.positionWS;
    o.uv = v.uv;
    VertexNormalInputs normalInput = GetVertexNormalInputs(v.normal, v.tangent);
    o.normal.xyz = normalInput.normalWS;
    o.tangent.xyz = normalInput.tangentWS;
    o.binormal.xyz = normalInput.bitangentWS;
    o.screenPos = ComputeScreenPos(o.vertex);

    return o;
}
half4 frag_unlit(v2f i) : SV_Target
{
    half4 col;
    return col;
}

void DepthNormalsFragment(
    v2f input
    , out half4 outNormalWS : SV_Target0
#ifdef _WRITE_RENDERING_LAYERS
    , out float4 outRenderingLayers : SV_Target1
#endif
)
{

    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    #ifdef LOD_FADE_CROSSFADE
    LODFadeCrossFade(input.positionCS);
    #endif

    // Output...
    #if defined(_GBUFFER_NORMALS_OCT)
    float3 normalWS = normalize(input.normalWS);
    float2 octNormalWS = PackNormalOctQuadEncode(normalWS);             // values between [-1, +1], must use fp32 on some platforms
    float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);     // values between [ 0,  1]
    half3 packedNormalWS = half3(PackFloat2To888(remappedOctNormalWS)); // values between [ 0,  1]
    outNormalWS = half4(packedNormalWS, 0.0);
    #else
    outNormalWS = half4(NormalizeNormalPerPixel(input.normal), 0.0);
    #endif

    #ifdef _WRITE_RENDERING_LAYERS
    uint renderingLayers = GetMeshRenderingLayer();
    outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
    #endif
}





