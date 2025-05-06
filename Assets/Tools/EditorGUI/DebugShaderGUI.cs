using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEditor;

public class DebugShaderGUI : ShaderGUI
{
    private SerializedProperty LightDebugSP;
    private int LightDebug = 0;
    private int SurfaceDataDebug = 0;
    private int PBRDataDebug = 0;

    private string m_debugKeyword;
    private string lightDebugStr = "_LightDebugMode";
    private string surfaceDataDebugStr = "_SurfaceDataDebugMode";




    public string debugKeyword
    {
        get
        {
            if (m_debugKeyword == null)
            {
                m_debugKeyword = "DEBUG";
            }

            return m_debugKeyword;
        }
    }

    enum LightDebugMode
    {
        all = 0,
        diffuse = 1,
        specular = 2,
        indirectDiffuse = 3,
        indirectSpec = 4,
        emissive = 5,
    }

    enum SurfaceDataDebugMode
    {
        non = 0,
        baseColor = 1,
        metallic = 2,
        linearRoughness = 3,
        occulusion = 4,
    }

    enum PBRDataDebugMode
    {
        
    }

    override public void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Material targetMat = materialEditor.target as Material;
        LightDebugSP = materialEditor.serializedObject.FindProperty("_LightDebug");
        
        //渲染默认的GUI 
        base.OnGUI(materialEditor, properties);
        
        LightDebug = Convert.ToInt32(EditorGUILayout.EnumPopup((LightDebugMode)LightDebug, GUILayout.Width(200)));
        targetMat.SetFloat(lightDebugStr,LightDebug);
        SurfaceDataDebug = Convert.ToInt32(EditorGUILayout.EnumPopup((SurfaceDataDebugMode)SurfaceDataDebug, GUILayout.Width(200)));
        targetMat.SetFloat(surfaceDataDebugStr, SurfaceDataDebug);
        
        


    }
}