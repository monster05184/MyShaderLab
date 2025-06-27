Shader "Water"
{
    Properties
    {
        [Main(Basic, _, on, off)] _BasicGroup ("Basic Settings", float) = 0
		[SubEnum(Basic, UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
		[SubEnum(Basic, UnityEngine.Rendering.BlendMode)] _SrcBlend ("SrcBlend", Float) = 1
		[SubEnum(Basic, UnityEngine.Rendering.BlendMode)] _DstBlend ("DstBlend", Float) = 0
		[SubToggle(Basic)] _ZWrite ("ZWrite ", Float) = 1
		[SubEnum(Basic, UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4 // 4 is LEqual
		[SubEnum(Basic, RGBA, 15, RGB, 14)] _ColorMask ("ColorMask", Float) = 15 // 15 is RGBA (binary 1111)

        [Advanced(Stencil)][Sub(Basic)]_StencilRef("Stencil Ref", Range(0, 255)) = 0
        [Advanced][SubEnum(Basic, UnityEngine.Rendering.CompareFunction)] _StencilComp("Stencil Comp", Float) = 8
        [Advanced][Sub(Basic)]_StencilReadMask("Stencil Read Mask", Range(0, 255)) = 255
        [Advanced][Sub(Basic)] _StencilWriteMask("Stencil Write Mask", Range(0, 255)) = 255
        [Advanced][SubEnum(Basic, UnityEngine.Rendering.StencilOp)] _StencilPass("Stencil Pass", Float) = 0
        [Advanced][SubEnum(Basic, UnityEngine.Rendering.StencilOp)] _StencilFail("Stencil Fail", Float) = 0
        [Advanced][SubEnum(Basic, UnityEngine.Rendering.StencilOp)] _StencilZFail("Stencil ZFail", Float) = 0
        
         
        //Surface
        [Main(Surface, _, on, off)]_SurfaceGroup("Surface", Float) = 1
        [Sub(Surface)]_AlbedoMap("Albedo Map", 2D) = "white" {}
        [Sub(Surface)]_AlbedoColor("Albedo Color", Color) = (1, 1, 1, 1)
        
        [Sub(Surface)]_EnvMap("环境贴图", Cube) = "grey" {}
        [Sub(Surface)]_EnvColor("环境光颜色", Color) = (1, 1, 1, 1)
        
        [Sub(Surface)][Normal]_NormalMap("Normal Map", 2D) = "bump" {}
        [Sub(Surface)]_MaterialParamsMap("Material Params Map", 2D) = "white" {}
        
        [Sub(Surface)]_MetallicMultiplier("Metallic Multiplier", Range(0, 2)) = 0
        [Sub(Surface)]_RoughnessMultiplier("Roughness Multiplier", Range(-1, 1)) = 0
        [Sub(Surface)]_AOMultiplier("AO Multiplier", Range(0, 1)) = 0
        
        [Main(WaterSetting, _, on, off)]WaterGroup("Reflection", Float) = 1
        [Sub(WaterSetting)]_WaterDepth("Water Depth", Float) = 1
        
        [Main(Reflection, _, on, off)]_ReflectionGroup("Reflection", Float) = 1
        [Sub(Reflection)]_ReflectionMap("Reflection Map", 2D) = "grey" {}
        [Sub(Reflection)]_ReflectionColor("Reflection Color", Color) = (1, 1, 1, 1)
        
        [Main(Refraction, _, on, off)]_RefractionGroup("Refraction", Float) = 1
        [Sub(Refraction)]_RefractionMap("Refraction Map", 2D) = "grey" {}
        
        [Main(Absorption, _, on, off)]_AbsorptionGroup("Absorption", Float) = 1
        [Sub(Absorption)]_AbsorptionRamp("Refraction Map", 2D) = "grey" {}
        
        [Main(Caustics, _, on, off)]_CausticsGroup("Caustics", Float) = 1
        [NoScaleOffset]_CausticsMap("Caustics Map", 2D) = "black"{ }
        _CausticsScale("Caustics Scale", Range(0.1,5)) = 1
        _WaterLevel("Water Level 水位", Float) = 0
        _CausticsOffset("Caustics Offset 焦散的上下偏移", Float) = 0
        _CausticsColor("Caustics Color", Color) = (1, 1, 1, 1)
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
        
        Cull [_Cull]
        ZWrite [_ZWrite]
        ZTest [_ZTest]
        Blend [_SrcBlend] [_DstBlend]
        ColorMask [_ColorMask]
        Stencil
        {
            Ref [_StencilRef]
            Comp [_StencilComp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
            Pass [_StencilPass]
            Fail [_StencilFail]
            ZFail [_StencilZFail]
        }
        
        Pass
        {
            Name "Forward"
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
            #include "Water.hlsl"
            #include "Assets/ShaderLab/DepthPassPBR.hlsl"

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
    CustomEditor "LWGUI.LWGUI"
}
