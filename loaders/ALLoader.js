/**
 * @author antlafarge / http://ant.lafarge.free.fr/
 */

THREE.ALLoader = function (showStatus)
{
	THREE.Loader.call(this, showStatus);
};

THREE.ALLoader.prototype = Object.create(THREE.Loader.prototype);

THREE.ALLoader.prototype.load = function (url, callback, texturePath)
{
	var scope = this;

	texturePath = texturePath ? texturePath : this.extractUrlBase(url);

	this.onLoadStart();
	this.loadAjaxJSON(this, url, callback, texturePath);
};

THREE.ALLoader.prototype.loadAjaxJSON = function (context, url, callback, texturePath, callbackProgress)
{
	var xhr = new XMLHttpRequest();
	var length = 0;

	xhr.onreadystatechange = function ()
	{
		if (xhr.readyState === xhr.DONE)
		{
			if (xhr.status === 200 || xhr.status === 0)
			{
				if (xhr.responseText)
				{
					var json = JSON.parse(xhr.responseText);
					context.parse(json, callback, texturePath);
				}
				else
				{
					console.warn("THREE.ALLoader: [" + url + "] seems to be unreachable or file there is empty");
				}

				// in context of more complex asset initialization
				// do not block on single failed file
				// maybe should go even one more level up

				context.onLoadComplete();
			}
			else
			{
				console.error("THREE.ALLoader: Couldn't load [" + url + "] [" + xhr.status + "]");
			}
		}
		else if (xhr.readyState === xhr.LOADING)
		{
			if (callbackProgress)
			{
				if (length === 0)
				{
					length = xhr.getResponseHeader("Content-Length");
				}
				callbackProgress({ total: length, loaded: xhr.responseText.length });
			}

		}
		else if (xhr.readyState === xhr.HEADERS_RECEIVED)
		{
			length = xhr.getResponseHeader("Content-Length");
		}
	};

	xhr.open("GET", url, true);
	xhr.send(null);
};

