
half4 _SelfGI;
float _Scale;
float _ScaleDepth;
float _Smooth;

//折射
half _ETA;
half3 _TransColor;
half _NormalFlatten;
half _MotionSpeed;
sampler2D _ThicknessMap;
sampler2D _DetailNormalMap;
samplerCUBE _EnvMap;
float4 _DetailNormalMap_ST;
//折射

//Matcap
sampler2D _CapTex;
half4 _SpColor;
sampler2D _MatcapEnvMap;
half4 _MatcapEnvColor;


//Parallax
float _ParallaxHeight;
sampler2D _ParallaxMap;
half4 _ParallaxColor;
float _ParallaxRange;

//Fresnel
half _F0;

//DetailNormal
float _DetailNormalScale;
float _BackDetailNormalMapScale;

//MatcapRefraction
half _Scale_Refraction;

//NormalRemapStrength
float _NormalRemapStrength;

half3 _MatcapRefractionColor;

float3 refractDir(half3 N, half3 V,half radius)
{
    half3 L = refract(-V, N, _ETA);
    half3 hn=cross(-V,N);
    hn=cross(hn,L)*radius;
    half3 newN= reflect(-N,hn);
    L = normalize(refract(L,-newN, 1/_ETA));
    return L;
}

half3 getDetailNormalTS(half2 uv)
{
    uv = uv * _DetailNormalMap_ST.xy + _DetailNormalMap_ST.zw;
    half4 normal = tex2D(_DetailNormalMap, uv);
    return normalize(UnpackNormal(normal));
}

half3 BlendNormal(half3 normalA, half3 normalB)
{
    return normalize(half3(normalA.rg+normalB.rg * _NormalRemapStrength,normalA.b+normalB.b * _NormalRemapStrength));
}


half _MetallicMultiplier;


struct LocalData
{
    half radius;
    float3 backNormal;
    float3 refDir;
};

LocalData _LocalData;
void PrepareSurfaceData(inout CustomSurfaceData sd, v2f i)
{
    _LocalData = (LocalData)0;
    half3 normalTS = GetNormalTS(i.uv);
    half4 albedo = GetAlbedo(i.uv);
    half4 materialParams = GetMaterialParams(i.uv);
    half metallic = materialParams.y * _MetallicMultiplier;
    sd.diffuse = albedo * (1 - metallic);
    sd.emissive = GetEmissive(i.uv);
    sd.normalTS = normalTS;
    sd.opacity = 1;
}

void PostSurfaceData(inout CustomSurfaceData sd, PBRData pd, v2f i)
{
    _LocalData.radius = tex2D(_ThicknessMap, i.uv).r;
    float3 viewDirTS = float3(dot(pd.V, i.tangent), dot(pd.V, i.binormal), dot(pd.V, i.normal));
    half3 backSideNormal = pd.N;

    
    float3 dir = 0.2 * refractDir(sd.normalTS, viewDirTS, _LocalData.radius * pd.Nov);
    _LocalData.backNormal = lerp((getDetailNormalTS((i.uv * _BackDetailNormalMapScale * 0.5 + _DetailNormalMap_ST.zw) + dir)) * 0.5 + 0.5, backSideNormal, lerp(1, _NormalFlatten, (sd.opacity)));
    _LocalData.refDir=refractDir(_LocalData.backNormal,pd.V,_LocalData.radius * pd.Nov * 10);
    
}

half3 decodeRGBM(half4 rgbm)
{
    half3 color = rgbm.xyz * (rgbm.w * kRGBMRange);
    color *= color;
    return color;
}


half3 _EnvColor;

half3 getPrefilterRefractionLD(samplerCUBE envmap, half envmapMipCount, float roughness)
{
    
    // Calculate the reflection vector
    half motionFlatten =(1-saturate(_NormalFlatten+0.2*(cos(_Time.x*_MotionSpeed)*0.5+0.5)));
    half3 L = normalize(_LocalData.refDir + _LocalData.backNormal * motionFlatten);
    half3 refractCol = decodeRGBM(texCUBElod(envmap, half4(L, 1)))*_EnvColor*_EnvColor;
    return refractCol;
}

half2 MatCapUV (in float3 N,in float3 viewPos)
{
    float3 viewNorm = mul((float3x3)UNITY_MATRIX_V, N);
    //viewPos = 
    float3 viewDir = normalize(viewPos);
    float3 viewCross = cross(viewDir, viewNorm);
    viewNorm = float3(-viewCross.y, viewCross.x, 0.0);
    float2 matCapUV = viewNorm.xy * 0.5 + 0.5;
    return matCapUV; 
}

half3 Refraction(CustomSurfaceData sd)
{
    half3 refractCol = getPrefilterRefractionLD(_EnvMap, 1, 1)* _TransColor * _TransColor * (sd.opacity * sd.opacity);
    refractCol *= sd.diffuse;
    return refractCol;
}

half3 Reflection(CustomSurfaceData sd, PBRData pd)
{
    float2 matcapUV = MatCapUV(pd.N, pd.V);
    half3 envCol = tex2D(_MatcapEnvMap, matcapUV) * _MatcapEnvColor * sd.diffuse;
    half3 specCol = tex2D(_CapTex, matcapUV) * _SpColor * sd.diffuse;
    half3 matcapCol = specCol * pd.lightCol + envCol * sd.diffuse * pd.lightCol;
    return matcapCol;
}




half3 CalculateMainLight(CustomSurfaceData sd, PBRData pd)
{
    float3 light;
    float3 refraction = Refraction(sd);
    float3 reflection = Reflection(sd, pd);
    light = refraction + reflection;
    return light;
}



            