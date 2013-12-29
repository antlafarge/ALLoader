/**
 * @author ant-lafarge / http://ant.lafarge.free.fr/
 */

THREE.ALMLoader = function (showStatus) {

	THREE.Loader.call(this, showStatus);

};

THREE.ALMLoader.prototype = Object.create(THREE.Loader.prototype);

THREE.ALMLoader.prototype.load = function (url, callback, texturePath) {

	var scope = this;

	texturePath = texturePath ? texturePath : this.extractUrlBase(url);

	this.onLoadStart();
	this.loadAjaxJSON(this, url, callback, texturePath);

};

THREE.ALMLoader.prototype.loadAjaxJSON = function (context, url, callback, texturePath, callbackProgress) {

	var xhr = new XMLHttpRequest();

	var length = 0;

	xhr.onreadystatechange = function () {

		if (xhr.readyState === xhr.DONE) {

			if (xhr.status === 200 || xhr.status === 0) {

				if (xhr.responseText) {
				
					var json = JSON.parse(xhr.responseText);
					context.parse(json, callback, texturePath);

				} else {

					console.warn("THREE.ALMLoader: [" + url + "] seems to be unreachable or file there is empty");

				}

				// in context of more complex asset initialization
				// do not block on single failed file
				// maybe should go even one more level up

				context.onLoadComplete();

			} else {

				console.error("THREE.ALMLoader: Couldn't load [" + url + "] [" + xhr.status + "]");

			}

		} else if (xhr.readyState === xhr.LOADING) {

			if (callbackProgress) {

				if (length === 0) {

					length = xhr.getResponseHeader("Content-Length");

				}

				callbackProgress({ total: length, loaded: xhr.responseText.length });

			}

		} else if (xhr.readyState === xhr.HEADERS_RECEIVED) {

			length = xhr.getResponseHeader("Content-Length");

		}

	};

	xhr.open("GET", url, true);
	xhr.send(null);

};