THREE.ALLoader.prototype.parse = function (json, callback, texturePath)
{
	var myObject = {};

	// Parse materials
	var materials = [];
	for (var i in json.materials)
	{
		var jsonMat = json.materials[i];
		var threeMat = parseMaterial(jsonMat);
		materials.push(threeMat);
		materials[jsonMat.name] = threeMat;
	}

	// Process multi-materials
	for (var i in json.materials)
	{
		var jsonMat = json.materials[i];
		if (jsonMat.multi)
		{
			var material = materials[jsonMat.name];
			for (var j in jsonMat.multi)
			{
				var matName = jsonMat.multi[j];
				material.materials.push(materials[matName]);
			}
		}
	}

	var meshes = [];
	for (var i in json.meshes)
	{
		var jsonMesh = json.meshes[i];
		var threeMesh = parseMesh(jsonMesh);
		meshes.push(threeMesh);
		meshes[jsonMesh.name] = threeMesh;
	}

	function parseMaterial(jsonMat)
	{
		// MATERIAL
		var material = null;
		if (jsonMat.multi)
		{
			material = new THREE.MeshFaceMaterial();
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
				material.map = THREE.ImageUtils.loadTexture(texturePath+'/'+jsonMat.texture);
			}
			
			if (jsonMat.side)
			{
				if (jsonMat.side === "double")
				{
					material.side = THREE.DoubleSide;
				}
				else if (jsonMat.side === "back" || jsonMat.side === "reverse")
				{
					material.side = THREE.BackSide;
				}
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
		
		// MESH NAME
		geometry.name = jsonMesh.name;
		
		// SKINNING TEST
		var skinning = (jsonMesh.skin && jsonMesh.skin_indices && jsonMesh.skin_weights);

		// VERTEX POSITIONS
		for (var i=0; i<jsonMesh.vertex_positions.length; i+=3)
		{
			geometry.vertices.push(new THREE.Vector3(jsonMesh.vertex_positions[i], jsonMesh.vertex_positions[i+1], jsonMesh.vertex_positions[i+2]));
		}
		
		// VERTEX INDICES (FACES)
		for (var i=0; i<jsonMesh.vertex_indices.length; i++)
		{
			var materialIndex = i;
			for (var j=0; j<jsonMesh.vertex_indices[i].length; j+=3)
			{
				var face_normal = null;
				if (jsonMesh.face_normals && jsonMesh.face_normals.length)
				{
					face_normal = new THREE.Vector3(jsonMesh.face_normals[i][j], jsonMesh.face_normals[i][j+1], jsonMesh.face_normals[i][j+2])
				}
				geometry.faces.push(new THREE.Face3(jsonMesh.vertex_indices[i][j], jsonMesh.vertex_indices[i][j+1], jsonMesh.vertex_indices[i][j+2], face_normal, null, materialIndex));
			}
		}
		
		// TEXTURE COORDINATES
		if (jsonMesh.uv && jsonMesh.uv_indices)
		{
			// UVS
			var uvs = [];
			for (var i=0; i<jsonMesh.uv.length; i+=2)
			{
				uvs.push(new THREE.Vector2(jsonMesh.uv[i], jsonMesh.uv[i+1]));
			}
		
			// UV INDICES
			for (var i=0; i<jsonMesh.uv_indices.length; i+=3)
			{
				geometry.faceVertexUvs[0].push([uvs[jsonMesh.uv_indices[i]], uvs[jsonMesh.uv_indices[i+1]], uvs[jsonMesh.uv_indices[i+2]]]);
			}
		}
		
		if (skinning)
		{
			// BONES
			geometry.bones = jsonMesh.skin;
			
			// SKIN INDICES && SKIN WEIGHTS
			for (var i=0; i<jsonMesh.skin_indices.length; i+=4)
			{
				var bi0 = jsonMesh.skin_indices[i+0];
				var bi1 = jsonMesh.skin_indices[i+1];
				var bi2 = jsonMesh.skin_indices[i+2];
				var bi3 = jsonMesh.skin_indices[i+3];
				geometry.skinIndices.push(new THREE.Vector4(bi0, bi1, bi2, bi3));
				
				var bw0 = jsonMesh.skin_weights[i+0];
				var bw1 = jsonMesh.skin_weights[i+1];
				var bw2 = jsonMesh.skin_weights[i+2];
				var bw3 = jsonMesh.skin_weights[i+3];
				geometry.skinWeights.push(new THREE.Vector4(bw0, bw1, bw2, bw3));
			}
		}

		// Post-processing
		if (jsonMesh.face_normals == null)
		{
			geometry.computeFaceNormals();
		}
		geometry.computeVertexNormals();
		geometry.computeBoundingBox();
		
		// MATERIAL
		var material = materials[jsonMesh.material];
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
		if (jsonMesh.position != null)
		{
			mesh.position.set(jsonMesh.position[0], jsonMesh.position[1], jsonMesh.position[2]);
		}
		if (jsonMesh.rotation != null)
		{
			mesh.quaternion.set(jsonMesh.rotation[0], jsonMesh.rotation[1], jsonMesh.rotation[2], jsonMesh.rotation[3]);
		}
		if (jsonMesh.scale != null)
		{
			mesh.scale.set(jsonMesh.scale[0], jsonMesh.scale[1], jsonMesh.scale[2]);
		}

		return mesh;
	}
	
	var object3d = new THREE.Object3D();
	for (var i=0; i<meshes.length; i++)
	{
		object3d.add(meshes[i]);
	}

	var animations = (json.animations ? json.animations.concat() : []);
	for (var i in json.animations)
	{
		animations[json.animations[i].name] = json.animations[i];
	}

	myObject.materials = materials;
	myObject.meshes = meshes;
	myObject.animations = animations;

	myObject.root = object3d;

	callback(myObject);
};
