Shader "DX11/Particles Sample 3D Texture" {
	Properties {
		_Size ("Size", Range(0, 0.3)) = 0.1
		_Sprite ("", 2D) = "white" {}
		_Volume ("Texture", 3D) = "" {}
	}
	SubShader {
		Pass {
				//ZWrite Off ZTest Always Cull Off Fog { Mode Off }
				ZWrite Off Cull Off Fog { Mode Off }
				//Blend SrcAlpha OneMinusSrcAlpha
				Blend One One

			CGPROGRAM
				#pragma only_renderers d3d11
				#pragma target 5.0
				#pragma vertex vert
				#pragma geometry geom
				#pragma fragment frag
		 
				#include "UnityCG.cginc"
			   
				uniform float _Size;
				sampler3D _Volume;
				uniform sampler2D _Sprite;
				//For when the particles are simulated in a compute shader
				//StructuredBuffer<float3> particleBuffer;
				//StructuredBuffer<float3> particleColor;
			 
				struct vs_in {
					float4 pos : POSITION;
					float4 uv : TEXCOORD0;
					float4 size : TEXCOORD1;
					float4 col : COLOR;
				};

				struct vs_out {
						float4 pos : SV_POSITION;
						float4 uv : TEXCOORD0;
						float4 size : TEXCOORD1;
						float4 col : COLOR;
				};

				//For when the particles are simulated in a compute shader
				//vs_out vert (uint id : SV_VertexID)
				//{
				//        // This runs through for each instance of the shader, id corrisponds to the particle in the list
				//        vs_out o;
				//        // Pull the location data and send it off to the geometry shader so it can be built into a particle
				//        o.pos = float4(particleBuffer[id], 1.0f);
				//        o.col = float4(particleColor[id], 1.0f);
				//        return o;
				//}

				vs_out vert (vs_in v)
				{
						// This runs through for each instance of the shader, id corrisponds to the particle in the list
						vs_out o;
						// Pull the location data and send it off to the geometry shader so it can be built into a particle
						o.pos = v.pos;
						//o.uv = v.uv;
						o.col = v.pos.xyzw*0.5+0.5;
						o.size = v.size;
						//o.col = v.col;
						return o;
				}
			   
				struct gs_out {
						float4 pos : SV_POSITION;
						float2 uv  : TEXCOORD0;
						float4 col : COLOR;
				};
			   
				[maxvertexcount(4)]
				void geom (point vs_out input[1], inout TriangleStream<gs_out> outStream)
				{
						//float Size = 0.1f;
					   
						float dx = _Size;
						float dy = _Size;// * _ScreenParams.x / _ScreenParams.y;
						gs_out output;
					   
						// Run the given position through the View Proj matrix
					   
						float4 corLoc = mul(UNITY_MATRIX_MVP, input[0].pos);
						//float4 corLoc = mul(UNITY_MATRIX_VP, input[0].pos);
						// Build the 4 points of the sprite and it's uv
						output.pos = corLoc + float4(-dx, dy,0,0); 
						output.uv=float2(0,0); 
						output.col = input[0].col; 
						outStream.Append (output);

						output.pos = corLoc + float4( dx, dy,0,0);
						output.uv=float2(1,0);
						output.col = input[0].col;
						outStream.Append (output);

						output.pos = corLoc + float4(-dx,-dy,0,0);
						output.uv=float2(0,1);
						output.col = input[0].col;
						outStream.Append (output);

						output.pos = corLoc + float4( dx,-dy,0,0);
						output.uv=float2(1,1);
						output.col = input[0].col;
						outStream.Append (output);
						
						
						// Send it off as a particle to the pixel shader
						outStream.RestartStrip();
				}
			   
				// Pixel shader, straight forward just sample the sprite
			   
				float4 frag (gs_out i ) : COLOR0
				{
						float4 c = tex3D (_Volume, i.col.xyz);
						float4 col = tex2D(_Sprite, i.uv) * c;
						//float4 col = tex2D(_Sprite, i.uv) * i.col;
						//col.w = 0.1f;
						//return i.col;
						return col;
				}

			ENDCG

			}
	}

Fallback "VertexLit"
}
