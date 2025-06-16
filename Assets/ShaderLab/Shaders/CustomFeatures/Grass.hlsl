//一个UnlitShader的hlsl
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
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

struct appdataUnlit
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;

    uint instanceID : SV_InstanceID;
    
};

v2f VertexFunc(v2f v, appdataUnlit i);
v2f VertexFunc(v2f v, appdataUnlit i)
{
    //v.vertex += 1;
    return v;
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

v2f vert_unlit (appdataUnlit v, uint vertexID : SV_VertexID)
{
    v2f o;
    UNITY_SETUP_INSTANCE_ID(v);
    o.vertexID = vertexID;
    VertexPositionInputs positionInput = GetVertexPositionInputs(v.vertex);
    o.vertex = positionInput.positionCS;
    o.positionWS = positionInput.positionWS;
    o.uv = v.uv;
    VertexNormalInputs normalInput = GetVertexNormalInputs(v.normal, v.tangent);
    o.normal.xyz = normalInput.normalWS;
    o.tangent.xyz = normalInput.tangentWS;
    o.binormal.xyz = normalInput.bitangentWS;
    o.screenPos = ComputeScreenPos(o.vertex);
    o = VertexFunc(o, v);

    return o;
}

half4 frag_unlit(v2f i) : SV_Target
{
    half4 col;
    half4 baseColor = GetBaseColor(i.uv);
    col = baseColor;
    col.xyz = (half)i.vertexID / 24.0;
    
    return col;
}






