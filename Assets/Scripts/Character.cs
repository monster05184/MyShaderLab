using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class Character : MonoBehaviour
{
    [SerializeField]private Material[] faceMats;
    [SerializeField]private Light mainLight;
    [SerializeField]private Transform CharacterForward;

    void Awake()
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

    private void Update()
    {
        CalculateSDFDistance();
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
            return ;
        var lightXoZ = new Vector3(mainLight.transform.forward.x, 0, mainLight.transform.forward.z);
        lightXoZ = lightXoZ.normalized;
        var d = Vector3.Dot(lightXoZ, CharacterForward.forward);
        foreach (var mat in faceMats)
        {
            mat.SetFloat("_SDFValue", d);
        }

        return ;
    }
}
