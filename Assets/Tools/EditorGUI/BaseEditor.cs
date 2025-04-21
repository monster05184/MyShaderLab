using UnityEditor;
using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// 通用 Editor 基类，提供基础功能
/// </summary>
public abstract class BaseEditor<T> : Editor where T : UnityEngine.Object
{
    protected T Target => (T)target;
    protected SerializedObject SerializedTarget => serializedObject;
    
    // 缓存所有找到的属性
    private Dictionary<string, SerializedProperty> _propertyCache = new Dictionary<string, SerializedProperty>();
    
    // 需要子类实现的抽象方法
    protected abstract void OnBaseInspectorGUI();
    
    public override void OnInspectorGUI()
    {
        serializedObject.Update();
        
        // 绘制默认脚本引用
        EditorGUI.BeginDisabledGroup(true);
        EditorGUILayout.ObjectField("Script", MonoScript.FromMonoBehaviour((MonoBehaviour)target), typeof(MonoScript), false);
        EditorGUI.EndDisabledGroup();
        
        // 调用子类实现
        OnBaseInspectorGUI();
        
        serializedObject.ApplyModifiedProperties();
    }
    
    /// <summary>
    /// 安全获取属性
    /// </summary>
    protected SerializedProperty GetProperty(string propertyName, bool logErrorIfMissing = true)
    {
        if (_propertyCache.TryGetValue(propertyName, out var cachedProperty))
        {
            return cachedProperty;
        }
        
        var property = serializedObject.FindProperty(propertyName);
        if (property == null && logErrorIfMissing)
        {
            Debug.LogError($"Property '{propertyName}' not found in {typeof(T).Name}!", target);
        }
        
        _propertyCache[propertyName] = property;
        return property;
    }
    
    /// <summary>
    /// 安全绘制属性字段
    /// </summary>
    protected void DrawPropertyField(string propertyName, GUIContent label = null, bool includeChildren = true)
    {
        var property = GetProperty(propertyName);
        if (property != null)
        {
            EditorGUILayout.PropertyField(property, label ?? new GUIContent(property.displayName), includeChildren);
        }
    }
    
    /// <summary>
    /// 绘制折叠式属性组
    /// </summary>
    protected bool DrawFoldoutGroup(string groupKey, string title, bool defaultState, System.Action contentDrawer)
    {
        bool state = EditorPrefs.GetBool(groupKey, defaultState);
        state = EditorGUILayout.Foldout(state, title, true);
        EditorPrefs.SetBool(groupKey, state);
        
        if (state)
        {
            EditorGUI.indentLevel++;
            contentDrawer?.Invoke();
            EditorGUI.indentLevel--;
        }
        
        return state;
    }
}