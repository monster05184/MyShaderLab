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

TEXTURE2D(_AbsorptionRamp2);
SAMPLER(sampler_AbsorptionRamp2);

TEXTURE2D(_CameraOpaqueTexture);
SAMPLER(sampler_CameraOpaqueTexture);

TEXTURE2D(_FoamMap);
SAMPLER(sampler_FoamMap);

half2 _NormalFlow;

struct LocalData1
{
    
};

LocalData1 _LocalData;

v2f VertexFunc(v2f i, appdataPBR v)
{
    return i;
}

float2 Flow(float2 uv, float2 flow)
{
    return uv + frac(flow * _Time.y * 0.1);
}

void PrepareSurfaceData(inout CustomSurfaceData sd, v2f i)
{
    _LocalData = (LocalData1)0;
    half4 normalTS = GetNormalTS(Flow(i.uv, _NormalFlow));
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

half3 GetRefractionColor(float2 screenUV)
{
    half3 refractionColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV).rgb;
    half3 causticsColor = Caustics(screenUV);
    refractionColor *= 1 + causticsColor;
    return refractionColor;
}

half4 Absorption(half height)
{
    half4 absorptionColor = SAMPLE_TEXTURE2D(_AbsorptionRamp, sampler_AbsorptionRamp, float2(height, 0));
    return absorptionColor;   
}
half _FoamDistance;
half3 CalculateMainLight(CustomSurfaceData sd, PBRData pd, v2f i)
{
    half3 light = half3(0, 0, 0);
    half3 specbrdf = CookTorranceBRDF(pd, sd);

    float3 diffBRDF = diffuseBRDF(sd.diffuse);

    

    //float3 refractionColor = GetRefractionColor(pd.V, pd.N);

    half depth = GetDepthFade(pd.posWS, _WaterDepth, pd.screenUv);

    half distortion = DistortionUVs(depth, pd.N);

    float3 reflectionColor = GetReflectionColor(pd.V, pd.N);

    float3 refractionColor = GetRefractionColor(pd.screenUv + distortion);

    float4 ramp = Absorption(depth);

    refractionColor = lerp(ramp.rgb, refractionColor, ramp.a);

    half sdf = SAMPLE_TEXTURE2D(_FoamMap, sampler_FoamMap, i.uv).r;

    sdf = sdf > _FoamDistance ? 1 : 0;

    //Debug(sdf);
    
    light = refractionColor + reflectionColor;
    
    return light;
}

half3 CalculateIndirectLight(CustomSurfaceData sd, PBRData pd, v2f i)
{
    half3 light = half3(0, 0, 0);
    //occusion
    // half occlusion = lerp(1, sd.occlusion, _AOMultiplier);
    // half indirectSpecAO = lerp(0.7, 1, occlusion);
    //
    // //indirect specular
    // float3 indirectSpecColor = getPrefilterSpecularLD(_EnvMap, 6, (0, 0, 0,0), pd.N, pd.V, sd.linearRoughness);
    // float3 indirectSpec = evalIndirectSpecular(pd.Nov, indirectSpecColor, sd.linearRoughness, 1) * sd.specular * _EnvColor;
    // indirectSpec *= indirectSpecAO;
    // light += indirectSpec * _EnvColor;
    //
    // //indirect diffuse
    // float3 indirectDiffuse = SampleSHPixel(i.vertexSH, pd.N) * sd.diffuse;
    // indirectDiffuse *= occlusion;
    // light += indirectDiffuse;
    return light;
}