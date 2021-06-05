// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Custom/PlanarShadow"
{
	Properties
	{
		// 阴影
		_ShadowColor ("Shadow Color", Color) = (0,0,0,1)
		_PlaneHeight ("planeHeight", Float) = 0
	}

	SubShader
	{
		Pass {   
			Tags {
				"Queue"="Transparent"
				"RenderType"="Transparent"
				"RenderPipeline" = "UniversalPipeline"
				"LightMode" = "PlanarShadow"
			}
			
			ZWrite on
			ZTest LEqual
			Blend SrcAlpha OneMinusSrcAlpha
			offset -1, 0
			
			Stencil {
				Ref 0
				Comp equal
				Pass incrWrap
				ZFail Keep
				Fail keep
			}
			
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// GPU Instancing
            #pragma multi_compile_instancing

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			struct Attributes
			{
				float4 positionOS: POSITION;
				float3 normalOS: NORMAL;
				half4 texcoord2: TEXCOORD2;//boneIndex
				float4 texcoord3: TEXCOORD3;//boneWeight
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float4 pos: SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _ShadowColor;
			float _PlaneHeight;
			CBUFFER_END


			Varyings vertPlanarShadow(Attributes v)
			{
				Varyings o = (Varyings)0;

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float3 positionWS = TransformObjectToWorld(v.positionOS);
				// 平行光的方向，由光源指向顶点
				half3 lightDirection = -(_MainLightPosition).xyz;
				// 已经归一化
				float3 lightDirectionOS = TransformWorldToObjectDir(lightDirection);

				// 顶点距离地板的高度
				float opposite = positionWS.y - _PlaneHeight;
				// cosTheta = dot(VectorA, VectorB) / |VectorA|*|VectorB|
				float cosTheta = -lightDirectionOS.y;	// = lightDirection dot (0,-1,0)
				// 得到顶点到顶点的影子的距离
				float hypotenuse = opposite / cosTheta;
				// 世界空间的顶点，向影子位置平移
				float3 vPos = positionWS.xyz + ( lightDirectionOS * hypotenuse );
				// vPos.y += _PlaneHeight;

				o.pos = mul (UNITY_MATRIX_VP, float4(vPos.x,_PlaneHeight,vPos.z,1));
				return o;
			}

			float4 fragPlanarShadow(Varyings i)
			{
				return _ShadowColor;
			}

			Varyings vert(Attributes v)
			{
				return vertPlanarShadow(v);
			}


			half4 frag(Varyings i) : SV_Target
			{
				return fragPlanarShadow(i);
			}

			ENDHLSL
		}
	}
	Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
