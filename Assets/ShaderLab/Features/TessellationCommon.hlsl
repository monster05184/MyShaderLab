#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Tessellation.hlsl"



// 细分评估阶段输出
struct DomainOutput
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normalWS : TEXCOORD1;
    float4 tangentWS : TEXCOORD2;
};

// 细分控制阶段
struct TessFactors
{
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

half _EdgeFactor = 5.0; // 边缘细分因子
half _InsideFactor = 2.0; // 内部细分因子
half _DisplacementStrength = 0.1; // 置换强度

// 常量外壳着色器：计算细分因子
TessFactors patchConstantFunc(InputPatch<TessControlPoint, 3> patch)
{
    TessFactors o;
    // 根据相机距离动态调整细分密度
    float3 centerPos = (patch[0].positionWS + patch[1].positionWS + patch[2].positionWS) / 3;
    float dist = distance(centerPos, _WorldSpaceCameraPos);
    float dynamicFactor = saturate(1 - dist / 50) * _EdgeFactor;
                
    o.edge[0] = dynamicFactor;
    o.edge[1] = dynamicFactor;
    o.edge[2] = dynamicFactor;
    o.inside = _InsideFactor;
    return o;
}

[domain("tri")]
[outputcontrolpoints(3)]
[outputtopology("triangle_cw")]
[partitioning("fractional_odd")] // 平滑细分模式
[patchconstantfunc("patchConstantFunc")]
TessControlPoint HullProgram(
    InputPatch<TessControlPoint, 3> patch,
    uint id : SV_OutputControlPointID)
{ 
    return patch[id];
}

//DomainOutput DomainFunc(TessFactors factors, DomainOutput DomainOut, float3 baryCoords);
            
// 域着色器：计算位移顶点
[domain("tri")]
DomainOutput DomainProgram(
    TessFactors factors,
    OutputPatch<TessControlPoint, 3> patch,
    float3 baryCoords : SV_DomainLocation)
{
    DomainOutput o;
                
    // 插值顶点属性
    float3 positionWS = 
        baryCoords.x * patch[0].positionWS.xyz +
        baryCoords.y * patch[1].positionWS.xyz +
        baryCoords.z * patch[2].positionWS.xyz;
                    
    float3 normalWS = 
        baryCoords.x * patch[0].normalWS +
        baryCoords.y * patch[1].normalWS +
        baryCoords.z * patch[2].normalWS;
                    
    o.uv = 
        baryCoords.x * patch[0].uv +
        baryCoords.y * patch[1].uv +
        baryCoords.z * patch[2].uv;
    
    //o = DomainFunc(factors, o, patch, baryCoords);
    
    // 转换到裁剪空间
    o.positionCS = TransformWorldToHClip(positionWS);
    o.normalWS = normalWS;
    return o;
}