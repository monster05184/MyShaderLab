#include "Assets/ShaderLab/ShaderCommon.hlsl"
#include "Assets/ShaderLab/PBR/PBR.hlsl"
#include "Assets/ShaderLab/Features/MatcapLight.hlsl"
half _MetallicMultiplier;
half _RoughnessMultiplier;
half _AOMultiplier;


TEXTURE2D(_HighLightMatcap);
SAMPLER(sampler_HighLightMatcap);

TEXTURE2D(_EnvLightMatcap);
SAMPLER(sampler_EnvLightMatcap);

TEXTURE2D(_DetailMap);
SAMPLER(sampler_DetailMap);
float4 _DetailMap_ST;

half4 _DetailsControl;

half _DetailAOControl;
half _DetailSpecControl;
half _DetailEnvControl;

half4 _HighLightColor;
half4 _EnvLightColor;


struct LocalData1
{
    float2 matcapUV;
    float2 specOffset;
    float2 envOffset;
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

    //DetailMap

    half2 SpecularOffset = half2(0, 0);
    half2 EnvirOffset = half2(0, 0);
    
    half DetailsMask = 1;
    half2 DetailsUV = TRANSFORM_TEX(i.uv.xy, _DetailMap);//UV
    half3 DetailsTex = SAMPLE_TEXTURE2D(_DetailMap, sampler_DetailMap, DetailsUV);
    half2 DetailsOffset = (DetailsTex.rg * 2 - 1) * DetailsMask;// * _DetailsSpOffset;
    SpecularOffset = DetailsOffset * _DetailSpecControl;
    EnvirOffset = DetailsOffset * _DetailEnvControl;

    _LocalData.specOffset = SpecularOffset;
    _LocalData.envOffset = EnvirOffset;
   
    
    half DetailsAO = saturate(DetailsTex.b + _DetailAOControl + (1 - DetailsMask));
    sd.specular *= DetailsAO;
    sd.diffuse *= DetailsAO;
}

half3 CalculateMainLight(CustomSurfaceData sd, PBRData pd, v2f i)
{


    
    half3 light = half3(0, 0, 0);

    // Sample the matcap texture
    float2 matcapUV = _LocalData.matcapUV;
    matcapUV += _LocalData.specOffset;
    half4 highLightMatcap = SAMPLE_TEXTURE2D(_HighLightMatcap, sampler_HighLightMatcap, matcapUV);

    half3 diffuseTerm = diffuseBRDF(sd.diffuse);
    light = highLightMatcap * sd.specular * _HighLightColor + diffuseTerm;
    light *= pd.Nol * pd.lightCol;


    
    return light;
}

half3 CalculateIndirectLight(CustomSurfaceData sd, PBRData pd, v2f i)
{
    //occusion
    half occlusion = lerp(1, sd.occlusion, _AOMultiplier);
    half indirectSpecAO = lerp(0.7, 1, occlusion);
    
    half3 light = half3(0, 0, 0);
    float2 envOffset = _LocalData.envOffset;
    float2 matcapUV = _LocalData.matcapUV;
    matcapUV += envOffset;
    half4 envLightMatcap = SAMPLE_TEXTURE2D(_EnvLightMatcap, sampler_EnvLightMatcap, matcapUV);
    light = envLightMatcap * sd.diffuse * _EnvLightColor * indirectSpecAO;

    half3 indirectDiffuse = SampleSH(pd.N) * sd.diffuse;
    indirectDiffuse *= occlusion;

    light += indirectDiffuse;
    

    return light;
}