Shader "Custom/Deferred Fog"
{

   Properties
   {
	   _MainTex ("Source", 2D) = "white" {}
   }



   Subshader
   {
	   Cull Off // ignore culling
	   ZTest Always // ignore depth buffer
	   ZWrite Off // don't write to depth buffer

	   Pass
	   {
			CGPROGRAM

			#pragma vertex VertexProgram 
			#pragma fragment FragmentProgram 

			#pragma multi_compile_fog

			// this enables a branch of the shader that has FOG_SKYBOX
			#pragma multi_compile __ FOG_SKYBOX
			#pragma multi_compile __ FOG_DISTANCE

			// the monobehavior DeferredFogEffect will enable these
			//#define FOG_DISTANCE // indicate we want to use distances for fog
			//#define FOG_SKYBOX // macro definition to see if we want fog drawn over the skybox

			#include "UnityCG.cginc"


			sampler2D _MainTex,
				_CameraDepthTexture; // unity had depth buffer available in _CameraDepthTexture

			float3 _FrustumCorners[4];



			struct VertexData
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};



			struct Interpolators
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;

				#if defined(FOG_DISTANCE)
					float3 ray : TEXCOORD1; // interpolate camera corner rays
				#endif
			};



			Interpolators VertexProgram(VertexData v)
			{
				Interpolators i;
				i.pos = UnityObjectToClipPos(v.vertex);
				i.uv = v.uv;

				#if defined(FOG_DISTANCE)
					// corner coordinates are (0, 0), (1, 0), (0, 1), and (1, 1). So the index is u + 2v
					i.ray = _FrustumCorners[v.uv.x + 2 * v.uv.y];
				#endif

				return i;
			}



			float4 FragmentProgram(Interpolators i) : SV_TARGET
			{
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv); // sample depth texture
				depth = Linear01Depth(depth); // convert depth to linear value in world space
				
				float viewDistance = depth * _ProjectionParams.z; // _ProjectionParams has clip space settings; z = far clipping value
				viewDistance -= _ProjectionParams.y; // y is the near clipping plane

				#if defined(FOG_DISTANCE)
					viewDistance = length(i.ray * depth);
				#endif

				UNITY_CALC_FOG_FACTOR_RAW(viewDistance);
				unityFogFactor = saturate(unityFogFactor);
				
				#if !defined(FOG_SKYBOX)
				if(depth > 0.9999)
				{
					unityFogFactor = 1;
				}
				#endif
				#if !defined(FOG_LINEAR) && !defined(FOG_EXP) && !defined(FOG_EXP2) // remove fog when fog is disabled
					unityFogFactor = 1;
				#endif

				float3 sourceColor = tex2D(_MainTex, i.uv).rgb;
				float3 foggedColor = lerp(unity_FogColor.rgb, sourceColor, unityFogFactor);
				return float4(foggedColor, 1);
			}

			ENDCG
	   }
   }
}
