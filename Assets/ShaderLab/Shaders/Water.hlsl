#include "Assets/ShaderLab/ShaderCommon.hlsl"
#include "Assets/ShaderLab/PBR/PBR.hlsl"
half _MetallicMultiplier;
half _RoughnessMultiplier;

float _Depth;
float _DetailNormalScale;
float _DetailNormalIntensity;
float _DetailNormalFlowX;
float _DetailNormalFlowY;

float _FresnelScale;
float _Metallic;
half4 _OceanDeepColor;
half4 _OceanShoalColor;
float _Gloss;
half4 _SpecularColor;
float _SpecularScale;

float _AirRefractiveIndex;
float _WaterRefractiveIndex;
float _RefrectionDistortion;
float _OceanOpacity;
half4 _SSSColor;
float _SSSScale;
float _SSSPower;
float _SSSDistortion;

//Caustics Value
float _WaterLevel;
float _CausticsOffset;
float _CausticsScale;
float _CausticsIntensity;
float _CausticsBlendDistance;

//Foam Value
float _BubbleScale;
float4 _FoamColor;
float _FoamParallax;
float _FoamFeather;

//屏幕深度贴图
TEXTURE2D(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);
//置换贴图
TEXTURE2D(_Displace);
SAMPLER(sampler_Displace);
//法线贴图
TEXTURE2D(_Normal);
SAMPLER(sampler_Normal);
//浮沫强度贴图
TEXTURE2D(_Bubble);
SAMPLER(sampler_Bubble);
//浮沫样式贴图
TEXTURE2D(_BubbleTexture);
SAMPLER(sampler_BubbleTexture);
//焦散贴图
TEXTURE2D(_CausticsMap);
SAMPLER(sampler_CausticsMap);
//细节法线贴图
TEXTURE2D(_DetailNormal);
SAMPLER(sampler_DetailNormal);
//吸收散射贴图
TEXTURE2D(_AbsorptionScatteringTexture);
SAMPLER(sampler_AbsorptionScatteringTexture);
//Opaque贴图
TEXTURE2D(_CameraOpaqueTexture);
SAMPLER(sampler_CameraOpaqueTexture);

float3 SampleSceneColor(float2 uv)
{
    return SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, UnityStereoTransformScreenSpaceTex(uv)).rgb;
}

float3 LoadSceneColor(uint2 uv)
{
    return LOAD_TEXTURE2D_X(_CameraOpaqueTexture, uv).rgb;
}


struct LocalData1
{
    float depthFade;
    float3 underWaterColor;
    float3 causticsColor;
};

LocalData1 _LocalData;


/*****计算水的深度*****/
float4 ComputeScreenPos(float4 pos, float projectionSign){
    float4 o = pos * 0.5f;
    o.xy = float2(o.x,o.y * projectionSign) + o.w;
    o.zw = pos.zw;
    return o;
}

float4 CustomSampleSceneDepth(float2 uv)
{
    return SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture,sampler_CameraDepthTexture,UnityStereoTransformScreenSpaceTex(uv),1.0).r;
            
}
float GetDepthFade(float3 WorldPos, float Distance)
{
    float4 ScreenPosition = ComputeScreenPos(TransformWorldToHClip(WorldPos),_ProjectionParams.x);
    float EyeDepth = LinearEyeDepth(CustomSampleSceneDepth(ScreenPosition.xy/ScreenPosition.w),_ZBufferParams);
    return saturate((EyeDepth - ScreenPosition.a)/Distance);
} 
/*****计算水的深度*****/

//FresnelSchlick
float FresnelSchlick(float HdotL)
{
    float fresnel = exp2((-5.55473 * HdotL - 6.98316) * HdotL);
    return lerp(fresnel, 1.0, _FresnelScale);
}
//SSS
float4 SSSColor(float3 lightDir, float3 viewDir, float3 normal, float waveHeight, float SSSMask){
    float3 H = normalize(-lightDir + normal * _SSSDistortion);
    float I = pow(saturate(dot(viewDir, -H)), _SSSPower)* _SSSScale * waveHeight * SSSMask;
    return _SSSColor*I;
}
//-----------------------SceneColor Refecation--------------------------//

float2 DistortionUVs(half depth, float3 normalWS)
{
    half3 viewNormal = mul((float3x3)GetWorldToHClipMatrix(), -normalWS).xyz;
    return viewNormal.xz * saturate(depth) * 5;
}

//------------------------------Caustics---------------------------------//
float3 RecoustructWorldPos(half2 screenPos, float depth)
{
    screenPos.y = 1 - screenPos.y;
    #if defined(SHADER_API_GLCORE) || defined (SHADER_API_GLES) || defined (SHADER_API_GLES3)			// OpenGL平台 //
        depth = depth * 2 - 1;
    #endif
    float4 raw = mul(UNITY_MATRIX_I_VP, float4(screenPos*2 - 1, depth, 1));
    float3 worldPos = raw.rgb / raw.a;
    return worldPos;
}

float2 CausticsUVs(float2 rawUV, float2 offset)
{
    float2 uv = rawUV * _CausticsScale + float2(_Time.y, _Time.y) * 0.1;
    return uv + offset * 0.25;
}
half3 Caustics(float3 worldPos)
{
    float blendDistance = 5 * _CausticsBlendDistance;
    float2 casusticsUV = CausticsUVs(worldPos.xz, float2(0, 0));
    half upperMask = (-worldPos.y + _WaterLevel + _CausticsOffset) / blendDistance;
    half lowerMask = (worldPos.y - _WaterLevel - _CausticsOffset) / blendDistance;
    float3 caustics = SAMPLE_TEXTURE2D_LOD(_CausticsMap, sampler_CausticsMap, casusticsUV, abs(worldPos.y - _WaterLevel - _CausticsOffset)/blendDistance).xyz;
    caustics *= _CausticsIntensity;
    caustics *= 1 - saturate(max(upperMask, lowerMask));
    return caustics;
    
}


