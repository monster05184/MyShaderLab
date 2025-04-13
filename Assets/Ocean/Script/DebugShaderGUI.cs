using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEditor;
using Object = UnityEngine.Object;

public class DebugShaderGUI : ShaderGUI
{
    private SerializedProperty debugSP;
    private SerializedProperty debugModeSP;
    private SerializedObject debugShaderGUISO;
    private bool debug = false;
    private int debugMode = 1;

    private string m_debugKeyword;
    private string m_debugModeStr;

    public string debugModeStr
    {
        get
        {
            if (m_debugModeStr == null)
            {
                m_debugModeStr = "_DebugMode";
            }

            return m_debugModeStr;
        }
    }

    public string debugKeyword
    {
        get
        {
            if (m_debugKeyword == null)
            {
                m_debugKeyword = "_DEBUG_ON";
            }

            return m_debugKeyword;
        }
    }

    enum DebugMode
    {
        Specular = 1,
        Fresnel = 2,
        OceanColor = 3,
        ReflectColor = 4,
        SSS = 5,
        Caustics = 6,
        UnderWaterColor = 7,
        shadow = 8,
    }

    override public void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Material targetMat = materialEditor.target as Material;
        debug = EditorGUILayout.Toggle("开启Debug模式", debug);

        if (debug)
        {
            targetMat.EnableKeyword(debugKeyword);
            debugMode = Convert.ToInt32(EditorGUILayout.EnumPopup((DebugMode)debugMode, GUILayout.Width(200)));
            
            targetMat.SetFloat(debugModeStr,debugMode);
        }
        else
        {
            targetMat.DisableKeyword(debugKeyword);
        }



        //渲染默认的GUI
        base.OnGUI(materialEditor, properties);

    }
}
