/**
 * @author antlafarge / http://ant.lafarge.free.fr/
 */

export class AnimationUtils
{
	static cloneAnimationData(data, newName)
	{
		var data2 = {};
		data2.name = newName;
		data2.JIT = data.JIT;
		data2.fps = data.fps;
		data2.hierarchy = data.hierarchy.slice();
		data2.initialized = false;
		data2.length = data.length;
		data2.loop = data.loop;
		return data2;
	}

	static merge(geometry1, geometry2, materialIndexOffset)
	{
		if (materialIndexOffset === undefined)
		{
			materialIndexOffset = 0;
		}
		geometry1.merge(geometry2, null, materialIndexOffset);
		AnimationUtils.mergeBones(geometry1, geometry2);
		if (geometry2.name.length)
		{
			if (geometry1.name.length)
			{
				geometry1.name += "_";
			}
			geometry1.name += geometry2.name;
		}
		return geometry1;
	}

	static mergeBones(geometry1, geometry2)
	{
		if (typeof(geometry1.bones) == "undefined")
		{
			geometry1.bones = [];
			geometry1.skinIndices = [];
			geometry1.skinWeights = [];
		}
	
		var bl, GB = [];
	
		// enumerate bone names in geometry1
		bl = geometry1.bones.length;
		for (var i=0 ; i < bl ; i++)
		{
			GB.push(geometry1.bones[i].name);
		}
	
		// if bone doesn't exist in geometry1, we push it from geometry2
		bl = geometry2.bones.length;
		for (var i=0 ; i < bl ; i++)
		{
			if (GB.indexOf(geometry2.bones[i].name) == -1)
				geometry1.bones.push(geometry2.bones[i]);
		}
	
		function treatSkinIndex(skinIndex)
		{
			var name = geometry2.bones[skinIndex].name;
			return getBoneIdFromName(geometry1.bones, name);
		}
	
		for (var i=0 ; i < geometry2.skinIndices.length ; i++)
		{
			var v4 = geometry2.skinIndices[i].clone();
	
			// skinIndices
			v4.x = (v4.x != -1 ? treatSkinIndex(v4.x) : 0);
			v4.y = (v4.y != -1 ? treatSkinIndex(v4.y) : 0);
			v4.z = (v4.z != -1 ? treatSkinIndex(v4.z) : 0);
			v4.w = (v4.w != -1 ? treatSkinIndex(v4.w) : 0);
			geometry1.skinIndices.push(v4);
		}
	
		geometry1.skinWeights = geometry1.skinWeights.concat(geometry2.skinWeights);
	}
}
