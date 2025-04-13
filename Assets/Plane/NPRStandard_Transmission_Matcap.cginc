#include "Packages/com.tencent.tmgp.yarp/Shaders/ShaderLib/GlobalConfig.cginc"
#include "Packages/com.tencent.tmgp.yarp/Shaders/ShaderLib/BRDF.cginc"
#include "Packages/com.tencent.tmgp.yarp/Shaders/ShaderLib/TypeDecl.cginc"
#include "Packages/com.tencent.tmgp.yarp/Shaders/ShadingSystem/GlobalVariables.cginc"
#include "Packages/com.tencent.tmgp.yarp/Shaders/ShadingSystem/ColorOutput.cginc"
#include "Packages/com.tencent.tmgp.yarp/Shaders/ShadingSystem/VertexInputData.cginc"
#include "Packages/com.tencent.tmgp.yarp/Shaders/ShadingSystem/ShadingModel/ShadingCommon.cginc"
#include "../MaterialShared.cginc"
#include "../../SurfaceShaders/SurfaceShaderHelper.cginc"
#include "../../MaterialFunctions/NPR_Common.cginc"

#include "../../MaterialFunctions/Utils_UV.cginc"
#include "../../MaterialFunctions/Noise.cginc"


#include "../../MaterialFunctions/Feature_RimLight.cginc"

/*
$ConfigImportPath
{
    ../../MaterialFunctions/Feature_RimLight.cginc
}
$properties {
    [MaterialToggle][AutoVariant][ShaderPass(ForwardBase)] _Anisotropy("Anisotropy", Int) = 0

    [Header(Diffuse)]
    [HDR] _SelfGI("Self GI COLOR", COLOR) = (0.9, 0.5, 0.2, 1)
    _AlphaAll ("Alpha All", range(0, 1)) = 1.0
    _AlbedoMap("Albedo Map (RGB,A)", 2D) = "white" {}
    _AlbedoColor("Albedo COLOR", COLOR) = (0.1, 0.1, 0.1, 1)
    _MaterialParamsMap("R=roughness, G=metallic,B=AO,A=colormask", 2D) = "white"{}
    _NormalMap("Normal Map", 2D) = "bump" {}
    [HDR]_EmissiveColor("Emissive COLOR", COLOR) = (1.0, 1.0, 1.0, 1)
    _EmissiveMap("Emissive Map (RGB)", 2D) = "black" {}
 //   [HDR]_EnvColor("反射颜色", COLOR) = (0.5,0.5,0.5,1)
    _MetallicMultiplier("Metallic multiplier (DEBUG Only)", range(0, 1)) = 1.0
    _RoughnessMultiplier("Roughness multiplier (DEBUG Only)", range(0, 1)) = 1.0
    _ShadowStrength("Shadow Strength", range(0, 1)) = 1.0

    [Group(光照光谱)][Toggle][AutoVariant(shader_feature)][ShaderPass(ForwardBase)] _EnableRampTex("使用光谱图",float) = 0

    [Group(光照光谱)][Depend(_EnableRampTex,0,Hide)]   _LitOffset("交界线随光源方向偏移(0普通1面部)", range(0, 1)) = 0.0
    [Group(光照光谱)][Depend(_EnableRampTex,0,Hide)]   _RampThreshold("交界线偏移阈值", range(0, 1)) = 0.5
    [Group(光照光谱)][Depend(_EnableRampTex,0,Hide)]   _RampSmooth("交界线模糊度", range(0, 1)) = 0.5
    [Group(光照光谱)][Depend(_EnableRampTex,0,Hide)]   _sssColor("交界线模糊处颜色", COLOR) = (1.0, 1.0, 1.0, 1)
    [Group(光照光谱)][Depend(_EnableRampTex,1,Hide)]   _RampTex("光谱图", 2D) = "white" {}
    [Group(光照光谱)]   _ParamsTex("参数图：x模糊度，y光照遮罩", 2D) = "white" {}

   

    

    [Group(边缘光)][HDR] _RimColor("边缘光颜色(旧)",COLOR)=(0,0,0,1)
    [Group(边缘光)]_RimThreshold("边缘光范围阈值(旧)",range(0,1))=0.5
    [Group(边缘光)]_RimSmooth("边缘光边界模糊度(旧)",range(0,1))=0.5

    [Group(描边)] _Smooth("读取UV4光滑数据",range(0,1)) =1
    [Group(描边)] _Scale("描边厚度",Range(0,1)) =0.25
	[Group(描边)] _ScaleDepth("描边深度",Range(0.01,1)) = 0.1
    [Group(描边)][HDR] _OutlineCol(" 描边颜色",COLOR)=(0,0,0,1)
    [Group(描边)][Toggle][AutoVariant(shader_feature)][ShaderPass(Outline)] _Has_Outlinetex ("使用描边颜色图",float) = 0
    [Group(描边)][Depend(_Has_Outlinetex,1,Hide)]  _OutlineTex("描边颜色图（RGB）", 2D) = "white" {}
    [Group(描边)][KeywordEnum(UVOne,UVTwo,screenUV)][Depend(_Has_Outlinetex,1,Hide)] _UVMode_OutLine("描边UV模式",float) = 0

    [Group(折射)] _EnvMap("折射图", Cube) = “black”{}
    [Group(折射)] [HDR]_EnvColor("折射颜色", COLOR) = (0.5,0.5,0.5,1)
    [Group(折射)] _TransColor("透射率", COLOR) = (0.6, 0.6, 0.6, 1)  
    [Group(折射)] _ETA("折射率（入射/出射）", Range(0.1,1)) = 0.75
    [Group(折射)] _NormalFlatten("投射法线平整度", Range(0.0,1)) = 0.7
    [Group(折射)] _MotionSpeed("折射变化速度", Range(0.0,100.0)) = 1.0
    [Group(折射)] _DetailNormalMap("投射法线纹理", 2D) = "bump" {}
    [Group(折射)] _ThicknessMap("厚度纹理", 2D) = "gray" {}

    [Group(溶解)] [Toggle][AutoVariant(multi_compile)] _EnableDissolve("Enable Dissolve",float) = 0
    [Group(溶解)] _DissolveTex ("Dissolve(RGB)", 2D) = "white" {}
    [Group(溶解)] _DissolveTexUVR ("UV-R", vector)=(1,1,0,0)
    [Group(溶解)] _DissolveTexUVG ("UV-B", vector)=(1,1,0,0)
    [Group(溶解)] _DissolveLV ("强度:x=R,y=B,z=Fresnel,w=溶解随机闪烁", vector)=(0,0,0,0) 
    [Group(溶解)] _DissolveEdgeColor ("颜色", vector)=(0.2,0.5,1,1) 
    [Group(溶解)] _DissolveEdgeColor2 ("颜色2", vector)=(0,0,0,0.5) 
    [Group(溶解)] _Dissolve ("_Dissolve", Range(-1,1)) = 0.0  
    [Group(溶解)] _DissolveON ("0=透明ON 1=透明OFF", Range(0,1)) = 0.0    
    [Group(溶解)] _EdgeWidth("边缘宽度",Range(-0.5,0.5)) = 0.1   

}
*/


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

