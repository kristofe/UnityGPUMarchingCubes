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
		dataSize ("Data Size", Vector) = (128,128,128,128)	
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
				float4 dataSize;
				// **************************************************************
				// Shader Programs												*
				// **************************************************************

				// Vertex Shader ------------------------------------------------
				GS_INPUT VS_Main(appdata_base v)
				{
					GS_INPUT output = (GS_INPUT)0;

					output.pos =  mul(_Object2World, v.vertex);
					output.norm = v.normal;
					output.tex0 = v.texcoord;

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

				// Geometry Shader -----------------------------------------------------
				/*
				[maxvertexcount(15)]
				void GS_Main(point GS_INPUT p[1], inout TriangleStream<FS_INPUT> triStream)	{
					const float cap = 0.5;
					const float halfSize = 10;
	 				const float4 cubeVerts[8] = {
						//front face
						float4(-halfSize, -halfSize, -halfSize, 1) ,		//LB   0
						float4(-halfSize,  halfSize, -halfSize,	1) ,		//LT   1
						float4( halfSize,  halfSize, -halfSize, 1) ,		//RT   2
						float4( halfSize, -halfSize, -halfSize, 1) ,		//RB   3
						//back
						float4(-halfSize, -halfSize,  halfSize, 1),		// LB  4
						float4(-halfSize,  halfSize,  halfSize, 1),		// LT  5
						float4( halfSize,  halfSize,  halfSize, 1),		// RT  6
						float4( halfSize, -halfSize,  halfSize, 1)		// RB  7
					};
					const float weights[8] = {
						SampleDensity(p[0].pos + cubeVerts[0]),
						SampleDensity(p[0].pos + cubeVerts[1]),
						SampleDensity(p[0].pos + cubeVerts[2]),
						SampleDensity(p[0].pos + cubeVerts[3]),
						SampleDensity(p[0].pos + cubeVerts[4]),
						SampleDensity(p[0].pos + cubeVerts[5]),
						SampleDensity(p[0].pos + cubeVerts[6]),
						SampleDensity(p[0].pos + cubeVerts[7])
					};

					int marchingCase = 
					(weights[7] > cap) * 128 + 
					(weights[6] > cap) * 64 +
					(weights[5] > cap) * 32 +
					(weights[4] > cap) * 16 +
					(weights[3] > cap) * 8 +
					(weights[2] > cap) * 4 +
					(weights[1] > cap) * 2 +
					(weights[0] > cap) * 1;

					float4x4 vp = mul(UNITY_MATRIX_MVP, _World2Object);
					//float4x4 vp = UNITY_MATRIX_IDENT;
					FS_INPUT pIn;
					for( int i = 0; i < 5; i++ ){
						if(i >= numpolys){
							pIn.pos = float4(0,0,0,0) + p[0].pos;
							pIn.tex0 = float2(1.0f, 0.0f);
							pIn.normal = float3(0,1,0);
							triStream.Append(pIn);
							triStream.Append(pIn);
							triStream.Append(pIn);
							triStream.RestartStrip();
						}else{
							
							int4 polyEdges = edge_connect_list[marchingCase * 5 + i];
							
							int va = edge_to_verts[polyEdges.x].x;
							int vb = edge_to_verts[polyEdges.x].y;
							float amount = (cap - weights[va]) / (weights[vb] - weights[va]);
							float4 worldPos = lerp( p[0].pos + cubeVerts[va],  p[0].pos + cubeVerts[vb], amount);
							float4 pA = mul(vp, worldPos);
							
							va = edge_to_verts[polyEdges.y].x;
							vb = edge_to_verts[polyEdges.y].y;
							amount = (cap - weights[va]) / (weights[vb] - weights[va]);
							worldPos = lerp( p[0].pos + cubeVerts[va],  p[0].pos + cubeVerts[vb], amount);
							float4 pB = mul(vp, worldPos);
							
							va = edge_to_verts[polyEdges.z].x;
							vb = edge_to_verts[polyEdges.z].y;
							amount = (cap - weights[va]) / (weights[vb] - weights[va]);
							worldPos = lerp( p[0].pos + cubeVerts[va],  p[0].pos + cubeVerts[vb], amount);
							float4 pC = mul(vp, worldPos);

							float4 r = pA - pC;
							float4 f = pA - pB;
							float3 normal = normalize(cross(f,r));

							pIn.pos = pA;
							pIn.tex0 = float2(1.0f, 0.0f);
							pIn.normal = normal;
							triStream.Append(pIn);
						
							pIn.pos = pB;
							pIn.tex0 = float2(1.0f, 0.0f);
							pIn.normal = normal;
							triStream.Append(pIn);

							pIn.normal = normal;
							pIn.pos = pC;
							pIn.tex0 = float2(1.0f, 0.0f);
							triStream.Append(pIn);

							triStream.RestartStrip();
						}
					}
					
				}
				///////////////////////////////////////////////////////////////////////////
				*/


				//Get vertex i position within current marching cube 
				//float3 cubePos(float3 vertDecals[8], float4 pos, int i){ 
	/*
				inline float3 cubePos(float4 pos){ 
					//return gl_PositionIn[0].xyz + vertDecals[i]; 

					//vertDecals have to be created and set in the shader. unity doesn't allow
					//uniform arrays
				} 
	*/
				 
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
					float4 uv = float4(1,1,0,0);
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
					return lerp(v0, v1, (isolevel-l0)/(l1-l0)); 
				} 
				 
				//Geometry Shader entry point 
				[maxvertexcount(15)]
				void GS_Main(point GS_INPUT p[1], inout TriangleStream<FS_INPUT> triStream)	{
				//void GS_Main(triangle GS_INPUT p[3], inout TriangleStream<FS_INPUT> triStream)	{
					float4 pos = p[0].pos;
					float4x4 vp = mul(UNITY_MATRIX_MVP, _World2Object);
					FS_INPUT pIn;

					const float3 cubeStep = float3(2.0, 2.0, 2.0)/cubeSize;

					const float3 dataStep = float3(1.0/dataSize.x,1.0/dataSize.y,1.0/dataSize.z);

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


					/*
					float4x4 vp = mul(UNITY_MATRIX_MVP, _World2Object);
					FS_INPUT pIn;
					for(uint i= 0; i < 3; i++){
						pIn.pos = mul(vp,p[i].pos);
						pIn.tex0 = p[i].tex0;
						pIn.norm = p[i].norm;
						triStream.Append(pIn);
					}					
					triStream.RestartStrip();
					*/




	 /*
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
*/


					int cubeindex = 
						(cubevals[7] < isolevel) * 128 + 
						(cubevals[6] < isolevel) * 64 +
						(cubevals[5] < isolevel) * 32 +
						(cubevals[4] < isolevel) * 16 +
						(cubevals[3] < isolevel) * 8 +
						(cubevals[2] < isolevel) * 4 +
						(cubevals[1] < isolevel) * 2 +
						(cubevals[0] < isolevel) * 1;
					
					cubeindex = clamp(cubeindex, 0, 255);
					//int cubeindex = 0;
					//Cube is entirely in/out of the surface 
					//if (!(cubeindex == 0 || cubeindex == 255))
					//{ 
					 
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
						
						int i = 0;	 

						int triTableValuesCache[16];

						for(i = 0; i < 16; i++){
							triTableValuesCache[i] = triTableValue(cubeindex,i);
						}
							
						// Create the triangle 
						//gl_FrontColor=vec4(cos(isolevel*10.0-0.5), sin(isolevel*10.0-0.5), cos(1.0-isolevel),1.0); 
						float4 position = float4(0,0,0,0);
						//float4x4 vp = mul(UNITY_MATRIX_MVP, _World2Object);
						//FS_INPUT pIn;
						for (i=0; i < 5; i++) { //Strange bug with this way, uncomment to test 
						//for (i=0; triTableValue(cubeindex, i)!=-1; i+=3) { //Strange bug with this way, uncomment to test 
							//if(triTableValue(cubeindex, i)!=-1){ 
							if(triTableValuesCache[i] >= 0){ 
								//Generate first vertex of triangle// 
								//Fill position varying attribute for fragment shader 
								int j = i  * 3 + 1;
								//position= float4(vertlist[triTableValue(cubeindex, j)], 1); 
								position= p[0].pos;//float4(vertlist[triTableValuesCache[j]], 1); 
								//Fill gl_Position attribute for vertex raster space position 
								//gl_Position = gl_ModelViewProjectionMatrix* position; 
								
								pIn.pos = mul(vp,position);
								pIn.tex0 = p[0].tex0;
								pIn.norm = p[0].norm;

								pIn.pos = float4(0,0,0,0);
								triStream.Append(pIn);	
								triStream.Append(pIn);	
								triStream.Append(pIn);	
								triStream.RestartStrip();
								/*
								triStream.Append(pIn);
								//EmitVertex(); 
								
								 
								//Generate second vertex of triangle// 
								//Fill position varying attribute for fragment shader 
								position= float4(vertlist[triTableValue(cubeindex, i+1)], 1); 
								//Fill gl_Position attribute for vertex raster space position 
								//gl_Position = gl_ModelViewProjectionMatrix* position; 
								pIn.pos = mul(vp,position);
								pIn.tex0 = p[0].tex0;
								pIn.norm = p[0].norm;
								triStream.Append(pIn);
								//EmitVertex(); 
								 
								//Generate last vertex of triangle// 
								//Fill position varying attribute for fragment shader 
								position= float4(vertlist[triTableValue(cubeindex, i+2)], 1); 
								//Fill gl_Position attribute for vertex raster space position 
								//gl_Position = gl_ModelViewProjectionMatrix* position; 
								pIn.pos = mul(vp,position);
								pIn.tex0 = p[0].tex0;
								pIn.norm = p[0].norm;
								triStream.Append(pIn);
								//EmitVertex(); 
								 
								//End triangle strip at firts triangle 
								//EndPrimitive(); 
								triStream.RestartStrip();
								*/
							}
							
							else{ 
								pIn.pos = float4(0,0,0,0);
								pIn.tex0 = p[0].tex0;
								pIn.norm = p[0].norm;
								triStream.Append(pIn);	
								triStream.Append(pIn);	
								triStream.Append(pIn);	
								triStream.RestartStrip();
							} 
							
					 
							//i=i+3; //Comment it to test the strange bug 
						} 
						
					//}
				}



			ENDCG
		}
	} 
}
/*//Geometry Shader entry point
// Geometry Shader Marching Cubes 
// Copyright Cyril Crassin, Junuary 2007. 
// This code is partially based on the example of  
// Paul Bourke "Polygonising a scalar field" located at : 
// http://local.wasp.uwa.edu.au/~pbourke/geometry/polygonise/ 
 
 
//GLSL version 1.20 
#version 120 
//New G80 extensions 
#extension GL_EXT_geometry_shader4 : enable 
#extension GL_EXT_gpu_shader4 : enable 
 
vec4 sampleFunction( vec3 p )
{
    return vec4(
        16.0*p.y*p.z +
        4.0*2.0*p.x,
        16.0*p.x*p.z +
        4.0*2.0*p.y,
        16.0*p.x*p.y +
        4.0*2.0*p.z,
        16.0*p.x*p.y*p.z +
        4.0*p.x*p.x +
        4.0*p.y*p.y +
        4.0*p.z*p.z - 1.0
        );
} 

//Volume data field texture 
uniform sampler3D dataFieldTex; 
//Edge table texture 
uniform isampler2D edgeTableTex; 
//Triangles table texture 
uniform isampler2D triTableTex; 
 
//Global iso level 
uniform float isolevel; 
//Marching cubes vertices decal 
uniform vec3 vertDecals[8]; 
 
//Vertices position for fragment shader 
varying vec4 position; 
 
//Get vertex i position within current marching cube 
vec3 cubePos(int i){ 
	return gl_PositionIn[0].xyz + vertDecals[i]; 
} 
 
//Get vertex i value within current marching cube 
float cubeVal(int i){ 
	//return sampleFunction(cubePos(i)).a;
	return texture3D(dataFieldTex, (cubePos(i)+1.0f)/2.0f).a; 
} 
 
 
//Get triangle table value 
int triTableValue(int i, int j){ 
	return texelFetch2D(triTableTex, ivec2(j, i), 0).a; 
} 
 
//Compute interpolated vertex along an edge 
vec3 vertexInterp(float isolevel, vec3 v0, float l0, vec3 v1, float l1){ 
	return mix(v0, v1, (isolevel-l0)/(l1-l0)); 
} 
 
//Geometry Shader entry point 
void main(void) { 
	int cubeindex=0; 
	  
	float cubeVal0 = cubeVal(0); 
	float cubeVal1 = cubeVal(1); 
	float cubeVal2 = cubeVal(2); 
	float cubeVal3 = cubeVal(3); 
	float cubeVal4 = cubeVal(4); 
	float cubeVal5 = cubeVal(5); 
	float cubeVal6 = cubeVal(6); 
	float cubeVal7 = cubeVal(7); 
	 
	//Determine the index into the edge table which 
	//tells us which vertices are inside of the surface 
	cubeindex = int(cubeVal0 < isolevel); 
	cubeindex += int(cubeVal1 < isolevel)*2; 
	cubeindex += int(cubeVal2 < isolevel)*4; 
	cubeindex += int(cubeVal3 < isolevel)*8; 
	cubeindex += int(cubeVal4 < isolevel)*16; 
	cubeindex += int(cubeVal5 < isolevel)*32; 
	cubeindex += int(cubeVal6 < isolevel)*64; 
	cubeindex += int(cubeVal7 < isolevel)*128; 
	 
	 
	//Cube is entirely in/out of the surface 
	if (cubeindex ==0 || cubeindex == 255) 
		return; 
	 
	vec3 vertlist[12]; 
	 
	//Find the vertices where the surface intersects the cube 
	vertlist[0] = vertexInterp(isolevel, cubePos(0), cubeVal0, cubePos(1), cubeVal1); 
	vertlist[1] = vertexInterp(isolevel, cubePos(1), cubeVal1, cubePos(2), cubeVal2); 
	vertlist[2] = vertexInterp(isolevel, cubePos(2), cubeVal2, cubePos(3), cubeVal3); 
	vertlist[3] = vertexInterp(isolevel, cubePos(3), cubeVal3, cubePos(0), cubeVal0); 
	vertlist[4] = vertexInterp(isolevel, cubePos(4), cubeVal4, cubePos(5), cubeVal5); 
	vertlist[5] = vertexInterp(isolevel, cubePos(5), cubeVal5, cubePos(6), cubeVal6); 
	vertlist[6] = vertexInterp(isolevel, cubePos(6), cubeVal6, cubePos(7), cubeVal7); 
	vertlist[7] = vertexInterp(isolevel, cubePos(7), cubeVal7, cubePos(4), cubeVal4); 
	vertlist[8] = vertexInterp(isolevel, cubePos(0), cubeVal0, cubePos(4), cubeVal4); 
	vertlist[9] = vertexInterp(isolevel, cubePos(1), cubeVal1, cubePos(5), cubeVal5); 
	vertlist[10] = vertexInterp(isolevel, cubePos(2), cubeVal2, cubePos(6), cubeVal6); 
	vertlist[11] = vertexInterp(isolevel, cubePos(3), cubeVal3, cubePos(7), cubeVal7); 
	 
		 
	// Create the triangle 
	gl_FrontColor=vec4(cos(isolevel*10.0-0.5), sin(isolevel*10.0-0.5), cos(1.0-isolevel),1.0); 
	int i=0;  

	//for (i=0; triTableValue(cubeindex, i)!=-1; i+=3) { //Strange bug with this way, uncomment to test 
	while(true){ 
		if(triTableValue(cubeindex, i)!=-1){ 
			//Generate first vertex of triangle// 
			//Fill position varying attribute for fragment shader 
			position= vec4(vertlist[triTableValue(cubeindex, i)], 1); 
			//Fill gl_Position attribute for vertex raster space position 
			gl_Position = gl_ModelViewProjectionMatrix* position; 
			EmitVertex(); 
			 
			//Generate second vertex of triangle// 
			//Fill position varying attribute for fragment shader 
			position= vec4(vertlist[triTableValue(cubeindex, i+1)], 1); 
			//Fill gl_Position attribute for vertex raster space position 
			gl_Position = gl_ModelViewProjectionMatrix* position; 
			EmitVertex(); 
			 
			//Generate last vertex of triangle// 
			//Fill position varying attribute for fragment shader 
			position= vec4(vertlist[triTableValue(cubeindex, i+2)], 1); 
			//Fill gl_Position attribute for vertex raster space position 
			gl_Position = gl_ModelViewProjectionMatrix* position; 
			EmitVertex(); 
			 
			//End triangle strip at firts triangle 
			EndPrimitive(); 
		}else{ 
			break; 
		} 
 
		i=i+3; //Comment it to test the strange bug 
	} 
 
} */

