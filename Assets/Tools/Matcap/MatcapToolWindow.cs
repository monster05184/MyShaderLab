// DataEditorWindow.cs
using UnityEditor;
using UnityEngine;

public class MatcapToolWindow : EditorWindow
{
    private MatcapToolConfig dataContainer;
    private SerializedObject serializedData;
    private SerializedProperty matcapGenerateShaderProp;
    private SerializedProperty textureSizeProp;
    private SerializedProperty savePathProp;

    [MenuItem("Window/MatcapToolWindow")]
    public static void ShowWindow()
    {
        GetWindow<MatcapToolWindow>("MatcapToolWindow");
    }

    void OnEnable()
    {
        // 尝试自动加载已存在的实例
        string[] guids = AssetDatabase.FindAssets("t:MatcapToolConfig");
        if (guids.Length > 0)
        {
            string path = AssetDatabase.GUIDToAssetPath(guids[0]);
            dataContainer = AssetDatabase.LoadAssetAtPath<MatcapToolConfig>(path);
            InitializeSerializedProperties();
        }
    }

    void InitializeSerializedProperties()
    {
        if (dataContainer != null)
        {
            serializedData = new SerializedObject(dataContainer);
            matcapGenerateShaderProp = serializedData.FindProperty("matcapGenerateShader");
            textureSizeProp = serializedData.FindProperty("textureSize");
            savePathProp = serializedData.FindProperty("savePath");
        }
    }

    void OnGUI()
    {
        DrawMatcapToolConfigField();
        
        if (dataContainer == null)
        {
            DrawCreationUI();
            return;
        }

        if (serializedData == null) InitializeSerializedProperties();

        serializedData.Update();
        
        EditorGUILayout.Space(10);
        EditorGUILayout.LabelField("Data Settings", EditorStyles.boldLabel);
        EditorGUILayout.PropertyField(matcapGenerateShaderProp);
        EditorGUILayout.PropertyField(textureSizeProp);
        EditorGUILayout.PropertyField(savePathProp);

        if (serializedData.ApplyModifiedProperties())
        {
            SaveData();
        }

        DrawSaveButton();
    }

    void DrawMatcapToolConfigField()
    {
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Data Container", GUILayout.Width(100));
        var newData = EditorGUILayout.ObjectField(
            dataContainer, 
            typeof(MatcapToolConfig), 
            false) as MatcapToolConfig;

        if (newData != dataContainer)
        {
            dataContainer = newData;
            InitializeSerializedProperties();
        }
        
        EditorGUILayout.EndHorizontal();
    }

    void DrawCreationUI()
    {
        EditorGUILayout.HelpBox("Create or select a Data Container to begin", MessageType.Info);
        
        if (GUILayout.Button("Create New Data Container", GUILayout.Height(40)))
        {
            CreateNewMatcapToolConfig();
        }
    }

    void CreateNewMatcapToolConfig()
    {
        MatcapToolConfig newData = ScriptableObject.CreateInstance<MatcapToolConfig>();
        
        string path = EditorUtility.SaveFilePanelInProject(
            "Save Data Container",
            "NewMatcapToolConfig",
            "asset",
            "Please enter a file name to save the data container");
        
        if (!string.IsNullOrEmpty(path))
        {
            AssetDatabase.CreateAsset(newData, path);
            AssetDatabase.SaveAssets();
            dataContainer = newData;
            InitializeSerializedProperties();
        }
    }

    void DrawSaveButton()
    {
        if (GUILayout.Button("Save Data", GUILayout.Height(30)))
        {
            SaveData();
        }
    }

    void SaveData()
    {
        if (dataContainer != null)
        {
            EditorUtility.SetDirty(dataContainer);
            AssetDatabase.SaveAssets();
            Debug.Log("Data saved successfully!");
        }
    }
}