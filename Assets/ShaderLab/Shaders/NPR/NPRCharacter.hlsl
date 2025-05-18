#include "Assets/ShaderLab/ShaderCommon.hlsl"
#include "Assets/ShaderLab/PBR/PBR.hlsl"
#include "Assets/ShaderLab/NPR/NPRCommon.hlsl"
half _MetallicMultiplier;
half _RoughnessMultiplier;

sampler2D _SDFTex;
float4 _SDFTex_ST;

half _SDFValue;
int _SDFSign;
half _SDFSmooth;
half3 _SpecColor;



struct LocalData1
{
    #ifdef _SDF_ON
    float3 sdf;
    #endif
    float3 vertexSH;
};

LocalData1 _LocalData;

v2f VertexFunc(v2f i)
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
    sd.baseColor = albedo;
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
    float2 sdfuv = i.uv * _SDFTex_ST.xy + _SDFTex_ST.zw;
    sdfuv.x = _SDFSign > 0 ? sdfuv.x : 1 - sdfuv.x;
    #ifdef _SDF_ON
    _LocalData.sdf.r = tex2D(_SDFTex, sdfuv).r;
    sdfuv.x = (1 - sdfuv.x);
    _LocalData.sdf.gb = tex2D(_SDFTex, sdfuv).gb;
    #endif
    _LocalData.vertexSH = i.vertexSH;
    half3 ramp = NPRRamp(pd.Nol);
    sd.diffuse = sd.diffuse * ramp;
    sd.specular = sd.specular * ramp;
}
half SDF(half3 sdf, half d)
{
    return smoothstep( d - _SDFSmooth * 0.05,  d + _SDFSmooth * 0.05, sdf.x);
}
half SDFHighLight(half3 sdf, half d)
{
    half lit1 = smoothstep( d - _SDFSmooth * 0.05,  d + _SDFSmooth * 0.05, 1 - sdf.y);
    half lit2 = smoothstep( d - _SDFSmooth * 0.05,  d + _SDFSmooth * 0.05, sdf.z);
    return saturate(lit2 - lit1);
}



half3 CalculateMainLight(CustomSurfaceData sd, PBRData pd, v2f i)
{
    half3 light = half3(0, 0, 0);
    
    
    float3 diffBRDF = diffuseBRDF(sd.diffuse);
    half3 specBRDF;
    
    #ifdef  _SDF_ON
    half d = (_SDFValue + 1) * 0.5;
    //return 1;
    half NoL = SDF(_LocalData.sdf, d);
    half specLobe = SDFHighLight(_LocalData.sdf, d);
    specBRDF = (specLobe * 2 + NoL) * sd.diffuse;
    light = (specBRDF * _SpecColor + diffBRDF)  * pd.lightCol;
    #else
    
    specBRDF = CookTorranceBRDF(pd, sd);
    half NPRnol = NPRNol(pd.Nol);
    
    light = (specBRDF * _SpecColor * NPRnol + diffBRDF * NPRnol)  * pd.lightCol;
    #endif
    light *= pd.atten;
    float3 rimLight = ToonRimLight(pd.N, pd.V, _RimPower) * _RimColor;
    light += rimLight;

    
    return light;
}

half3 CalculateIndirectLight(CustomSurfaceData sd, PBRData pd, v2f i)
{
    half3 light = half3(0, 0, 0);
    float3 indirectSpecColor = getPrefilterSpecularLD(_EnvMap, 6, (0, 0, 0,0), pd.N, pd.V, sd.linearRoughness);
    float3 indirectSpec = evalIndirectSpecular(pd.Nov, indirectSpecColor, sd.linearRoughness, 1) * sd.specular * _EnvColor;
    light += indirectSpec * _EnvColor;
    float indirectDiffuse = SampleSHPixel(_LocalData.vertexSH, pd.N) * sd.diffuse;
    light += indirectDiffuse;
    return light;
}

