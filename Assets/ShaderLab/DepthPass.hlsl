#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

v2f VertexFunc(v2f i);
half Alpha(half albedoAlpha, half4 color, half cutoff)
{
    #if !defined(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A) && !defined(_GLOSSINESS_FROM_BASE_ALPHA)
    half alpha = albedoAlpha * color.a;
    #else
    half alpha = color.a;
    #endif

    alpha = AlphaDiscard(alpha, cutoff);

    return alpha;
}

half4 SampleAlbedoAlpha(float2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap))
{
    return half4(SAMPLE_TEXTURE2D(albedoAlphaMap, sampler_albedoAlphaMap, uv));
}
//TEXTURE2D(_AlbedoMap);
//SAMPLER(sampler_AlbedoMap);
//float4 _AlbedoColor;
half _Cutoff;
//int _AlbedoMap_ST;

v2f DepthOnlyVertex(appdataPBR input)
{
    v2f output = (v2f)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);


    output.uv = TRANSFORM_TEX(input.uv, _AlbedoMap);
    output.vertex = TransformObjectToHClip(input.vertex.xyz);
    return output;
}

half DepthOnlyFragment(v2f input) : SV_TARGET
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    Alpha(SampleAlbedoAlpha(input.uv, _AlbedoMap, samplers_DFGTexture).a, _AlbedoColor, _Cutoff);

    #ifdef LOD_FADE_CROSSFADE
    LODFadeCrossFade(input.positionCS);
    #endif

    return input.vertex.z;
}

v2f DepthNormalsVertex(appdataPBR input)
{
    v2f output = (v2f)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    output.vertex = TransformObjectToHClip(input.vertex.xyz);


    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangent);
    output.normal = NormalizeNormalPerVertex(normalInput.normalWS);

    output = VertexFunc(output, input);

    return output;
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