float DistributionGGX(float NdotH, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH2 = NdotH * NdotH;
    
    float nom = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;
    
    return nom / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness) {
    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;

    float nom = NdotV;
    float denom = NdotV * (1.0 - k) + k;
    
    return nom / denom;
}

float GeometrySmith(float NdotV, float NdotL, float roughness) {
    float ggx1 = GeometrySchlickGGX(NdotV, roughness);
    float ggx2 = GeometrySchlickGGX(NdotL, roughness);
    
    return ggx1 * ggx2;
}

float3 fresnelSchlick(float cosTheta, float3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

float3 CookTorranceBRDF(float3 N, float3 V, float3 L, float3 albedo, float metallic, float roughness) {
    float3 H = normalize(V + L);
    
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float NdotH = max(dot(N, H), 0.0);
    float HdotV = max(dot(H, V), 0.0);
    
    // 基础反射率 (F0) - 绝缘体使用0.04，金属使用albedo
    float3 F0 = lerp(0.04, albedo, metallic);
    
    // 计算各分量
    float D = DistributionGGX(NdotH, roughness);
    float3 F = fresnelSchlick(HdotV, F0);
    float G = GeometrySmith(NdotV, NdotL, roughness);
    
    // 组合Cook-Torrance BRDF
    float3 nominator = D * G * F;
    float denominator = 4.0 * NdotV * NdotL;
    float3 specular = nominator / max(denominator, 0.001);
    specular = max(specular, 0);
    
    // 漫反射部分 (金属没有漫反射)
    float3 kD = (1.0 - metallic);
    
    // 最终结果
    return (specular) * NdotL;
}

//Disney diffuse
float3 DisneyDiffuse(float3 N, float3 L, float3 albedo) {
    float3 diffuse = albedo / PI;
    return diffuse * max(dot(N, L), 0.0);
}


float3 CookTorranceBRDF(PBRData pd, CustomSurfaceData sd)
{
    return CookTorranceBRDF(pd.N, pd.V, pd.H, sd.diffuse, sd.metallic, sd.linearRoughness);
}

//--------------------Anisotropic---------------------
half sqr(half a)
{
    return a * a;
}
float Gvis_GGX_Anisotropic(half NdotV, half TdotV, half BdotV, 
                           half NdotL, half TdotL, half BdotL,
                           half at, half ab)
{
    float G_V = (NdotV + sqrt(sqr(TdotV*at) + sqr(BdotV*ab) + sqr(NdotV)));
    float G_L = (NdotL + sqrt(sqr(TdotL*at) + sqr(BdotL*ab) + sqr(NdotL)));
    return 1.0 / ( G_V * G_L );
}
#define UNITY_PI 3.1415926
half NDF_GGX_Anisotropic(half at, half ab, half NdotH, half TdotH, half BdotH)
{
    // D = 1 / (M_PI * at * ab * cosTheta^4 * (1 + tanTheta^2 * (cosPhi^2 / at^2 + sinPhi^2 / ab^2))^2)
    //   = 1 / (M_PI * at * ab * (cosTheta^2 + sinTheta^2 * (cosPhi^2 / at^2 + sinPhi^2 / ab^2))^2)
    //   = 1 / (M_PI * at * ab * (cosTheta^2 + (sinTheta * cosPhi / at)^2 + (sinTheta * sinPhi / ab)^2)^2)
    // plugin into following variable NdotH = cosTheta, TdotH = sinTheta * cosPhi, BdotH = sinTheta * sinPhi we got
    // D = 1 / (M_PI * at * ab * (NdotH^2 + (TdotH / at)^2 + (BdotH / ab)^2)^2)
    //   = (at * ab)^3 / (M_PI * (at * ab)^4 * (NdotH^2 + (TdotH / at)^2 + (BdotH / ab)^2)^2)
    //   = (at * ab)^3 / (M_PI * ((NdotH * at * ab)^2 + (TdotH * ab)^2 + (BdotH * at)^2)^2)
    // let a2 = at * ab
    // D = a2^3 / (M_PI * ((NdotH * a2)^2 + (TdotH * ab)^2 + (BdotH * at)^2)^2)
    float a2 = at * ab;
    float3 d = float3(a2 * NdotH, ab * TdotH, at * BdotH);
    float d2 = dot(d, d);
    half b2 = a2 / d2;
    return a2 * b2 * b2 * (1.0 / UNITY_PI);
}
#define MIN_GGX_ALPHA           0.002025
void getAnisotropicAlpha(half alpha, half anisotropic, out half at, out half ab)
{
    // Kulla 2017, "Revisiting Physically Based Shading At Imageworks"
    // Original formula listed below, we reformulate in MAD form
    // at = alpha * (1 + anisotropic)
    // ab = alpha * (1 - anisotropic)
    at = max(alpha + alpha * anisotropic, MIN_GGX_ALPHA);
    ab = max(alpha - alpha * anisotropic, MIN_GGX_ALPHA);
}
half3 fresnelSchlick(half3 f0, half3 f90, half cosTheta)
{
    half Fc = pow(1 - cosTheta, 5);                 // 1 sub, 3 mul
    //return Fc + (1 - Fc) * SpecularColor;            // 1 add, 3 mad

    // Anything less than 2% is physically impossible and is instead considered to be shadowing
    return saturate(50.0 * f0.g) * Fc + (1 - Fc) * f0;
}
half3 AnisotropicSpecularBRDF(half alpha, half anisotropic, half3 specular, half NdotV, half NdotL, half NdotH, half LdotH,
                                   half3 V, half3 L, half3 H, half3 T, half3 B)
{
    half at, ab;
    getAnisotropicAlpha(alpha, anisotropic, at, ab);

    half TdotH = dot(T, H);
    half BdotH = dot(B, H);
    half TdotV = dot(T, V);
    half BdotV = dot(B, V);
    half TdotL = dot(T, L);
    half BdotL = dot(B, L);

    half D = NDF_GGX_Anisotropic(at, ab, NdotH, TdotH, BdotH);
    half Gvis = Gvis_GGX_Anisotropic(NdotV, TdotV, BdotV, NdotL, TdotL, BdotL, at, ab);
    half3 F = fresnelSchlick(specular, 1, LdotH);
    return F * (D * Gvis);
}

//----------------------Anisotropic------------------------
half3 diffuseBRDF(float3 albedo)
{
    return albedo/UNITY_PI;
}
//------------------------Indirect-------------------------
samplerCUBE _EnvMap;
half4 _EnvColor;


half linearRoughnessToLod(half linearRoughness, half mipCount)
{
#if 0
    return linearRoughness * (mipCount - 1);
#else
    // MAD form
    return linearRoughness * mipCount - linearRoughness;
#endif
}
half linearRoughnessToAlpha(half linearRoughness)
{
    return linearRoughness * linearRoughness;
}

// Refer to https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf P69
half3 getSpecularDominantDir(half3 N, half3 R, half alpha)
{
    // The result is not normalized as we fetch from cubemap
#if 1
    // another cheap approximation from google filament
    // we had validate that it's a better approximation compare to frosbite: https://github.com/guoxx/Notebooks/blob/dev/PBR/off_specular_peak.ipynb
    half a2 = alpha * alpha;
    return lerp(R, N, a2);
#else
    half smoothness = 1 - alpha;
    half factor = smoothness * (sqrt(smoothness) + alpha);
    return lerp(N, R, factor);
#endif
}
half3 decodeRGBM(half4 rgbm)
{
    half3 color = rgbm.xyz * (rgbm.w * kRGBMRange);
    color *= color;
    return color;
}
half3 rotateInAxisY(half3 dir, half4 rotationParam)
{
    return half3(dot(rotationParam.xy, dir.xz), dir.y, dot(rotationParam.zw, dir.xz));
}
half3 getPrefilterSpecularLD(samplerCUBE envmap, half envmapMipCount, half4 rotationParam,
                                   half3 N, half3 V,
                                   half linearRoughness)
{
    half mipLevel = linearRoughnessToLod(linearRoughness, envmapMipCount);

    // Calculate the reflection vector
    half3 L = reflect(-V, N);
    half3 dominantDir = getSpecularDominantDir(N, L, linearRoughnessToAlpha(linearRoughness));

    //dominantDir = rotateInAxisY(dominantDir, rotationParam);
    return decodeRGBM(texCUBElod(envmap, half4(dominantDir, mipLevel)));
}
TEXTURE2D(s_DFGTexture);
SAMPLER(samplers_DFGTexture);
half4 integrateDFGApprox(half NoV, half linearRoughness)
{
    // Refer to https://www.unrealengine.com/en-US/blog/physically-based-shading-on-mobile
    const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
    const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
    half4 r = linearRoughness * c0 + c1;
    half a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
    half2 AB = half2(-1.04, 1.04) * a004 + r.zw;
    return half4(AB, 0, 1);
}
half3 IntegralDFG(half3 specularColor, half NdotV, half linearRoughness)
{
    #if 1
    half2 dfg = integrateDFGApprox(NdotV, linearRoughness);
    #else
    half2 dfg = SAMPLE_TEXTURE2D(s_DFGTexture, samplers_DFGTexture, half2(NdotV, linearRoughness)).xy;
    #endif
    //ld * (f0 * Gv * (1 - Fc)) + (f90 * Gv * Fc)
    // Anything less than 2% is physically impossible and is instead considered to be shadowing 
    return specularColor * dfg.x + saturate(50.0 * specularColor.g) * dfg.y;
}
half3 evalIndirectSpecular(half NoV, in half3 specularColor, half linearRoughness, in half3 specularLd)
{
    half3 indirectSpecular = specularLd * IntegralDFG(specularColor, NoV, linearRoughness);
    return indirectSpecular;
}
