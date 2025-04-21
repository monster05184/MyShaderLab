#include "Assets/ShaderLab/ShaderCommon.hlsl"
#include "Assets/ShaderLab/PBR/PBR.hlsl"
half _MetallicMultiplier;
half _RoughnessMultiplier;

sampler2D _SDFTex;
float4 _SDFTex_ST;

#define _SDF_ON

struct LocalData1
{
    #ifdef _SDF_ON
    float3 sdf;
    #endif
};

LocalData1 _LocalData;



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
    float2 sdfuv = i.uv * _SDFTex_ST.xy + _SDFTex_ST.zw;
    _LocalData.sdf = tex2D(_SDFTex, sdfuv);
}

half3 CalculateMainLight(CustomSurfaceData sd, PBRData pd)
{
    half3 light = half3(0, 0, 0);
    half3 brdf = CookTorranceBRDF(pd, sd);
    light = brdf * pd.lightCol;
    Debug(_LocalData.sdf);
    
    #ifdef  _SDF_ON
    return 1;
    #endif
    
    return light;
}