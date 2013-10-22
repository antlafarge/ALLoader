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

	var meshes = [];
	for (var i=0; i < json.meshes.length; i++)
	{
		meshes.push(parseMesh(json.meshes[i]));
	}

	function getMatIdFromName(name)
	{
		for (var i=0; i < materials.length; i++)
		{
			if (materials[i].name == name)
			{
				return i;
			}
		}
		return -1;
	}

	function parseMaterial(jsonMat)
	{
		// MATERIAL
		var material = new THREE.MeshPhongMaterial();

		if (jsonMat.name)
		{
			material.name = jsonMat.name;
		}

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
		
		return material;
	}

	function parseMesh(jsonMesh)
	{
		var geometry = new THREE.Geometry();
		//var material = null;
		
		geometry.name = jsonMesh.name;
		
		var skinning = (jsonMesh.skinIndices && jsonMesh.skinWeights && jsonMesh.skinIndices.length && jsonMesh.skinWeights.length);
		// There is only 1 material per mesh
		var materialId = getMatIdFromName(jsonMesh.material);
		if (materialId === -1)
		{
			material = new THREE.MeshNormalMaterial();
		}
		else
		{
			material = materials[materialId];
			//geometry.materials.push(material);
			//materialId = 0;
			if (skinning)
			{
				material.skinning = true;
			}
		}
		
		// VERTICES
		for (var i=0; i < jsonMesh.vertices.length; i+=3)
		{
			geometry.vertices.push(new THREE.Vector3(jsonMesh.vertices[i], jsonMesh.vertices[i+1], jsonMesh.vertices[i+2]));
		}
		
		// NORMALS
		geometry.normals = [];
		for (var i=0; i < jsonMesh.normals.length; i+=3)
		{
			geometry.normals.push(new THREE.Vector3(jsonMesh.normals[i], jsonMesh.normals[i+1], jsonMesh.normals[i+2]));
		}
		
		// UVS
		geometry.uvs = [];
		for (var i=0; i < jsonMesh.texcoord.length; i+=2)
		{
			geometry.uvs.push(new THREE.Vector2(jsonMesh.texcoord[i], jsonMesh.texcoord[i+1]));
		}
		
		// INDICES / FACES
		var n = 0;
		for (var i=0; i < jsonMesh.indices.length; i+=3)
		{
			geometry.faces.push(new THREE.Face3(jsonMesh.indices[i], jsonMesh.indices[i+1], jsonMesh.indices[i+2], geometry.normals[n], null, 0));
			if (geometry.uvs.length)
			{
				geometry.faceVertexUvs[0].push([geometry.uvs[jsonMesh.indices[i]], geometry.uvs[jsonMesh.indices[i+1]], geometry.uvs[jsonMesh.indices[i+2]]]);
			}
			n++;
		}
		
		if (skinning)
		{
			// BONES
			geometry.bones = jsonMesh.bones;
			
			// SKININDEX && SKINWEIGHT
			for (var i=0; i < jsonMesh.skinIndices.length; i+=4)
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
		if (jsonMesh.normals.length === 0)
		{
			geometry.computeFaceNormals();
		}
		geometry.computeCentroids();
		geometry.computeBoundingBox();
		
		var mesh;
		if (skinning)
		{
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
