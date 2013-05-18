using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

public class CreateLatticeMesh : MonoBehaviour {
	// Use this for initialization
    [MenuItem ("Asset Creation/Create Point Lattice Mesh")]
	static void CreatePointLatticeMesh () {
        string meshName = "LatticeMesh1x1x1";
        Mesh m = CreateLattice(32);
        saveMesh(m, meshName);
       
	}
	


    private static void saveMesh(Mesh m, string meshName){
        string path = "Assets/Meshes/" + meshName + ".asset";
        Mesh tmp = (Mesh)AssetDatabase.LoadAssetAtPath(path, typeof(Mesh));
        if(tmp){
            AssetDatabase.DeleteAsset(path);
            tmp = null;
        }

        AssetDatabase.CreateAsset(m, path);
        AssetDatabase.SaveAssets();
    }


    private static Mesh CreateLattice(int meshDim)
    {
        Mesh m = new Mesh();
        ConstructMesh(m, meshDim);
        m.RecalculateBounds();
        return m;
    }

    private static void ConstructMesh(Mesh m, int meshDim)
    {
        int vertexCount = meshDim * meshDim * meshDim;
        Vector3[] vertices = new Vector3[vertexCount];
        //Vector2[] uv = new Vector2[meshDim];
        Vector3[] normals = new Vector3[vertexCount];
        List<int> triangles = new List<int>(vertexCount * 3);
        float scale = 1.0f / meshDim;
        for (int z = 0; z < meshDim; ++z)
        {
            for (int y = 0; y < meshDim; ++y)
            {
                for (int x = 0; x < meshDim; ++x)
                {
                    int idx = z * meshDim * meshDim + y * meshDim + x;
                    vertices[idx] = new Vector3(x * scale, y * scale, z * scale);
                    normals[idx] = Vector3.right;
                    triangles.Add(idx);
                    triangles.Add(idx);
                    triangles.Add(idx);
                }
            }
        }
        m.vertices = vertices;
        //m.uv = uv;
        m.normals = normals;
        m.triangles = triangles.ToArray(); 
    }
}
