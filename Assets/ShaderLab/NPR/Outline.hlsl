struct Attributes_Outline
{
    float4 posOS : POSITION;
    float2 texcoord : TEXCOORD0;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float4 color : COLOR;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings_Outline
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float4 color : COLOR;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

float4 _OutlineColor;
float _OutlineWidth;

sampler2D _AlbedoMap;
float4 _AlbedoMap_ST;
half4 GetAlbedo(float2 uv)
{
    float2 albedoUV = uv * _AlbedoMap_ST.xy + _AlbedoMap_ST.zw;
    return tex2D(_AlbedoMap, albedoUV);
}

float3 OctahedronToUnitVector(float2 Oct)
{
    float3 N = float3(Oct, 1 - dot(1, abs(Oct)));
    if (N.z < 0)
    {
        N.xy = (1 - abs(N.yx)) * (N.xy >= 0 ? float2(1, 1) : float2(-1, -1));
    }
    return normalize(N);
}

float3 TransformTBN(float2 bakedNormal, float3x3 tbn)
{
    float3 normal = OctahedronToUnitVector(bakedNormal);
    return  (mul(normal, tbn));
}
Varyings_Outline vert_outline(Attributes_Outline input)
{
    Varyings_Outline output = (Varyings_Outline)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    #if _OUTLINE
        VertexPositionInputs vertexInput = GetVertexPositionInputs(input.posOS.xyz);
        float4 positionCS = vertexInput.positionCS;
        float3 normalOS = normalize(input.normalOS);
        #if _SMOOTHEDNORMAL
            float3 tangentOS = input.tangentOS;
            tangentOS = normalize(tangentOS);
            float3 bitangentOS = normalize(cross(normalOS, tangentOS) * input.tangentOS.w);
            float3x3 tbn = float3x3(tangentOS, bitangentOS, normalOS);
            float3 smoothedNormal = (TransformTBN(input.smoothedNormal, tbn));
            normalOS = smoothedNormal;
        #endif
            float Set_OutlineWidth = positionCS.w * _OutlineWidth;
            Set_OutlineWidth = min(Set_OutlineWidth, _OutlineWidth);
            Set_OutlineWidth *= _OutlineWidth;
            Set_OutlineWidth = min(Set_OutlineWidth, _OutlineWidth) * 0.01;
        #if _OUTLINEWIDTHWITHVERTEXTCOLORA
            Set_OutlineWidth *= input.color.a;
        #elif _OUTLINEWIDTHWITHUV8A
            Set_OutlineWidth *= input.smoothedNormal.a;
        #endif
        //output.positionCS = PerspectiveRemove(output.positionCS, vertexInput.positionWS, input.posOS);
        output.positionCS = TransformObjectToHClip(input.posOS + normalOS * Set_OutlineWidth);
        
        //output.positionCS = positionCS;
        

        output.color = input.color;
        output.uv = input.texcoord;
    #endif
    return output;
}

half4 frag_outline(Varyings_Outline input) : SV_Target
{
    return _OutlineColor;

}



