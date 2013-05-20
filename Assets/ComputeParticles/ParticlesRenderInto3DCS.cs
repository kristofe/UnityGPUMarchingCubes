using UnityEngine;

public class ParticlesRenderInto3DCS : MonoBehaviour
{
	public ComputeShader cs;
	public int size = 16;
    public int texSize = 64;
	private RenderTexture volume;
		
	void OnDisable ()
	{
		if (volume != null) DestroyImmediate (volume);
		volume = null;
	}
	
	private void CreateResources ()
	{
		if (!volume)
		{
			volume = new RenderTexture (texSize, texSize, 0, RenderTextureFormat.ARGB32);
			volume.volumeDepth = texSize;
			volume.isVolume = true;
			volume.enableRandomWrite = true;
			volume.Create();
			renderer.material.SetTexture ("_Volume", volume);
		}
	}
	
	void Update ()
	{
		if (!SystemInfo.supportsComputeShaders)
			return;
		CreateResources ();
		cs.SetVector ("g_Params", new Vector4(Time.timeSinceLevelLoad, texSize, 1.0f/texSize, 1.0f));
		
		cs.SetTexture (0, "Result", volume);
		cs.Dispatch (0, size,size,size);
	}
}