half3 Caustics(float2 screenUV, float depth)
{
    float3 worldPos = RecoustructWorldPos(screenUV, depth);
    return Caustics(worldPos);
}

//-----------------------Caustics-------------------------------//

//-------------------------Foam---------------------------------//
struct FoamWorldXZ
{
    float2 displacedXZ;
    float2 undisplacedXZ;
};
float WhiteFoam(FoamWorldXZ worldPosXZ, float bubble, float height)
{
    float2 foamUV = worldPosXZ.undisplacedXZ / _BubbleScale;
    float foam = SAMPLE_TEXTURE2D(_BubbleTexture, sampler_BubbleTexture, foamUV).r;
    bubble = saturate(1 - bubble);
    
    return smoothstep(bubble, bubble + _FoamFeather, foam) * saturate(height * 4);
}

float4 ApplyFoam(FoamWorldXZ worldPosXZ, float bubble, float3 viewVector, float3 normal, float height)
{
    float4 whiteFoamCol;
    float whiteFoam = WhiteFoam(worldPosXZ, bubble, height);
    whiteFoamCol.rgb = _FoamColor;
    whiteFoamCol.rgb *= whiteFoam;
    whiteFoamCol.a = whiteFoam;
    return whiteFoamCol;
    
}
//-------------------------Foam---------------------------------//
//-------------------------Lighting-----------------------------//
float Absorption(float depth)
{
    return SAMPLE_TEXTURE2D(_AbsorptionScatteringTexture, sampler_AbsorptionScatteringTexture, float2(depth, 0.0));
}
float Scattering(float depth)
{
    return SAMPLE_TEXTURE2D(_AbsorptionScatteringTexture, sampler_AbsorptionScatteringTexture, float2(depth, 0.375));
}

//-------------------------Lighting-----------------------------//
// Unpack normal as DXT5nm (1, y, 0, x) or BC5 (x, y, 0, 1)
float3 UnpackNormal_Scale(float4 packedNormal, float Scale)
{
    //Convert to (?, y, 0, x)
    packedNormal.a *= packedNormal.r;
    float3 normal;
    normal.xy = (packedNormal.ag * 2.0 - 1.0) * Scale;
    normal.z = max(1.0e-16, sqrt(1.0 - saturate(dot(normal.xy, normal.xy))));
    return normal; 
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

    float2 detailNormalUV = i.uv * _DetailNormalScale * 5 + float2(_DetailNormalFlowX, _DetailNormalFlowY) * _Time.y;
    float3 detailNormalTS = (SAMPLE_TEXTURE2D(_DetailNormal, sampler_DetailNormal, detailNormalUV));

    sd.normalTS = BlendNormalRNM(sd.normalTS, detailNormalTS);
}
void PostSurfaceData(inout CustomSurfaceData sd, PBRData pd, v2f i)
{

    
    float rawDepth = SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture,sampler_CameraDepthTexture, pd.screenUv,1.0).r;
    //水深的计算
    float depthfade = GetDepthFade(pd.posWS, _Depth);
    //水的折射和扭曲
    float2 distortion = DistortionUVs(depthfade, pd.N);
    float2 distortedScreenUV = pd.screenUv + distortion;
                  
    //焦散的计算
    float3 caustics = Caustics(distortedScreenUV, rawDepth);
    //水底的图片
    half4 texUnderWater = SAMPLE_TEXTURE2D(_CameraOpaqueTexture,sampler_CameraOpaqueTexture, i.uv);
    texUnderWater.xyz = SampleSceneColor(distortedScreenUV);
    _LocalData.depthFade = depthfade;
    _LocalData.causticsColor = caustics;
    //Debug(caustics);
    _LocalData.underWaterColor = texUnderWater.xyz;
    
    
}

half3 CalculateMainLight(CustomSurfaceData sd, PBRData pd)
{
    half3 light = half3(0, 0, 0);

    //----------------光线计算-----------------------//
                    
    float fresnel = FresnelSchlick(pd.Nov);
                    
    //采样反射探针或者是天空盒
    float3 reflectDir = reflect(normalize(-pd.V), pd.N);
    half4 rgbm = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,samplerunity_SpecCube0, reflectDir, 1);
    half3 sky = DecodeHDREnvironment(rgbm,unity_SpecCube0_HDR);

    float3 reflectColor = lerp(0.04,sky,_Metallic);
        
    //反射部分
    float3 oceanColor = lerp(_OceanShoalColor,_OceanDeepColor,_LocalData.depthFade);
    //Debug(oceanColor);
    float OpacityControl = clamp(_LocalData.depthFade*_OceanOpacity, 0, 1);
    oceanColor = lerp(_LocalData.underWaterColor + _LocalData.causticsColor, oceanColor, OpacityControl);
    Debug(_LocalData.causticsColor);
    oceanColor = lerp(reflectColor, oceanColor, saturate(1 - fresnel));
    //oceanColor = lerp(oceanColor, foamColor, foamColor.a);
    //Debug(_LocalData.depthFade);

    half3 brdf = CookTorranceBRDF(pd, sd);
    pd.atten = 1;
    float specular = brdf * pd.lightCol * pd.atten;
    specular = 0;

    float3 sss = SSSColor(pd.L, pd.V, pd.N, 1, 1);
    light = oceanColor + specular + sss;
    return light;
}