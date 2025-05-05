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

struct LightOut
{
    half3 diffuse;
    half3 specular;
    half3 indirectDiffuse;
    half3 indirectSpecular;
    half3 emissive;
};