import * as THREE from '../examples/libs/three.js/build/three.module.js'

export class ALLoader extends THREE.Loader
{
	constructor(manager)
	{
		super(manager);
	}

	// urls : string or Array<string>
	// Files have to be loaded in this order : materials, skeletons, meshs, animations
	load(urls, data, onLoad, onProgress, onError)
	{
		if (urls instanceof Array)
		{
			this.#loadMultiParts(urls, data, onLoad, onProgress, onError);
			return;
		}

		const url = urls;
		const { texturePath = this.extractUrlBase(url), materials = {}, skeletons = {}, meshes = {}, animations = {} } = data;

		const loader = new THREE.FileLoader(this.manager);
		loader.setPath(this.path );
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.setResponseType("json");

		loader.load(url, (text) =>
		{
			try
			{
				onLoad(this.parse(text, { texturePath, materials, skeletons, meshes, animations }));
			}
			catch(ex)
			{
				if (onError)
				{
					onError(ex);
				}
				else
				{
					console.error(ex);
				}

				scope.manager.itemError(url);
			}

		}, onProgress, onError);
	}

	#loadMultiParts(urls, data, onLoad, onProgress, onError)
	{
		this.load(urls.shift(), data, (urls.length ? (data) => this.#loadMultiParts(urls, data, onLoad, onProgress, onError) : onLoad), onProgress, onError);
	}

	parse(json, data)
	{
		console.debug("parse", json, data);

		const { texturePath, materials, skeletons, meshes, animations } = data;

		// MATERIALS
		if (json.materials)
		{
			for (const matName in json.materials)
			{
				const jsonMat = json.materials[matName];
				const material = this.parseMaterial(jsonMat, texturePath);
				material.name = matName;
				materials[matName] = material;
			}

			for (const matName in json.materials)
			{
				const jsonMat = json.materials[matName];
				if (jsonMat.ml && jsonMat.ml.length)
				{
					const materials2 = materials[matName];
					for (const matName2 of jsonMat.ml)
					{
						materials2.push(materials[matName2] ?? null);
					}
				}
			}
		}

		// SKELETONS
		if (json.skeletons)
		{
			for (const skeName in json.skeletons)
			{
				const jsonSkeleton = json.skeletons[skeName];
				const skeleton = this.parseSkeleton(jsonSkeleton);
				skeleton.name = skeName;
				skeletons[skeName] = skeleton;
			}
		}

		// MESHES
		if (json.meshes)
		{
			for (const meshName in json.meshes)
			{
				const jsonMesh = json.meshes[meshName];
				const mesh = this.parseMesh(jsonMesh, materials, skeletons);
				mesh.name = meshName;
				meshes[meshName] = mesh;
			}
		}
		
		// ANIMATIONS
		if (json.animations)
		{
			for (const animName in json.animations)
			{
				const jsonAnimation = json.animations[animName];
				const animation = this.parseAnimation(jsonAnimation, animName);
				const mesh = meshes[jsonAnimation.ms];
				mesh.animations.push(animation);
				animations[animName] = animation;
			}
		}

		return data;
	}

	parseMaterial(jsonMat, texturePath)
	{
		console.debug("parseMaterial", jsonMat, texturePath);

		let material;

		if (jsonMat.ml)
		{
			// MULTI-MATERIALS
			material = [];
		}
		else
		{
			material = new THREE.MeshPhongMaterial();

			// COLOR
			if (jsonMat.cl)
			{
				material.color.set(jsonMat.cl[0] / 255, jsonMat.cl[1] / 255, jsonMat.cl[2] / 255);
			}
			
			// SPECULAR
			if (jsonMat.sp)
			{
				material.specular.set(jsonMat.sp[0] / 255, jsonMat.sp[1] / 255, jsonMat.sp[2] / 255);
			}

			// OPACITY
			if (jsonMat.op)
			{
				material.opacity = jsonMat.op;
				if (material.opacity != 1)
				{
					material.transparent = true;
				}
			}
			
			// COLOR MAP (TEXTURE)
			if (jsonMat.cm)
			{
				const textureUrl = `${texturePath}/${jsonMat.cm}`;

				const onTextureLoaded = (texture) =>
				{
					console.debug(`Texture "${textureUrl}" loaded`);
				};

				const onTextureProgress = (xhr) => { console.debug(`${textureUrl} (${xhr.loaded / xhr.total * 100}%)`) };

				const onTextureError = (xhr) => { console.debug("Texture load failed", xhr) };

				material.map = (new THREE.TextureLoader()).load(textureUrl, onTextureLoaded, onTextureProgress, onTextureError);
			}
			
			if (jsonMat.sd)
			{
				if (jsonMat.sd == "double")
				{
					material.side = THREE.DoubleSide;
				}
				else if (jsonMat.sd == "back" || jsonMat.sd == "reverse")
				{
					material.side = THREE.BackSide;
				}
			}
		}

		return material;
	}

	parseSkeleton(jsonSkeleton)
	{
		console.debug("parseSkeleton", jsonSkeleton);

		// SKELETON / BONES
		const bones = [];

		for (const jsonBone of jsonSkeleton)
		{
			const bone = new THREE.Bone();
			bone.name = jsonBone.nm;
			bone.userData.parent = jsonBone.pr;
			bone.position.fromArray(jsonBone.ps);
			bone.quaternion.fromArray(jsonBone.rt);
			bone.scale.fromArray(jsonBone.sc);
			bones.push(bone);
		}

		for (const bone of bones)
		{
			if (bone.userData.parent != -1)
			{
				const parent = bones[bone.userData.parent];
				parent.add(bone);
			}
		}

		return new THREE.Skeleton(bones);
	}

	parseMesh(jsonMesh, materials, skeletons)
	{
		console.debug("parseMesh", jsonMesh, materials, skeletons);

		// MATERIAL
		const material = materials[jsonMesh.mt];
		if (material == null)
		{
			material = new THREE.MeshNormalMaterial();
		}
		
		// GEOMETRY
		const geometry = new THREE.BufferGeometry();

		// VERTICES (Vertex Positions and Vertex Indices)
		if (jsonMesh.vi && jsonMesh.vi.length)
		{
			// INDEXED (remove indices)
			const verticesSize = 3 * jsonMesh.vi.reduce((acc, value) => (acc + value.length), 0);
			const vertices = new Float32Array(verticesSize);
			let index = 0;
			let materialIndex = 0;
			for (const groupVertexIndices of jsonMesh.vi)
			{
				geometry.addGroup((index / 3), groupVertexIndices.length, materialIndex++);
				for (const vertexIndex of groupVertexIndices)
				{
					const vertexIndexPosition = vertexIndex * 3;
					vertices[index++] = jsonMesh.vp[vertexIndexPosition];
					vertices[index++] = jsonMesh.vp[vertexIndexPosition + 1];
					vertices[index++] = jsonMesh.vp[vertexIndexPosition + 2];
				}
			}
			geometry.setAttribute('position', new THREE.BufferAttribute(vertices, 3));
		}
		else
		{
			// NOT INDEXED
			geometry.setAttribute('position', new THREE.BufferAttribute(new Float32Array(jsonMesh.vp), 3));
		}

		// NORMALS (Face normals)
		if (jsonMesh.fn && jsonMesh.fn.length && jsonMesh.vi && jsonMesh.vi.length)
		{
			// INDEXED (remove indices)
			const normalsSize = 3 * jsonMesh.fn.reduce((acc, value) => (acc + value.length), 0);
			const normals = new Float32Array(normalsSize);
			let index = 0;
			for (const groupFaceNormals of jsonMesh.fn)
			{
				for (let i = 0; i < groupFaceNormals.length; i += 3)
				{
					normals[index++] = groupFaceNormals[i];
					normals[index++] = groupFaceNormals[i + 1];
					normals[index++] = groupFaceNormals[i + 2];
					normals[index++] = groupFaceNormals[i];
					normals[index++] = groupFaceNormals[i + 1];
					normals[index++] = groupFaceNormals[i + 2];
					normals[index++] = groupFaceNormals[i];
					normals[index++] = groupFaceNormals[i + 1];
					normals[index++] = groupFaceNormals[i + 2];
				}
			}
			geometry.setAttribute('normal', new THREE.BufferAttribute(normals, 3));
		}
		else if (jsonMesh.nm)
		{
			// NOT INDEXED
			geometry.setAttribute('normal', new THREE.BufferAttribute(new Float32Array(jsonMesh.nm), 3));
		}
		else
		{
			// NO NORMALS
			geometry.computeVertexNormals();
		}

		// UVS
		if (jsonMesh.ui && jsonMesh.ui.length)
		{
			// INDEXED (remove indices)
			const uvs = new Float32Array(jsonMesh.ui.length * 2);
			for (let i = 0, sz = jsonMesh.ui.length; i < sz; i++)
			{
				const index = jsonMesh.ui[i];
				uvs[2 * i] = jsonMesh.uv[2 * index];
				uvs[2 * i + 1] = jsonMesh.uv[2 * index + 1];
			}
			geometry.setAttribute('uv', new THREE.BufferAttribute(uvs, 2));
		}
		else if (jsonMesh.uv)
		{
			// NOT INDEXED
			geometry.setAttribute('uv', new THREE.BufferAttribute(new Float32Array(jsonMesh.uv), 2));
		}

		// MESH
		let mesh;
		if (jsonMesh.si && jsonMesh.sw)
		{
			const skinIndicesSize = 4 * jsonMesh.vi.reduce((acc, value) => (acc + value.length), 0);
			const skinIndices = new Uint16Array(skinIndicesSize);
			const skinWeights = new Float32Array(skinIndicesSize);
			let index = 0;
			for (const groupVertexIndices of jsonMesh.vi)
			{
				for (const vertexIndex of groupVertexIndices)
				{
					const skinIndexPosition = vertexIndex * 4;
					const i0 = jsonMesh.si[skinIndexPosition];
					const i1 = jsonMesh.si[skinIndexPosition+1];
					const i2 = jsonMesh.si[skinIndexPosition+2];
					const i3 = jsonMesh.si[skinIndexPosition+3];

					const w0 = jsonMesh.sw[skinIndexPosition];
					const w1 = jsonMesh.sw[skinIndexPosition+1];
					const w2 = jsonMesh.sw[skinIndexPosition+2];
					const w3 = jsonMesh.sw[skinIndexPosition+3];

					const total = w0 + w1 + w2 + w3;
					if (total < 0.1)
					{
						console.warn(skinIndexPosition, "=>", index);
						console.debug("total=", total);
						console.debug("IDX", i0, i1, i2, i3);
						console.debug("WGT", w0, w1, w2, w3);
					}

					skinIndices[index] = i0;
					skinWeights[index] = w0 / total;
					index++;

					skinIndices[index] = i1;
					skinWeights[index] = w1 / total;
					index++;

					skinIndices[index] = i2;
					skinWeights[index] = w2 / total;
					index++;

					skinIndices[index] = i3;
					skinWeights[index] = w3 / total;
					index++;
				}
			}
			geometry.setAttribute('skinIndex', new THREE.BufferAttribute(skinIndices, 4));
			geometry.setAttribute('skinWeight', new THREE.BufferAttribute(skinWeights, 4));
			
			// SKINNED_MATERIALS
			if (material instanceof Array)
			{
				for (const mat of material)
				{
					if (mat)
					{
						mat.skinning = true;
					}
				}
			}
			else
			{
				material.skinning = true;
			}

			// SKINNED_MESH
			mesh = new THREE.SkinnedMesh(geometry, material);
			mesh.userData.animated = true;
			
			// SKELETON
			if (jsonMesh.sk && skeletons)
			{
				const skeleton = skeletons[jsonMesh.sk];
				if (skeleton)
				{
					for (const bone of skeleton.bones)
					{
						if (bone.userData.parent == -1)
						{
							mesh.add(bone);
						}
					}

					mesh.bind(skeleton);
					mesh.userData.skeletonName = jsonMesh.sk;
				}
			}
		}
		else
		{
			mesh = new THREE.Mesh(geometry, material);
		}

		if (jsonMesh.ps)
		{
			mesh.position.fromArray(jsonMesh.ps);
		}

		if (jsonMesh.rt)
		{
			mesh.quaternion.fromArray(jsonMesh.rt);
		}

		if (jsonMesh.sc)
		{
			mesh.scale.fromArray(jsonMesh.sc);
		}

		return mesh;
	}

	parseAnimation(jsonAnim, animName)
	{
		console.debug("parseAnimation", jsonAnim, animName);

		const tracks = [];

		for (const jsonTrack of jsonAnim.hr)
		{
			const boneName = jsonTrack.bn;
			const times = [];
			const positions = [];
			const orientations = [];
			const scales = [];

			for (const jsonFrame of jsonTrack.ky)
			{
				times.push(jsonFrame.tm);
				positions.push(...jsonFrame.ps);
				orientations.push(...jsonFrame.rt);
				scales.push(...jsonFrame.sc);
			}
			tracks.push(new THREE.VectorKeyframeTrack(`${boneName}.position`, times, positions));
			tracks.push(new THREE.QuaternionKeyframeTrack(`${boneName}.quaternion`, times, orientations));
			tracks.push(new THREE.VectorKeyframeTrack(`${boneName}.scale`, times, scales));
		}

		return new THREE.AnimationClip(animName, jsonAnim.dr, tracks);
	}
	
	static cloneAnimationData(data, newName)
	{
		return {
			name: newName,
			JIT: data.JIT,
			fps: data.fps,
			hierarchy: data.hierarchy.slice(),
			initialized: false,
			length: data.length,
			loop: data.loop
		};
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
	
		let bl, GB = [];
	
		// enumerate bone names in geometry1
		bl = geometry1.bones.length;
		for (let i=0 ; i < bl ; i++)
		{
			GB.push(geometry1.bones[i].name);
		}
	
		// if bone doesn't exist in geometry1, we push it from geometry2
		bl = geometry2.bones.length;
		for (let i=0 ; i < bl ; i++)
		{
			if (GB.indexOf(geometry2.bones[i].name) == -1)
			{
				geometry1.bones.push(geometry2.bones[i]);
			}
		}
	
		function treatSkinIndex(skinIndex)
		{
			const name = geometry2.bones[skinIndex].name;
			return getBoneIdFromName(geometry1.bones, name);
		}
	
		for (let i=0 ; i < geometry2.skinIndices.length ; i++)
		{
			const v4 = geometry2.skinIndices[i].clone();
	
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
