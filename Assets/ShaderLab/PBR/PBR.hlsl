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
    
    // 漫反射部分 (金属没有漫反射)
    float3 kD = (1 - F) * (1.0 - metallic);
    
    // 最终结果
    return (kD * albedo / PI + specular) * NdotL;
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