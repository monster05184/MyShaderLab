//一个UnlitShader的hlsl
#include "Assets/ShaderLab/UnlitCommon.hlsl"


struct appdataUnlit
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
};

float3 _P0;
float3 _P1;
float3 _P2;
float3 _Root;


float3 Bezier(float3 p0, float3 p1, float3 p2, float t)
{
    return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
}

float3 BendGrass(float3 positionOS)
{
    positionOS *= (50, 6, 100);
    float3 T = float3(positionOS.x, 0, 0);
    
    float t = (positionOS.x - _Root.x); 

    
    float3 bendPos = Bezier(_P0, _P1, _P2, t);

    positionOS += bendPos - T;
    positionOS /= (50, 6, 100);
    

    
    return positionOS;
}

v2f VertexFunc(v2f v, appdataUnlit i);
v2f VertexFunc(v2f v, appdataUnlit i)
{
    i.vertex.xyz = BendGrass(i.vertex.xyz);
    //Debug(i.vertex.x * 100, v.debugColor);
    v.debugColor = i.vertex.x;
    VertexPositionInputs positionInput = GetVertexPositionInputs(i.vertex);
    v.vertex = positionInput.positionCS;
    v.positionWS = positionInput.positionWS;
    v.uv = v.uv;
    VertexNormalInputs normalInput = GetVertexNormalInputs(i.normal, i.tangent);
    v.normal.xyz = normalInput.normalWS;
    v.tangent.xyz = normalInput.tangentWS;
    v.binormal.xyz = normalInput.bitangentWS;
    v.screenPos = ComputeScreenPos(v.vertex);
    return v;
}



v2f vert_unlit (appdataUnlit v)
{
    v2f o;

    o = VertexFunc(o, v);

    return o;
}

half4 frag_unlit(v2f i) : SV_Target
{
    half4 col;
    half4 baseColor = GetBaseColor(i.uv);
    col = baseColor;

    


    return finalOutput(col, i);
}






