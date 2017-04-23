using UnityEngine;

public class LatticeRenderInto3DCS : MonoBehaviour
{
	public ComputeShader cs;
	public int size = 16;	
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
			volume = new RenderTexture (size, size, 0, RenderTextureFormat.ARGB32);
			volume.volumeDepth = size;
			volume.isVolume = true;
			volume.enableRandomWrite = true;
			volume.Create();
			Renderer Rend = GetComponent<Renderer>().GetComponent<Renderer>();
			Rend.material.SetTexture ("_Volume", volume);
		}
	}
	
	void Update ()
	{
		if (!SystemInfo.supportsComputeShaders)
			return;
		CreateResources ();
		cs.SetVector ("g_Params", new Vector4(Time.timeSinceLevelLoad, size, 1.0f/size, 1.0f));
		
		cs.SetTexture (0, "Result", volume);
		cs.Dispatch (0, size,size,size);
	}
}