half4 _Debug;
void Debug(half4 colorIn)
{
    _Debug = colorIn;
}
void Debug(half3 colorIn)
{
    _Debug = half4(colorIn, 1);
}

void Debug(half2 colorIn)
{
    _Debug = half4(colorIn, 0, 1);
}
void Debug(half colorIn)
{
    _Debug = half4(colorIn, colorIn, colorIn, 1);
}


struct VsOutFull
{
    half4 color :XGY01;
    VsOutBuiltin builtin;
};

struct SurfaceData
{
    half3 emissive;
    half3 baseColor;
    half metallic;
    half3 diffuse;
    half3 specular;
    half opacity;
    half linearRoughness;
    half alpha;
    half3 normalTS;

    half occlusion;
    half3 selfGI;
    half cutoffThreshold;
};

struct MaterialUserData
{
    half3 litsNoL;
    half3 params;
    //refraction-------------
    float3 refDir;
    float3 backNormal;
    half radius;
    //refraction-------------
    int unused;
    //fresnel----------------
    float fresnel;
};


void SF_VertexFunc(in VertexInputData vsIn, inout VsOutFull vsOut)
{
    vsOut.color=vsIn.color;

#if CONF_SHADER_PASS == SHADERPASS_OUTLINE
    OutlineVertexFunc(vsIn,  vsOut);
#endif
}

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


