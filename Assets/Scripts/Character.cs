using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class Character : MonoBehaviour
{
    [SerializeField]private Material[] faceMats;
    [SerializeField]private Light mainLight;
    private Transform CharacterForward;

    void OnEnable()
    {
        if (faceMats == null)
        {
            GetFace();
        }
    }

    private void Start()
    {
        GetFace();
    }

    private void GetFace()
    {
        //获取所有_SDF_ON关键字开启的材质
        faceMats = GetComponentsInChildren<Renderer>()
            .SelectMany(r => r.sharedMaterials)
            .Where(m => m != null && m.shader != null && m.IsKeywordEnabled("_SDF_ON"))
            .Distinct()  // 避免重复材质
            .ToArray();
    }

    private void CalculateSDFDistance()
    {
        //计算光照在xz平面的分量
        if (mainLight == null || CharacterForward == null)
            return;
        

    }
}
