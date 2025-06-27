#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Assets/ShaderLab/Debug.hlsl"

struct v2f
{
    float2 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
    
    //TBN
    float3 normal : TEXCOORD1;
    float3 tangent : TEXCOORD2;
    float3 binormal : TEXCOORD3;

    float3 positionWS : TEXCOORD4;
    float4 screenPos : TEXCOORD5;

    float3 vertexLight : TEXCOORD6;

    float3 vertexSH    : TEXCOORD7;

    #ifdef DEBUG
    float4 debugColor  : TEXCOORD8;
    #endif
    float4 shadowCoord : TEXCOORD9;
    uint vertexID : TEXCOORD10;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    
};



half4 finalOutput(half4 color, v2f i)
{
    #ifdef DEBUG
    if(length(i.debugColor.xyz) > 0)
    {
        return DebugOut(i.debugColor);
    }else
    {
        return DebugOut(color);
    }
    #endif
    return color;
}



TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
float4 _BaseMap_ST;
half4 _BaseColor;

half4 GetBaseColor(float2 uv)
{
    float2 baseUV = uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
    return SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV) * _BaseColor;
}
