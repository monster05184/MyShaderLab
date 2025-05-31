using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering.Universal;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class OutlineAddFeature : ScriptableRendererFeature
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
            PassNames = new string[] { "Outline"};
        }
    }

    public static OutlineAddFeature instance;

    [System.Serializable]
    public class PassSettings
    {
        public string passTag = "Outline";
        [Header("Settings")] public bool ShouldRender = true;
        
        [Tooltip("Set LayerNum")] [Range(1, 200)]
        public int PassLayerNum = 20;

        [Range(1000, 5000)] public int QueueMin = 2000;
        [Range(1000, 5000)] public int QueueMax = 5000;
        public RenderPassEvent PassEvent = RenderPassEvent.AfterRenderingSkybox;
        public FilterSettings filterSettings = new FilterSettings();

    }

    public class OutlineRenderPass : ScriptableRenderPass
    {
        private string m_ProfilerTag;
        private RenderQueueType renderQueueType;
        private PassSettings settings;
        private OutlineAddFeature outlineAddFeature = null;
        public List<ShaderTagId> m_ShaderTagIdList = new List<ShaderTagId>();
        private ShaderTagId shadowCasterSTI = new ShaderTagId("ShadowCaster");
        private FilteringSettings filter;

        public OutlineRenderPass(PassSettings settings, OutlineAddFeature render, FilterSettings filterSettings)
        {
            m_ProfilerTag = settings.passTag;
            string[] shaderTags = filterSettings.PassNames;
            this.settings = settings;
            this.renderQueueType = filterSettings.RenderQueueType;
            outlineAddFeature = render;
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
            cmd.Clear();
            context.ExecuteCommandBuffer(cmd);
            context.DrawRenderers(renderingData.cullResults,ref baseDrawingSettings,ref filter);
            CommandBufferPool.Release(cmd);
            
        }
    }



    public PassSettings settings = new PassSettings();
    OutlineRenderPass m_ScriptablePass;

    public override void Create()
    {
        instance = this;
        FilterSettings filter = settings.filterSettings;
        m_ScriptablePass = new OutlineRenderPass(settings, this, filter);
        m_ScriptablePass.renderPassEvent = settings.PassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}
