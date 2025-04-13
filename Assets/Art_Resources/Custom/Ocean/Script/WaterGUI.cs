
using UnityEngine;
using UnityEditor;
using System.IO;
[CustomEditor(typeof(FFTOcean), true)]
public class WaterGUI : Editor
{
    private bool absorptionScatteringChanged = false;
    private int textureWidth = 128;
    private Gradient absorption;
    private Gradient scattering;

    private void OnEnable()
    {
        absorption = (target as FFTOcean).absorption;
        scattering = (target as FFTOcean).scattering;
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        FFTOcean oceanCS = target as FFTOcean;
        EditorGUI.BeginChangeCheck();
        oceanCS.absorption = EditorGUILayout.GradientField("absorption", oceanCS.absorption, GUILayout.Width(340));
        oceanCS.scattering = EditorGUILayout.GradientField("scattering", oceanCS.scattering, GUILayout.Width(340));
        if (EditorGUI.EndChangeCheck())
        {
            absorptionScatteringChanged = true;
            Debug.Log("changed");
        }
    }
    //Generate AbsorptionScatteringTexture
    private void GenerateTexture()
    {
        
        Texture2D tex = new Texture2D(textureWidth, 2);
        Color[] colors = new Color[textureWidth * 2];
        float time = 0;
        for (int i = 0; i < textureWidth; i++)
        {
            time = i / textureWidth;
            colors[2 * i] = absorption.Evaluate(time);
            colors[2 * i + 1] = scattering.Evaluate(time);
        }
        tex.SetPixels(colors);
        tex.Apply();
        
        


    }

    private void CreateTexture()
    {
        string texFolder = "Assets/Texture/Water/";
        string texName = "";
        Texture2D tex = new Texture2D(textureWidth, 2, TextureFormat.ARGB32, false);
        Color[] colors = new Color[2 * textureWidth];
        for(int i = 0; i <colors.Length; i++)
        {
            colors[i] = new Color(1f, 1f, 1f, 1f);
        }
        tex.SetPixels(colors);
        
        //判断文件是否重名
        bool exporNameSuccess = true;
        for (int num = 1; exporNameSuccess; num++)
        {
            string Next = Selection.activeTransform.name + "_" + num;
            if (!File.Exists(texFolder + Selection.activeTransform.name + ".png"))
            {
                texName = Selection.activeTransform.name;
                exporNameSuccess = false;
            }
            else if (!File.Exists(texFolder + Next + ".png"))
            {
                texName = Next;
                exporNameSuccess = false;
            }

        }

        string path = texFolder + texName + ".png";
        byte[] bytes = tex.EncodeToPNG();
        File.WriteAllBytes(path, bytes);
        
        AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);
        //Control贴图的导入设置
        TextureImporter textureIm = AssetImporter.GetAtPath(path) as TextureImporter;
        textureIm.textureFormat = TextureImporterFormat.ARGB32;
        textureIm.textureCompression = TextureImporterCompression.Uncompressed;
        textureIm.isReadable = true;
        textureIm.anisoLevel = 9;
        textureIm.mipmapEnabled = false;
        textureIm.wrapMode = TextureWrapMode.Clamp;
        AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);
        
    }

}
