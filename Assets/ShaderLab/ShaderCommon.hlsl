#include "Debug.hlsl"
sampler2D _NormalMap;
float4 _NormalMap_ST;
half3 GetNormalTS(float2 uv)
{
    float2 normalTSUV = uv * _NormalMap_ST.xy + _NormalMap_ST.zw;
    return tex2D(_NormalMap, normalTSUV);
}

sampler2D _AlbedoMap;
float4 _AlbedoMap_ST;
half4 _AlbedoColor;
half4 GetAlbedo(float2 uv)
{
    float2 albedoUV = uv * _AlbedoMap_ST.xy + _AlbedoMap_ST.zw;
    return tex2D(_AlbedoMap, albedoUV) * _AlbedoColor;
}

sampler2D _MaterialParamsMap;
float4 _MaterialParamsMap_ST;
half4 GetMaterialParams(float2 uv)
{
    float2 materialParamsUV = uv * _MaterialParamsMap_ST.xy + _MaterialParamsMap_ST.zw;
    return tex2D(_MaterialParamsMap, materialParamsUV);
}

sampler2D EmissiveMap;
float4 _EmissiveMap_ST;
half4 GetEmissive(float2 uv)
{
    float2 emissiveUV = uv * _EmissiveMap_ST.xy + _EmissiveMap_ST.zw;
    return tex2D(EmissiveMap, emissiveUV);
}

struct v2f
{
    float2 uv : TEXCOORD0;
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
    
};

struct appdataPBR
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
};

half3 GetNormal(half3 normalTS, v2f i)
{
    normalTS = normalTS * 2.0 - 1.0;
    half3 normal;
    float3x3 tbn = float3x3(normalize(i.tangent.xyz), normalize(i.binormal.xyz), normalize(i.normal.xyz));
    normal = normalize(mul(normalTS, tbn));

    return normal;
}

half4 finalOutput(half4 color, v2f i)
{
    #ifdef DEBUG
    if(length(i.debugColor.xyz) > 0)
    {
        return DebugOut(i.debugColor);
    }else
    {
        return DebugOut(color);
    }
    #endif
    return color;
}




//Todo Vertex Light Is Non SH Light Is Wrong
half3 VertexLight(appdataPBR v)
{
    uint lightCount = GetAdditionalLightsCount();
    return lightCount;
    
}
v2f VertexFunc(v2f i);
v2f vert_pbr (appdataPBR v)
{
    v2f o;
    VertexPositionInputs positionInput = GetVertexPositionInputs(v.vertex);
    o.vertex = positionInput.positionCS;
    o.positionWS = positionInput.positionWS;
    o.uv = v.uv;
    VertexNormalInputs normalInput = GetVertexNormalInputs(v.normal, v.tangent);
    o.normal.xyz = normalInput.normalWS;
    o.tangent.xyz = normalInput.tangentWS;
    o.binormal.xyz = normalInput.bitangentWS;
    o.screenPos = ComputeScreenPos(o.vertex);
    o.vertexLight = VertexLight(v);
    //o.vertexSH = GetVertexSH(v.positionWS, normalInput.normalWS);
    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(o.normal, o.vertexSH);

    o = VertexFunc(o);
    

    return o;
}

void PrepareSurfaceData(inout CustomSurfaceData sd, v2f i);
void PostSurfaceData(inout CustomSurfaceData sd, PBRData pd,  v2f i);
half3 CalculateMainLight(CustomSurfaceData sd, PBRData pd, v2f i);
half3 CalculateIndirectLight(CustomSurfaceData sd, PBRData pd, v2f i);

void HandleSurfaceData(CustomSurfaceData sd, inout PBRData pd, v2f i, Light light)
{
    pd.N = GetNormal(sd.normalTS, i);
    pd.L = light.direction;
    pd.Nol = saturate(dot(pd.N, pd.L));
    pd.lightCol = light.color;
    pd.atten = light.shadowAttenuation * light.distanceAttenuation;
    pd.posWS = i.positionWS;
    pd.V = normalize(_WorldSpaceCameraPos - pd.posWS);
    pd.Nov = saturate(dot(pd.N, pd.V));
    pd.H = normalize(pd.L + pd.V);
    pd.NoH = saturate(dot(pd.N, pd.H));
    pd.screenUv = i.screenPos.xy / i.screenPos.w;
    pd.alpha = sd.linearRoughness * sd.linearRoughness;
    
}
float4 _FPParams0;
#define URP_FP_DIRECTIONAL_LIGHTS_COUNT ((uint)_FPParams0.w)

half4 frag_pbr(v2f i) : SV_Target
{
    CustomSurfaceData sd = (CustomSurfaceData)0;
    PBRData pd = (PBRData)0;
    // sample the texture
    half4 col;
    PrepareSurfaceData(sd, i);

    HandleSurfaceData(sd, pd, i, GetMainLight());

    PostSurfaceData(sd, pd, i);

    half3 lightColor = CalculateMainLight(sd, pd, i);

    lightColor += CalculateIndirectLight(sd, pd, i);

    uint AddLightCount = GetAdditionalLightsCount();

    for (uint index = 0; index < AddLightCount; index++)
    {
        Light light = GetAdditionalLight(index, pd.posWS);
        HandleSurfaceData(sd, pd, i, light);
        lightColor += CalculateMainLight(sd, pd, i);
    }
    for(uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        
        Light light = GetAdditionalLight(lightIndex, pd.posWS);
        HandleSurfaceData(sd, pd, i, light);
        lightColor += CalculateMainLight(sd, pd, i);
    }
    
    col.xyz = lightColor;

    
    //col.rgb += sd.emissive;
    col.a = sd.opacity;
    #ifdef DEBUG
    DebugSD(sd, col);
    #endif
    return finalOutput(col, i);
}






