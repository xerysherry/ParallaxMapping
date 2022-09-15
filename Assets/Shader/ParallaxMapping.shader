Shader "Unlit/ParallaxMapping" 
{
	Properties {
		_Color("颜色",Color) = (1,1,1,1)
		_MainTex("深度图",2D) = "white"{}
		[NoScaleOffset]_BaseTex("颜色图",2D)="white"{}
		_Height("位移高度",range(0,1)) = 0.15
		_HeightAmount("基准高度",range(0,2)) = 1
		_MaxStep("最大迭代步长", Range(4, 64)) = 16
	}
	SubShader 
	{
        Tags 
		{
            "IgnoreProjector"="True"
            "Queue"="Opaque"
            "RenderType"="Opaque"
        }

		Pass
		{
		    Name "FORWARD"
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _MainTex_TexelSize;

			sampler2D _BaseTex;
			half _Height;
			half _HeightAmount;
			half4 _Color;
			int _MaxStep;

			struct v2f 
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 viewDir : TEXCOORD2;
			};

			v2f vert (appdata_full v) 
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
				TANGENT_SPACE_ROTATION;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				float3 viewRay=normalize(i.viewDir*-1);
				viewRay.z=abs(viewRay.z) + 0.2;
				viewRay.xy *= _Height;

				float3 shadeP = float3(i.uv,0);
				float h2 = _HeightAmount;
				
				float3 lioffset = viewRay / viewRay.z;
				float2 pixels = lioffset.xy * _MainTex_TexelSize.zw;
				float pixel = max(max(abs(pixels.x), abs(pixels.y)), 1);
				float linearStep = min(_MaxStep, floor(pixel));
				lioffset /= linearStep;

				float d = 1.0 - tex2Dlod(_MainTex, float4(shadeP.xy,0,0)).b * h2	;
				float3 prev_d = d;
				float3 prev_shadeP = shadeP;
				while(d > shadeP.z)
				{
					prev_shadeP = shadeP;
					shadeP += lioffset;
					prev_d = d;
					d = 1.0 - tex2Dlod(_MainTex, float4(shadeP.xy,0,0)).b * h2;
				}
				float d1 = d - shadeP.z;
				float d2 = prev_d - prev_shadeP.z;
				float w = d1 / (d1 - d2);
				shadeP = lerp(shadeP, prev_shadeP, w);

				half4 c = tex2D(_BaseTex, shadeP.xy) * _Color;
				return c;
			}
			ENDCG
		}
	}
}
