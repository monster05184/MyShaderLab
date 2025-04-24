Shader "NPRCharacter"
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
        
        //Surface
        _AlbedoMap("Albedo Map", 2D) = "white" {}
        _AlbedoColor("Albedo Color", Color) = (1, 1, 1, 1)
        
        _NormalMap("Normal Map", 2D) = "bump" {}
        _MaterialParamsMap("Material Params Map", 2D) = "white" {}
        
        _MetallicMultiplier("Metallic Multiplier", Range(0, 10)) = 1
        _RoughnessMultiplier("Roughness Multiplier", Range(0, 10)) = 1
        [Header(Light)]
        _SpecColor("Spec Color", Color) = (0, 0, 0, 1)
        
        //Outline 
        [Toggle] _SmoothNormal("Smooth Normal", Float) = 0
        _OutlineColor("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineWidth("Outline Width", Range(0, 1)) = 0.1
        
        //SDF
        [Toggle] _SDF("sdf 面部阴影", float) = 0
        _SDFTex("SDF 图", 2D) = "white"
        _SDFValue("sdf的值", Float) = 0
        _SDFSign("sdf sign", int) = 1
        _SDFSmooth("sdf 平滑度", Float) = 0

        //_SpecColor("Spec Color", Color) = (0, 0, 0, 1)
        

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
            #pragma shader_feature _ _SDF_ON
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "NPRCharacter.hlsl"

            ENDHLSL
        }

//        Pass
//        {
//            Name "Outline"
//            Tags
//            {
//                "LightMode" = "UniversalForward"
//            }
//            Cull Back
//            ZWrite On
//            ZTest LEqual
//            HLSLPROGRAM
//            
//            #pragma vertex vert_outline
//            #pragma fragment frag_outline
//            // make fog work
//            #define _OUTLINE 1
//            #pragma shader_feature _SMOOTHNORMAL_ON
//            
//            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
//            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//            #include "..\..\NPR\Outline.hlsl"
//
//            ENDHLSL
//            
//        }



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
            #pragma vertex vert_outline
            
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
            #include  "..\..\NPR\Outline.hlsl"
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
            
            #define _OUTLINE 1

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitDepthNormalsPass.hlsl"
            #include  "..\..\NPR\Outline.hlsl"
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
