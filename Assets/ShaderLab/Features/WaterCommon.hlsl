TEXTURE2D(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);
//Caustics Value
float _WaterLevel;
float _CausticsOffset;
float _CausticsScale;
float4 _CausticsColor;
float _CausticsBlendDistance;

TEXTURE2D(_CausticsMap);
SAMPLER(sampler_CausticsMap);

float4 CustomSampleSceneDepth(float2 uv)
{
    return SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture, sampler_CameraDepthTexture,UnityStereoTransformScreenSpaceTex(uv),1.0).r;
}

float GetDepthFade(float3 WorldPos, float Distance, float4 screenUV)
{
    float EyeDepth = LinearEyeDepth(CustomSampleSceneDepth(screenUV),_ZBufferParams);
    return saturate((EyeDepth - screenUV.a)/Distance);
}

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
    caustics *= _CausticsColor;
    caustics *= 1 - saturate(max(upperMask, lowerMask));
    return caustics;
                    
}

half3 Caustics(half2 screenUv)
{
    float depth = CustomSampleSceneDepth(screenUv);
    float3 worldPos = RecoustructWorldPos(screenUv, depth);
    return Caustics(worldPos);
}