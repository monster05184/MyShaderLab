#include "Assets/ShaderLab/ShaderCommon.hlsl"
#include "Assets/ShaderLab/PBR/PBR.hlsl"
half _MetallicMultiplier;
half _RoughnessMultiplier;



struct LocalData1
{
    
};

LocalData1 _LocalData;

v2f VertexFunc(v2f i)
{
    Debug(1, i.debugColor);
    return i;
}

void PrepareSurfaceData(inout CustomSurfaceData sd, v2f i)
{
    _LocalData = (LocalData1)0;
    half3 normalTS = GetNormalTS(i.uv);
    half4 albedo = GetAlbedo(i.uv);
    half4 materialParams = GetMaterialParams(i.uv);
    half metallic = materialParams.y * _MetallicMultiplier;
    sd.diffuse = albedo;
    sd.emissive = GetEmissive(i.uv);
    sd.normalTS = normalTS;
    sd.opacity = albedo.a;
    sd.linearRoughness = materialParams.x * _RoughnessMultiplier;
    sd.metallic = metallic;
}
void PostSurfaceData(inout CustomSurfaceData sd, PBRData pd, v2f i)
{
    
}

half3 CalculateMainLight(CustomSurfaceData sd, PBRData pd)
{
    half3 light = half3(0, 0, 0);
    half3 specbrdf = CookTorranceBRDF(pd, sd);

    float3 diffBRDF = diffuseBRDF(sd.diffuse);
    
    light = (specbrdf + diffBRDF) * pd.Nol * pd.lightCol;
    return light;
}

half3 CalculateIndirectLight(CustomSurfaceData sd, PBRData pd)
{
    half3 light = half3(0, 0, 0);
    float3 indirectSpecColor = getPrefilterSpecularLD(_EnvMap, 6, (0, 0, 0,0), pd.N, pd.V, sd.linearRoughness);
    float3 indirectSpec = evalIndirectSpecular(pd.Nov, indirectSpecColor, sd.linearRoughness, 1) * sd.diffuse * _EnvColor;
    light += indirectSpec * _EnvColor;
    
    float indirectDiffuse = SampleSH(pd.N) * sd.diffuse;
    light += indirectDiffuse;
    return light;
}