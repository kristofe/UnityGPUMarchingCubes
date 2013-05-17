using UnityEngine;
using UnityEditor;
using System.Collections;

public class CreateTexture : MonoBehaviour {
    public string textureName;
    public int n;
    public Color color;

    private Texture2D texture2D;

	// Use this for initialization
	void Start () {
        Generate2DTexture();
        save2DTexture();
	
	}
	
	// Update is called once per frame
	void Update () {
	
	}


    public void Generate2DTexture()
    {
        texture2D = new Texture2D(n, n, TextureFormat.ARGB32, true);
        int size = n * n;
        Color[] cols = new Color[size];
        //float u, v;
        int idx = 0;
        //Color c = Color.white;
        for (int i = 0; i < n; i++)
        {
            //u = i / (float)n;
            for (int j = 0; j < n; j++, ++idx)
            {
                cols[idx] = color;

            }
        }

        texture2D.SetPixels(cols);
        texture2D.Apply();

    }

    private void save2DTexture()
    {
        string path = "Assets/Textures/" + textureName + ".asset";
        Texture2D tmp = (Texture2D)AssetDatabase.LoadAssetAtPath(path, typeof(Texture2D));
        if (tmp)
        {
            AssetDatabase.DeleteAsset(path);
            tmp = null;
        }

        AssetDatabase.CreateAsset(texture2D, path);
        AssetDatabase.SaveAssets();
    }	
}
