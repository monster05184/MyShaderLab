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
    half3 ramp;
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
    sd.baseColor = albedo;
    sd.specular = lerp(0.04f, albedo.rgb, metallic);
    sd.diffuse = albedo * (1 - metallic);
    sd.emissive = GetEmissive(i.uv);
    sd.normalTS = normalTS;
    sd.opacity = albedo.a;
    sd.linearRoughness = materialParams.x * _RoughnessMultiplier;
    sd.metallic = metallic;
    sd.occlusion = materialParams.z;
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
    half fullNol  = dot(pd.N, pd.L);
    fullNol = fullNol * 0.5 + 0.5;
    half3 ramp = NPRRamp(fullNol);
    _LocalData.ramp = ramp;

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
    half3 NPRnol = NPRNol(pd.Nol);
    #ifdef _RAMP_ON
    NPRnol = _LocalData.ramp;
    #endif
    
    light = (specBRDF * _SpecColor * NPRnol + diffBRDF * NPRnol)  * pd.lightCol;
    #endif
    //Debug(NPRnol);
    
    light *= pd.atten;
    

    
    return light;
}

half3 CalculateIndirectLight(CustomSurfaceData sd, PBRData pd, v2f i)
{
    half3 light = half3(0, 0, 0);
    //indirect specular
    float3 indirectSpecColor = getPrefilterSpecularLD(_EnvMap, 6, (0, 0, 0,0), pd.N, pd.V, sd.linearRoughness);
    int indirectSpecAO = lerp(0.7, 1, sd.occlusion);
    float3 indirectSpec = evalIndirectSpecular(pd.Nov, indirectSpecColor, sd.linearRoughness, 1) * sd.specular * _EnvColor;
    indirectSpec *= indirectSpecAO;
    light += indirectSpec * _EnvColor;

    //indirect diffuse
    float indirectDiffuse = SampleSHPixel(_LocalData.vertexSH, pd.N) * sd.diffuse;
    indirectDiffuse *= sd.occlusion;
    light += indirectDiffuse;
    return light;
}

