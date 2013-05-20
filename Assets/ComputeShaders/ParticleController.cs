using UnityEngine;
using System.Collections;
using System.Threading;

public class ParticleController : MonoBehaviour
{


    public Texture2D particleTexture;

    public Shader shader;

    private Material mat;

    //private ComputeBuffer cbDrawArgs;
    //private ComputeBuffer cbPoints;

    public ComputeShader cs;

    public int particleCount = 1000;
    public Transform rootLocation;

    private float[] x_p;
    private float[] y_p;
    private float[] z_p;

    private Vector3[] particleLocations;
    private Vector3[] particleColors;
    private Vector3[] particleTargets;

    private ComputeBuffer particleBuffer;
    private ComputeBuffer particleColorBuffer;
    private ComputeBuffer targetBuffer;

    private bool useCS = true;



    // Setup the shaders and such
    void Start()
    {
        // Setup the base args buffer
        particleLocations = new Vector3[particleCount];
        particleColors = new Vector3[particleCount];
        particleTargets = new Vector3[particleCount];

        for (int i = 0; i < particleCount; i++)
        {
            // Generate a random location
            Vector3 newLoc = rootLocation.position + Random.insideUnitSphere;
            particleLocations[i] = newLoc;
            particleTargets[i] = newLoc;
            particleColors[i] = new Vector3(Random.value, Random.value, Random.value);
        }

        targetBuffer = new ComputeBuffer(particleCount, 12);
        targetBuffer.SetData(particleTargets);

        particleColorBuffer = new ComputeBuffer(particleCount, 12);
        particleColorBuffer.SetData(particleColors);

        particleBuffer = new ComputeBuffer(particleCount, 12);
        particleBuffer.SetData(particleLocations);

        // Setup the material based on the shader
        mat = new Material(shader);
        mat.hideFlags = HideFlags.HideAndDontSave;

        mat.SetTexture("_Sprite", particleTexture);
        Debug.Log("Finshed setting up");
    }

    private void ReleaseResources()
    {

        if (targetBuffer != null)
        {
            targetBuffer.Release();
            targetBuffer = null;
        }
        if (particleColorBuffer != null)
        {
            particleColorBuffer.Release();
            particleColorBuffer = null;
        }
        if (particleBuffer != null)
        {
            particleBuffer.Release();
            particleBuffer = null;
        }
        //Object.DestroyImmediate(mat);
    }

    void OnDisable()
    {
        ReleaseResources();
    }


    void Update()
    {
        float T = Time.timeSinceLevelLoad;

        if (useCS)
        {
            if (useCS)
            {
                // Set time to the compute shader
                cs.SetFloat("Time", T);
                cs.SetVector("CoreLoc", rootLocation.position);

                // Have the compute shader process all the particle locations
                cs.SetBuffer(cs.FindKernel("CSMain"), "colBuffer", particleColorBuffer);
                cs.SetBuffer(cs.FindKernel("CSMain"), "posBuffer", particleBuffer);
                cs.SetBuffer(cs.FindKernel("CSMain"), "tarBuffer", targetBuffer);
                // Dispatch the compute shader
                cs.Dispatch(cs.FindKernel("CSMain"), particleCount, 1, 1);
                // Reconstruct the locations and colors
            }
        }
        else
        {
            // Do some modifications on the cpu

            for (int i = 0; i < particleCount; i++)
            {
                particleColors[i].x = Mathf.Cos(T);
                particleColors[i].y = Mathf.Sin(T);
                particleLocations[i] += Random.insideUnitSphere / 3;
            }


            // Set the buffers
            particleColorBuffer.SetData(particleColors);
            particleBuffer.SetData(particleLocations);
        }
    }

    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        // The meat of the controller, this is where we can actually render our particles
        mat.SetTexture("_Sprite", particleTexture);

        // Blit the sceene without any interaction
        //Graphics.Blit(src, dst);


        // Set the buffers
        //particleBuffer.SetData(particleLocations);
        mat.SetBuffer("particleBuffer", particleBuffer);
        mat.SetBuffer("particleColor", particleColorBuffer);
        mat.SetPass(0);
        // Draw the particles into the scene
        Graphics.DrawProcedural(MeshTopology.LineStrip, particleCount);


        // Blit the sceene without any interaction
        Graphics.Blit(src, dst);
    }
}
