#include "Assets/ShaderLab/ShaderCommon.hlsl"
#include "Assets/ShaderLab/PBR/PBR.hlsl"
#include "Assets/ShaderLab/Features/MatcapLight.hlsl"
half _MetallicMultiplier;
half _RoughnessMultiplier;

TEXTURE2D(_HighLightMatcap);
SAMPLER(sampler_HighLightMatcap);

TEXTURE2D(_EnvLightMatcap);
SAMPLER(sampler_EnvLightMatcap);


struct LocalData1
{
    float2 matcapUV;
};

LocalData1 _LocalData;

v2f VertexFunc(v2f i, appdataPBR v)
{
    return i;
}

void PrepareSurfaceData(inout CustomSurfaceData sd, v2f i)
{
    _LocalData = (LocalData1)0;
    half3 normalTS = GetNormalTS(i.uv);
    half4 albedo = GetAlbedo(i.uv);
    half4 materialParams = GetMaterialParams(i.uv);
    half metallic = materialParams.y * _MetallicMultiplier;
    sd.specular = lerp(0.04f, albedo.rgb, metallic);
    sd.diffuse = albedo * (1 - metallic);
    sd.emissive = GetEmissive(i.uv);
    sd.normalTS = normalTS;
    sd.opacity = albedo.a;
    sd.linearRoughness = materialParams.x * _RoughnessMultiplier;
    sd.metallic = metallic;

}
void PostSurfaceData(inout CustomSurfaceData sd, PBRData pd, v2f i)
{
    half3 viewPos;
    //将模型世界空间坐标转换成视图空间坐标
    viewPos = TransformWorldToView(i.positionWS);
    float2 matcapUV = MatCapUV(pd.N, viewPos);
    _LocalData.matcapUV = matcapUV;
}

half3 CalculateMainLight(CustomSurfaceData sd, PBRData pd, v2f i)
{
    half3 light = half3(0, 0, 0);

    // Sample the matcap texture
    float2 matcapUV = _LocalData.matcapUV;
    half4 highLightMatcap = SAMPLE_TEXTURE2D(_HighLightMatcap, sampler_HighLightMatcap, matcapUV);

    half3 diffuseTerm = diffuseBRDF(sd.diffuse);
    light = highLightMatcap * sd.specular + diffuseTerm;
    light *= pd.Nol * pd.lightCol;
    //Debug(light); 

    
    
    return light;
}

half3 CalculateIndirectLight(CustomSurfaceData sd, PBRData pd, v2f i)
{
    half3 light = half3(0, 0, 0);
    float2 matcapUV = _LocalData.matcapUV;
    half4 envLightMatcap = SAMPLE_TEXTURE2D(_EnvLightMatcap, sampler_EnvLightMatcap, matcapUV);
    light = envLightMatcap * sd.diffuse * _EnvColor;
    

    return light;
}