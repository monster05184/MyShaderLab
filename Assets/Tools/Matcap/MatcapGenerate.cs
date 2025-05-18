using System.IO;
using UnityEngine;
using UnityEditor;

public class MatcapTool : MonoBehaviour
{
	public static RenderTexture rt;
	public static GameObject camera;
	public static GameObject matcapSphere;
	private static Vector3 cameraPosCache;
	private static Vector3 cameraRotationCache;
	
	public static void OnInitialize(MatcapToolConfig config)
	{

		AsignCamera();
		var cameraComp = camera.GetComponent<Camera>();
		var assetPath = config.savePath;
		var mat = config.matcapGenerateMaterial;
		if (assetPath == string.Empty) return;

		if (!Directory.Exists(Application.dataPath+"/"+ assetPath.Replace("Assets/","")))
		{
			Directory.CreateDirectory(Application.dataPath + "/" + assetPath.Replace("Assets/", ""));
		}

		var obj = AssetDatabase.LoadAssetAtPath(SpherePath, typeof(GameObject)) as GameObject;
		matcapSphere = Instantiate(obj);
		Debug.Log(matcapSphere);
		matcapSphere.layer = LayerMask.NameToLayer("LookInteractor");
		matcapSphere.transform.position = Vector3.zero;
		var render = matcapSphere.GetComponent<MeshRenderer>();
		render.sharedMaterial = mat;
		int _textureSize = (int)config.textureSize;
		cameraComp.orthographicSize = 0.5f;

		RenderTexture rt = new RenderTexture(_textureSize, _textureSize, 24, RenderTextureFormat.ARGB32)
		{
			antiAliasing = 1,
			useMipMap = false,
			autoGenerateMips = false,
			filterMode = FilterMode.Bilinear,
			wrapMode = TextureWrapMode.Clamp
		};
		rt.name = "MatcapRT";
		rt.Create();
		
		cameraComp.targetTexture = rt;
		
	}
	


	public static void RenderCamera()
	{
		var cameraComp = camera.GetComponent<Camera>();
		cameraComp.Render();
	}
	
	public static void RotateCamera(Vector3 rotation)
	{
		camera.transform.position = cameraPosCache;
		camera.transform.eulerAngles = cameraRotationCache;
		Quaternion quaternion = Quaternion.Euler(rotation);
		camera.transform.position = quaternion * camera.transform.position;
		camera.transform.LookAt(Vector3.zero);
		
	}

	public static void CaptureTexture(MatcapToolConfig config)
	{
		var mat = config.matcapGenerateMaterial;
		RenderTexture.active = camera.GetComponent<Camera>().targetTexture;
		int _textureSize = (int)config.textureSize;
		var assetPath = config.savePath;

		Texture2D tt = new Texture2D(_textureSize, _textureSize, TextureFormat.RGB24, false);
		tt.ReadPixels(new Rect(0, 0, _textureSize, _textureSize), 0, 0);
		tt.Apply();
		var bytes = tt.EncodeToPNG();
		string path = string.Format("{0}/{1}_matcap_{2}.png", assetPath, mat.name, _textureSize);
		File.WriteAllBytes(path, bytes);
		AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);
		TextureImporter textureImporter = AssetImporter.GetAtPath(path) as TextureImporter;
		textureImporter.sRGBTexture = false;
		textureImporter.SaveAndReimport();
	}

	public static void Release()
	{
		if (rt != null)
		{
			rt.Release();
			rt = null;
		}
		if(camera != null)
		{
			DestroyImmediate(camera);
			camera = null;
		}
		if(matcapSphere != null)
		{
			DestroyImmediate(matcapSphere);
			matcapSphere = null;
		}
		
	}

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

	private static void AsignCamera()
	{
		camera = new GameObject("tempCamera");
		Camera tempCamera = camera.AddComponent<Camera>();
		tempCamera.orthographic = true;
		tempCamera.cullingMask = 1 << 8;
		tempCamera.farClipPlane = 50;
		tempCamera.nearClipPlane = 0.5f;
		tempCamera.clearFlags = CameraClearFlags.SolidColor;
		tempCamera.backgroundColor = Color.black;
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
		cameraPosCache = camera.transform.position;
		cameraRotationCache = camera.transform.eulerAngles;


	}
	
	private static int cullingMask = 1 << 8;

	private static string SpherePath = "Assets/Tools/Matcap/Mesh/Sphere.prefab";




}