THREE.ALMLoader.prototype.parse = function (json, callback, texturePath) {

	var materials = [];
	for (var i=0; i < json.materials.length; i++)
	{
		materials.push(parseMaterial(json.materials[i]));
	}

	// for multi-materials
	for (var i in materials)
	{
		var material = materials[i];
		if (material instanceof THREE.MeshFaceMaterial)
		{
			for (var j in material.multi)
			{
				var matName = material.multi[j];
				material.materials.push(getMaterialFromName(matName));
			}
		}
	}

	var meshes = [];
	for (var i=0; i < json.meshes.length; i++)
	{
		meshes.push(parseMesh(json.meshes[i]));
	}

	function getMaterialFromName(name)
	{
		for (var i=0; i < materials.length; i++)
		{
			if (materials[i].name == name)
			{
				return materials[i];
			}
		}
		return null;
	}

	function parseMaterial(jsonMat)
	{
		// MATERIAL
		var material = null;
		if (jsonMat.multi)
		{
			material = new THREE.MeshFaceMaterial();
			material.multi = jsonMat.multi;
		}
		else
		{
			material = new THREE.MeshPhongMaterial();

			if (jsonMat.ambient)
			{
				material.ambient.r = jsonMat.ambient[0] / 255;
				material.ambient.g = jsonMat.ambient[1] / 255;
				material.ambient.b = jsonMat.ambient[2] / 255;
			}
			
			if (jsonMat.diffuse)
			{
				material.color.r = jsonMat.diffuse[0] / 255;
				material.color.g = jsonMat.diffuse[1] / 255;
				material.color.b = jsonMat.diffuse[2] / 255;
			}
			
			if (jsonMat.specular)
			{
				material.specular.r = jsonMat.specular[0] / 255;
				material.specular.g = jsonMat.specular[1] / 255;
				material.specular.b = jsonMat.specular[2] / 255;
			}

			if (jsonMat.opacity)
			{
				material.opacity = jsonMat.opacity;
				if (jsonMat.opacity != 1)
				{
					material.transparent = true;
				}
			}
			
			if (jsonMat.texture)
			{
				material.map = THREE.ImageUtils.loadTexture(texturePath + '/' + jsonMat.texture);
			}
			
			if (jsonMat.side === "double")
			{
				material.side = THREE.DoubleSide;
			}
			else if (jsonMat.side === "reverse" || jsonMat.side === "back")
			{
				material.side = THREE.BackSide;
			}
		}

		if (jsonMat.name)
		{
			material.name = jsonMat.name;
		}

		return material;
	}

	function parseMesh(jsonMesh)
	{
		var geometry = new THREE.Geometry();
		//var material = null;
		
		// MESH NAME
		geometry.name = jsonMesh.name;
		
		// SKINNING TEST
		var skinning = (jsonMesh.skinIndices && jsonMesh.skinWeights && jsonMesh.skinIndices.length && jsonMesh.skinWeights.length);

		// VERTICES
		for (var i=0; i<jsonMesh.vertices.length; i+=3)
		{
			geometry.vertices.push(new THREE.Vector3(jsonMesh.vertices[i], jsonMesh.vertices[i+1], jsonMesh.vertices[i+2]));
		}
		
		// VERTEX INDICES (FACES)
		var n = 0;
		var materialIndex = 0;
		for (var i=0; i<jsonMesh.vertex_indices.length; i++)
		{
			var indices = jsonMesh.vertex_indices[i];
			for (var j=0; j<indices.length; j+=3)
			{
				geometry.faces.push(new THREE.Face3(indices[j], indices[j+1], indices[j+2], /*normals[n]*/null, null, materialIndex));
				n++;
			}
			materialIndex++;
		}
		
		// UVS
		var uvs = [];
		for (var i=0; i<jsonMesh.uvs.length; i+=2)
		{
			uvs.push(new THREE.Vector2(jsonMesh.uvs[i], jsonMesh.uvs[i+1]));
		}
		
		// UV INDICES
		for (var i=0; i<jsonMesh.uv_indices.length; i+=3)
		{
			geometry.faceVertexUvs[0].push([uvs[jsonMesh.uv_indices[i]], uvs[jsonMesh.uv_indices[i+1]], uvs[jsonMesh.uv_indices[i+2]]]);
		}
		
		// NORMALS
		var normals = [];
		if (jsonMesh.normals)
		{
			for (var i=0; i<jsonMesh.normals.length; i+=3)
			{
				normals.push(new THREE.Vector3(jsonMesh.normals[i], jsonMesh.normals[i+1], jsonMesh.normals[i+2]));
			}
		}
		
		if (skinning)
		{
			// BONES
			geometry.bones = jsonMesh.bones;
			
			// SKININDEX && SKINWEIGHT
			for (var i=0; i<jsonMesh.skinIndices.length; i+=4)
			{
				var bi0 = jsonMesh.skinIndices[i+0];
				var bi1 = jsonMesh.skinIndices[i+1];
				var bi2 = jsonMesh.skinIndices[i+2];
				var bi3 = jsonMesh.skinIndices[i+3];
				geometry.skinIndices.push(new THREE.Vector4(bi0, bi1, 0, 0));
				
				var bw0 = jsonMesh.skinWeights[i+0];
				var bw1 = jsonMesh.skinWeights[i+1];
				var bw2 = jsonMesh.skinWeights[i+2];
				var bw3 = jsonMesh.skinWeights[i+3];
				geometry.skinWeights.push(new THREE.Vector4(bw0, bw1, 0, 0));
			}
		}

		// Post-processing
		if (jsonMesh.normals == null || jsonMesh.normals.length === 0)
		{
			geometry.computeFaceNormals();
		}
		geometry.computeCentroids();
		geometry.computeBoundingBox();
		
		// MATERIAL
		var material = getMaterialFromName(jsonMesh.material);
		if (material == null)
		{
			material = new THREE.MeshNormalMaterial();
		}
		
		// MESH
		var mesh;
		if (skinning)
		{
			if (material instanceof THREE.MeshFaceMaterial)
			{
				material.materials.map(function(mat){mat.skinning = true;})
			}
			else
			{
				material.skinning = true;
			}
			mesh = new THREE.SkinnedMesh(geometry, material);
		}
		else
		{
			mesh = new THREE.Mesh(geometry, material);
		}
		mesh.name = jsonMesh.name;

		return mesh;
	}
	
	var object3d = new THREE.Object3D();
	for (var i=0; i<meshes.length; i++)
	{
		object3d.add(meshes[i]);
	}

	callback(object3d);
};
