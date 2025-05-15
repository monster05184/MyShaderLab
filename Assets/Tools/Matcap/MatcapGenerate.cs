using System.IO;
using UnityEngine;
using UnityEditor;

public class MatcapTool : MonoBehaviour
{
	//get a layer not created
	private static int GetUnUsedLayer()
	{
		return LayerMask.NameToLayer("Default");
		for (int i = 8; i < 32; i++)
		{
			if (string.IsNullOrEmpty(LayerMask.LayerToName(i)))
			{
				return 1 << i;
			}
		}
		return -1;
	}

	private static void AsignCamera(Camera camera)
	{
		Light[] lights = FindObjectsOfType<Light>();
		//Get the main Light of scene
		Light mainLight = null;

		foreach (var light in lights)
		{
			if (light.type == LightType.Directional)
			{
				mainLight = light;
				break;
			}
		}
		
		//摄像机沿着主光源的方向看向（0， 0， 0）
		var dir = mainLight.transform.forward;
		var cameraPos = -dir;
		camera.transform.position = cameraPos * 10;
		camera.transform.forward = dir;

	}
	
	private static int cullingMask = 1 << 8;


	public static void ExportAndSetMaterials( MatcapToolConfig settingsObj)
    {
		GameObject tempObj = new GameObject("tempCamera");
		Camera tempCamera = tempObj.AddComponent<Camera>();
		tempCamera.orthographic = true;
		tempCamera.cullingMask = 1 << 8;
		tempCamera.farClipPlane = 50;
		tempCamera.nearClipPlane = 0.5f;
		tempCamera.clearFlags = CameraClearFlags.SolidColor;
		tempCamera.backgroundColor = Color.black;
		AsignCamera(tempCamera);




	    CreateMatcpTextureByMaterial(settingsObj, tempCamera);
        
		DestroyImmediate(tempObj);
	}
	private static string SpherePath = "Assets/Tools/Matcap/Mesh/Sphere.prefab";

    private static void CreateMatcpTextureByMaterial(MatcapToolConfig settingsObj, Camera camera)
    {
	    var assetPath = settingsObj.savePath;
	    var mat = settingsObj.matcapGenerateMaterial;
		if (assetPath == string.Empty) return;

		if (!Directory.Exists(Application.dataPath+"/"+ assetPath.Replace("Assets/","")))
		{
			Directory.CreateDirectory(Application.dataPath + "/" + assetPath.Replace("Assets/", ""));
		}

		var obj = AssetDatabase.LoadAssetAtPath(SpherePath, typeof(GameObject)) as GameObject;
		var tempObj = Instantiate(obj);
		tempObj.layer = LayerMask.NameToLayer("LookInteractor");
		tempObj.transform.position = Vector3.zero;
		var render = tempObj.GetComponent<MeshRenderer>();
		render.sharedMaterial = mat;
		int _textureSize = (int)settingsObj.textureSize;
		camera.orthographicSize = 0.5f;

		RenderTexture rt = new RenderTexture(_textureSize, _textureSize, 24, RenderTextureFormat.ARGB32)
		{
		    antiAliasing = 1,
		    useMipMap = false,
		    autoGenerateMips = false,
		    filterMode = FilterMode.Bilinear,
		    wrapMode = TextureWrapMode.Clamp
		};
		rt.Create();

		
		
		camera.targetTexture = rt;
		camera.Render();
		RenderTexture.active = rt;


		Texture2D tt = new Texture2D(_textureSize, _textureSize, TextureFormat.RGB24, true);
                tt.ReadPixels(new Rect(0, 0, _textureSize, _textureSize), 0, 0);
		//TexEdgeProcessing(tt);
		tt.Apply();
		var bytes = tt.EncodeToPNG();
		string path = string.Format("{0}/{1}_matcap_{2}.png", assetPath, mat.name, _textureSize);
		File.WriteAllBytes(path, bytes);
		AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);
		TextureImporter textureImporter = AssetImporter.GetAtPath(path) as TextureImporter;
		textureImporter.sRGBTexture = false;
		textureImporter.SaveAndReimport();
		// mat.SetFloat("_MATCAP", 1);
		
		DestroyImmediate(tempObj);
		Debug.Log("导出成功：" + path);

	}
}

