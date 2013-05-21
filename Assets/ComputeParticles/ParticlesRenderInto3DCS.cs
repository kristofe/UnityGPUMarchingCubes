using UnityEngine;

public class ParticlesRenderInto3DCS : MonoBehaviour
{
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

    private ComputeBuffer particleBuffer;
    //private ComputeBuffer particleColorBuffer;
    private ComputeBuffer targetBuffer;


    private uint frame;

	void OnDisable ()
	{
		if (volume != null) DestroyImmediate (volume);
		volume = null;
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
        frame = 0;
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

		if (!volume)
		{
			volume = new RenderTexture (textureSize, textureSize, 0, RenderTextureFormat.RFloat);
			volume.volumeDepth = textureSize;
			volume.isVolume = true;
			volume.enableRandomWrite = true;
			volume.Create();
			//renderer.material.SetTexture ("_Volume", volume);
            renderer.material.SetTexture("_dataFieldTex", volume);
		}
        

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
         updateParticlePositionsCS.Dispatch(updateParticlePositionsCS.FindKernel("CSMain"), particleCount, 1, 1);

         //Render Volume Texture
         updateTexture3DCS.SetVector("g_Params", new Vector4(Time.timeSinceLevelLoad, textureSize, 1.0f / textureSize, 1.0f));
         updateTexture3DCS.SetInt("numParticles", particleCount);
         updateTexture3DCS.SetBuffer(updateTexture3DCS.FindKernel("CSMain"), "posBuffer", particleBuffer);
         //updateTexture3DCS.SetTexture(0, "Result", volume);
         updateTexture3DCS.Dispatch(0, textureSize, textureSize, textureSize);


	}
}
