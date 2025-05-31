//一个UnlitShader的hlsl
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Assets/ShaderLab/Debug.hlsl"

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
struct v2f
{
    float4 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
    
    //TBN
    float3 normal : TEXCOORD1;
    float3 tangent : TEXCOORD2;
    float3 binormal : TEXCOORD3;

    float3 positionWS : TEXCOORD4;
    float4 screenPos : TEXCOORD5;

    float3 vertexLight : TEXCOORD6;

    float3 vertexSH    : TEXCOORD7;

    #ifdef DEBUG
    float4 debugColor  : TEXCOORD8;
    #endif
    float4 shadowCoord : TEXCOORD9;
    float4 color : COLOR0;
    
};

struct appdataUnlit
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
};


CBUFFER_START(UnityPerMaterial)
float4 _UvOffset;
float4  _AlbedoMap_ST;
float _FurAlphaScale;
float _FurLength;
half4 _DiffColor;
half4 _OcclusionColor;
float _FresnelLV;
float _LightFilter;
half4 _SpecColor1;
half4 _SpecColor2;
float4 _SpecInfo;
float _FlowMapScale;
CBUFFER_END
float FUR_OFFSET;
sampler2D _FlowMap;
TEXTURE2D(_FurMask);
SAMPLER(sampler_FurMask);
TEXTURE2D(_FurAlpha);
SAMPLER(sampler_FurAlpha);
TEXTURE2D( _AlbedoMap);
SAMPLER(sampler_AlbedoMap);
v2f VertexFunc(v2f v, appdataUnlit i);
v2f VertexFunc(v2f output, appdataUnlit v)
{
    float4 furInfo = tex2Dlod(_FlowMap,float4(v.uv.xy,0,0));
    //将顶点挤出
    FUR_OFFSET = max(0,FUR_OFFSET*furInfo.b); 
    float3 aNormal = (v.normal.xyz);
    float3 n = aNormal*(FUR_OFFSET)*_FurLength * 0.001;
    v.vertex.xyz +=n;
    // GetVertexPositionInputs方法根据使用情况自动生成各个坐标系下的定点信息
    const VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
    output.vertex = vertexInput.positionCS;
   

    //数据准备
    float3 normalWS = normalize(TransformObjectToWorldNormal(v.normal));
    output.normal = normalWS;
    float3 positionWS = vertexInput.positionWS;
    float3 viewVec = normalize(_WorldSpaceCameraPos-positionWS);
    float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
    float2 inUv = TRANSFORM_TEX(v.uv.xy, _AlbedoMap);
    
    //uv的偏移，毛发的偏移
    float2 flowMapOff = furInfo.rg;
    flowMapOff = (flowMapOff*2 -1) * _FlowMapScale;
    float2 uvoffset = _UvOffset.xy * FUR_OFFSET + flowMapOff*20 * FUR_OFFSET;
    uvoffset *=0.1;
    float2 uv1 = TRANSFORM_TEX(v.uv.xy, _AlbedoMap) + uvoffset*float2(1,1)/_FurAlphaScale;
    float2 uv2 = TRANSFORM_TEX(v.uv.xy, _AlbedoMap)*_FurAlphaScale + uvoffset;
    output.uv = float4(uv1,uv2);

    //毛发的环境光遮蔽
    half3 SH = half3(0.5,0.5,0.5);
    half Occlusion = FUR_OFFSET*FUR_OFFSET;//伽马转为线性光照
    Occlusion += 0.04;
 

    //模型周围毛发的透射光
    half Fresnel  = 1 - max(0,dot(normalWS,viewVec));
    half RimLight = Fresnel * Occlusion;
    RimLight *= RimLight;
    RimLight *= _FresnelLV * SH;

    //太阳光//TODO接收阴影
    Light mainLight = GetMainLight(shadowCoord);
    half3 lightDir = mainLight.direction;
    half NoL = dot(lightDir,normalWS);
    half3 DirLight = saturate(NoL + _LightFilter + FUR_OFFSET)*mainLight.color;
    output.color.xyz = RimLight * _OcclusionColor + DirLight * Occlusion;
    //v.vertex += 1;
    return output;
}

v2f vert_unlit (appdataUnlit v)
{
    v2f output;
    output = VertexFunc(output, v);
    
    return output;
}

half4 frag_unlit(v2f i) : SV_Target
{
    //对毛发的噪声Alpha图和主图片进行取样
    half3 NoiseTex = SAMPLE_TEXTURE2D(_FurAlpha, sampler_FurAlpha, i.uv.zw);
    half3 MainTex = SAMPLE_TEXTURE2D( _AlbedoMap, sampler_AlbedoMap, i.uv.xy);
    half Noise = NoiseTex.r;
                    
    //光照采样开启GI之后采样GI，不开启则默认
    half4 col = float4(MainTex,1);
    #ifdef _GI_ON
    float3 bakeGI = SAMPLE_GI(i.lightmapUV,i.vertexSH,i.normal);
    //MixRealtimeAndBakedGI(GetMainLight(),input.normal,bakeGI,half4(0,0,0,0));
    bakeGI = lerp(bakeGI*_OcclusionColor, bakeGI, i.color.w);
    col.xyz *= (i.color.xyz + bakeGI);
    #else
    col.xyz *= i.color.xyz;
    #endif
    col.a = max(0,Noise - FUR_OFFSET);
    //Debug(Noise);
    
    
    #ifdef DEBUG
    col = DebugOut(col);
    #endif
    
    return col;
}







