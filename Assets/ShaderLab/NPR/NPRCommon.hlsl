half _NolSmooth;
sampler2D _RampTex;
half NPRNol(half Nol)
{
    return smoothstep(0, _NolSmooth, Nol);
}
half3 NPRRamp(half Nol, float smooth)
{
    float2 uv = float2(Nol, smooth);
    half4 ramp = tex2D(_RampTex, uv).rgba;
    return ramp.rgb * ramp.a;
}
half3 NPRRamp(half Nol)
{
    Nol = min(0.98, Nol);
    float2 uv = float2(Nol, 0);
    half4 ramp = tex2D(_RampTex, uv).rgba;
    return ramp.rgb * ramp.a;
}
half3 _RimColor;
half _RimPower;
half3 ToonRimLight(half3 normal, half3 viewDir, half rimPower)
{
    half3 rim = pow(1 - max(0, dot(normal, viewDir)), rimPower);
    rim = smoothstep(0.5, 0.7, rim);
    return rim;
}