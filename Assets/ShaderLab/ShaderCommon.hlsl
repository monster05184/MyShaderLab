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
half4 GetAlbedo(float2 uv)
{
    float2 albedoUV = uv * _AlbedoMap_ST.xy + _AlbedoMap_ST.zw;
    return tex2D(_AlbedoMap, albedoUV);
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
    //normalTS = normalTS * 2.0 - 1.0;
    half3 normal;
    
    float3x3 tbn = float3x3(normalize(i.tangent.xyz), normalize(i.binormal.xyz), normalize(i.normal.xyz));
    normal = normalize(mul(normalTS, tbn));

    return normal;
}

half4 finalOutput(half4 color)
{
    #ifdef DEBUG
    return DebugOut(color);
    #endif
    return color;
}


struct CustomSurfaceData
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
    half cutoffThreshold;
};

struct PBRData
{
    half Nol;
    half Nov;
    half3 N;
    half3 H;
    half3 L;
    half NoH;
    half3 V;
    half alpha;
    half3 lightCol;
    half atten;
    half3 posWS;
    float2 screenUv;
};



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

    return o;
}

void PrepareSurfaceData(inout CustomSurfaceData sd, v2f i);
void PostSurfaceData(inout CustomSurfaceData sd, PBRData pd,  v2f i);
half3 CalculateMainLight(CustomSurfaceData sd, PBRData pd);

void HandleSurfaceData(CustomSurfaceData sd, inout PBRData pd, v2f i)
{
    pd.N = GetNormal(sd.normalTS, i);
    Light light = GetMainLight();
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


half4 frag_pbr(v2f i) : SV_Target
{
    CustomSurfaceData sd = (CustomSurfaceData)0;
    PBRData pd = (PBRData)0;
    // sample the texture
    half4 col;
    PrepareSurfaceData(sd, i);

    HandleSurfaceData(sd, pd, i);

    PostSurfaceData(sd, pd, i);

    half3 lightColor = CalculateMainLight(sd, pd);
    col.xyz = lightColor;
    
    //col.rgb += sd.emissive;
    col.a = sd.opacity;
    return finalOutput(col);
}