/* FRAGMENT SHADER
#version 120

varying vec4 position;

uniform vec3 dataStep;
uniform sampler3D dataFieldTex;

const vec3 diffuseMaterial = vec3(0.7, 0.7, 0.7);
const vec3 specularMaterial = vec3(0.99, 0.99, 0.99);
const vec3 ambiantMaterial = vec3(0.1, 0.1, 0.1);


void main(void)
{

#if 1
    vec3 grad = vec3(
		texture3D(dataFieldTex, (position.xyz+vec3(dataStep.x, 0, 0)+1.0f)/2.0f).a - texture3D(dataFieldTex, (position.xyz+vec3(-dataStep.x, 0, 0)+1.0f)/2.0f).a, 
		texture3D(dataFieldTex, (position.xyz+vec3(0, dataStep.y, 0)+1.0f)/2.0f).a - texture3D(dataFieldTex, (position.xyz+vec3(0, -dataStep.y, 0)+1.0f)/2.0f).a, 
		texture3D(dataFieldTex, (position.xyz+vec3(0,0,dataStep.z)+1.0f)/2.0f).a - texture3D(dataFieldTex, (position.xyz+vec3(0,0,-dataStep.z)+1.0f)/2.0f).a);
    

    
    vec3 lightVec=normalize(gl_LightSource[0].position.xyz-position.xyz);
    
    vec3 normalVec = normalize(grad);

	vec3 color=gl_Color.rgb*0.5+abs(normalVec)*0.5;

    // calculate half angle vector
    vec3 eyeVec = vec3(0.0, 0.0, 1.0);
    vec3 halfVec = normalize(lightVec + eyeVec);
    
    // calculate diffuse component
    vec3 diffuse = vec3(abs(dot(normalVec, lightVec))) * color*diffuseMaterial;

    // calculate specular component
    vec3 specular = vec3(abs(dot(normalVec, halfVec)));
    specular = pow(specular.x, 32.0) * specularMaterial;
    
    // combine diffuse and specular contributions and output final vertex color
    gl_FragColor.rgb =gl_Color.rgb*ambiantMaterial + diffuse + specular;
    gl_FragColor.a = 1.0;
#else

	gl_FragColor=gl_Color;
#endif

    
}
*/
/*
#version 120

void main(void)
{
    gl_TexCoord[0]=gl_MultiTexCoord0;

	gl_Position=gl_Vertex;//ftransform();

	gl_FrontColor=gl_Color;

}
*/

