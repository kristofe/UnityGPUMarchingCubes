using UnityEngine;

public class ParticlesRenderInto3DCS : MonoBehaviour
{
    public Material marchingCubesMaterial;
	public ComputeShader updateTexture3DCS;
	public ComputeShader updateParticlePositionsCS;
	public int textureSize = 16;
	private RenderTexture volume;

    public int particleCount = 1000;
    public float particlePower = 0.2f;
    //public Transform rootLocation;

    private Vector4[] particleLocations;
    //private Vector4[] particleColors;
    private Vector4[] particleTargets;

    private Color[] pixels;
    private ComputeBuffer volumeBuffer;
    private Texture3D tex3D;  // texture to pass to geometry shader

    private ComputeBuffer particleBuffer;
    //private ComputeBuffer particleColorBuffer;
    private ComputeBuffer targetBuffer;


	void OnDisable ()
	{
        if (volume!= null)
        {
            volume.Release();
            volume= null;
        }

        if (volumeBuffer != null)
        {
            volumeBuffer.Release();
            volumeBuffer = null;
        }

        if (targetBuffer != null)
        {
            targetBuffer.Release();
            targetBuffer = null;
        }
        /*
        if (particleColorBuffer != null)
        {
            particleColorBuffer.Release();
            particleColorBuffer = null;
        }
         */

        if (particleBuffer != null)
        {
            particleBuffer.Release();
            particleBuffer = null;
        }
	}
	
	void Start ()
	{
         // Setup the base args buffer
        particleLocations = new Vector4[particleCount];
        //particleColors = new Vector4[particleCount];
        particleTargets = new Vector4[particleCount];

        for (int i = 0; i < particleCount; i++)
        {
            // Generate a random location
            Vector3 newLoc = Random.insideUnitSphere * 0.5f + new Vector3(0.5f,0.5f,0.5f);
            particleLocations[i] = new Vector4(newLoc.x, newLoc.y, newLoc.z, particlePower);
            particleTargets[i] = newLoc;
            //particleColors[i] = new Vector3(Random.value, Random.value, Random.value);
        }

        targetBuffer = new ComputeBuffer(particleCount, 16);
        targetBuffer.SetData(particleTargets);

        //particleColorBuffer = new ComputeBuffer(particleCount, 16);
        //particleColorBuffer.SetData(particleColors);

        particleBuffer = new ComputeBuffer(particleCount, 16);
        particleBuffer.SetData(particleLocations);

        int pixelCount = textureSize * textureSize * textureSize;

        tex3D = new Texture3D( textureSize, textureSize, textureSize, TextureFormat.ARGB32, false);
        tex3D.wrapMode = TextureWrapMode.Clamp;
        tex3D.anisoLevel = 0;

        pixels = new Color[pixelCount];
        volumeBuffer = new ComputeBuffer(pixelCount, 16);
        volumeBuffer.SetData(pixels);

        /*
        volume = new RenderTexture(textureSize, textureSize, 0, RenderTextureFormat.ARGB32);
        volume.volumeDepth = textureSize;
        volume.isVolume = true;
        volume.enableRandomWrite = true;
        volume.Create();
        */

        //renderer.material.SetTexture ("_Volume", tex3D);
        //renderer.material.SetTexture ("_Volume", volume);
        //renderer.material.SetTexture("_dataFieldTex", tex3D);
        marchingCubesMaterial.SetTexture("_dataFieldTex", tex3D);
        

	}


	void Update ()
	{
		if (!SystemInfo.supportsComputeShaders)
			return;

         float T = Time.timeSinceLevelLoad;


         updateParticlePositionsCS.SetFloat("Time", T);
         updateParticlePositionsCS.SetVector("CoreLoc", Vector3.zero);

         //cs.SetBuffer(cs.FindKernel("CSMain"), "colBuffer", particleColorBuffer);
         updateParticlePositionsCS.SetBuffer(updateTexture3DCS.FindKernel("CSMain"), "posBuffer", particleBuffer);
         updateParticlePositionsCS.SetBuffer(updateTexture3DCS.FindKernel("CSMain"), "tarBuffer", targetBuffer);
         updateParticlePositionsCS.Dispatch(updateParticlePositionsCS.FindKernel("CSMain"), particleCount/10, 1, 1);


         

         //Render Volume Texture
         updateTexture3DCS.SetVector("g_Params", new Vector4(Time.timeSinceLevelLoad, textureSize, 1.0f / textureSize, 1.0f));
         updateTexture3DCS.SetInt("numParticles", particleCount);
         updateTexture3DCS.SetBuffer(updateTexture3DCS.FindKernel("CSMain"), "posBuffer", particleBuffer);
         updateTexture3DCS.SetBuffer(updateTexture3DCS.FindKernel("CSMain"), "pixels", volumeBuffer);
         //updateTexture3DCS.SetTexture(0, "pixels", volume);
         updateTexture3DCS.Dispatch(0, textureSize/8, textureSize/8, textureSize/8);

         //get pixels from render texture and copy to texture3D
         //Debug.Log("Before: " + pixels.Length);
         volumeBuffer.GetData(pixels);
         /*int count = 0;
         for (int i = 0; i < textureSize * textureSize * textureSize; ++i)
         {
             if (pixels[i].r > 0.0f || pixels[i].g > 0.0f || pixels[i].b > 0.0f)
             {
                 count++; 
                 //Debug.Log("Success");
             }
         }
         Debug.Log("After: " + pixels.Length + " count: " + count);
         */
         tex3D.SetPixels(pixels);
         tex3D.Apply();

         //renderer.material.SetTexture ("_Volume", tex3D);
	}
}
