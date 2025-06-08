#include "Assets/ShaderLab/ShaderCommon.hlsl"
#include "Assets/ShaderLab/PBR/FabricBRDF.hlsl"
half _MetallicMultiplier;
half _RoughnessMultiplier;
half _AOMultiplier;

TEXTURE2D(_DetailMap);
SAMPLER(sampler_DetailMap);
half4 _DetailMap_ST;
half _DetailNormalScale;
half _DetailMapAOScale;




struct LocalData1
{
    
};

LocalData1 _LocalData;

v2f VertexFunc(v2f i, appdataPBR v)
{
    return i;
}

void PrepareSurfaceData(inout CustomSurfaceData sd, v2f i)
{
    _LocalData = (LocalData1)0;
    half4 normalTS = GetNormalTS(i.uv);
    half4 albedo = GetAlbedo(i.uv);
    half4 materialParams = GetMaterialParams(i.uv);
    half metallic = materialParams.y * _MetallicMultiplier;
    sd.specular = lerp(0.04f, albedo.rgb, metallic);
    sd.diffuse = albedo * (1 - metallic);
    sd.emissive = GetEmissive(i.uv);
    sd.normalTS = normalTS;
    sd.opacity = albedo.a;
    sd.linearRoughness = materialParams.x + _RoughnessMultiplier;
    sd.metallic = metallic;
    
    
    float4 detailNormal = SAMPLE_TEXTURE2D(_DetailMap, sampler_DetailMap, i.uv * _DetailMap_ST.xy + _DetailMap_ST.zw);
    
    
}
void PostSurfaceData(inout CustomSurfaceData sd, PBRData pd, v2f i)
{
    float4 detailNormal = SAMPLE_TEXTURE2D(_DetailMap, sampler_DetailMap, i.uv * _DetailMap_ST.xy + _DetailMap_ST.zw);

    float3 detailNormalWS = GetNormal(detailNormal, i);
    
    //DetailMap
}

half3 CalculateMainLight(CustomSurfaceData sd, PBRData pd, v2f i)
{
    half3 light = half3(0, 0, 0);
    half3 specbrdf = FabricBRDF(pd, sd);

    float3 diffBRDF = FabricLambert(sd.linearRoughness) * sd.diffuse;
    light = (specbrdf + diffBRDF) * pd.Nol * pd.lightCol;
    return light;
}

half3 CalculateIndirectLight(CustomSurfaceData sd, PBRData pd, v2f i)
{
    half3 light = half3(0, 0, 0);
    //occusion
    half occlusion = lerp(1, sd.occlusion, _AOMultiplier);
    half indirectSpecAO = lerp(0.7, 1, occlusion);
    
    //indirect specular
    float3 indirectSpecColor = getPrefilterSpecularLD(_EnvMap, 6, (0, 0, 0,0), pd.N, pd.V, sd.linearRoughness);
    float3 indirectSpec = evalIndirectSpecular(pd.Nov, indirectSpecColor, sd.linearRoughness, 1) * sd.specular * _EnvColor;
    indirectSpec *= indirectSpecAO;
    light += indirectSpec * _EnvColor;

    //indirect diffuse
    float3 indirectDiffuse = SampleSHPixel(i.vertexSH, pd.N) * sd.diffuse;
    indirectDiffuse *= occlusion;
    light += indirectDiffuse;
    return light;
}