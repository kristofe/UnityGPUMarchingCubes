using UnityEngine;
using System.Collections;

public class PlayWithIsoLevels : MonoBehaviour {

	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () 
	{
		 float level = Mathf.Sin(Time.time) * 0.5f + 0.5f;
		 level =  0.05f + level * 0.25f;
		Renderer Rend = GetComponent<Renderer>().GetComponent<Renderer>();
		Rend.material.SetFloat("_isoLevel", level);
	}
}
