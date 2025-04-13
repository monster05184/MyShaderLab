Shader "Water"
{
    Properties
    {
         // ---- Begin build-in properties
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 2
        [SimpleToggle] _ZWrite("ZWrite", Float) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTestMode("ZTest", Float) = 4
        [SimpleToggle] _SpOpacity("透明是否保留高光", int) = 0
        [Enum(UnityEngine.Rendering.YABlendMode)] _BlendMode("Blend Mode", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("SrcBlend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("DstBlend", Float) = 0
        [Toggle] _AlphaTest("Alpha Test", Float) = 0
        [Toggle] _Visibility("Use Visibility", Float) = 0
        _OcclusionScale("Occlusion Scale", Range(0, 1)) = 1
        _GIBakerMode("GIBakerMode", Int) = 10
        [IntRange] _StencilRef("Stencil Ref$Group#Stencil$", Range(0, 255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp("Stencil Comp$Group#Stencil$", Float) = 8
        [IntRange] _StencilReadMask("Stencil Read Mask$Group#Stencil$", Range(0, 255)) = 255
        [IntRange] _StencilWriteMask("Stencil Write Mask$Group#Stencil$", Range(0, 255)) = 255
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass("Stencil Pass$Group#Stencil$", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilFail("Stencil Fail$Group#Stencil$", Float) = 0
        
        
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilZFail("Stencil ZFail$Group#Stencil$", Float) = 0
        
        //Surfaces
        _AlbedoMap("Albedo Map", 2D) = "white" {}
        _AlbedoColor("Albedo Color", Color) = (1, 1, 1, 1)
        
        _NormalMap("Normal Map", 2D) = "bump" {}
        _MaterialParamsMap("Material Params Map", 2D) = "white" {}
        
        _MetallicMultiplier("Metallic Multiplier", Range(0, 10)) = 1
        _RoughnessMultiplier("Roughness Multiplier", Range(0, 10)) = 1
        
        [HideInInspector]_Displace("Displace", 2D) = "black"{ }
        [HideInInspector]_Normal("Normal", 2D) = "black"{ }
        [HideInInspector]_Bubble("Bubble", 2D) = "black"{ }
        
        _Depth("DepthOfWater", Range(0, 1000)) = 1
        _DetailNormal("Detail Normal", 2D) = "White"{ }
        _DetailNormalScale("Detail Normal Scale", Range(0.1, 2)) = 1
        _DetailNormalIntensity("Detail Normal Intensity", Range(0.1, 2)) = 1
        _DetailNormalFlowX("Detail Normal Flow X", Range(0, 1)) = 0.1
        _DetailNormalFlowY("Detail Normal Flow Y", Range(0, 1)) = 0.1
        _AbsorptionScatteringTexture("Absorption Scatering Texture", 2D) = "white"{ }
        
        [Header(Bubble)]
        _BubbleTexture("BubbleTexture", 2D) = "white"{ }
        _BubbleScale("BubbleScale", Range(0,400)) = 100 
        _FoamColor("Foam Color 浮沫的颜色", Color) = (1.0, 1.0, 1.0, 1.0)
        _FoamParallax("Foam Parallex, 浮沫的视差贴图的高度", Float) = 1
        _FoamFeather("Foam Feather", Float) = 0.1
        
        _Metallic("Metallic", Range(0, 1)) = 0
        _OceanDeepColor("OceanDeppColor", Color) = (1, 1, 1, 0)
        _OceanShoalColor("OceanShoalColor", Color) = (1, 1, 1, 0)
        _OceanOpacity("OceanOpacity", Range(0.1,3)) = 1 
        
        
        [Header(SSS)]
        _SSSColor("SSS Color", Color) = (1, 1, 1, 0)
        _SSSScale("SSS Scale", Range(0, 2)) = 1
        _SSSPower("SSS Power", Range(0, 10)) = 4
        _SSSDistortion("SSS Normal Distion, 次表面散射的法线偏移", Range(0,1)) = 0.1
        
        
        [Header(Caustics)]
        [NoScaleOffset]_CausticsMap("Caustics Map", 2D) = "black"{ }
        _CausticsScale("Caustics Scale", Range(0.1,5)) = 1
        _WaterLevel("Water Level 水位", Float) = 0
        _CausticsOffset("Caustics Offset 焦散的上下偏移", Float) = 0
        _CausticsIntensity("Caustics Intensity", Range(0.1, 6)) = 1
        _CausticsBlendDistance("Caustics Blend Distance 焦散混合的宽度", Range(0.1, 10)) = 1
        
        

    }
    SubShader
    {
        Tags {             
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit"
            "IgnoreProjector" = "True" 
        }
        LOD 100
        
        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #define DEBUG
            #pragma vertex vert_pbr
            #pragma fragment frag_pbr
            // make fog work
            #pragma multi_compile_fog
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Water.hlsl"






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

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthOnlyVertex
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

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthNormalsVertex
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

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitDepthNormalsPass.hlsl"
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
}
