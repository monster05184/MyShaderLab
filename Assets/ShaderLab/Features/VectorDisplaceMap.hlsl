            // --- 外壳着色器：控制细分因子 ---
[domain("tri")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[patchconstantfunc("hull_const")]
[outputcontrolpoints(3)]
appdata hull(InputPatch<appdata, 3> patch, uint id : SV_OutputControlPointID)
{
    return patch[id];
}

UnityTessellationFactors hull_const(InputPatch<appdata, 3> patch)
{
    UnityTessellationFactors o;
    o.edge[0] = _Tessellation;
    o.edge[1] = _Tessellation;
    o.edge[2] = _Tessellation;
    o.inside = _Tessellation;
    return o;
}

// --- 域着色器：执行矢量置换 ---
[domain("tri")]
v2f domain(UnityTessellationFactors factors, OutputPatch<appdata, 3> patch, float3 baryCoords : SV_DomainLocation)
{
    appdata v;
    v.vertex = patch[0].vertex * baryCoords.x + patch[1].vertex * baryCoords.y + patch[2].vertex * baryCoords.z;
    v.normal = patch[0].normal * baryCoords.x + patch[1].normal * baryCoords.y + patch[2].normal * baryCoords.z;
    v.tangent = patch[0].tangent * baryCoords.x + patch[1].tangent * baryCoords.y + patch[2].tangent * baryCoords.z;
    v.uv = patch[0].uv * baryCoords.x + patch[1].uv * baryCoords.y + patch[2].uv * baryCoords.z;

    // 采样VDM并转换到模型空间
    float3 vdm = tex2Dlod(_VDMap, float4(v.uv, 0, 0)).rgb * 2 - 1; // 从[0,1]解码到[-1,1]
    float3x3 TBN = float3x3(
        UnityObjectToWorldDir(v.tangent.xyz),
        UnityObjectToWorldDir(cross(v.normal, v.tangent.xyz) * v.tangent.w),
        UnityObjectToWorldDir(v.normal)
    );
    float3 worldDisplacement = mul(TBN, vdm) * _DisplacementStrength;
    v.vertex.xyz += mul(unity_WorldToObject, float4(worldDisplacement, 0)).xyz; // 应用置换

    return vert(v);
}