SurfaceData SF_PrepareSurfaceData(in VsOutFull psInput, in bool isFrontFace, inout MaterialUserData md)
{
    half2 uv0 = psInput.builtin.uv0_uv1.xy;

    half2 AlbedoUV = getAlbedoUV(uv0);
    half4 albedo = getAlbedo(AlbedoUV);

    half4 materialParams = getMaterialParams(AlbedoUV);
    albedo *= lerp(1, _AlbedoColor, materialParams.w);

    //SD
    SurfaceData sd = (SurfaceData)0;
    sd.emissive = getEmissive(AlbedoUV);
    sd.opacity = albedo.a;
    sd.opacity = 0.5;
    sd.linearRoughness = clampLinearRoughness(materialParams.x * _RoughnessMultiplier);
    sd.alpha = linearRoughnessToAlpha(sd.linearRoughness);
    half metallic = materialParams.y * _MetallicMultiplier;
    sd.diffuse = albedo.rgb * (1 - metallic);
    sd.specular = lerp(0.0f, albedo.rgb, metallic);
    half3 normalTS = getNormalTS(AlbedoUV);
    half3 detailNormalTS = getDetailNormalTS(AlbedoUV);
    sd.normalTS = lerp(normalTS, BlendNormal(normalTS, detailNormalTS), _DetailNormalScale);
    
    
    //sd.normalTS = getNormalTS(AlbedoUV);
    
    sd.selfGI = _SelfGI;
    sd.occlusion = materialParams.z;
    sd.cutoffThreshold = 0.23;

    md.params = GetParamsValue(uv0);
    md.litsNoL = 0;
    
    return sd;
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




float Fresnel_Schlick(float3 N, float3 V, float F0) {
    float cosTheta = saturate(dot(N, V));
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}
#define _REFRACTMODE_MATCAP 1

//折射  输入：    MatCap-(uv.xy,0,r);Cube-(uv.xyz,r):2D-(screenUV.xy,0,r)   GrabPass-(screenUV.xy,0,0)
#ifdef _REFRACTMODE_MATCAP
TEXTURE2D(_RefractionMap_MatCap);
SAMPLER(sampler_RefractionMap_MatCap);
#endif
half3 GetCustomEnvColor_Refract(half4 uv)
{
    half4 refractColor = 0;
    //2D纹理
    #ifdef _REFRACTMODE_SCREEN2D 
    refractColor = SAMPLE_TEXTURE2D_LOD(_RefractionMap_Screen2D, sampler_RefractionMap_Screen2D, uv.xy, uv.w);
    //refractColor.rgb *= _RefractEnvColor ;
    EnsureLinearColor(refractColor.rgb);//Gamma 矫正
    refractColor.rgb *= refractColor.a; //模拟HDR
    #endif
    //MatCap
    #ifdef _REFRACTMODE_MATCAP
    refractColor = SAMPLE_TEXTURE2D_LOD(_RefractionMap_MatCap, sampler_RefractionMap_MatCap, uv.xy, uv.w);
    //refractColor.rgb *= _RefractEnvColor ;
    EnsureLinearColor(refractColor.rgb);//Gamma 矫正
    refractColor.rgb *= refractColor.a; //模拟HDR
    #endif
    //CubeMap
    #ifdef _REFRACTMODE_CUBE
    refractColor = SAMPLE_TEXTURECUBE_LOD(_RefractionMap_Cube, sampler_RefractionMap_Cube, uv.xyz, uv.w * 9);//8 for 256 Env Tex size  size= 2^x
    //refractColor.rgb *= _RefractEnvColor;
    EnsureLinearColor(refractColor.rgb);//Gamma 矫正
    refractColor.rgb *= refractColor.a; //模拟HDR
    #endif 
    //GrabPass
    #ifdef _REFRACTMODE_GRABPASS
    //Gamma 矫正
    refractColor = sampleGrabTexture(uv);
    #endif
    return refractColor;
}


half3 GetRefractionColor(Intersection its, VsOutFull psInput, SurfaceData sd, MaterialUserData md, half mask)
{
    //half thickness = its.NdotV * its.NdotV;
    half4 uv = 0;
    half motionFlatten = 1;// (1 - saturate(0.2 * (cos(_Time.x * _MotionSpeed) * 0.5 + 0.5)));
    #ifdef _REFRACTMODE_MATCAP
    float2 offset = normalize(mul(UNITY_MATRIX_V, float4(normalize(md.backNormal * motionFlatten), 0)).xyz).xy * _Scale_Refraction * mask;    //ComputeRefractMatCapOffset(its, _ETA);
    half2 matcapUV = GetMatCapUV_Fixed(its.shFrame.normal, VsOut_GetPositionWS(psInput.builtin));
    uv = half4(matcapUV + offset, 0, sd.linearRoughness);
    #endif
    
    half3 refractColor = GetCustomEnvColor_Refract(uv);
    return   refractColor;
}

half3 GetBackSideNormal(half3 frontNormal, half3 viewDir)
{
    half3 hn = cross(-viewDir, frontNormal);
    hn = cross(hn, -viewDir);
    return reflect(-frontNormal, hn);
}

//half3 remapNormal(half3 normal, )

void SF_PostSurfaceIntersection(VsOutFull psInput, inout Intersection its, inout SurfaceData sd, inout MaterialUserData md)
{
    md.radius=tex2D(_ThicknessMap,psInput.builtin.uv0_uv1.xy);
    
    // why radius need multiply NdotV? because when it is like a sphere or it is a symmetry object, the radius is the same as NdotV multiply thickness map value
    float3 dir =0.2* refractDir(sd.normalTS,Frame_toLocal(its.geoFrame,its.V),md.radius * its.NdotV );
    
    half3 backSideNormal = its.shFrame.normal;
    //backSideNormal = GetBackSideNormal(its.shFrame.normal, its.V);
    md.backNormal = lerp((getDetailNormalTS((psInput.builtin.uv0_uv1.xy * _BackDetailNormalMapScale * 0.5 + _DetailNormalMap_ST.zw) + dir)) * 0.5 + 0.5, backSideNormal, lerp(1, _NormalFlatten, (sd.opacity)));
    md.backNormal =  Frame_toWorld(its.shFrame,md.backNormal);
    md.refDir=refractDir(md.backNormal,its.V,md.radius * its.NdotV * 10);
}

half2 CaculateParallaxUV(half3 viewDir_tangent, half heightMulti,half hightmap)
{
    float hight =heightMulti;// tex2D(_HightMap, i.uv.xy * 5).rg;
    hight *= hightmap;
    //normalize view Dir
    float3 viewDir = normalize(viewDir_tangent);
    viewDir.z += 0.42;
    //偏移值 = 切线空间的视线方向.xy（uv空间下的视线方向）* height * 控制系数
    float2 offset = (viewDir.xy/viewDir.z) * hight;
    return offset;
}

half3 SF_EvalPunctualLight(VsOutFull psInput, Intersection its, SurfaceData sd, LightData ld,inout MaterialUserData md)
{
    ld.intensity = 1;
    half3 litColor = ld.intensity * ld.shadowFactor;
    md.litsNoL +=  ld.NoL* litColor;

    float fullNdL = (dot(its.shFrame.normal, ld.L) * 0.5 + 0.5) * ld.shadowFactor;




    half3 refDir= md.refDir;// refractDir(its.shFrame.normal,its.V,md.radius);
    half3 transColor=_TransColor*_TransColor;
    half nol=saturate(dot(its.shFrame.normal, ld.L));
    half backSpec= saturate(dot(ld.H,md.backNormal));
    backSpec=saturate(pow(backSpec,100))*transColor;
    //nol = saturate(dot(its.shFrame.normal, ld.L));

    
    //Parallax Refraction Test ***************************************
    half3 ViewTS = Frame_toLocal(its.shFrame, its.V);
    float height = (1 - md.radius);
    height *= its.NdotV;
    //height = 1;
    //Debug(its.NdotV);
    //height = md.radius;
    //Debug(height);
    half2 ParallaxUV = CaculateParallaxUV(ViewTS, _ParallaxHeight, height);
    half4 ParallaxMap = tex2D(_ParallaxMap, psInput.builtin.uv0_uv1.xy + ParallaxUV);
    ParallaxMap.xyz *= _ParallaxColor.a * _ParallaxColor.rgb;
    ParallaxMap.xyz *= sd.diffuse;
    

    
    //Fresnel
    half fresnel = Fresnel_Schlick(its.shFrame.normal, its.V, _F0);
    md.fresnel = fresnel;
    //Matcap Lighting
    float2 MatcapUV = MatCapUV(its.shFrame.normal, its.V);
    half3 spmatCap = tex2D(_CapTex, MatcapUV);
    
    half3 Specular = spmatCap * _SpColor;
    Specular *= sd.diffuse;

    half3 MatcapEnvColor = tex2D(_MatcapEnvMap, MatcapUV);
    MatcapEnvColor *= _MatcapEnvColor;
    MatcapEnvColor *= sd.diffuse;
    //Debug(MatcapEnvColor);

    //Matcap Refract Test ***************************************
    half3 refractColor=GetRefractionColor(its, psInput, sd, md, 1) * 0.2;//MatcapRefract
    refractColor *= _MatcapRefractionColor;
    
    

    //Debug(refractColor);
    //Debug(Specular);
    //Debug(ParallaxMap);
    //Debug(sd.diffuse);
    
    
    
    return (Specular * md.litsNoL * fresnel) + MatcapEnvColor;
    //+ refractColor * fresnel; 
    
   // return ((specularLobe + diffuseLobe) * ld.NoL)*ld.intensity * ld.shadowFactor;
}

half3 SF_EvalDiffuseGI(VsOutFull psInput, Intersection its, SurfaceData sd, MaterialUserData md)
{
    
    //return 0;
    return getIndirectIrradiance(its, sd.selfGI, false, false);
}

half3 getPrefilterRefractionLD(samplerCUBE envmap, half envmapMipCount, half4 rotationParam,half linearRoughness,MaterialUserData md)
{
    half mipLevel = linearRoughnessToLod(linearRoughness, envmapMipCount);
    // Calculate the reflection vector
    half motionFlatten =(1-saturate(_NormalFlatten+0.2*(cos(_Time.x*_MotionSpeed)*0.5+0.5)));
    half3 L = normalize(md.refDir + md.backNormal * motionFlatten);
    L = rotateInAxisY(L, rotationParam);
    half3 refractCol=decodeIBLColor(texCUBElod(envmap, half4(L, mipLevel)))*_EnvColor*_EnvColor;
    //Debug(refractCol);
    return refractCol;
}




half3 SF_EvalSpecularReflection(VsOutFull psInput, Intersection its, SurfaceData sd, float envmapWeight, MaterialUserData md)
{
    /*
    half3 worldReflection = reflect(-normalize(its.V), normalize(its.shFrame.normal));
    half3 specularLd = CarToonMetalReflectionColor(worldReflection,its.NdotV , sd.linearRoughness);// g_EnvmapIntensity.xyz abandened for black minline
    
    half diffuseOcclusion = 1;
    half specularOcclusion = 1;
    computeDirectOcclusion(its, sd.linearRoughness, diffuseOcclusion, specularOcclusion);
    half3 multiBounceSO = multiBounceSpecularOcclusion(diffuseOcclusion, specularOcclusion, _SelfGI);
    specularLd *= multiBounceSO;

    half3 refractCol= getPrefilterRefractionLDgetPrefilterRefractionLD(_EnvTex, g_EnvmapMipLevelsUsed, g_EnvmapRotationParam,sd.linearRoughness,md)*_TransColor;
    refractCol *= g_EnvmapIntensity.xyz;


    
    return specularLd *sd.specular +CarToonRim(its.NdotV) * multiBounceSO * md.litsNoL * _RimColor+refractCol;
    */
    half diffuseOcclusion = 1;
    half specularOcclusion = 1;
    computeDirectOcclusion(its, sd.linearRoughness, diffuseOcclusion, specularOcclusion);
    half3 multiBounceSO = multiBounceSpecularOcclusion(diffuseOcclusion, specularOcclusion, _SelfGI);

    half3 specularLd = getSpecularReflectionLightingScaleWithGI(its.shFrame.normal, its.V, sd.linearRoughness, envmapWeight);
    specularLd *= multiBounceSO;
    
    //half3 ReflectCol = evalIndirectSpecular(its, sd.specular, sd.linearRoughness, specularLd) * _EnvColor * _EnvColor;
    half3 RefractCol = getPrefilterRefractionLD(_EnvMap, g_EnvmapMipLevelsUsed, g_EnvmapRotationParam, sd.linearRoughness, md) * _TransColor * _TransColor * (sd.opacity * sd.opacity);
    half3 RimCol = CarToonRim(its.NdotV) * multiBounceSO * md.litsNoL * _RimColor;

    //Debug(RefractCol);//
    //return 0;
    return (RimCol + RefractCol);
}

half4 SF_FinalColor(VsOutFull psInput, Intersection its, SurfaceData sd, MaterialUserData md, half4 color)
{

    
#ifndef _SPACEMODE_NONE
    half4 rimColor = GetRimLighting(its.shFrame.normal, VsOut_GetPositionWS(psInput.builtin), psInput.builtin.uv0_uv1.xy);
    color.rgb = lerp(color.rgb, rimColor.rgb, rimColor.a);
#endif
    color.rgb = ApplyFog(color.rgb, psInput.builtin.positionWS_fogFactor.w);
    if(length(_Debug.xyz) > 0.01 || _Debug.a > 0)
    {
        return _Debug;
    }
    return finalColor(color, isAlphaBlendEnabled());

}