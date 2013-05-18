// Upgrade NOTE: commented out 'float4x4 _Object2World', a built-in variable
// Upgrade NOTE: commented out 'float4x4 _World2Object', a built-in variable

Shader "Custom/GSMarchingCubesNew" 
{
  Properties 
	{
		dataFieldTex ("Data Field Texture", 3D) = "white"{}
		triTableTex ("Triangle Table Lookup Texture", 2D) = "white"{}
		testTexture ("Test Texture", 2D) = "white"{}
		isolevel ("ISO Level", float) = 0.1	
		cubeSize ("Cube Size", Vector) = (32,32,32,32)	
	}

	SubShader 
	{
		Pass
		{
			Tags { "RenderType"="Opaque" }
			LOD 200
		
			CGPROGRAM
				#pragma target 5.0
				#pragma debug
				#pragma only_renderers d3d11
				#pragma vertex VS_Main
				#pragma fragment FS_Main
				#pragma geometry GS_Main
				#include "UnityCG.cginc"  

				//1.0/256.0
				#define TX 0.00390625 
				//1/16
				#define TY 0.0625
				
					
				// **************************************************************
				// Data structures												*
				// **************************************************************
				struct GS_INPUT
				{
					float4	pos		: POSITION;
					float3	norm	: NORMAL;
					float2  tex0	: TEXCOORD0;
				};

				struct FS_INPUT
				{
					float4	pos		: POSITION;
					float3	norm	: NORMAL;
					float2  tex0	: TEXCOORD0;
				};


				// **************************************************************
				// Vars															*
				// **************************************************************

 				float isolevel;
 				sampler3D dataFieldTex;
 				sampler2D triTableTex;
 				sampler2D testTex;
				float4 cubeSize;
				// **************************************************************
				// Shader Programs												*
				// **************************************************************

				
				// Vertex Shader ------------------------------------------------
				GS_INPUT VS_Main(appdata_base v)
				{
					GS_INPUT output = (GS_INPUT)0;

					output.pos =  v.vertex;//mul(_Object2World, v.vertex);
					output.norm = v.normal.xyz;
					output.tex0 = v.texcoord.xy;

					return output;
				}
		
	

				// Fragment Shader -----------------------------------------------
				float4 FS_Main(FS_INPUT input) : COLOR
				{
					//return _SpriteTex.Sample(sampler_SpriteTex, input.tex0)  * saturate(0.5 + input.normal.y * 0.5) ;
					float3 N = input.norm;
					float3 L = normalize(_WorldSpaceLightPos0 - input.pos);
					float4 diffuseLight = max(dot(N,L),0);
					return tex2D(testTex,input.tex0) * diffuseLight;
				}

				//Get vertex i value within current marching cube 
				//float cubeVal(float3 vertDecals[8], float4 pos, int i){ 
				inline float cubeVal(float3 pos){ 
					//return sampleFunction(cubePos(i)).a;
					//return tex3D(dataFieldTex, (cubePos(vertDecals, pos,i)+1.0f)/2.0f).a; 
					return tex3D(dataFieldTex, (pos+1.0f)/2.0f).a; 

				} 
				 
	 
				//Get triangle table value 
				inline int triTableValue(int i, int j){ 
					//HACK: Remember unity doesn't allow me to create a 2d int texture
					//So the values are actually 1 greater.
					//Subtract 1 from every value because 1 was added when the texture
					//was created

					//Use tex2dlod
					//TODO: CHECK THIS WORKS!!!!!!
					//return int(tex2Dlod(triTableTex,float4(i*TX,j*TY,0.0,0.0)).w) - 1;
					//return int(tex2Dlod(triTableTex,float4(0.0,0.0,0.0,0.0)).w) - 1;
					float u = saturate(i * TX);
					float v = saturate(j * TY);
					float4 uv = float4(u,v,0,0);
					float4 color = tex2D(triTableTex,uv.xy);
					int c = color.w * 255;
					return c - 1;
					//return int(tex2Dlod(triTableTex,float4(0.0,0.0,0.0,0.0)).a) - 1;

					//GLSL's way of using integer coordinates to get a specific texel
					//return texelFetch2D(triTableTex, ivec2(j, i), 0).a - 1; 
				} 
				 
				//Compute interpolated vertex along an edge 
				inline float3 vertexInterp(float isolevel, float3 v0, float l0, float3 v1, float l1){ 
					//return mix(v0, v1, (isolevel-l0)/(l1-l0)); 
					//return lerp(v0, v1, (isolevel-l0)/(l1-l0)); 
					return float3(1,1,1);
				} 
				 
				//Geometry Shader entry point 
				[maxvertexcount(15)]
				void GS_Main(point GS_INPUT p[1], inout TriangleStream<FS_INPUT> triStream)	{
				//void GS_Main(triangle GS_INPUT p[3], inout TriangleStream<FS_INPUT> triStream)	{
					float4 pos = p[0].pos;
					float4x4 vp = mul(UNITY_MATRIX_MVP, _World2Object);
					FS_INPUT pIn;

					const float3 cubeStep = float3(2.0, 2.0, 2.0)/cubeSize;


										//Decal for each vertex in a marching cube
					const float3 vertDecals[8] = {
						float3(0.0, 0.0, 0.0), 
						float3(cubeStep.x, 0.0, 0.0), 
						float3(cubeStep.x, cubeStep.y, 0.0), 
						float3(0.0, cubeStep.y, 0.0), 
						float3(0.0, 0.0, cubeStep.z), 
						float3(cubeStep.x, 0.0, cubeStep.z), 
						float3(cubeStep.x, cubeStep.y, cubeStep.z), 
						float3(0.0, cubeStep.y, cubeStep.z), 
					};

					const float cubevals[8] = {
						cubeVal(pos + vertDecals[0]), 
						cubeVal(pos + vertDecals[1]), 
						cubeVal(pos + vertDecals[2]), 
						cubeVal(pos + vertDecals[3]), 
						cubeVal(pos + vertDecals[4]), 
						cubeVal(pos + vertDecals[5]), 
						cubeVal(pos + vertDecals[6]), 
						cubeVal(pos + vertDecals[7]), 
					};

					const float3 cubepos[8] = {
						(pos + vertDecals[0]), 
						(pos + vertDecals[1]), 
						(pos + vertDecals[2]), 
						(pos + vertDecals[3]), 
						(pos + vertDecals[4]), 
						(pos + vertDecals[5]), 
						(pos + vertDecals[6]), 
						(pos + vertDecals[7]), 
					};

					int cubeindex=0; 
					//Determine the index into the edge table which 
					//tells us which vertices are inside of the surface 
					cubeindex += int(cubevals[0] < isolevel); 
					cubeindex += int(cubevals[1] < isolevel)*2; 
					cubeindex += int(cubevals[2] < isolevel)*4; 
					cubeindex += int(cubevals[3] < isolevel)*8; 
					cubeindex += int(cubevals[4] < isolevel)*16; 
					cubeindex += int(cubevals[5] < isolevel)*32; 
					cubeindex += int(cubevals[6] < isolevel)*64; 
					cubeindex += int(cubevals[7] < isolevel)*128; 


					cubeindex = clamp(cubeindex, 0, 255);



					//I CAN'T USE THE VERTLIST.... I HAVE TO GENERATE IT!!!!
					float3 vertlist[12]; 
					//Find the vertices where the surface intersects the cube 
					vertlist[0] = vertexInterp(isolevel, cubepos[0], cubevals[0], cubepos[1], cubevals[1]); 
					vertlist[1] = vertexInterp(isolevel, cubepos[1], cubevals[1], cubepos[2], cubevals[2]); 
					vertlist[2] = vertexInterp(isolevel, cubepos[2], cubevals[2], cubepos[3], cubevals[3]); 
					vertlist[3] = vertexInterp(isolevel, cubepos[3], cubevals[3], cubepos[0], cubevals[0]); 
					vertlist[4] = vertexInterp(isolevel, cubepos[4], cubevals[4], cubepos[5], cubevals[5]); 
					vertlist[5] = vertexInterp(isolevel, cubepos[5], cubevals[5], cubepos[6], cubevals[6]); 
					vertlist[6] = vertexInterp(isolevel, cubepos[6], cubevals[6], cubepos[7], cubevals[7]); 
					vertlist[7] = vertexInterp(isolevel, cubepos[7], cubevals[7], cubepos[4], cubevals[4]); 
					vertlist[8] = vertexInterp(isolevel, cubepos[0], cubevals[0], cubepos[4], cubevals[4]); 
					vertlist[9] = vertexInterp(isolevel, cubepos[1], cubevals[1], cubepos[5], cubevals[5]); 
					vertlist[10] = vertexInterp(isolevel, cubepos[2], cubevals[2], cubepos[6], cubevals[6]); 
					vertlist[11] = vertexInterp(isolevel, cubepos[3], cubevals[3], cubepos[7], cubevals[7]); 
					

					int triTableValuesCache[16];
						
					int i = 0;
					for(i = 0; i < 16; i++){
						triTableValuesCache[i] = triTableValue(cubeindex,i);
					}
					
					float4 position = float4(0,0,0,0);
					//for (i=0; triTableValuesCache[i] >= 0; i+=3) { //Strange bug with this way, uncomment to test 
					for (i=0; i<5; i++) { //Strange bug with this way, uncomment to test 
						//if(triTableValuesCache[i] >= 0){ 
							//int idx = triTableValuesCache[i*3];
							//position = float4(p,1);
						//I HAVE TO GENERATE THE VERTICES ON THE FLY.  I HAVE TO INLINE THESE FUNCTIONS
						//LOOK AT THE ARRAYS IN HACKY.
						//use edge_to_vertex to lookup the indices in the cubepos and cubevals
						//use case_to_numpolys to emit zero size tris

						/*
							vertlist[0] = vertexInterp(isolevel, cubepos[0], cubevals[0], cubepos[1], cubevals[1]); 
					vertlist[1] = vertexInterp(isolevel, cubepos[1], cubevals[1], cubepos[2], cubevals[2]); 
					vertlist[2] = vertexInterp(isolevel, cubepos[2], cubevals[2], cubepos[3], cubevals[3]); 
					vertlist[3] = vertexInterp(isolevel, cubepos[3], cubevals[3], cubepos[0], cubevals[0]); 
					vertlist[4] = vertexInterp(isolevel, cubepos[4], cubevals[4], cubepos[5], cubevals[5]); 
					vertlist[5] = vertexInterp(isolevel, cubepos[5], cubevals[5], cubepos[6], cubevals[6]); 
					vertlist[6] = vertexInterp(isolevel, cubepos[6], cubevals[6], cubepos[7], cubevals[7]); 
					vertlist[7] = vertexInterp(isolevel, cubepos[7], cubevals[7], cubepos[4], cubevals[4]); 
					vertlist[8] = vertexInterp(isolevel, cubepos[0], cubevals[0], cubepos[4], cubevals[4]); 
					vertlist[9] = vertexInterp(isolevel, cubepos[1], cubevals[1], cubepos[5], cubevals[5]); 
					vertlist[10] = vertexInterp(isolevel, cubepos[2], cubevals[2], cubepos[6], cubevals[6]); 
					vertlist[11] = vertexInterp(isolevel, cubepos[3], cubevals[3], cubepos[7], cubevals[7]);
					*/
					//pIn.pos = mul(vp,p[0].pos);
					//pIn.pos = mul(vp,position);
					pIn.tex0 = p[0].tex0;
					pIn.norm = p[0].norm;
					triStream.Append(pIn);

					pIn.pos = mul(vp,p[0].pos + float4(0.05,0.1,0,0));
					triStream.Append(pIn);
					
					pIn.pos = mul(vp,p[0].pos + float4(0.1,0,0,0));
					triStream.Append(pIn);
					
					triStream.RestartStrip();
					/*
							pIn.pos = mul(vp,position);
							pIn.tex0 = p[0].tex0;
							pIn.norm = p[0].norm;
							triStream.Append(pIn);	

							position = float4(vertlist[triTableValuesCache[i*3+1]], 1); 
							pIn.pos = mul(vp,position);
							pIn.tex0 = p[0].tex0;
							pIn.norm = p[0].norm;
							triStream.Append(pIn);	

							position = float4(vertlist[triTableValuesCache[i*3+2]], 1); 
							pIn.pos = mul(vp,position);
							pIn.tex0 = p[0].tex0;
							pIn.norm = p[0].norm;
							triStream.Append(pIn);	

							triStream.RestartStrip();
							
							*/
							
						//}
						
					} 
//------------------------------------------------------------------------------
					/*
					pIn.pos = mul(vp,p[0].pos);
					pIn.tex0 = p[0].tex0;
					pIn.norm = p[0].norm;
					triStream.Append(pIn);

					pIn.pos = mul(vp,p[0].pos + float4(0.05,0.1,0,0));
					triStream.Append(pIn);
					
					pIn.pos = mul(vp,p[0].pos + float4(0.1,0,0,0));
					triStream.Append(pIn);
					
					triStream.RestartStrip();
					*/
//------------------------------------------------------------------------------
				}


				
			ENDCG
		}
	} 
}