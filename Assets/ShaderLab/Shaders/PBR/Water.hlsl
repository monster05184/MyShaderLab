#include "Assets/ShaderLab/ShaderCommon.hlsl"
#include "Assets/ShaderLab/PBR/PBR.hlsl"
#include "Assets/ShaderLab/Features/DualParaboloidMap.hlsl"
#include "Assets/ShaderLab/Features/WaterCommon.hlsl"
half _MetallicMultiplier;
half _RoughnessMultiplier;
half _AOMultiplier;
half _WaterDepth;

sampler2D _ReflectionMap;
half4 _ReflectionColor;

TEXTURE2D(_AbsorptionRamp);
SAMPLER(sampler_AbsorptionRamp);

struct LocalData1
{
    
};

LocalData1 _LocalData;

v2f VertexFunc(v2f i, appdataPBR v)
{
    return i;
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
}
void PostSurfaceData(inout CustomSurfaceData sd, PBRData pd, v2f i)
{
    
}

half3 GetReflectionColor(float3 ViewDir, float3 Normal)
{
    float3 reflectionColor = DualParaboloidMapUp(ViewDir, Normal, _ReflectionMap);
    reflectionColor *= _ReflectionColor.rgb * _ReflectionColor.a;
    return reflectionColor;
}

half3 GetRefractionColor()
{

}

half4 Absorption(half height)
{
    half4 absorptionColor = SAMPLE_TEXTURE2D(_AbsorptionRamp, sampler_AbsorptionRamp, float2(height, 0));
    return absorptionColor;   
}

half4 GetHeight(float3 position)
{
    // Assuming the height is stored in the y component of the position
    return half4(position.y, 0, 0, 0);
}

half3 CalculateMainLight(CustomSurfaceData sd, PBRData pd, v2f i)
{
    half3 light = half3(0, 0, 0);
    half3 specbrdf = CookTorranceBRDF(pd, sd);

    float3 diffBRDF = diffuseBRDF(sd.diffuse);

    

    //float3 refractionColor = GetRefractionColor(pd.V, pd.N);

    float3 reflectionColor = GetReflectionColor(pd.V, pd.N);
    Debug(Caustics(pd.screenUv.xy));
    
    light = (specbrdf + diffBRDF) * pd.Nol * pd.lightCol;
    
    return light;
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
    light += indirectSpec * _EnvColor;

    //indirect diffuse
    float3 indirectDiffuse = SampleSHPixel(i.vertexSH, pd.N) * sd.diffuse;
    indirectDiffuse *= occlusion;
    light += indirectDiffuse;
    return light;
}