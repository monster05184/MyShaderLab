 half _Bias = 0.001;
half4 DualParaboloidMap(float3 viewDir, float3 normalWS, sampler2D _Front, sampler2D _Back)
{
    float3 R = reflect(viewDir, normalWS);
    //half3 gi_specColor = GI_IBL_Lite(specColor, roughness, R) * ao;
    half3 TexColor;
    R = R.xzy;
    R.x = -R.x;
    if (R.z > 0)
    {
        float2 frontUV = R.xy / (R.z + 1 + _Bias);
        frontUV.xy = -0.5 * frontUV.xy + 0.5; 
        //float level = EnvLODLevel(roughness);
        //gi_specColor =  tex2Dlod(_FrontDualParaboloidMap, float4(frontUV.xy, 0, level)) * specColor * _RealtimeGISpecularColor * ao;
        TexColor =  tex2D(_Front, frontUV) ;
    }
    else 
    {
        float2 backUV = R.xy / (1.0 - R.z + _Bias);
        backUV.xy = -0.5 * backUV.xy + 0.5;
        //float level = EnvLODLevel(roughness);
        //gi_specColor =  tex2Dlod(_BackDualParaboloidMap, float4(backUV.xy, 0, level)) * specColor * _RealtimeGISpecularColor * ao;
        TexColor =  tex2D(_Back, backUV);
    }
    return half4(TexColor.rgb, 1.0);
}

half4 DualParaboloidMapUp(float3 viewDir, float3 normalWS, sampler2D _Front)
{
    float3 R = normalize(reflect(-viewDir, normalWS));
    R = R.xzy;  
    R.x = -R.x;
    float2 frontUV = R.xy / (R.z + 1.02); // bias = 0.02
    frontUV.xy = -0.5 * frontUV.xy + 0.5;
    return tex2D(_Front, frontUV); // Convert to range [-1, 1]
}

