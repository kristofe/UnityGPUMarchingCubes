Shader "Custom/RenderParticles" {
Properties {
        _Sprite ("", 2D) = "white" {}
}
       
SubShader {
Pass{
        //ZWrite Off ZTest Always Cull Off Fog { Mode Off }
        Cull Off Fog { Mode Off }
        Blend SrcAlpha One
 
        CGPROGRAM
        #pragma target 5.0
 
        #pragma vertex vert
        #pragma geometry geom
        #pragma fragment frag
 
        #include "UnityCG.cginc"
       
        StructuredBuffer<float3> particleBuffer;
        StructuredBuffer<float3> particleColor;
       
        struct vs_out {
                float4 pos : SV_POSITION;
                float4 col : COLOR;
        };
       
        vs_out vert (uint id : SV_VertexID)
        {
                // This runs through for each instance of the shader, id corrisponds to the particle in the list
                vs_out o;
                // Pull the location data and send it off to the geometry shader so it can be built into a particle
                o.pos = float4(particleBuffer[id], 1.0f);
                o.col = float4(particleColor[id], 1.0f);
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
                float Size = 0.1f;
               
                float dx = Size;
                float dy = Size * _ScreenParams.x / _ScreenParams.y;
                gs_out output;
               
                // Run the given position through the View Proj matrix
               
                float4 corLoc = mul(UNITY_MATRIX_MVP, input[0].pos);
                // Build the 4 points of the sprite and it's uv
                output.pos = corLoc + float4(-dx, dy,0,0); output.uv=float2(0,0); output.col = input[0].col; outStream.Append (output);
                output.pos = corLoc + float4( dx, dy,0,0); output.uv=float2(1,0); output.col = input[0].col; outStream.Append (output);
                output.pos = corLoc + float4(-dx,-dy,0,0); output.uv=float2(0,1); output.col = input[0].col; outStream.Append (output);
                output.pos = corLoc + float4( dx,-dy,0,0); output.uv=float2(1,1); output.col = input[0].col; outStream.Append (output);
                // Send it off as a particle to the pixel shader
                outStream.RestartStrip();
        }
       
        // Pixel shader, straight forward just sample the sprite
        sampler2D _Sprite;
       
        fixed4 frag (gs_out i ) : COLOR0
        {
                fixed4 col = tex2D(_Sprite, i.uv) * i.col;
                //col.w = 0.1f;
                //return i.col;
                return col;
        }
       
        ENDCG
       
        }
}
 
Fallback Off
}