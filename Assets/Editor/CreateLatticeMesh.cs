using UnityEngine;
using UnityEditor;
using System.Collections;

public class CreateLatticeMesh : MonoBehaviour {
    public Mesh m;
    public float worldSize;
    public int meshDim;
    public string meshName = "LatticeMesh";
    public bool run;
    public bool overwrite;
	// Use this for initialization
	void Start () {
        if (run)
        {
            CreateLattice();
            saveMesh();
        }
	}
	
	// Update is called once per frame
	void Update () {
	
	}


    private void saveMesh(){
        string path = "Assets/Meshes/" + meshName + ".asset";
        Mesh tmp = (Mesh)AssetDatabase.LoadAssetAtPath(path, typeof(Mesh));
        if(tmp && overwrite){
            AssetDatabase.DeleteAsset(path);
            tmp = null;
        }

        AssetDatabase.CreateAsset(m, path);
        AssetDatabase.SaveAssets();
    }


    private Mesh CreateLattice()
    {
        m = GetComponent<MeshFilter>().mesh;
        ConstructMesh(m);
        m.RecalculateBounds();
        MeshFilter mf = (MeshFilter)transform.GetComponent(typeof(MeshFilter));
        mf.mesh = m;
        return m;
    }

    void ConstructMesh(Mesh m)
    {
        int vertexCount = meshDim * meshDim * meshDim;
        Vector3[] vertices = new Vector3[vertexCount];
        //Vector2[] uv = new Vector2[meshDim];
        Vector3[] normals = new Vector3[vertexCount];
        int[] triangles = new int[vertexCount*3];
        float scale = worldSize / meshDim;
        for (int z = 0; z < meshDim; ++z)
        {
            for (int y = 0; y < meshDim; ++y)
            {
                for (int x = 0; x < meshDim; ++x)
                {
                    int idx = z * meshDim * meshDim + y * meshDim + x;
                    vertices[idx] = new Vector3(x * scale, y * scale, z * scale);
                    normals[idx] = Vector3.right;
                    triangles[idx] = idx;
                }
            }
        }
        m.vertices = vertices;
        //m.uv = uv;
        m.normals = normals;
        m.triangles = triangles; 
    }
}
