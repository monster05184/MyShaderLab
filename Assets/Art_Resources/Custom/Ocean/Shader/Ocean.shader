
Shader "Ocean"
{
    Properties
    {
        [Header(Base)]
        _BaseMap("MainTex", 2D) = "White" { }
        _BaseColor("BaseColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _Depth("DepthOfWater", Range(0, 1000)) = 1
        _DetailNormal("Detail Normal", 2D) = "White"{ }
        _DetailNormalScale("Detail Normal Scale", Range(0.1, 2)) = 1
        _DetailNormalIntensity("Detail Normal Intensity", Range(0.1, 2)) = 1
        _DetailNormalFlowX("Detail Normal Flow X", Range(0, 1)) = 0.1
        _DetailNormalFlowY("Detail Normal Flow Y", Range(0, 1)) = 0.1
        _AbsorptionScatteringTexture("Absorption Scatering Texture", 2D) = "white"{ }
        
        [HideInInspector]_Displace("Displace", 2D) = "black"{ }
        [HideInInspector]_Normal("Normal", 2D) = "black"{ }
        [HideInInspector]_Bubble("Bubble", 2D) = "black"{ }
        [Header(Bubble)]
        _BubbleTexture("BubbleTexture", 2D) = "white"{ }
        _BubbleScale("BubbleScale", Range(0,400)) = 100 
        _FoamColor("Foam Color 浮沫的颜色", Color) = (1.0, 1.0, 1.0, 1.0)
        _FoamParallax("Foam Parallex, 浮沫的视差贴图的高度", Float) = 1
        _FoamFeather("Foam Feather", Float) = 0.1
        
        [Space(20)]
        _Metallic("Metallic", Range(0, 1)) = 0
        _OceanDeepColor("OceanDeppColor", Color) = (1, 1, 1, 0)
        _OceanShoalColor("OceanShoalColor", Color) = (1, 1, 1, 0)
        _OceanOpacity("OceanOpacity", Range(0.1,3)) = 1 
        
        [Header(Light)]
        _Gloss("Specular Gloss", Range(0, 128)) = 3
        _SpecularColor("Specular Color", Color) = (1, 1, 1, 0)
        _SpecularScale("Specular Scale", Float) = 1
        _FresnelScale("FresnelScale",Range(0,1)) = 0
        _RefrectionDistortion("RefrectionDistortion",Range(0,1)) = 0
        
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
        // URP的shader要在Tags中注明渲染管线是UniversalPipeline
        Tags
        {
            "RanderPipline" = "UniversalPipeline"
            "RanderType" = "Transparent"
        }

        HLSLINCLUDE

            // 引入Core.hlsl头文件，替换UnityCG中的cginc
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            // 将不占空间的材质相关变量放在CBUFFER中，为了兼容SRP Batcher
            CBUFFER_START(UnityPerMaterial)
                //Base
                float4 _BaseMap_ST;
                half4 _BaseColor;
                float _Depth;
                float _DetailNormalScale;
                float _DetailNormalIntensity;
                float _DetailNormalFlowX;
                float _DetailNormalFlowY;
        
                float _FresnelScale;
                float _Metallic;
                half4 _OceanDeepColor;
                half4 _OceanShoalColor;
                float _Gloss;
                half4 _SpecularColor;
                float _SpecularScale;
                
                
                float _AirRefractiveIndex;
                float _WaterRefractiveIndex;
                float _RefrectionDistortion;
                float _OceanOpacity;
                half4 _SSSColor;
                float _SSSScale;
                float _SSSPower;
                float _SSSDistortion;
        
                //Caustics Value
                float _WaterLevel;
                float _CausticsOffset;
                float _CausticsScale;
                float _CausticsIntensity;
                float _CausticsBlendDistance;

                //Foam Value
                float _BubbleScale;
                float4 _FoamColor;
                float _FoamParallax;
                float _FoamFeather; 
            CBUFFER_END
            //Temp Value
            #ifdef _DEBUG_ON
            float _DebugMode;
            #endif
        

            // 材质单独声明，使用DX11风格的新采样方法
            TEXTURE2D (_BaseMap);
            SAMPLER(sampler_BaseMap);
            //屏幕深度贴图
            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);
            //置换贴图
            TEXTURE2D(_Displace);
            SAMPLER(sampler_Displace);
            //法线贴图
            TEXTURE2D(_Normal);
            SAMPLER(sampler_Normal);
            //浮沫强度贴图
            TEXTURE2D(_Bubble);
            SAMPLER(sampler_Bubble);
            //浮沫样式贴图
            TEXTURE2D(_BubbleTexture);
            SAMPLER(sampler_BubbleTexture);
            //焦散贴图
            TEXTURE2D(_CausticsMap);
            SAMPLER(sampler_CausticsMap);
            //细节法线贴图
            TEXTURE2D(_DetailNormal);
            SAMPLER(sampler_DetailNormal);
            //吸收散射贴图
            TEXTURE2D(_AbsorptionScatteringTexture);
            SAMPLER(sampler_AbsorptionScatteringTexture);
            

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                float3 normal     : NORMAL;
                float4 tangent    : TANGENT;
                
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                float4 ScreenPos  : TEXCOORD2;
                float4 TtoW0      : TEXCOORD3;
                float4 TtoW1      : TEXCOORD4;
                float4 TtoW2      : TEXCOORD5;
                float4 waterInfo  : TEXCOORD6;//x:WaterHeight yz:undisplacedWorldPosXZ
            };

        ENDHLSL

        Pass
        {
            // 声明Pass名称，方便调用与识别
            Name "ForwardUnlit"
            Tags {"LightMode" = "UniversalForward"}

            HLSLPROGRAM
                #pragma shader_feature _DEBUG_ON

                // 声明顶点/片段着色器对应的函数
                #pragma vertex vert
                #pragma fragment frag
                struct WaveInfo
                {
                    
                };
                /*****计算水的深度*****/
                float4 ComputeScreenPos(float4 pos, float projectionSign){
                    float4 o = pos * 0.5f;
                    o.xy = float2(o.x,o.y * projectionSign) + o.w;
                    o.zw = pos.zw;
                    return o;
                }

                float4 CustomSampleSceneDepth(float2 uv)
                {
                    return SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture,sampler_CameraDepthTexture,UnityStereoTransformScreenSpaceTex(uv),1.0).r;
            
                }
                float GetDepthFade(float3 WorldPos, float Distance)
                {
                    float4 ScreenPosition = ComputeScreenPos(TransformWorldToHClip(WorldPos),_ProjectionParams.x);
                    float EyeDepth = LinearEyeDepth(CustomSampleSceneDepth(ScreenPosition.xy/ScreenPosition.w),_ZBufferParams);
                    return saturate((EyeDepth - ScreenPosition.a)/Distance);
                } 
                /*****计算水的深度*****/
                //FresnelSchlick
                float FresnelSchlick(float HdotL)
                {
                    float fresnel = exp2((-5.55473 * HdotL - 6.98316) * HdotL);
                    return lerp(fresnel, 1.0, _FresnelScale);
                }
                //SSS
                float4 SSSColor(float3 lightDir, float3 viewDir, float3 normal, float waveHeight, float SSSMask){
                    float3 H = normalize(-lightDir + normal * _SSSDistortion);
                    float I = pow(saturate(dot(viewDir, -H)), _SSSPower)* _SSSScale * waveHeight * SSSMask;
                    return _SSSColor*I;
                }
                //-----------------------SceneColor Refecation--------------------------//

                float2 DistortionUVs(half depth, float3 normalWS)
                {
                    half3 viewNormal = mul((float3x3)GetWorldToHClipMatrix(), -normalWS).xyz;
                    return viewNormal.xz * saturate(depth) * 5;
                }
                
                //------------------------------Caustics---------------------------------//
                float3 RecoustructWorldPos(half2 screenPos, float depth)
                {
                    screenPos.y = 1 - screenPos.y;
                    #if defined(SHADER_API_GLCORE) || defined (SHADER_API_GLES) || defined (SHADER_API_GLES3)			// OpenGL平台 //
                        depth = depth * 2 - 1;
                    #endif
                    float4 raw = mul(UNITY_MATRIX_I_VP, float4(screenPos*2 - 1, depth, 1));
                    float3 worldPos = raw.rgb / raw.a;
                    return worldPos;
                }
                
                float2 CausticsUVs(float2 rawUV, float2 offset)
                {
                    float2 uv = rawUV * _CausticsScale + float2(_Time.y, _Time.y) * 0.1;
                    return uv + offset * 0.25;
                }
                half3 Caustics(float3 worldPos)
                {
                    float blendDistance = 5 * _CausticsBlendDistance;
                    float2 casusticsUV = CausticsUVs(worldPos.xz, float2(0, 0));
                    half upperMask = (-worldPos.y + _WaterLevel + _CausticsOffset) / blendDistance;
                    half lowerMask = (worldPos.y - _WaterLevel - _CausticsOffset) / blendDistance;
                    float3 caustics = SAMPLE_TEXTURE2D_LOD(_CausticsMap, sampler_CausticsMap, casusticsUV, abs(worldPos.y - _WaterLevel - _CausticsOffset)/blendDistance).xyz;
                    caustics *= _CausticsIntensity;
                    caustics *= 1 - saturate(max(upperMask, lowerMask));
                    return caustics;
                    
                }

            
                half3 Caustics(float2 screenUV, float depth)
                {
                    float3 worldPos = RecoustructWorldPos(screenUV, depth);
                    return Caustics(worldPos);
                }
                
                //-----------------------Caustics-------------------------------//
                //-------------------------Foam---------------------------------//
                struct FoamWorldXZ
                {
                    float2 displacedXZ;
                    float2 undisplacedXZ;
                };
                float WhiteFoam(FoamWorldXZ worldPosXZ, float bubble, float height)
                {
                    float2 foamUV = worldPosXZ.undisplacedXZ / _BubbleScale;
                    float foam = SAMPLE_TEXTURE2D(_BubbleTexture, sampler_BubbleTexture, foamUV).r;
                    bubble = saturate(1 - bubble);
                    
                    return smoothstep(bubble, bubble + _FoamFeather, foam) * saturate(height * 4);
                }
                
                float4 ApplyFoam(FoamWorldXZ worldPosXZ, float bubble, float3 viewVector, float3 normal, float height)
                {
                    float4 whiteFoamCol;
                    float whiteFoam = WhiteFoam(worldPosXZ, bubble, height);
                    whiteFoamCol.rgb = _FoamColor;
                    whiteFoamCol.rgb *= whiteFoam;
                    whiteFoamCol.a = whiteFoam;
                    return whiteFoamCol;
                    
                }
                //-------------------------Foam---------------------------------//
                //-------------------------Lighting-----------------------------//
                float Absorption(float depth)
                {
                    return SAMPLE_TEXTURE2D(_AbsorptionScatteringTexture, sampler_AbsorptionScatteringTexture, float2(depth, 0.0));
                }
                float Scattering(float depth)
                {
                    return SAMPLE_TEXTURE2D(_AbsorptionScatteringTexture, sampler_AbsorptionScatteringTexture, float2(depth, 0.375));
                }
                
                //-------------------------Lighting-----------------------------//
                // Unpack normal as DXT5nm (1, y, 0, x) or BC5 (x, y, 0, 1)
                float3 UnpackNormal_Scale(float4 packedNormal, float Scale)
                {
                    //Convert to (?, y, 0, x)
                    packedNormal.a *= packedNormal.r;
                    float3 normal;
                    normal.xy = (packedNormal.ag * 2.0 - 1.0) * Scale;
                    normal.z = max(1.0e-16, sqrt(1.0 - saturate(dot(normal.xy, normal.xy))));
                    return normal; 
                }
            
                // 顶点着色器
                Varyings vert(Attributes input)
                {
                    Varyings output;
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                    const VertexPositionInputs undisplacedVertexInput = GetVertexPositionInputs(input.positionOS);
                    output.waterInfo.yz = undisplacedVertexInput.positionWS.xz;
                    
                    //计算置换贴图
                    float4 displace = SAMPLE_TEXTURE2D_X_LOD(_Displace,sampler_Displace,input.uv,0);
                    input.positionOS +=float4(displace.xyz, 0);
                    // GetVertexPositionInputs方法根据使用情况自动生成各个坐标系下的定点信息
                    const VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                   
                    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                    output.positionCS = vertexInput.positionCS;
                    output.ScreenPos = ComputeScreenPos(vertexInput.positionCS);
                    //handle normal
                    const VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normal,input.tangent);
                    float3 tangentWS = vertexNormalInput.tangentWS;
                    float3 normalWS = vertexNormalInput.normalWS;
                    float3 binormalWS = vertexNormalInput.bitangentWS;
                    float3 posWS =  vertexInput.positionWS; 
                    output.TtoW0 = float4(tangentWS.x, binormalWS.x, normalWS.x, posWS.x);
                    output.TtoW1 = float4(tangentWS.y, binormalWS.y, normalWS.y, posWS.y);
                    output.TtoW2 = float4(tangentWS.z, binormalWS.z, normalWS.z, posWS.z);
                    output.waterInfo.x = displace.y;
                    
                    return output;
                }

                // 片段着色器
                half4 frag(Varyings input) : SV_Target
                {
                    half4 col;
                    //--------------------数据准备-----------------------//
                    float3 posWS = float3(input.TtoW0.w, input.TtoW1.w, input.TtoW2.w);
                    float2 screenUV = input.ScreenPos.xy/input.ScreenPos.w;
                    float rawDepth = SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture,sampler_CameraDepthTexture, screenUV,1.0).r;
                    Light mainLight = GetMainLight();
                    float3 viewVec = normalize(GetCameraPositionWS() - posWS);
                    float3 lightDir = mainLight.direction;
                    float shadowAtten = mainLight.shadowAttenuation;
                    float2 undisplacedWorldPosXZ = input.waterInfo.yz;
                    float height = input.waterInfo.x;
                    
                    float3 halfDir = normalize(lightDir + viewVec);
                    //采样法线贴图
                    float4 normalOS = SAMPLE_TEXTURE2D(_Normal,sampler_Normal,input.uv);
                    float3 normalWS = normalize(mul(normalOS, unity_ObjectToWorld));
                    //应用细节法线贴图
                    float2 detailNormalUV = input.uv * _DetailNormalScale * 5 + float2(_DetailNormalFlowX, _DetailNormalFlowY) * _Time.y;
                    float3 detailNormalTS = UnpackNormal_Scale((SAMPLE_TEXTURE2D(_DetailNormal, sampler_DetailNormal, detailNormalUV)), 0.1 * _DetailNormalIntensity);
                    
                    float3 detailNormalWS = normalize(float3(dot(input.TtoW0,detailNormalTS), dot(input.TtoW1,detailNormalTS), dot(input.TtoW2,detailNormalTS)));
                    normalWS = BlendNormalWorldspaceRNM(normalWS, detailNormalWS, float3(0, 1, 0));
                    normalWS = normalize(normalWS);
                    float NdotV = dot(normalWS, viewVec);
                    //--------------------数据准备-----------------------//

                    
                    
                    
                    //水面浮沫detailNormalTS
                    float bubble = SAMPLE_TEXTURE2D(_Bubble,sampler_Bubble,input.uv);
                    //bubble = pow(bubble, 3);
                    FoamWorldXZ foamWorldXZ;
                    foamWorldXZ.displacedXZ = posWS.xz;
                    foamWorldXZ.undisplacedXZ = undisplacedWorldPosXZ;
                    float4 foamColor = ApplyFoam(foamWorldXZ, bubble, viewVec, normalWS, input.waterInfo.x);
                    
                    
                        
                    
                    //水深的计算
                    float depthfade = GetDepthFade(posWS, _Depth);
                    //水的折射和扭曲
                    float2 distortion = DistortionUVs(depthfade, normalWS);
                    float2 distortedScreenUV = screenUV + distortion;
                  
                    //焦散的计算
                    float3 caustics = Caustics(distortedScreenUV, rawDepth);
                    //水底的图片
                    half4 texUnderWater = SAMPLE_TEXTURE2D(_CameraOpaqueTexture,sampler_CameraOpaqueTexture,input.uv);
                    texUnderWater.xyz = SampleSceneColor(distortedScreenUV);
                    //----------------光线计算-----------------------//
                    
                    float fresnel = FresnelSchlick(NdotV);
                    
                    //采样反射探针或者是天空盒
                    float3 reflectDir = reflect(normalize(-viewVec), normalWS);
                    half4 rgbm = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,samplerunity_SpecCube0, reflectDir, 1);
                    half3 sky = DecodeHDREnvironment(rgbm,unity_SpecCube0_HDR);
                    
                    float3 reflectColor = lerp(0.04,sky,_Metallic);
                    //反射部分
                    float3 oceanColor = lerp(_OceanShoalColor,_OceanDeepColor,depthfade);
                    oceanColor += caustics;
                    float OpacityControl = clamp(depthfade*_OceanOpacity, 0, 1);
                    oceanColor = lerp(texUnderWater, oceanColor, OpacityControl);
                    oceanColor = lerp(reflectColor, oceanColor, saturate(1 - fresnel));
                    oceanColor = lerp(oceanColor, foamColor, foamColor.a);
                    //oceanColor = lerp(oceanColor, foamColor, bubble);
                    
                    float3 specular = pow(max(0, dot(normalWS, halfDir)), _Gloss) * _SpecularColor * _SpecularScale;
                    //SSS光照计算
                    float3 sss = SSSColor(lightDir, viewVec, normalWS, input.waterInfo.x, 1);
                    //----------------光线计算-----------------------//
                    col.xyz = oceanColor + specular + sss;
                    #ifdef _DEBUG_ON
                    switch(_DebugMode)
                    {
                    case 1:
                        col.xyz = specular;
                        break;
                    case 2:
                        col.xyz = fresnel;
                        break;
                    case 3:
                        col.xyz = oceanColor;
                        break;
                    case 4:
                        col.xyz = reflectColor;
                        break;
                    case 5:
                        col.xyz = sss;
                        break;
                    case 6:
                        col.xyz = caustics;
                        break;
                    case 7:
                        col.xyz = texUnderWater;
                        break;
                    case 8:
                        
                        col.xyz = foamColor.a;
                        col.xyz = bubble;
                        //col.xy = undisplacedWorldPosXZ * 0.01f;
                        break;
                    default:
                        break;
                    }
                    #endif
                    
                    //return depthfade;
                    //return float4(caustics,1);
                    return col;
                }
            
            ENDHLSL
        }
    }
    CustomEditor "DebugShaderGUI"
}
