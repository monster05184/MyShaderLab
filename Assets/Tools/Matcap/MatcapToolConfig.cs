// DataContainer.cs
using UnityEngine;


[CreateAssetMenu(fileName = "DataContainer", menuName = "Custom/Data Container")]
public class MatcapToolConfig : ScriptableObject
{
    public enum TextureSize
    {
        Size128 = 128,
        Size256 = 256,
        Size512 = 512,
        Size1024 = 1024,
        Size2048 = 2048,
        Size4096 = 4096
    }
    
    public Material matcapGenerateMaterial;
    public TextureSize textureSize = TextureSize.Size512;
    public string savePath = "Assets/Art_Resources/Matcap";
    
    
}