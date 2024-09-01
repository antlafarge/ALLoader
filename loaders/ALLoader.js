import * as THREE from '../examples/libs/three.js/build/three.module.js'

export class ALLoader extends THREE.Loader
{
	constructor(manager)
	{
		super(manager);
	}

	load(url, data, onLoad, onProgress, onError)
	{
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
				if (jsonMat.multi && jsonMat.multi.length)
				{
					const materials2 = materials[matName];
					for (const matName2 of jsonMat.multi)
					{
						materials2.push(materials[matName2]);
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
				const skeleton = skeletons[jsonAnimation.skeleton];
				const animation = this.parseAnimation(jsonAnimation, skeleton);
				animation.name = animName;
				const mesh = meshes[jsonAnimation.mesh];
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

		if (jsonMat.multi)
		{
			// MULTI-MATERIAL
			material = [];
		}
		else
		{
			material = new THREE.MeshPhongMaterial();

			// DIFFUSE
			if (jsonMat.diffuse)
			{
				material.color.r = jsonMat.diffuse[0] / 255;
				material.color.g = jsonMat.diffuse[1] / 255;
				material.color.b = jsonMat.diffuse[2] / 255;
			}
			
			// SPECULAR
			if (jsonMat.specular)
			{
				material.specular.r = jsonMat.specular[0] / 255;
				material.specular.g = jsonMat.specular[1] / 255;
				material.specular.b = jsonMat.specular[2] / 255;
			}

			// OPACITY
			if (jsonMat.opacity)
			{
				material.opacity = jsonMat.opacity;
				if (jsonMat.opacity != 1)
				{
					material.transparent = true;
				}
			}
			
			// TEXTURE
			if (jsonMat.texture)
			{
				const textureUrl = `${texturePath}/${jsonMat.texture}`;

				const onTextureLoaded = (texture) =>
				{
					console.debug(`Texture "${textureUrl}" loaded`);
				};

				const onTextureProgress = (xhr) => { console.debug(`${textureUrl} (${xhr.loaded / xhr.total * 100}%)`) };

				const onTextureError = (xhr) => { console.debug("Texture load failed", xhr) };

				material.map = (new THREE.TextureLoader()).load(textureUrl, onTextureLoaded, onTextureProgress, onTextureError);
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
			bone.name = jsonBone.name;
			bone.userData.parent = jsonBone.parent;
			bone.position.fromArray(jsonBone.pos);
			bone.quaternion.fromArray(jsonBone.rotq);
			bone.scale.fromArray(jsonBone.scl);
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
		const material = materials[jsonMesh.material];
		if (material == null)
		{
			material = new THREE.MeshNormalMaterial();
		}
		
		// GEOMETRY
		const geometry = new THREE.BufferGeometry();

		// VERTICES
		if (jsonMesh.vertex_indices && jsonMesh.vertex_indices.length)
		{
			// INDEXED (remove indices)
			const verticesSize = 3 * jsonMesh.vertex_indices.reduce((acc, value) => (acc + value.length), 0);
			const vertices = new Float32Array(verticesSize);
			let index = 0;
			let materialIndex = 0;
			for (const groupVertexIndices of jsonMesh.vertex_indices)
			{
				geometry.addGroup((index / 3), groupVertexIndices.length, materialIndex++);
				for (const vertexIndex of groupVertexIndices)
				{
					const vertexIndexPosition = vertexIndex * 3;
					vertices[index++] = jsonMesh.vertex_positions[vertexIndexPosition];
					vertices[index++] = jsonMesh.vertex_positions[vertexIndexPosition + 1];
					vertices[index++] = jsonMesh.vertex_positions[vertexIndexPosition + 2];
				}
			}
			geometry.setAttribute('position', new THREE.BufferAttribute(vertices, 3));
		}
		else
		{
			// NOT INDEXED
			geometry.setAttribute('position', new THREE.BufferAttribute(new Float32Array(jsonMesh.vertex_positions), 3));
		}

		// NORMALS
		if (jsonMesh.face_normals && jsonMesh.face_normals.length && jsonMesh.vertex_indices && jsonMesh.vertex_indices.length)
		{
			// INDEXED (remove indices)
			const normalsSize = 3 * jsonMesh.face_normals.reduce((acc, value) => (acc + value.length), 0);
			const normals = new Float32Array(normalsSize);
			let index = 0;
			for (const groupFaceNormals of jsonMesh.face_normals)
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
		else if (jsonMesh.normals)
		{
			// NOT INDEXED
			geometry.setAttribute('normal', new THREE.BufferAttribute(new Float32Array(jsonMesh.normals), 3));
		}
		else
		{
			// NO NORMALS
			geometry.computeVertexNormals();
		}

		// UVS
		if (jsonMesh.uv_indices && jsonMesh.uv_indices.length)
		{
			// INDEXED (remove indices)
			const uvs = new Float32Array(jsonMesh.uv_indices.length * 2);
			for (let i = 0, sz = jsonMesh.uv_indices.length; i < sz; i++)
			{
				const index = jsonMesh.uv_indices[i];
				uvs[2 * i] = jsonMesh.uv[2 * index];
				uvs[2 * i + 1] = jsonMesh.uv[2 * index + 1];
			}
			geometry.setAttribute('uv', new THREE.BufferAttribute(uvs, 2));
		}
		else if (jsonMesh.uvs)
		{
			// NOT INDEXED
			geometry.setAttribute('uv', new THREE.BufferAttribute(new Float32Array(jsonMesh.uvs), 2));
		}

		// MESH
		let mesh;
		if (jsonMesh.skin_indices && jsonMesh.skin_weights)
		{
			const skinIndicesSize = 4 * jsonMesh.vertex_indices.reduce((acc, value) => (acc + value.length), 0);
			const skinIndices = new Uint16Array(skinIndicesSize);
			const skinWeights = new Float32Array(skinIndicesSize);
			let index = 0;
			for (const groupVertexIndices of jsonMesh.vertex_indices)
			{
				for (const vertexIndex of groupVertexIndices)
				{
					const skinIndexPosition = vertexIndex * 4;
					const i0 = jsonMesh.skin_indices[skinIndexPosition];
					const i1 = jsonMesh.skin_indices[skinIndexPosition+1];
					const i2 = jsonMesh.skin_indices[skinIndexPosition+2];
					const i3 = jsonMesh.skin_indices[skinIndexPosition+3];

					const w0 = jsonMesh.skin_weights[skinIndexPosition];
					const w1 = jsonMesh.skin_weights[skinIndexPosition+1];
					const w2 = jsonMesh.skin_weights[skinIndexPosition+2];
					const w3 = jsonMesh.skin_weights[skinIndexPosition+3];

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
					mat.skinning = true;
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
			if (jsonMesh.skeleton && skeletons)
			{
				const skeleton = skeletons[jsonMesh.skeleton];
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
					mesh.userData.skeletonName = jsonMesh.skeleton;
				}
			}
		}
		else
		{
			mesh = new THREE.Mesh(geometry, material);
		}

		if (jsonMesh.position)
		{
			mesh.position.fromArray(jsonMesh.position);
		}

		if (jsonMesh.rotation)
		{
			mesh.quaternion.fromArray(jsonMesh.rotation);
		}

		if (jsonMesh.scale)
		{
			mesh.scale.fromArray(jsonMesh.scale);
		}

		return mesh;
	}

	parseAnimation(jsonAnim, skeleton)
	{
		const tracks = [];

		for (let jsonTrackIndex = 0; jsonTrackIndex < jsonAnim.hierarchy.length; jsonTrackIndex++)
		{
			const jsonTrack = jsonAnim.hierarchy[jsonTrackIndex];
			const boneName = skeleton.bones[jsonTrackIndex].name;
			const times = [];
			const positions = [];
			const orientations = [];
			const scales = [];
			for (const jsonFrame of jsonTrack.keys)
			{
				times.push(jsonFrame.time);
				positions.push(...jsonFrame.pos);
				orientations.push(...jsonFrame.rot);
				scales.push(...jsonFrame.scl);
			}
			tracks.push(new THREE.VectorKeyframeTrack(`${boneName}.position`, times, positions));
			tracks.push(new THREE.QuaternionKeyframeTrack(`${boneName}.quaternion`, times, orientations));
			tracks.push(new THREE.VectorKeyframeTrack(`${boneName}.scale`, times, scales));
		}

		return new THREE.AnimationClip(jsonAnim.name, jsonAnim.length, tracks);
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
