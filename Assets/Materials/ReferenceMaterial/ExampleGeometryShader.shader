// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/GeomShader-PassThrough" {
	Properties 
	{
		_SpriteTex ("Base (RGB)", 2D) = "white" {}
		_Size ("Size", Range(0, 3)) = 0.5
		lightPos ("Light Position", Vector) = (1.0, 1.0, 1.0, 1.0)
	}

	SubShader 
	{
		Pass
		{
			Tags { "RenderType"="Transparent" }
			LOD 200
			//ZWrite Off
			//Blend SrcAlpha One
		
			CGPROGRAM
				#pragma only_renderers d3d11
				#pragma target 4.0
				#pragma vertex VS_Main
				#pragma fragment FS_Main
				#pragma geometry GS_Main
				#include "UnityCG.cginc" 

				// **************************************************************
				// Data structures												*
				// **************************************************************
				struct GS_INPUT
				{
					float4	pos		: POSITION;
					float3	normal	: NORMAL;
					float2  tex0	: TEXCOORD0;
				};

				struct FS_INPUT
				{
					float4	pos		: POSITION;
					float3  normal	: NORMAL;
					float2  tex0	: TEXCOORD0;
				};


				// **************************************************************
				// Vars															*
				// **************************************************************

				float _Size;
				float4 lightPos;
				float4x4 _VP;
				Texture2D _SpriteTex;
				SamplerState sampler_SpriteTex;

				// **************************************************************
				// Shader Programs												*
				// **************************************************************

				// Vertex Shader ------------------------------------------------
				GS_INPUT VS_Main(appdata_base v)
				{
					GS_INPUT output = (GS_INPUT)0;

					output.pos =  mul(unity_ObjectToWorld, v.vertex);
					output.normal = v.normal;
					output.tex0 = v.texcoord;

					return output;
				}



				// Geometry Shader -----------------------------------------------------
				[maxvertexcount(3)]
				void GS_Main(triangle GS_INPUT p[3], inout TriangleStream<FS_INPUT> triStream)
				{
					float4x4 vp = mul(UNITY_MATRIX_MVP, unity_WorldToObject);
					FS_INPUT pIn;
					for(uint i= 0; i < 3; i++){
						pIn.pos = mul(vp,p[i].pos);
						pIn.tex0 = p[i].tex0;
						pIn.normal = p[i].normal;
						triStream.Append(pIn);
					}					
					triStream.RestartStrip();
				}



				// Fragment Shader -----------------------------------------------
				float4 FS_Main(FS_INPUT input) : COLOR
				{
					float3 N = input.normal;
					float3 L = normalize(lightPos - input.pos);
					float4 diffuseLight = max(dot(N,L),0);
					return _SpriteTex.Sample(sampler_SpriteTex, input.tex0) * diffuseLight;
				}

			ENDCG
		}
	} 
}

