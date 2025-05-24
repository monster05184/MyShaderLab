
 
using UnityEngine;
using UnityEditor;
using System;
using System.IO;
using System.Text;
using UnityEditor.ProjectWindowCallback;
using System.Text.RegularExpressions;

public class ExtendTemplate : EditorWindow
{
    public const string PbrPath = "Assets/Create/Shader/PBRTemplate";
    public static string monoScriptPath = "Assets/Tools/Template";
    
    public enum ShaderType
    {
        PBR,
        Unlit
    }
    public ShaderType shaderType = ShaderType.PBR;
    public string shaderName = "ShaderName";
    [MenuItem("Assets/Create/Shader/ShaderTemplate")]
    public static void ShowWindow()
    {
        GetWindow<ExtendTemplate>("ShaderTemplate");
    }
    
    private void OnGUI()
    {
        GUILayout.Label("Settings", EditorStyles.boldLabel);

        // 多选框
        shaderType = (ShaderType)EditorGUILayout.EnumPopup("ShaderType", shaderType, GUILayout.Width(200));

        // 文本输入框
        shaderName = EditorGUILayout.TextField("PBRTemplate", shaderName);
        
        // 添加一些间距
        EditorGUILayout.Space(10);
        
        if(GUILayout.Button("Create Shader"))
        {
            if (string.IsNullOrEmpty(shaderName))
            {
                EditorUtility.DisplayDialog("Error", "Shader name cannot be empty.", "OK");
                return;
            }
            switch (shaderType)
            {
                case ShaderType.PBR:
                    CreateNewShader("PBRTemplate", shaderName);
                    break;
                case ShaderType.Unlit:
                    CreateNewShader("UnlitTemplate", shaderName);
                    break;
            }
        }
        
    }
    
    static string GetResourcePath(string name)
    {
        //Get the path of the current script
        string path = monoScriptPath;
        //Get the path of the template file
        string resourcePath = Path.Combine(path , name);
        return resourcePath;

    }

    [MenuItem(PbrPath, false, 80)]
    public static void CreatNewPBRShader()
    {
        CreateNewShader("PBRTemplate", "PBRTemplate");
    }

    static void CreateNewShader(string shaderName, string replaceShaderName)
    {
        var selectedPath = GetSelectedPathOrFallback();
        Debug.Log(GetResourcePath($"{shaderName}.shader"));
        Debug.Log(selectedPath + $"{replaceShaderName}.shader");
        ProjectWindowUtil.StartNameEditingIfProjectWindowExists(0,
            ScriptableObject.CreateInstance<MyDoCreateScriptAsset>(),
            selectedPath + $"/{replaceShaderName}.shader",
            null,
            GetResourcePath($"{shaderName}.shader"));
        ProjectWindowUtil.StartNameEditingIfProjectWindowExists(0,
            ScriptableObject.CreateInstance<MyDoCreateScriptAsset>(),
            selectedPath + $"/{replaceShaderName}.hlsl",
            null,
            GetResourcePath($"{shaderName}.hlsl"));

    }



    public static string GetSelectedPathOrFallback()
    {
        string path = "Assets";
        foreach (UnityEngine.Object obj in Selection.GetFiltered(typeof(UnityEngine.Object), SelectionMode.Assets))
        {
            path = AssetDatabase.GetAssetPath(obj);
            if (!string.IsNullOrEmpty(path) && File.Exists(path))
            {
                path = Path.GetDirectoryName(path);
                break;
            }
        }
        return path;
    }
    
}
class MyDoCreateScriptAsset : EndNameEditAction
{
 
 
    public override void Action(int instanceId, string pathName, string resourceFile)
    {
        UnityEngine.Object o = CreateScriptAssetFromTemplate(pathName, resourceFile);
        ProjectWindowUtil.ShowCreatedAsset(o);
    }
 
    internal static UnityEngine.Object CreateScriptAssetFromTemplate(string pathName, string resourceFile)
    {
        string fullPath = Path.GetFullPath(pathName);
        StreamReader streamReader = new StreamReader(resourceFile);
        string text = streamReader.ReadToEnd();
        streamReader.Close();
        string fileNameWithoutExtension = Path.GetFileNameWithoutExtension(pathName);
        text = Regex.Replace(text, "#NAME#", fileNameWithoutExtension);

        bool encoderShouldEmitUTF8Identifier = true;
        bool throwOnInvalidBytes = false;
        UTF8Encoding encoding = new UTF8Encoding(encoderShouldEmitUTF8Identifier, throwOnInvalidBytes);
        bool append = false;
        StreamWriter streamWriter = new StreamWriter(fullPath, append, encoding);
        streamWriter.Write(text);
        streamWriter.Close();
        AssetDatabase.ImportAsset(pathName);
        return AssetDatabase.LoadAssetAtPath(pathName, typeof(UnityEngine.Object));
    }
 
}