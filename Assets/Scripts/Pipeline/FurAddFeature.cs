using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering.Universal;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FurAddFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class FilterSettings
    {
        public RenderQueueType RenderQueueType;
        public LayerMask LayerMask = 1;
        public string[] PassNames;

        public FilterSettings()
        {
            RenderQueueType = RenderQueueType.Opaque;
            LayerMask = ~0;
            PassNames = new string[] { "", "FurRenderLayer" };
        }
    }

    public static FurAddFeature instance;

    [System.Serializable]
    public class PassSettings
    {
        public string passTag = "FurRenderer";
        [Header("Settings")] public bool ShouldRender = true;
        
        [Tooltip("Set LayerNum")] [Range(1, 200)]
        public int PassLayerNum = 20;

        [Range(1000, 5000)] public int QueueMin = 2000;
        [Range(1000, 5000)] public int QueueMax = 5000;
        public RenderPassEvent PassEvent = RenderPassEvent.AfterRenderingSkybox;
        public FilterSettings filterSettings = new FilterSettings();

    }

    public class FurRenderPass : ScriptableRenderPass
    {
        private string m_ProfilerTag;
        private RenderQueueType renderQueueType;
        private PassSettings settings;
        private FurAddFeature furAddFeature = null;
        public List<ShaderTagId> m_ShaderTagIdList = new List<ShaderTagId>();
        private ShaderTagId shadowCasterSTI = new ShaderTagId("ShadowCaster");
        private FilteringSettings filter;
        public Material overrideMaterial { get; set; }
        public int overrideMaterialPassIndex { get; set; }

        public FurRenderPass(PassSettings settings, FurAddFeature render, FilterSettings filterSettings)
        {
            m_ProfilerTag = settings.passTag;
            string[] shaderTags = filterSettings.PassNames;
            this.settings = settings;
            this.renderQueueType = filterSettings.RenderQueueType;
            furAddFeature = render;
            RenderQueueRange queue = new RenderQueueRange();
            queue.lowerBound = settings.QueueMin;
            queue.upperBound = settings.QueueMax;
            filter = new FilteringSettings(queue, filterSettings.LayerMask);
            if (shaderTags != null && shaderTags.Length > 0)
            {
                foreach(var passName in shaderTags)
                    m_ShaderTagIdList.Add(new ShaderTagId(passName));
            }

        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            SortingCriteria sortingCriteria = (renderQueueType == RenderQueueType.Transparent)
                ? SortingCriteria.CommonTransparent
                : renderingData.cameraData.defaultOpaqueSortFlags;
            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
            DrawingSettings baseDrawingSettings, layerDrawingSettings;
            if (m_ShaderTagIdList.Count > 0)
                baseDrawingSettings = CreateDrawingSettings(m_ShaderTagIdList[0], ref renderingData,
                    renderingData.cameraData.defaultOpaqueSortFlags);
            else return;
            if (m_ShaderTagIdList.Count > 1)
                layerDrawingSettings = CreateDrawingSettings(m_ShaderTagIdList[1], ref renderingData,
                    renderingData.cameraData.defaultOpaqueSortFlags);
            else return;
            float inter = (float)1 / (float)settings.PassLayerNum;
            cmd.Clear();
            cmd.SetGlobalFloat("FUR_OFFSET",0);
            context.ExecuteCommandBuffer(cmd);
            context.DrawRenderers(renderingData.cullResults,ref baseDrawingSettings,ref filter);
            //设定OffsetInter的变化为先大后小，符合y = Ax + B
            //总的Offset积分得到为y = 0.5 * i ^ 2 + B * i 
            for (int i = 1; i < settings.PassLayerNum; i++)
            {
                float A = -(float)inter / (float)settings.PassLayerNum;
                float B = inter;
                float furOffset = (float)  A * Mathf.Pow(i, 2) + 2 * B * i;
                cmd.Clear();
                cmd.SetGlobalFloat("FUR_OFFSET", furOffset * 0.8f);
                context.ExecuteCommandBuffer(cmd);
                context.DrawRenderers(renderingData.cullResults,ref layerDrawingSettings,ref filter);
            }
            CommandBufferPool.Release(cmd);
            
        }
    }



    public PassSettings settings = new PassSettings();
    FurRenderPass m_ScriptablePass;

    public override void Create()
    {
        instance = this;
        FilterSettings filter = settings.filterSettings;
        m_ScriptablePass = new FurRenderPass(settings, this, filter);
        m_ScriptablePass.renderPassEvent = settings.PassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}
