#include "Assets/ShaderLab/ShaderCommon.hlsl"
#include "Assets/ShaderLab/PBR/PBR.hlsl"
half _MetallicMultiplier;
half _RoughnessMultiplier;
half _AOMultiplier;

half _ClearCoatMetallic;
half _ClearCoatRoughness;
half3 _ClearCoatEnvColor;
float _MainLightAO;
half3 _ClearCoatLightColor;

struct ClearCoatSurfaceData
{
    half3 emissive;
    half3 baseColor;
    half metallic;
    half3 diffuse;
    half3 specular;
    half opacity;
    half linearRoughness;
    half alpha;
    half4 normalTS;

    half occlusion;
    half cutoffThreshold;
};

struct LocalData1
{
    ClearCoatSurfaceData clearCoatData;
    half clearCoatFresnel;
};

LocalData1 _LocalData;

v2f VertexFunc(v2f i, appdataPBR v)
{
    return i;
}

void PrepareClearCoatSurfaceData(inout ClearCoatSurfaceData sd, v2f i)
{
    half4 normalTS = (0, 0, 1, 1);
    half4 albedo = (1, 1, 1);
    
    half metallic = _ClearCoatMetallic;
    sd.baseColor = albedo;
    sd.specular = lerp(0.04f, albedo.rgb, metallic);
    sd.diffuse = albedo * (1 - metallic);
    sd.emissive = GetEmissive(i.uv);
    sd.normalTS = normalTS;
    sd.opacity = albedo.a;
    sd.linearRoughness = _ClearCoatRoughness;
    sd.metallic = metallic;
    sd.occlusion = 1;
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
    sd.occlusion = materialParams.z;

    PrepareClearCoatSurfaceData(_LocalData.clearCoatData, i);
}
void PostSurfaceData(inout CustomSurfaceData sd, PBRData pd, v2f i)
{
    _LocalData.clearCoatFresnel = fresnelSchlick(pd.Nov, sd.specular);
}
half3 CalculateClearCoatLight(ClearCoatSurfaceData sd, PBRData pd, v2f i)
{
    half3 light = half3(0, 0, 0);
    half3 specbrdf = CookTorranceBRDF(pd.modelNormal, pd.V, pd.L, sd.specular, sd.metallic, sd.linearRoughness);
    float3 diffBRDF = diffuseBRDF(sd.diffuse);
    half NolModel = dot(pd.modelNormal, pd.L);
    
    light = (specbrdf + diffBRDF) * NolModel * pd.lightCol;
    
    return light;
}
half3 CalculateMainLight(CustomSurfaceData sd, PBRData pd, v2f i)
{
    half3 light = half3(0, 0, 0);
    half3 specbrdf = CookTorranceBRDF(pd, sd);
    half3 diffBRDF = diffuseBRDF(sd.diffuse);
    light = (specbrdf + diffBRDF) * pd.Nol * pd.lightCol;
    

    half3 clearCoatLight = CalculateClearCoatLight(_LocalData.clearCoatData, pd, i) * _ClearCoatLightColor;
    

    //Mix clear coat light with main light
    half3 refrectedLight = light * (1 - _LocalData.clearCoatFresnel) * lerp(1, sd.occlusion, _MainLightAO);
    light = refrectedLight + clearCoatLight;
    
    
    return light;
}

half3 CalculateClearCoatIndirectLight(ClearCoatSurfaceData sd, PBRData pd, v2f i)
{
    float3 indirectSpecColor = getPrefilterSpecularLD(_EnvMap, 6, (0, 0, 0,0), pd.modelNormal, pd.V, sd.linearRoughness);
    half Nov = dot(pd.modelNormal, pd.V);
    float3 indirectSpec = evalIndirectSpecular(Nov, indirectSpecColor, sd.linearRoughness, 1) * sd.specular * _ClearCoatEnvColor;
    //indirect diffuse
    float3 indirectDiffuse = SampleSHPixel(i.vertexSH, pd.N) * sd.diffuse * _ClearCoatEnvColor;

    return (indirectSpec + indirectDiffuse);
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
    light += indirectSpec;

    //indirect diffuse
    float3 indirectDiffuse = SampleSHPixel(i.vertexSH, pd.modelNormal) * sd.diffuse * _EnvColor;
    indirectDiffuse *= occlusion;
    light += indirectDiffuse;
    half3 ClearCoatLight = CalculateClearCoatIndirectLight(_LocalData.clearCoatData, pd, i);
    half3 RefractedLight = light * (1 - _LocalData.clearCoatFresnel);
    light = RefractedLight + ClearCoatLight;

    
    return light;
}