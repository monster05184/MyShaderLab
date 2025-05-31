Shader "FurLayer"
{
    Properties
    {
        // BlendMode
        _Blend("__mode", Float) = 0.0
        _Cull("__cull", Float) = 2.0
        [ToggleUI] _AlphaClip("__clip", Float) = 0.0
        _BlendOp("__blendop", Float) = 0.0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("SrcBlend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("DstBlend", Float) = 0
        _SrcBlendAlpha("__srcA", Float) = 1.0
        _DstBlendAlpha("__dstA", Float) = 0.0
        _ZWrite("__zw", Float) = 1.0
        _AlphaToMask("__alphaToMask", Float) = 0.0


        [NoScaleOffset] _AlbedoMap("MainTex", 2D) = "White" { }
        //_FurMask("毛发的遮罩层贴图",2D) = "White" { }
        [Header(FurAlpha)]
        [NoScaleOffset]_FurAlpha("毛发的生成透明度贴图",2D) = "White" { }
        [NoScaleOffset]_FlowMap("毛发的UV偏移FlowMap",2D) = "Black" { }
        _FlowMapScale("FlowMap的权重",Range(0,1)) = 0
        _FurAlphaScale("毛发生成透明贴图缩放",Range(0,10)) = 1
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
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100

        // -------------------------------------
        // Render State Commands
        Blend [_SrcBlend][_DstBlend], [_SrcBlendAlpha][_DstBlendAlpha]
        ZWrite [_ZWrite]
        Cull [_Cull]

        Pass
        {
            Name "Unlit"
            Tags
            {
                "LightMode" = "FurRenderLayer"
            }

            // -------------------------------------
            // Render State Commands
            AlphaToMask[_AlphaToMask]

            HLSLPROGRAM
            #pragma target 2.0
            #pragma shader_feature _ _GI_ON
            #pragma shader_feature _ _StrandSpecular_ON

            // -------------------------------------
            // Shader Stages
            #pragma vertex vert_unlit
            #pragma fragment frag_unlit
            #define DEBUG


            
            #include "FurLayer.hlsl"



            ENDHLSL
        }
        Pass
        {
            Name "Unlit"
            Tags
            {
                "LightMode" = "FurRenderBase"
            }
            
            // -------------------------------------
            // Render State Commands
            AlphaToMask[_AlphaToMask]
            Blend One Zero


            HLSLPROGRAM
            #pragma target 2.0
            #pragma shader_feature _ _GI_ON
            #pragma shader_feature _ _StrandSpecular_ON

            // -------------------------------------
            // Shader Stages
            #pragma vertex vert_unlit
            #pragma fragment frag_unlit

            #define DEBUG


            
            #include "FurLayer.hlsl"



            ENDHLSL
        }
                




        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            // -------------------------------------
            // Render State Commands
            Cull Off

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaUnlit

            // -------------------------------------
            // Unity defined keywords
            #pragma shader_feature EDITOR_VISUALIZATION

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitMetaPass.hlsl"
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
