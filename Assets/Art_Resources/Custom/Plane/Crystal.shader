Shader "Unlit/Crystal"
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
        // ---- End build-in properties
        // ---- Begin material properties (NPRStandard_Transmission.cginc)
        [Toggle] _Anisotropy("Anisotropy", Int) = 0
        [Header(Diffuse)] [HDR] _SelfGI("Self GI COLOR", Color) = (0.9, 0.5, 0.2, 1)
        _AlphaAll("Alpha All", Range (0, 1)) = 1.0
        _AlbedoMap("Albedo Map (RGB,A)", 2D) = "white" {}
        _AlbedoColor("Albedo COLOR", Color) = (0.1, 0.1, 0.1, 1)
        _MaterialParamsMap("R=roughness, G=metallic,B=AO,A=colormask", 2D) = "white"{}
        _NormalMap("Normal Map", 2D) = "bump" {}
        [HDR] _EmissiveColor("Emissive COLOR", Color) = (1.0, 1.0, 1.0, 1)
        _EmissiveMap("Emissive Map (RGB)", 2D) = "black" {}
        _MetallicMultiplier("Metallic multiplier (DEBUG Only)", Range (0, 1)) = 1.0
        _RoughnessMultiplier("Roughness multiplier (DEBUG Only)", Range (0, 1)) = 1.0
        _ShadowStrength("Shadow Strength", Range (0, 1)) = 1.0
        

        
        
        
        _EnvMap("折射图$Group#折射$", Cube) = "" {}
        [HDR] _EnvColor("折射颜色$Group#折射$", Color) = (0.5, 0.5, 0.5, 1)
        _TransColor("透射率$Group#折射$", Color) = (0.6, 0.6, 0.6, 1)
        _ETA("折射率（入射/出射）$Group#折射$", Range (0.1, 1)) = 0.75
        _NormalFlatten("投射法线平整度$Group#折射$", Range (0, 1)) = 0.7
        _MotionSpeed("折射变化速度$Group#折射$", Range (0, 100)) = 1.0
        _ThicknessMap("厚度纹理$Group#折射$", 2D) = "gray" {}
        [Toggle] [AutoVariant(multi_compile)] _EnableDissolve("Enable Dissolve$Group#溶解$", Float) = 0
        _DissolveTex("Dissolve(RGB)$Group#溶解$", 2D) = "white" {}
        _DissolveTexUVR("UV-R$Group#溶解$", Vector) = (1, 1, 0, 0)
        _DissolveTexUVG("UV-B$Group#溶解$", Vector) = (1, 1, 0, 0)
        _DissolveLV("强度:x=R,y=B,z=Fresnel,w=溶解随机闪烁$Group#溶解$", Vector) = (0, 0, 0, 0)
        _DissolveEdgeColor("颜色$Group#溶解$", Vector) = (0.2, 0.5, 1, 1)
        _DissolveEdgeColor2("颜色2$Group#溶解$", Vector) = (0, 0, 0, 0.5)
        _Dissolve("_Dissolve$Group#溶解$", Range (-1, 1)) = 0.0
        _DissolveON("0=透明ON 1=透明OFF$Group#溶解$", Range (0, 1)) = 0.0
        _EdgeWidth("边缘宽度$Group#溶解$", Range (-0.5, 0.5)) = 0.1
        [KeywordEnum(None, World, View)] [AutoVariant(shader_feature)] _RimSpaceMode("空间模式$Group#边缘光$", Float) = 0
        _LightPos("光源位置$Group#边缘光$$Depend#_RimSpaceMode#1#Hide$", Vector) = (0, 1, 0, 0)
        _LightDir("光源方向$Group#边缘光$$Depend#_RimSpaceMode#2#Hide$", Vector) = (0, 1, 0, 0)
        [HDR] _RimLightColor("边缘光颜色$Group#边缘光$", Color) = (1, 1, 1, 0)
        _RimLightSmooth("柔和度$Group#边缘光$", Range (0, 1)) = 0.5
        _RumLightMaskTex("遮罩图$Group#边缘光$", 2D) = "white"{}
        // ---- End material properties (NPRStandard_Transmission.cginc)
        
        //RefractMatcap
        _RefractionMap_MatCap("折射Matcap$Group#折射$", 2D) = "black" {}
        _Scale_Refraction("Matcap折射强度(当Matcap折射开启)$Group#折射$", Range (0, 1)) = 0.0553
        [HDR]_MatcapRefractionColor("Matcap折射颜色$Group#折射$", Color) = (0.333, 0.526, 0.688, 1)
        
        //DetailNormal
        _DetailNormalMap("细节法线纹理$Group#细节法线$", 2D) = "bump" {}
        _DetailNormalScale("细节法线强度$Group#细节法线$", Range (0, 1)) = 0.5
        
        //BackDetailNormal
        _BackDetailNormalMapScale("背面细节法线缩放$Group#细节法线$", Range(0, 2)) = 0.5
                //NormalRemap
        _NormalRemapStrength("法线重映射强度$Group#细节法线$", Range(0.1, 2)) = 0.5
        

        
        //Matcap
        [HDR]_SpColor("高光颜色 $Group#光照$", Color) = (1.0,1.0,1.0,1.0)
		[NoScaleOffset]_CapTex ("高光 Matcup  $Group#光照$", 2D) = "white" {}
        
        //Fenier
        _F0("F0(菲涅尔强度控制) $Group#菲尼尔$", Range(0, 1)) = 0.048//水晶的F0
        
        //EnvMap
        _MatcapEnvMap("环境图$Group#光照$", 2D) = "" {}
        _MatcapEnvColor("环境颜色$Group#光照$", Color) = (0.5, 0.5, 0.5, 1)
        
        _ParallaxHeight("视差高度$Group#视差$", Float) = 0.1
        _ParallaxMap("视差纹理$Group#视差$", 2D) = "white" {}
        _ParallaxColor("视差颜色$Group#视差$", Color) = (1.0, 1.0, 1.0, 1.0)
        _ParallaxRange("视差范围$Group#视差$", Range(0.1, 1)) = 0.3
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

            //#include "UnityCG.cginc"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/ShaderLab/ShaderCommon.hlsl"
            #include "Crystal.hlsl"





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
