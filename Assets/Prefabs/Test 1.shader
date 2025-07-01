Shader "Custom/TessellationExample"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DisplacementMap ("Displacement Map", 2D) = "bump" {}
        _TessFactor ("Tessellation Factor", Range(1, 32)) = 4
        _Displacement ("Displacement", Range(0, 10)) = 0.3
        _DisplacementOffset ("Displacement Offset", Vector) = (0, 0, 0, 0)
        _Color ("Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        
        HLSLINCLUDE
        
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct TessControlPoint
            {
                float4 positionWS : INTERNALTESSPOS;
                float3 normalWS : NORMAL;
                float4 tangentWS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct TessellationFactors
            {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _TessFactor;
            float _Displacement;
            float4 _Color;
            CBUFFER_END
            
            sampler2D _MainTex;
            //sampler2D _DisplacementMap;
            TEXTURE2D(_DisplacementMap);
            SAMPLER(sampler_DisplacementMap);

            half3 _DisplacementOffset;

            // 应用向量位移
            float3 applyVectorDisplacement(float3 positionWS, float3 normalWS, float4 tangentWS, float2 uv) {



                // 采样向量位移贴图
                float4 displacementVector = 0;
                //= SAMPLE_TEXTURE2D(_DisplacementMap, sampler_DisplacementMap, uv);
                displacementVector = SAMPLE_TEXTURE2D_LOD(_DisplacementMap, sampler_DisplacementMap, uv, 0);



                
                // 从[0,1]转换到[-1,1]范围
                //displacementVector.xyz = displacementVector.xyz * 2.0 - 1.0;
                
                // 构造切线空间到世界空间的矩阵
                float3 bitangent = cross(normalWS, tangentWS.xyz) * tangentWS.w;
                float3x3 tangentToWorld = float3x3(
                    tangentWS.xyz,
                    bitangent,
                    normalWS
                );
                
                // 将向量从切线空间转换到世界空间
                float3 worldDisplacement = mul(tangentToWorld, displacementVector.xyz);
                
                // 应用位移缩放和偏移
                worldDisplacement = worldDisplacement * _Displacement + _DisplacementOffset.xyz;
                
                // 应用位移
                return positionWS + worldDisplacement;
            }

            // 顶点着色器
            TessControlPoint vert(Attributes v)
            {
                TessControlPoint o;
                o.positionWS.xyz = TransformObjectToWorld(v.positionOS);


                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.normalWS = normalInputs.normalWS;
                o.tangentWS.xyz = normalInputs.tangentWS;
                
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            // Hull Shader - 曲面细分控制
            [domain("tri")]
            [outputcontrolpoints(3)]
            [outputtopology("triangle_cw")]
            [partitioning("fractional_odd")]
            [patchconstantfunc("patchConstantFunction")]
            TessControlPoint hull(
                InputPatch<TessControlPoint, 3> patch,
                uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }

            // 曲面细分因子计算
            TessellationFactors patchConstantFunction(
                InputPatch<TessControlPoint, 3> patch)
            {
                TessellationFactors f;
                float avgTess = _TessFactor;
                f.edge[0] = avgTess;
                f.edge[1] = avgTess;
                f.edge[2] = avgTess;
                f.inside = avgTess;
                return f;
            }

            // Domain Shader - 曲面细分顶点计算
            //[domain("tri")]
            struct DomainOutput
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD0;
            };

            // Domain Shader - 曲面细分顶点计算 (修复了错误)
            [domain("tri")] // 添加必要的属性声明
            DomainOutput domain(
                TessellationFactors factors,
                OutputPatch<TessControlPoint, 3> patch,
                float3 barycentricCoordinates : SV_DomainLocation)
            {
                DomainOutput o;
                
                // 插值位置和法线
                float3 positionWS = 
                    patch[0].positionWS * barycentricCoordinates.x +
                    patch[1].positionWS * barycentricCoordinates.y +
                    patch[2].positionWS * barycentricCoordinates.z;
                
                float3 normalWS = 
                    patch[0].normalWS * barycentricCoordinates.x +
                    patch[1].normalWS * barycentricCoordinates.y +
                    patch[2].normalWS * barycentricCoordinates.z;
                normalWS = normalize(normalWS);

                float4 tangentWS = 
                    patch[0].tangentWS * barycentricCoordinates.x +
                    patch[1].tangentWS * barycentricCoordinates.y +
                    patch[2].tangentWS * barycentricCoordinates.z;
                tangentWS = normalize(tangentWS);
                

                float2 uv = 
                    patch[0].uv * barycentricCoordinates.x +
                    patch[1].uv * barycentricCoordinates.y +
                    patch[2].uv * barycentricCoordinates.z;
                
                // 位移贴图（简单示例）
                //float height = tex2Dlod(_DisplacementMap, float4(uv, 0, 0)).r;
                positionWS = applyVectorDisplacement(positionWS, normalWS, tangentWS, uv);
                //positionWS += normalWS * height * _Displacement;
                
                o.positionCS = TransformWorldToHClip(positionWS);
                o.normalWS = normalWS;
                o.uv = uv; // 简化UV插值
                return o;
            }

            // 片段着色器
            half4 frag(DomainOutput i) : SV_Target
            {

                
                half4 texColor = tex2D(_MainTex, i.uv);

                return half4(texColor);
            }

            void DepthNormalsFragment(
                DomainOutput input
                , out half4 outNormalWS : SV_Target0
            #ifdef _WRITE_RENDERING_LAYERS
                , out float4 outRenderingLayers : SV_Target1
            #endif
            )
            {

                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                #ifdef LOD_FADE_CROSSFADE
                LODFadeCrossFade(input.positionCS);
                #endif

                // Output...
                #if defined(_GBUFFER_NORMALS_OCT)
                float3 normalWS = normalize(input.normalWS);
                float2 octNormalWS = PackNormalOctQuadEncode(normalWS);             // values between [-1, +1], must use fp32 on some platforms
                float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);     // values between [ 0,  1]
                half3 packedNormalWS = half3(PackFloat2To888(remappedOctNormalWS)); // values between [ 0,  1]
                outNormalWS = half4(packedNormalWS, 0.0);
                #else
                outNormalWS = half4(NormalizeNormalPerPixel(input.normalWS), 0.0);
                #endif

                #ifdef _WRITE_RENDERING_LAYERS
                uint renderingLayers = GetMeshRenderingLayer();
                outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
                #endif
            }


            
        ENDHLSL
        
        Pass
        {
            Tags { "LightMode"="UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma hull hull
            #pragma domain domain
            #pragma fragment frag
            #pragma require tessellation tessHW
            
            // 曲面细分控制
            #pragma target 4.6
            
            
            ENDHLSL
        }

        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma hull hull
            #pragma domain domain
            #pragma fragment DepthNormalsFragment
            #pragma require tessellation tessHW

            
            ENDHLSL
        }
    }


}