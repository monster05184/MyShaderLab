#include "Assets/ShaderLab/ShaderCommon.hlsl"
#include "Assets/ShaderLab/PBR/PBR.hlsl"
half _MetallicMultiplier;
half _RoughnessMultiplier;

half _TangentShift;
half3 _SpecColor;

half _AnisotropicMultiplier;

sampler2D _ShiftTex;
float4 _ShiftTex_ST;
half _ShiftTexScale;

float _AlphaIntensity;


struct LocalData1
{
    float3 shiftTangent;
    float3 B;
    half2 anisotropic;
};

LocalData1 _LocalData;


v2f VertexFunc(v2f i, appdataPBR v)
{
    //Debug(1, i.debugColor);
    return i;
}
void PrepareSurfaceData(inout CustomSurfaceData sd, v2f i)
{
    _LocalData = (LocalData1)0;
    half3 normalTS = GetNormalTS(i.uv);
    half4 albedo = GetAlbedo(i.uv);
    half4 materialParams = GetMaterialParams(i.uv);
    half metallic = materialParams.y * _MetallicMultiplier;
    sd.diffuse = albedo * (1 - metallic);
    sd.specular = lerp(0.04f, albedo.rgb, metallic);
    sd.emissive = GetEmissive(i.uv);
    sd.normalTS = normalTS;
    sd.opacity = albedo.a * _AlphaIntensity;
    sd.linearRoughness = materialParams.x * _RoughnessMultiplier;
    sd.metallic = metallic;
    _LocalData.anisotropic.x = _AnisotropicMultiplier;
}

min16float3 ShiftTangent(min16float3 tangent, min16float3 normal, half shift)
{
    return normalize(tangent + shift * normal);
}
void PostSurfaceData(inout CustomSurfaceData sd, PBRData pd, v2f i)
{
    //Debug(i.debugColor);
    half shiftTex = tex2D(_ShiftTex, i.uv * _ShiftTex_ST.xy + _ShiftTex_ST.zw);
    half shift1 = (shiftTex - 0.5) * _ShiftTexScale;
    
    _LocalData.shiftTangent = ShiftTangent(i.tangent, i.normal, _TangentShift);
    
    _LocalData.B = ShiftTangent(i.binormal, i.normal, shift1);
    //_LocalData.T = i.binormal;
}

half3 CalculateMainLight(CustomSurfaceData sd, PBRData pd, v2f i)
{
    
    half3 light = half3(0, 0, 0);
    half LoH = max(0, dot(pd.L, pd.H));
    half3 brdfSpec = AnisotropicSpecularBRDF(pd.alpha, _LocalData.anisotropic.x,sd.diffuse, pd.Nov, pd.Nol, pd.NoH, LoH, pd.V, pd.L, pd.H, _LocalData.shiftTangent, _LocalData.B);
    half3 brdfDiffuse = diffuseBRDF(sd.diffuse);
    light = (brdfDiffuse * pd.Nol + brdfSpec * pd.Nol * _SpecColor) * pd.lightCol;
    
    return light;
}

half3 CalculateIndirectLight(CustomSurfaceData sd, PBRData pd, v2f i)
{
    half3 light = half3(0, 0, 0);
    float3 indirectSpecColor = getPrefilterSpecularLD(_EnvMap, 6, (0, 0, 0,0), pd.N, pd.V, sd.linearRoughness);
    float3 indirectSpec = evalIndirectSpecular(pd.Nov, indirectSpecColor, sd.linearRoughness, 1) * sd.specular * _EnvColor;
    light += indirectSpec * _EnvColor;
    float indirectDiffuse = SampleSH(pd.N) * sd.diffuse;
    light += indirectDiffuse;
    return light;
}