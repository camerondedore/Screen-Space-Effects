using UnityEngine;
using System;
using UnityEngine.Rendering;

[ExecuteAlways]
public class DeferredFogEffect : MonoBehaviour
{
    
	public Shader deferredFog;
	public bool drawFogOnSkybox = false,
		useDistance = true;
	[NonSerialized]
	Material fogMaterial;
	[NonSerialized]
	Camera deferredCamera;
	[NonSerialized]
	Vector3[] frustumCorners;
	[NonSerialized]
	Vector4[] vectorArray;


	[ImageEffectOpaque]
	void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if(fogMaterial == null)
		{
			// create fog material using fog shader if a material doesn't exist
			fogMaterial = new Material(deferredFog);
			deferredCamera = GetComponent<Camera>();
			frustumCorners = new Vector3[4];
			vectorArray = new Vector4[4];
		}

		deferredCamera.CalculateFrustumCorners(new Rect(0, 0, 1, 1), deferredCamera.farClipPlane, deferredCamera.stereoActiveEye, frustumCorners);

		vectorArray[0] = frustumCorners[0];
		vectorArray[1] = frustumCorners[3];
		vectorArray[2] = frustumCorners[1];
		vectorArray[3] = frustumCorners[2];
		fogMaterial.SetVectorArray("_FrustumCorners", vectorArray);


		// set shader to draw on skybox or not
		if(drawFogOnSkybox && !Shader.IsKeywordEnabled("FOG_SKYBOX"))
		{
			Shader.EnableKeyword("FOG_SKYBOX"); // enable marco on shader; if it doesn't exist, create it
		}
		else if(!drawFogOnSkybox && Shader.IsKeywordEnabled("FOG_SKYBOX"))
		{
			Shader.DisableKeyword("FOG_SKYBOX");
		}


		// set shader to use distance or depth fog
		if(useDistance && !Shader.IsKeywordEnabled("FOG_DISTANCE"))
		{
			Shader.EnableKeyword("FOG_DISTANCE");
		}
		else if(!useDistance && Shader.IsKeywordEnabled("FOG_DISTANCE"))
		{
			Shader.DisableKeyword("FOG_DISTANCE");
		}

		
		Graphics.Blit(source, destination, fogMaterial);
	}
}
