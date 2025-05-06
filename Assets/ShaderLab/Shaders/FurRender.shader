
Shader "CharacterRender/Fur"
{
    Properties
    {
        [NoScaleOffset]_BaseMap("MainTex", 2D) = "White" { }
        //_FurMask("毛发的遮罩层贴图",2D) = "White" { }
        [Header(FurAlpha)]
        [NoScaleOffset]_FurAlpha("毛发的生成透明度贴图",2D) = "White" { }
        [NoScaleOffset]_FlowMap("毛发的UV偏移FlowMap",2D) = "Black" { }
        _FlowMapScale("FlowMap的权重",Range(0,1)) = 0
        _FurAlphaScale("毛发生成透明贴图缩放",Range(1,1000)) = 1
        _UvOffset("Uv的偏移程度:XY=UV偏移;ZW=UV扰动",Vector) = (0,0,0.2,0.2)
        [Header(FurSetting)]
        _FurLength("毛发的长度",Range(0,2)) = 1
        [Space(10)]
        [Header(Lighting)]
        _DiffColor("漫反射的颜色",Color) = (0,0,0,0)
        _OcclusionColor("毛发环境光遮蔽的颜色",Color) = (1,1,1,0)
        _FresnelLV("毛发的边缘透光的强度",Range(0,100)) = 0
        _LightFilter("平行光毛发穿透",Range(-0.5,0.5))  = 0.0
        [Toggle(_StrandSpecular_ON)]_StrandSpecular_ON("各向异性高光",Float) = 0
        _SpecColor1("高光颜色1",Color) = (1,1,1,0)
        _SpecColor2("高光颜色2",Color) = (1,1,1,0)
        _SpecInfo("高光的调节系数",Vector) = (1,1,1,0)
        [Toggle(_GI_ON)]_GI_ON("开启全局光照",Float) = 0
        [Space(10)]
        [Header(BasicSetting)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode",Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend Mode", Float) = 10
        [Toggle]_ZWrite("深度测试",Float) = 1.0
        [Toggle(_Shadow_ON)]_Shadow_ON("接收投射阴影",Float) = 1.0
        
        
        //FUR_OFFSET("Test FurOffset",Range(0,1)) = 1
    }

    SubShader
    {
        // URP的shader要在Tags中注明渲染管线是UniversalPipeline
        Tags
        {
            "RanderPipline" = "UniversalPipeline"
           
        }

        HLSLINCLUDE

            // 引入Core.hlsl头文件，替换UnityCG中的cginc
        #include <HLSLSupport.cginc>
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            // 将不占空间的材质相关变量放在CBUFFER中，为了兼容SRP Batcher
            CBUFFER_START(UnityPerMaterial)
                float4 _UvOffset;
                float4 _BaseMap_ST;
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
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            // 材质单独声明，使用DX11风格的新采样方法
            
            #ifdef _DEBUG_ON
                float _DebugMode;
            #endif

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                float3 normal     : NORMAL;
                #ifdef _StrandSpecular_ON
                float4 tangent    : TANGENT;
                #endif
                    
                float4 color      : COlOR;
                #ifdef _GI_ON
                float2 lightmapUV : TEXCOORD1;
                #endif
                
            };

            struct Varyings
            {
                float4 positionCS          : SV_POSITION;
                float4 uv                  : TEXCOORD0;
                
                float3 vertexSH            : TEXCOORD4;
                
                float4 color               : COLOR;//xyz顶点光照颜色，w环境光遮蔽
                float4 lightmapUVOrVertexSH: TEXCOORD1;
                float3 normal              : TEXCOORD2;
                float4 shadowCoord         : TEXCOORD3;
            };

        ENDHLSL

        Pass
        {
            // 声明Pass名称，方便调用与识别
            Name "FurRender"
            Tags {"LightMode" = "FurRenderLayer"
                 "RanderType" = "Opaque"}
            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            HLSLPROGRAM

                // 声明顶点/片段着色器对应的函数
                #pragma target 5.0
                #pragma vertex vert
                #pragma fragment frag
                #pragma shader_feature _ _GI_ON
                #pragma shader_feature _ _StrandSpecular_ON
                #pragma shader_feature _ _Shadow_ON
                #pragma shader_feature _DEBUG_ON
                //开启阴影相关的宏
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
                #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
                #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
                #pragma multi_compile_fragment _ _SHADOWS_SOFT
                //全局光照相关的宏
                #pragma multi_compile _ LIGHTMAP_ON
                #pragma multi_compile _ DIRLIGHTMAP_COMBINED LightMap
                #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            
                float3 StrandSpecular(float3 T, float3 V, float3 L,float exponent)
                {
                    float3 H = normalize(L+V);
                    float dotTH = dot(T,H);
                    float sinTH = sqrt(1 - dotTH*dotTH);
                    float dirAtten = smoothstep(-1, 0, dotTH);
                    return dirAtten*pow(sinTH, exponent);
                }
                float3 Kajiya_KaySpecular(float3 furDir, float3 normalWS, float3 viewVec, float3 lightDir)
                {
                    _SpecInfo = max(1e-4f, _SpecInfo);
                    float3 T1 = ShiftTangent(furDir,normalWS,_SpecInfo.y*0.1);
                    float3 T2 = ShiftTangent(furDir,normalWS,_SpecInfo.w*0.1);
                    float Spec1 = StrandSpecular(T1,viewVec,lightDir,_SpecInfo.x*16);
                    float Spec2 = StrandSpecular(T2,viewVec,lightDir,_SpecInfo.z*16);
                    float3 SpecColor = Spec1 * _SpecColor1+Spec2 * _SpecColor2;
                    return SpecColor;
                }
                // 顶点着色器
                Varyings vert(Attributes input)
                {

                    
                    float4 furInfo = tex2Dlod(_FlowMap,float4(input.uv.xy,0,0));
                    
                    //将顶点挤出
                    FUR_OFFSET = max(0,FUR_OFFSET*furInfo.b); 
                    float3 aNormal = (input.normal.xyz);
                    float3 n = aNormal*(FUR_OFFSET)*_FurLength;
                    input.positionOS.xyz +=n;
                    // GetVertexPositionInputs方法根据使用情况自动生成各个坐标系下的定点信息
                    const VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                    Varyings output;
                    output.positionCS = vertexInput.positionCS;
                   
            
                    //数据准备
                    float3 normalWS = normalize(TransformObjectToWorldNormal(input.normal));
                    output.normal = normalWS;
                    float3 positionWS = vertexInput.positionWS;
                    float3 viewVec = normalize(_WorldSpaceCameraPos-positionWS);
                    float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
                    float2 inUv = TRANSFORM_TEX(input.uv.xy,_BaseMap);
                    
                    //uv的偏移，毛发的偏移
                    float2 flowMapOff = furInfo.rg;
                    flowMapOff = (flowMapOff*2 -1) * _FlowMapScale;
                    float2 uvoffset = _UvOffset.xy * FUR_OFFSET + flowMapOff*20 * FUR_OFFSET;
                    uvoffset *=0.1;
                    float2 uv1 = TRANSFORM_TEX(input.uv.xy,_BaseMap) + uvoffset*float2(1,1)/_FurAlphaScale;
                    float2 uv2 = TRANSFORM_TEX(input.uv.xy,_BaseMap)*_FurAlphaScale + uvoffset;
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
                    #ifdef _Shadow_ON
                        DirLight*=mainLight.shadowAttenuation*mainLight.distanceAttenuation;
                    #endif
            
                    //GI采样
                    //TODO 环境光
                    half3 SHL;
                    SHL = lerp(SH*_OcclusionColor,SH,Occlusion);
            
                    #ifdef _GI_ON
                    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                    OUTPUT_SH(normalWS, output.vertexSH);
                    output.color.w = Occlusion;
                    SHL = float3(0,0,0);
                    #endif
            
                    
            
                    //毛发的各向异性高光
                    #if defined(_StrandSpecular_ON)
                        //计算毛发的方向
                        float3 tangentWS = normalize(mul(unity_ObjectToWorld, input.tangent.xyz).xyz);
                        float3 binormalWS = cross(normalWS, tangentWS) * input.tangent.w ;
                        float3x3 TBN = float3x3(tangentWS, binormalWS, normalWS);
                        float3 furDir = - SafeNormalize(mul(float3(uvoffset.xy, 0), TBN));
                        //furDir = binormalWS;
                        float spec = Kajiya_KaySpecular(furDir, normalWS, viewVec, lightDir) * furInfo.z * saturate(NoL * 4);
                        SHL += spec;
                    #endif

                    
                    
                    //光照的计算
                    SHL +=RimLight;
                    SHL +=DirLight*_DiffColor;
                    
                    
                    output.color.xyz = SHL;

                    

            
                    return output;
                }

                // 片段着色器
                half4 frag(Varyings input) : SV_Target
                {
                    
                    //对毛发的噪声Alpha图和主图片进行取样
                    half3 NoiseTex = SAMPLE_TEXTURE2D(_FurAlpha, sampler_FurAlpha, input.uv.zw);
                    half3 MainTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy);
                    half Noise = NoiseTex.r;
                    
                    //光照采样开启GI之后采样GI，不开启则默认
                    half4 col = float4(MainTex,1);
                    #ifdef _GI_ON
                    float3 bakeGI = SAMPLE_GI(input.lightmapUV,input.vertexSH,input.normal);
                    //MixRealtimeAndBakedGI(GetMainLight(),input.normal,bakeGI,half4(0,0,0,0));
                    bakeGI = lerp(bakeGI*_OcclusionColor,bakeGI,input.color.w);
                    col.xyz *= (input.color.xyz+bakeGI);
                    #else
                    col.xyz *=input.color.xyz;
                    #endif
                    col.a = max(0,Noise - FUR_OFFSET);
                    
                    //Debug
                    #ifdef _DEBUG_ON
                        col.xyz = input.color.xyz;
                    #endif
                   
                    return col;
                    
                }
            
            ENDHLSL
        }
    
    Pass
        {
             // 声明Pass名称，方便调用与识别
            Name "FurRender"
            Tags {"LightMode" = "FurRenderBase"
                 "RanderType" = "Opaque"}
            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            HLSLPROGRAM

                // 声明顶点/片段着色器对应的函数
                #pragma target 5.0
                #pragma vertex vert
                #pragma fragment frag
                #pragma shader_feature _ _GI_ON
                #pragma shader_feature _ _StrandSpecular_ON
                #pragma shader_feature _ _Shadow_ON
                //开启阴影相关的宏
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
                #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
                #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
                #pragma multi_compile_fragment _ _SHADOWS_SOFT
                //全局光照相关的宏
                #pragma multi_compile _ LIGHTMAP_ON
                #pragma multi_compile _ DIRLIGHTMAP_COMBINED LightMap
                #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            
                // 顶点着色器
                Varyings vert(Attributes input)
                {

                    //将顶点挤出

                    float3 aNormal = (input.normal.xyz);
                    float3 n = aNormal*(FUR_OFFSET)*_FurLength;
                    input.positionOS.xyz +=n;
                    // GetVertexPositionInputs方法根据使用情况自动生成各个坐标系下的定点信息
                    const VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                    Varyings output;
                    output.positionCS = vertexInput.positionCS;
                   
            
                    //数据准备
                    float3 normalWS = normalize(TransformObjectToWorldNormal(input.normal));
                    output.normal = normalWS;
                    float3 positionWS = vertexInput.positionWS;
                    float3 viewVec = normalize(_WorldSpaceCameraPos-positionWS);
                    float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
                    float2 inUv = TRANSFORM_TEX(input.uv.xy,_BaseMap);
                    
                    //uv的偏移，毛发的偏移

                    float2 uv1 = TRANSFORM_TEX(input.uv.xy,_BaseMap);
                    output.uv = float4(uv1,0,0);
            
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
                    #ifdef _Shadow_ON
                        DirLight*=mainLight.shadowAttenuation*mainLight.distanceAttenuation;
                    #endif
            
                    //GI采样
                    //TODO 环境光
                    half3 SHL;
                    SHL = lerp(SH*_OcclusionColor,SH,Occlusion);
                    #ifdef _GI_ON
                    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                    OUTPUT_SH(normalWS,output.vetexSH);
                    output.color.w = Occlusion;
                    SHL = float3(0,0,0);
                    #endif
                    
            
                    
                    
                    
                    
                    
                    //光照的计算
                    SHL +=RimLight;
                    SHL +=DirLight*_DiffColor;
                    output.color.xyz = SHL;
                   
                    return output;
                }

                // 片段着色器
                half4 frag(Varyings input) : SV_Target
                {
                    
                    //对毛发的噪声Alpha图和主图片进行取样
                    //half3 NoiseTex = SAMPLE_TEXTURE2D(_FurAlpha, sampler_FurAlpha, input.uv.zw);
                    half3 MainTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy);
                    //half Noise = NoiseTex.r;
                    
                    //光照采样开启GI之后采样GI，不开启则默认
                    half4 col = float4(MainTex,1);
                    #ifdef _GI_ON
                    float3 bakeGI = SAMPLE_GI(input.lightmapUV,input.vertexSH,input.normal);
                    //MixRealtimeAndBakedGI(GetMainLight(),input.normal,bakeGI,half4(0,0,0,0));
                    bakeGI = lerp(bakeGI*_OcclusionColor,bakeGI,input.color.w);
                    col.xyz *= (input.color.xyz+bakeGI);
                    #else
                    col.xyz *=input.color.xyz;
                    #endif
                    
                    //col.a = max(0,Noise - FUR_OFFSET);
                    return col;
                    
                }
            
            ENDHLSL
        }
    

   
        Pass
        {
            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}
            
            ZWrite On // the only goal of this pass is to write depth!
            ZTest LEqual // early exit at Early-Z stage if possible            
            ColorMask 0 // we don't care about color, we just want to write depth, ColorMask 0 will save some write bandwidth
            Cull Back // support Cull[_Cull] requires "flip vertex normal" using VFACE in fragment shader, which is maybe beyond the scope of a simple tutorial shader
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            half3 _LightDirection;
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                float3 posWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = normalize(TransformObjectToWorldNormal(input.normal.xyz));
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(posWS,normalWS,_LightDirection));
                //not UNITY_REVERSE_Z!!!!
                #if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, positionCS.w*UNITY_NEAR_CLIP_VALUE);
                #else
                positionCS.z = max(positionCS.z, positionCS.w*UNITY_NEAR_CLIP_VALUE);
                #endif
                output.positionCS = positionCS;
                return output;
            }
            
            real4 frag(Varyings input): SV_TARGET
            {
                return 0;
            }
            
            ENDHLSL
            
        }

         Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            
            // -------------------------------------
            // Render State Commands
            ZWrite On
            ColorMask R

            HLSLPROGRAM
            #pragma target 2.0
            Varyings vert(Attributes input)
            {

                
                float4 furInfo = tex2Dlod(_FlowMap,float4(input.uv.xy,0,0));
                
                //将顶点挤出
                FUR_OFFSET = max(0,FUR_OFFSET*furInfo.b); 
                float3 aNormal = (input.normal.xyz);
                float3 n = aNormal*(FUR_OFFSET)*_FurLength;
                input.positionOS.xyz +=n;
                // GetVertexPositionInputs方法根据使用情况自动生成各个坐标系下的定点信息
                const VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                Varyings output;
                output.positionCS = vertexInput.positionCS;
               
        
                //数据准备
                float3 normalWS = normalize(TransformObjectToWorldNormal(input.normal));
                output.normal = normalWS;
                float3 positionWS = vertexInput.positionWS;
                float3 viewVec = normalize(_WorldSpaceCameraPos-positionWS);
                float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
                float2 inUv = TRANSFORM_TEX(input.uv.xy,_BaseMap);
                
                //uv的偏移，毛发的偏移
                float2 flowMapOff = furInfo.rg;
                flowMapOff = (flowMapOff*2 -1) * _FlowMapScale;
                float2 uvoffset = _UvOffset.xy * FUR_OFFSET + flowMapOff*20 * FUR_OFFSET;
                uvoffset *=0.1;
                float2 uv1 = TRANSFORM_TEX(input.uv.xy,_BaseMap) + uvoffset*float2(1,1)/_FurAlphaScale;
                float2 uv2 = TRANSFORM_TEX(input.uv.xy,_BaseMap)*_FurAlphaScale + uvoffset;
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
                #ifdef _Shadow_ON
                    DirLight*=mainLight.shadowAttenuation*mainLight.distanceAttenuation;
                #endif
        
                //GI采样
                //TODO 环境光
                half3 SHL;
                SHL = lerp(SH*_OcclusionColor,SH,Occlusion);
        
                #ifdef _GI_ON
                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                OUTPUT_SH(normalWS, output.vertexSH);
                output.color.w = Occlusion;
                SHL = float3(0,0,0);
                #endif
        
                
        
                //毛发的各向异性高光
                #if defined(_StrandSpecular_ON)
                    //计算毛发的方向
                    float3 tangentWS = normalize(mul(unity_ObjectToWorld, input.tangent.xyz).xyz);
                    float3 binormalWS = cross(normalWS, tangentWS) * input.tangent.w ;
                    float3x3 TBN = float3x3(tangentWS, binormalWS, normalWS);
                    float3 furDir = - SafeNormalize(mul(float3(uvoffset.xy, 0), TBN));
                    //furDir = binormalWS;
                    float spec = Kajiya_KaySpecular(furDir, normalWS, viewVec, lightDir) * furInfo.z * saturate(NoL * 4);
                    SHL += spec;
                #endif

                
                
                //光照的计算
                SHL +=RimLight;
                SHL +=DirLight*_DiffColor;
                
                
                output.color.xyz = SHL;

                

        
                return output;
            }

            // -------------------------------------
            // Shader Stages
            #pragma vertex vert
            
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #define _OUTLINE 1

            
            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormalsOnly"
            Tags
            {
                "LightMode" = "DepthNormalsOnly"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On

            HLSLPROGRAM
            #pragma target 2.0
                           
            Varyings vert(Attributes input)
            {

                
                float4 furInfo = tex2Dlod(_FlowMap,float4(input.uv.xy,0,0));
                
                //将顶点挤出
                FUR_OFFSET = max(0,FUR_OFFSET*furInfo.b); 
                float3 aNormal = (input.normal.xyz);
                float3 n = aNormal*(FUR_OFFSET)*_FurLength;
                input.positionOS.xyz +=n;
                // GetVertexPositionInputs方法根据使用情况自动生成各个坐标系下的定点信息
                const VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                Varyings output;
                output.positionCS = vertexInput.positionCS;
               
        
                //数据准备
                float3 normalWS = normalize(TransformObjectToWorldNormal(input.normal));
                output.normal = normalWS;
                float3 positionWS = vertexInput.positionWS;
                float3 viewVec = normalize(_WorldSpaceCameraPos-positionWS);
                float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
                float2 inUv = TRANSFORM_TEX(input.uv.xy,_BaseMap);
                
                //uv的偏移，毛发的偏移
                float2 flowMapOff = furInfo.rg;
                flowMapOff = (flowMapOff*2 -1) * _FlowMapScale;
                float2 uvoffset = _UvOffset.xy * FUR_OFFSET + flowMapOff*20 * FUR_OFFSET;
                uvoffset *=0.1;
                float2 uv1 = TRANSFORM_TEX(input.uv.xy,_BaseMap) + uvoffset*float2(1,1)/_FurAlphaScale;
                float2 uv2 = TRANSFORM_TEX(input.uv.xy,_BaseMap)*_FurAlphaScale + uvoffset;
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
                #ifdef _Shadow_ON
                    DirLight*=mainLight.shadowAttenuation*mainLight.distanceAttenuation;
                #endif
        
                //GI采样
                //TODO 环境光
                half3 SHL;
                SHL = lerp(SH*_OcclusionColor,SH,Occlusion);
        
                #ifdef _GI_ON
                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                OUTPUT_SH(normalWS, output.vertexSH);
                output.color.w = Occlusion;
                SHL = float3(0,0,0);
                #endif
        
                
        
                //毛发的各向异性高光
                #if defined(_StrandSpecular_ON)
                    //计算毛发的方向
                    float3 tangentWS = normalize(mul(unity_ObjectToWorld, input.tangent.xyz).xyz);
                    float3 binormalWS = cross(normalWS, tangentWS) * input.tangent.w ;
                    float3x3 TBN = float3x3(tangentWS, binormalWS, normalWS);
                    float3 furDir = - SafeNormalize(mul(float3(uvoffset.xy, 0), TBN));
                    //furDir = binormalWS;
                    float spec = Kajiya_KaySpecular(furDir, normalWS, viewVec, lightDir) * furInfo.z * saturate(NoL * 4);
                    SHL += spec;
                #endif

                
                
                //光照的计算
                SHL +=RimLight;
                SHL +=DirLight*_DiffColor;
                
                
                output.color.xyz = SHL;

                

        
                return output;
            }
            // -------------------------------------
            // Shader Stages
            #pragma vertex vert 
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT // forward-only variant
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            
            #define _OUTLINE 1

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitDepthNormalsPass.hlsl"
            ENDHLSL
        }
    
    }

   

    
    CustomEditor "DebugShaderGUI"
}
