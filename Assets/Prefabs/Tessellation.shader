Shader "Tessellation"
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
        
        [Main(Unlit, _, on, off)]_UnlitGroup("Unlit Settings", float) = 1
        [Sub(Unlit)]_BaseMap("Texture", 2D) = "white" {}
        [Sub(Unlit)]_BaseColor("Color", Color) = (1, 1, 1, 1)
        
        

        
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
            Name "Unlit"

            // -------------------------------------
            // Render State Commands
            AlphaToMask[_AlphaToMask]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex vert_unlit
            #pragma fragment frag_unlit


            
            #include "Tessellation.hlsl"



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
            #pragma shader_feature_local_fragment _ALPHATessellation_ON

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
            #include "Tessellation.hlsl"
            #include "Assets/ShaderLab/DepthPassUnlit.hlsl"

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
    CustomEditor "LWGUI.LWGUI"
}
