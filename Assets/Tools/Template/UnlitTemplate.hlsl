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
    
};

struct appdataUnlit
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
};

v2f VertexFunc(v2f v, appdataUnlit i);
v2f VertexFunc(v2f v, appdataUnlit i)
{
    //v.vertex += 1;
    return v;
}

v2f vert_unlit (appdataUnlit v)
{
    v2f o;
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
    col = 1;
    return col;
}






