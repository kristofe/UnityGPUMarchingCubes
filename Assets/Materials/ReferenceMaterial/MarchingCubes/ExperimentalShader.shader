// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/Experimental" {
	Properties {
		_Color("Color", Color) = (1,1,1,1)
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		Pass {
			CGPROGRAM
		    #pragma target 5.0
			#pragma only_renderers d3d11
			#pragma vertex vert  
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			 float4 _Color;

			 struct VS_INPUT { 
				 float4 pos : POSITION;
				 float3 norm : NORMAL;
			 };

			 struct VS_OUTPUT {
				 float4 pos : POSITION;
				 float4 posWorld : TEXCOORD0;
				 float3 norm : TEXCOORD1;
			 };

			 VS_OUTPUT vert(VS_INPUT v) {
				VS_OUTPUT o;

				float4x4 modelMatrix = unity_ObjectToWorld;
				float4x4 modelMatrixInverse = unity_WorldToObject;

				o.norm = normalize( mul( float4(v.norm,1.0), modelMatrixInverse).xyz);
				o.posWorld = mul(modelMatrix,v.pos);
				o.pos = mul(UNITY_MATRIX_MVP,v.pos);

				return o;
			 }

			 float4 frag(VS_OUTPUT i) : COLOR {
				 //assuming directional light for now
				 float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				 float d = saturate(dot(lightDirection, i.norm));
				 return float4(abs(i.norm),1);//_Color * d;
			 }

			ENDCG
		}
	} 
	FallBack "Diffuse"
}
