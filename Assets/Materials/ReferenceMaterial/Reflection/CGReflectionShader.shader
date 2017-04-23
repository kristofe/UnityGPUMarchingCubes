// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/CG Reflection Map" {
   Properties {
      _Cube("Reflection Map", Cube) = "" {}
      _CubeAdd("Additive Reflection Map", Cube) = "" {}
	  _MainColor ("Main Material Color", Color) = (1,1,1,1) 
      _SpecularColor ("Specular Material Color", Color) = (1,1,1,1) 
	  _ReflectionColor("Reflection Color", Color) = (1.0,1.0,1.0,1.0)
	  _ReflectionAddColor("Reflection Add Color", Color) = (1.0,1.0,1.0,1.0)
      _Shininess ("Shininess", Float) = 10
   }
   SubShader {
      Pass {   
         CGPROGRAM
		 #pragma target 3.0
         #pragma vertex vert  
         #pragma fragment frag 
 
         // User-specified uniforms
         uniform samplerCUBE _Cube;   
         uniform samplerCUBE _CubeAdd;   
		 uniform float4 _MainColor;
		 uniform float4 _SpecularColor;
		 uniform float4 _ReflectionColor;
		 uniform float4 _ReflectionAddColor;
		 uniform float _Shininess;
 
         // The following built-in uniforms are also
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		  
         struct vertexInput {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
         };
         struct vertexOutput {
            float4 pos : SV_POSITION;
            float4 posWorld : TEXCOORD0;
            float3 normalDir : TEXCOORD1;
         };
 
         vertexOutput vert(vertexInput input) 
         {
            vertexOutput output;
 
            float4x4 modelMatrix = unity_ObjectToWorld;
            float4x4 modelMatrixInverse = unity_WorldToObject; 
               // multiplication with unity_Scale.w is unnecessary 
               // because we normalize transformed vectors
 
            output.posWorld = mul(modelMatrix, input.vertex);
            output.normalDir = normalize( mul(float4(input.normal, 0.0), modelMatrixInverse).xyz);
            output.pos = mul(UNITY_MATRIX_MVP, input.vertex);
            return output;
         }
 
         float4 frag(vertexOutput input) : COLOR
         {
            float3 normalDirection = normalize(input.normalDir);
 
            float3 viewDirection = normalize(
                input.posWorld.xyz - _WorldSpaceCameraPos);
            float3 lightDirection;
            float attenuation;
 
            if (0.0 == _WorldSpaceLightPos0.w) // directional light?
            {
               attenuation = 1.0; // no attenuation
               lightDirection = 
                  normalize(_WorldSpaceLightPos0.xyz);
            } 
            else // point or spot light
            {
               float3 vertexToLightSource = 
                  (_WorldSpaceLightPos0 - input.posWorld).xyz;
               float distance = length(vertexToLightSource);
               attenuation = 1.0 / distance; // linear attenuation 
               lightDirection = normalize(vertexToLightSource);
            }
 
            float3 ambientLighting = 
               UNITY_LIGHTMODEL_AMBIENT.xyz * _MainColor.xyz;
 
            float3 diffuseReflection = 
               attenuation * _LightColor0.xyz * _MainColor.xyz
               * max(0.0, dot(normalDirection, lightDirection));
 
            float3 specularReflection;
            if (dot(normalDirection, lightDirection) < 0.0) 
               // light source on the wrong side?
            {
               specularReflection = float3(0.0, 0.0, 0.0); 
                  // no specular reflection
            }
            else // light source on the right side
            {
               specularReflection = attenuation * _LightColor0.xyz 
                  * _SpecColor.xyz * pow(max(0.0, dot(
                  reflect(-lightDirection, normalDirection), 
                  viewDirection)), _Shininess);
            }
 
			float3 reflectedDir = 
               reflect(viewDirection, normalDirection);
			float4 reflection = texCUBE(_Cube, reflectedDir) * _ReflectionColor;
			float4 reflection2 = texCUBE(_CubeAdd, reflectedDir) * _ReflectionAddColor;

            return float4(ambientLighting + diffuseReflection 
               + specularReflection + reflection + reflection2, 1.0);
         }
 
         ENDCG
      }

	  Pass {    
         Tags { "LightMode" = "ForwardAdd" } 
            // pass for additional light sources
         Blend One One // additive blending 
 
         CGPROGRAM
 
         #pragma vertex vert  
         #pragma fragment frag 
 
         // User-specified uniforms
         uniform samplerCUBE _Cube;   
		 uniform float4 _MainColor;
		 uniform float4 _SpecularColor;
		 uniform float4 _ReflectionColor;
		 uniform float _Shininess;
 
         // The following built-in uniforms are also
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
 
         struct vertexInput {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
         };
         struct vertexOutput {
            float4 pos : SV_POSITION;
            float4 col : COLOR;
         };
 
         vertexOutput vert(vertexInput input) 
         {
            vertexOutput output;

            float4x4 modelMatrix = unity_ObjectToWorld;
            float4x4 modelMatrixInverse = unity_WorldToObject; 
               // multiplication with unity_Scale.w is unnecessary 
               // because we normalize transformed vectors
 
            float3 normalDirection = normalize(
				mul(float4(input.normal, 0.0), modelMatrixInverse).xyz
				);
            float3 viewDirection = normalize( mul(modelMatrix, input.vertex).xyz 
				- float4(_WorldSpaceCameraPos, 1.0) );
            float3 lightDirection;
            float attenuation;
			
            if (0.0 == _WorldSpaceLightPos0.w) // directional light?
            {
               attenuation = 1.0; // no attenuation
               lightDirection = 
                  normalize(_WorldSpaceLightPos0.xyz);
            } 
            else // point or spot light
            {
               float3 vertexToLightSource = (_WorldSpaceLightPos0
                  - mul(modelMatrix, input.vertex)).xyz;
               float distance = length(vertexToLightSource);
               attenuation = 1.0 / distance; // linear attenuation 
               lightDirection = normalize(vertexToLightSource);
            }
 
            float3 diffuseReflection = 
               attenuation * _LightColor0.xyz * _MainColor.xyz
               * max(0.0, dot(normalDirection, lightDirection));

            float3 specularReflection;
            if (dot(normalDirection, lightDirection) < 0.0) 
               // light source on the wrong side?
            {
               specularReflection = float3(0.0, 0.0, 0.0); 
                  // no specular reflection
            }
            else // light source on the right side
            {
               specularReflection = attenuation * _LightColor0.xyz 
                  * _SpecularColor.xyz * pow(max(0.0, dot(
                  reflect(-lightDirection, normalDirection), 
                  viewDirection)), _Shininess);
            }
 
            output.col = float4(diffuseReflection 
               + specularReflection, 1.0);
               // no ambient contribution in this pass
            output.pos = mul(UNITY_MATRIX_MVP, input.vertex);
            return output;
         }
 
         float4 frag(vertexOutput input) : COLOR
         {
            return input.col;
         }
 
         ENDCG
      }
   }
}