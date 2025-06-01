#include "Assets/ShaderLab/ShaderCommon.hlsl"
#include "Assets/ShaderLab/PBR/PBR.hlsl"
half _MetallicMultiplier;
half _RoughnessMultiplier;

half _SSSIntensity;
sampler2D _SkinSSSTex;
half3 _SSSColor1;
half3 _SSSColor2;
half3 _SSSColor3;

struct LocalData1
{
    half SSSIntensity;
    half3 SSSBentNormal;
    half3 SSSColor1;
    half3 SSSColor2;
    half3 SSSColor3;
    half curvature;
};

LocalData1 _LocalData;

v2f VertexFunc(v2f i, appdataPBR v)
{
    
    return i;
}

half4 getSkinSSS(float2 uv)
{
    half4 SkinSSSParams = tex2D(_SkinSSSTex, uv);
    SkinSSSParams = saturate(SkinSSSParams);
    return SkinSSSParams;
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


    _LocalData.SSSIntensity = _SSSIntensity * _SSSIntensity;
    half4 SkinSSSParams = getSkinSSS(i.uv);
    _LocalData.curvature = SkinSSSParams.x * (1 - metallic);
    _LocalData.curvature = saturate(_LocalData.curvature * _LocalData.SSSIntensity);
    _LocalData.curvature = sqrt(_LocalData.curvature);


    
    _LocalData.SSSColor1 = _SSSColor1;
    _LocalData.SSSColor2 = _SSSColor2;
    _LocalData.SSSColor3 = _SSSColor3;
}
void PostSurfaceData(inout CustomSurfaceData sd, PBRData pd, v2f i)
{
    
}

void LightSSS(CustomSurfaceData sd, PBRData pd, in half ao, out half3 SSSResult)
{ 
    half3 SSSResult1 = dot(pd.N, pd.L);
    half3 SSSResult2 = dot(pd.N, pd.L) - SSSResult1;
    
    SSSResult1 /= 1 + _LocalData.curvature;
    SSSResult1 += 0.5 * _LocalData.curvature;
    half4 _ShadowCol = 0;
    SSSResult1 = saturate(SSSResult1) * (lerp(_ShadowCol,1,pd.atten));
    _LocalData.SSSColor3 = lerp(_LocalData.SSSColor3, _LocalData.SSSColor2, SSSResult1);
    SSSResult1 = lerp(SSSResult1 * _LocalData.SSSColor3, _LocalData.SSSColor1, SSSResult1);

    SSSResult2 *= 2;
    SSSResult2 += 1;
    SSSResult2 *= sqrt(ao);
    SSSResult2 = saturate(SSSResult2);
    SSSResult2 = lerp(_LocalData.SSSColor2, 1, SSSResult2);
    SSSResult1 *= SSSResult2;

    SSSResult = SSSResult1;
}

half3 CalculateMainLight(CustomSurfaceData sd, PBRData pd, v2f i)
{
    half3 sss;
    LightSSS(sd, pd, 1, sss);
    half3 light = half3(0, 0, 0);
    half3 specbrdf = CookTorranceBRDF(pd, sd);

    float3 diffBRDF = diffuseBRDF(sd.diffuse);
    
    light = (specbrdf * sd.specular + diffBRDF) * sss * pd.lightCol;
    return light;
}

half3 CalculateIndirectLight(CustomSurfaceData sd, PBRData pd, v2f i)
{
    half3 light = half3(0, 0, 0);
    float3 indirectSpecColor = getPrefilterSpecularLD(_EnvMap, 6, (0, 0, 0,0), pd.N, pd.V, sd.linearRoughness);
    float3 indirectSpec = evalIndirectSpecular(pd.Nov, indirectSpecColor, sd.linearRoughness, 1) * sd.diffuse * _EnvColor;
    light += indirectSpec * _EnvColor;
    
    float indirectDiffuse = SampleSH(pd.N) * sd.diffuse;
    light += indirectDiffuse;
    return light;
}