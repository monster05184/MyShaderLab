using UnityEngine;
using UnityEditor; // 需要命名空间用于保存资源

[ExecuteInEditMode] // 允许在编辑器模式下运行
public class AutoCaptureToTexture : MonoBehaviour
{
    [Header("Settings")]
    public Camera captureCamera;
    public string textureName = "GeneratedTexture";
    public string savePath = "Assets/MaterialShow/Texture";
    public int resolution = 512;

    private RenderTexture rt;

    // 添加一个ContextMenu按钮
    [ContextMenu("Capture and Generate Texture")]
    public void CaptureAndGenerateTexture()
    {
        if (captureCamera == null)
        {
            Debug.LogError("Capture Camera not assigned!");
            return;
        }

        // 创建或复用RenderTexture
        if (rt == null || rt.width != resolution)
        {
            if (rt != null) rt.Release();
            rt = new RenderTexture(resolution, resolution, 24);
            rt.Create();
        }

        // 设置相机并渲染
        captureCamera.targetTexture = rt;
        captureCamera.Render();

        // 转换为Texture2D
        Texture2D texture = RenderTextureToTexture2D(rt);

        // 保存为PNG和.asset文件
        SaveTextureAsAsset(texture);

        // 清理
        captureCamera.targetTexture = null;
        Debug.Log("Texture generated at: " + savePath + textureName + ".png");
    }

    private Texture2D RenderTextureToTexture2D(RenderTexture rt)
    {
        Texture2D tex = new Texture2D(rt.width, rt.height, TextureFormat.RGBA32, false);
        RenderTexture.active = rt;
        tex.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0);
        tex.Apply();
        RenderTexture.active = null;
        return tex;
    }

    private void SaveTextureAsAsset(Texture2D texture)
    {
        // 确保路径存在
        if (!System.IO.Directory.Exists(savePath))
        {
            System.IO.Directory.CreateDirectory(savePath);
        }

        // 保存为PNG文件
        byte[] bytes = texture.EncodeToPNG();
        string pngPath = savePath + textureName + ".png";
        System.IO.File.WriteAllBytes(pngPath, bytes);

        // 刷新AssetDatabase
        AssetDatabase.Refresh();

        // 转换为Texture2D资源
        TextureImporter importer = AssetImporter.GetAtPath(pngPath) as TextureImporter;
        if (importer != null)
        {
            importer.textureType = TextureImporterType.Default;
            importer.SaveAndReimport();
        }
    }

    private void OnDestroy()
    {
        if (rt != null) rt.Release();
    }
}