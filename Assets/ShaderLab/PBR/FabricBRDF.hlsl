#include "Assets/ShaderLab/PBR/PBR.hlsl"
#define  M_INV_TWO_PI (0.15915494) // 1 / (2 * PI)
#define  M_PI (3.14159265)
// Ref: https://knarkowicz.wordpress.com/2018/01/04/cloth-shading/
half D_Charlie(half alpha, half NoH)
{
    half invR = 1.0 / alpha;
    half cos2h = NoH * NoH;
    half sin2h = 1.0 - cos2h;
    return (2.0 + invR) * pow(sin2h, invR * 0.5) * M_INV_TWO_PI;
}

half Gvis_Ashikhmin(half NdotL, half NdotV)
{
    // Use soft visibility term introduce in: Crafting a Next-Gen Material Pipeline for The Order : 1886
    return 1.0 / max((4.0 * (NdotL + NdotV - NdotL * NdotV)), 0.04);
}

half3 FabricBRDF(PBRData pd, CustomSurfaceData sd)
{
    half3 N = pd.N;
    half3 V = pd.V;
    half3 L = pd.L;
    half3 H = normalize(V + L);

    half NdotL = max(dot(N, L), 0.0);
    half NdotV = max(dot(N, V), 0.0);
    half NdotH = max(dot(N, H), 0.0);
    half HdotV = max(dot(H, V), 0.0);

    // Albedo and roughness
    half roughness = sd.linearRoughness;
    
    half3 F = fresnelSchlick(HdotV, sd.specular);


    // Distribution term
    half D = D_Charlie(roughness * roughness, NdotH);
    
    // Visibility term
    half G = Gvis_Ashikhmin(NdotL, NdotV);

    // Specular BRDF
    float3 nominator = D * G * F;
    float denominator = max(4.0 * NdotV * NdotL, 0.001);
    half3 specular = nominator;

    return specular;
}



