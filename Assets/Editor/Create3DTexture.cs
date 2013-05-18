using UnityEngine;
using UnityEditor;
using System.Collections;

public class Create3DTexture : MonoBehaviour
{

    [MenuItem ("Asset Creation/Create 3D Texture")]
    public static void CreateTexture()
    {
        int n = 64;
        string texName = "pyroclasticNoise";
        Texture3D texture3D = new Texture3D(n, n, n, TextureFormat.ARGB32, true);

        Generate3DTexture(ref texture3D, n);
        save3DTexture(texture3D, texName);
    }

    public static  void Generate3DTexture(ref Texture3D texture3D, int n)
    {
        float r = 0.3f;
        int size = n * n * n;
        Color[] cols = new Color[size];
        int idx = 0;

        Color c = Color.white;
        float frequency = 0.01f / n;
        float center = n / 2.0f + 0.5f;

        for (int i = 0; i < n; i++)
        {
            for (int j = 0; j < n; j++)
            {
                for (int k = 0; k < n; k++, ++idx)
                {
                    float dx = center - i;
                    float dy = center - j;
                    float dz = center - k;

                    float off = Mathf.Abs(Perlin.Turbulence(i * frequency,
                                   j * frequency,
                                   k * frequency,
                                   6));

                    float d = Mathf.Sqrt(dx * dx + dy * dy + dz * dz) / (n);
                    //c.r = c.g = c.b = c.a = ((d-off) < r)?1.0f:0.0f;
                    float p = d - off;
                    c.r = c.g = c.b = c.a = Mathf.Clamp01(r - p);
                    cols[idx] = c;
                }
            }
        }

        //for(int i = 0; i < size; i++)
        //	Debug.Log (newC[i]);
        texture3D.SetPixels(cols);
        texture3D.Apply();
        texture3D.filterMode = FilterMode.Trilinear;
        texture3D.wrapMode = TextureWrapMode.Clamp;
        texture3D.anisoLevel = 1;
    }

    private static void save3DTexture(Texture3D texture3D, string texture3DName)
    {
        string path = "Assets/Textures3D/" + texture3DName + ".asset";
        Texture3D tmp = (Texture3D)AssetDatabase.LoadAssetAtPath(path, typeof(Texture3D));
        if (tmp)
        {
            AssetDatabase.DeleteAsset(path);
            tmp = null;
        }

        AssetDatabase.CreateAsset(texture3D, path);
        AssetDatabase.SaveAssets();
    }

}
