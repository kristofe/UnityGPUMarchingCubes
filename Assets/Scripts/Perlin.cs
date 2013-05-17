using System.Collections;
using System;
using UnityEngine;

public class Perlin
{
	// Returns noise between 0 - 1
	static public float NoiseNormalized(float x, float y)
	{
		//-0.697 - 0.795 + 0.697
		float value = Noise(x, y);
		
		/* Replacing division with multipling by the inverse as a decimal
			0.793+0.69 	= 1.483
			1/1.483		= 0.67430883345
		*/
		//value = (value + 0.69F) / (0.793F + 0.69F);
		value = (value + 0.69F) *0.67430883345F;
        return value;
	}
 
	static public float Noise(float x, float y)
	{
		int X = (int)Mathf.Floor(x) & 255,                  // FIND UNIT CUBE THAT
		Y = (int)Mathf.Floor(y) & 255;                  // CONTAINS POINT.
		x -= Mathf.Floor(x);                                // FIND RELATIVE X,Y,Z
		y -= Mathf.Floor(y);                                // OF POINT IN CUBE.
		float u = fade(x),                                // COMPUTE FADE CURVES
		v = fade(y);                                // FOR EACH OF X,Y,Z.
		int A = p[X  ]+Y, AA = p[A], AB = p[A+1],      // HASH COORDINATES OF
		B = p[X+1]+Y, BA = p[B], BB = p[B+1];      // THE 8 CUBE CORNERS,
		
		float res = lerp(v, lerp(u, grad2(p[AA  ], x  , y   ),  // AND ADD
                                     grad2(p[BA  ], x-1, y )), // BLENDED
                             lerp(u, grad2(p[AB  ], x  , y-1 ),  // RESULTS
                                     grad2(p[BB  ], x-1, y-1 )));// FROM  8
                 return res;
 	}
	
	static public float Noise(float x, float y, float z) {
		int X = (int)Mathf.Floor(x) & 255,                  // FIND UNIT CUBE THAT
		Y = (int)Mathf.Floor(y) & 255,                  // CONTAINS POINT.
		Z = (int)Mathf.Floor(z) & 255;
		x -= Mathf.Floor(x);                                // FIND RELATIVE X,Y,Z
		y -= Mathf.Floor(y);                                // OF POINT IN CUBE.
		z -= Mathf.Floor(z);
		float u = fade(x),                                // COMPUTE FADE CURVES
		v = fade(y),                                // FOR EACH OF X,Y,Z.
		w = fade(z);
		int A = p[X  ]+Y, AA = p[A]+Z, AB = p[A+1]+Z,      // HASH COORDINATES OF
		B = p[X+1]+Y, BA = p[B]+Z, BB = p[B+1]+Z;      // THE 8 CUBE CORNERS,
		
		return lerp(w, lerp(v, lerp(u, grad(p[AA  ], x  , y  , z   ),  // AND ADD
		grad(p[BA  ], x-1, y  , z   )), // BLENDED
		lerp(u, grad(p[AB  ], x  , y-1, z   ),  // RESULTS
		grad(p[BB  ], x-1, y-1, z   ))),// FROM  8
		lerp(v, lerp(u, grad(p[AA+1], x  , y  , z-1 ),  // CORNERS
		grad(p[BA+1], x-1, y  , z-1 )), // OF CUBE
		lerp(u, grad(p[AB+1], x  , y-1, z-1 ),
		grad(p[BB+1], x-1, y-1, z-1 ))));
	}

  static public float Turbulence(float posX, float posY, int octaves) {
    float x = 0;
    float scale = 1;
    int octave = 0;
    while (++octave <= octaves) {
      posX = posX/scale;
      posY = posY/scale;
      x = x + Math.Abs(Noise(posX, posY))*scale;
      scale = scale/2;
    }
    return x;
  }

  static public float Fractal(float posX, float posY, int octaves)
  {
      float x = 0;
      float scale = 1;
      int octave = 0;
      while (++octave <= octaves)
      {
          posX = posX / scale;
          posY = posY / scale;
          x = x + Noise(posX, posY) * scale;
          scale = scale / 2;
      }
      return x;
  }

  static public float Marble(float posX, float posY, int octaves) {
    //Vector3 rgb =  new Vector3();
    float x = Mathf.Sin((posY+3.0f*Turbulence(posX,posY,octaves))*Mathf.PI);
    x = Mathf.Sqrt(x+1)*.7071f;
    //rgb.z=.3+.8*x;
    //x = Mathf.sqrt(x);
    //rgb.x = .3 + .6*x;
    //rgb.z = .6 + .4*x;
    
    return x;
  }
  static public float Turbulence(float posX, float posY, float posZ, int octaves) {
    float x = 0;
    float scale = 1;
    int octave = 0;
    while (++octave <= octaves) {
      posX = posX/scale;
      posY = posY/scale;
      posZ = posZ/scale;
      x = x + Math.Abs(Noise(posX, posY, posZ))*scale;
      scale = scale/2;
    }
    return x;
  }

  static public float Marble(float posX, float posY, float posZ, int octaves) {
    //Vector3 rgb =  new Vector3();
    float x = Mathf.Sin((posY+3.0f*Turbulence(posX,posY,posZ,octaves))*Mathf.PI);
    x = Mathf.Sqrt(x+1)*.7071f;
    //rgb.z=.3+.8*x;
    //x = Mathf.sqrt(x);
    //rgb.x = .3 + .6*x;
    //rgb.z = .6 + .4*x;
    
    return x;
  }

	static float fade(float t) { return t * t * t * (t * (t * 6 - 15) + 10); }
	static float lerp(float t, float a, float b) { return a + t * (b - a); }
	static float grad(int hash, float x, float y, float z) {
	int h = hash & 15;                      // CONVERT LO 4 BITS OF HASH CODE
	float u = h<8 ? x : y,                 // INTO 12 GRADIENT DIRECTIONS.
	v = h<4 ? y : h==12||h==14 ? x : z;
	return ((h&1) == 0 ? u : -u) + ((h&2) == 0 ? v : -v);
	}
 
	static float grad2(int hash, float x, float y) {
		int h = hash & 15;                      // CONVERT LO 4 BITS OF HASH CODE
		float u = h < 8 ? x : y,                 // INTO 12 GRADIENT DIRECTIONS.
		v = h < 4 ? y : h==12 || h==14 ? x : 0;
		return ((h&1) == 0 ? u : -u) + ((h&2) == 0 ? v : -v);
	}
	
	static int[] p = { 151,160,137,91,90,15,
		131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
		190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
		88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
		77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
		102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
		135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
		5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
		223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
		129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
		251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
		49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
		138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
		151,160,137,91,90,15,
		131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
		190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
		88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
		77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
		102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
		135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
		5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
		223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
		129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
		251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
		49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
		138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
	};
}
