//一个UnlitShader的hlsl

#include "Assets/ShaderLab/UnlitCommon.hlsl"


struct appdataUnlit
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;

    uint instanceID : SV_InstanceID;
    
};

float3 _P0;
float3 _P1;
float3 _P2;
float3 _Root;
float _Height;

float3 Bezier(float3 p0, float3 p1, float3 p2, float t)
{
    return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
}

float3 BendGrass(float3 positionOS)
{
    float3 T = float3(0, positionOS.y, 0);
    
    float t = (positionOS.y - _Root.y); 

    
    float3 bendPos = Bezier(_P0, _P1, _P2, t);

    positionOS += bendPos - T;
    

    
    return positionOS;
}


v2f VertexFunc(v2f v, appdataUnlit i);
v2f VertexFunc(v2f v, appdataUnlit i)
{
    //i.vertex.xyz = BendGrass(i.vertex.xyz);
    VertexPositionInputs positionInput = GetVertexPositionInputs(i.vertex);
    v.vertex = positionInput.positionCS;
    v.positionWS = positionInput.positionWS;
    v.uv = v.uv;
    VertexNormalInputs normalInput = GetVertexNormalInputs(i.normal, i.tangent);
    v.normal.xyz = normalInput.normalWS;
    v.tangent.xyz = normalInput.tangentWS;
    v.binormal.xyz = normalInput.bitangentWS;
    v.screenPos = ComputeScreenPos(i.vertex);
    
    v.vertex += 1;
    return v;
}




v2f vert_unlit (appdataUnlit v, uint vertexID : SV_VertexID)
{
    v2f o;
    UNITY_SETUP_INSTANCE_ID(v);
    o.vertexID = vertexID;
    
    o = VertexFunc(o, v);

    return o;
}



half4 frag_unlit(v2f i) : SV_Target
{
    half4 col;
    half4 baseColor = GetBaseColor(i.uv);
    col = baseColor;
    col.xyz = (half)i.vertexID / 24.0;

    float bezier = Bezier(_P0, _P1, _P2, 1).z;
    DebugNumber(bezier, i.uv);
    

    
    return finalOutput(col, i);
}






