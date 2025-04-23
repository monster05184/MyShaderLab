using UnityEditor;
using UnityEngine;
using System.Collections.Generic;

// [CustomEditor(typeof(Character))]
// public class MyComponentEditor : BaseEditor<Character>
// {
//
//     
//     protected override void OnBaseInspectorGUI()
//     {
//         // 绘制默认属性
//         DrawPropertyField("health");
//         DrawPropertyField("damage");
//         
//         // 使用折叠组
//         DrawFoldoutGroup("MyComponent_Advanced", "Advanced Settings", false, () => 
//         {
//             DrawPropertyField("attackSpeed");
//             DrawPropertyField("criticalChance");
//         });
//         
//
//     }
// }