/*

	cubeSize=Vector3f(32,32,32);
	cubeStep=Vector3f(2.0f, 2.0f, 2.0f)/cubeSize;

	dataSize=Vector3i(128, 128, 128);

	isolevel=0.5f;


//Step in data 3D texture for gradient computation (lighting)
glUniform3fARB(glGetUniformLocationARB(programObject, "dataStep"), 1.0f/dataSize.x, 1.0f/dataSize.y, 1.0f/dataSize.z); 


//Decal for each vertex in a marching cube
glUniform3fARB(glGetUniformLocationARB(programObjectGS, "vertDecals[0]"), 0.0f, 0.0f, 0.0f); 
glUniform3fARB(glGetUniformLocationARB(programObjectGS, "vertDecals[1]"), cubeStep.x, 0.0f, 0.0f); 
glUniform3fARB(glGetUniformLocationARB(programObjectGS, "vertDecals[2]"), cubeStep.x, cubeStep.y, 0.0f); 
glUniform3fARB(glGetUniformLocationARB(programObjectGS, "vertDecals[3]"), 0.0f, cubeStep.y, 0.0f); 
glUniform3fARB(glGetUniformLocationARB(programObjectGS, "vertDecals[4]"), 0.0f, 0.0f, cubeStep.z); 
glUniform3fARB(glGetUniformLocationARB(programObjectGS, "vertDecals[5]"), cubeStep.x, 0.0f, cubeStep.z); 
glUniform3fARB(glGetUniformLocationARB(programObjectGS, "vertDecals[6]"), cubeStep.x, cubeStep.y, cubeStep.z); 
glUniform3fARB(glGetUniformLocationARB(programObjectGS, "vertDecals[7]"), 0.0f, cubeStep.y, cubeStep.z); 

*/