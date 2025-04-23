#include "Assets/ShaderLab/ShaderCommon.hlsl"
#include "Assets/ShaderLab/PBR/PBR.hlsl"
half _MetallicMultiplier;
half _RoughnessMultiplier;

half _TangentShift;
half3 _SpecColor;


struct LocalData1
{
    float3 shiftTangent;
    float3 B;
};

LocalData1 _LocalData;



void PrepareSurfaceData(inout CustomSurfaceData sd, v2f i)
{
    _LocalData = (LocalData1)0;
    half3 normalTS = GetNormalTS(i.uv);
    half4 albedo = GetAlbedo(i.uv);
    half4 materialParams = GetMaterialParams(i.uv);
    half metallic = materialParams.y * _MetallicMultiplier;
    sd.diffuse = albedo * (1 - metallic);
    sd.emissive = GetEmissive(i.uv);
    sd.normalTS = normalTS;
    sd.opacity = albedo.a;
    sd.linearRoughness = materialParams.x * _RoughnessMultiplier;
    sd.metallic = metallic;
}

min16float3 ShiftTangent(min16float3 tangent, min16float3 normal, half shift)
{
    return normalize(tangent + shift * normal);
}
void PostSurfaceData(inout CustomSurfaceData sd, PBRData pd, v2f i)
{
    _TangentShift = 1;
    _LocalData.shiftTangent = ShiftTangent(i.tangent, i.normal, _TangentShift);\
    _LocalData.B = i.binormal;
}

half3 CalculateMainLight(CustomSurfaceData sd, PBRData pd)
{
    
    half3 light = half3(0, 0, 0);
    half LoH = max(0, dot(pd.L, pd.H));
    half3 brdfSpec = AnisotropicSpecularBRDF(pd.alpha, 1,sd.diffuse, pd.Nov, pd.Nol, pd.NoH, LoH, pd.V, pd.L, pd.H, _LocalData.shiftTangent, _LocalData.B);
    half3 brdfDiffuse = diffuseBRDF(sd.diffuse);
    light = (brdfDiffuse + brdfSpec * _SpecColor) * pd.lightCol;
    return light;
}