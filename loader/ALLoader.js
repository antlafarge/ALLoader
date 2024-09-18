import * as THREE from '../examples/libs/three.js/build/three.module.js'

export class ALLoader extends THREE.Loader {
	constructor(manager) {
		super(manager);
	}

	// urls : string or Array<string>
	// Files have to be loaded in this order : materials, skeletons, meshs, animations
	load(urls, data, onLoad, onProgress, onError) {
		if (urls instanceof Array) {
			this.#loadMultiParts(urls, data, onLoad, onProgress, onError);
			return;
		}

		const url = urls;
		const {
			texturePath = this.extractUrlBase(url),
			materials = {},
			skeletons = {},
			meshes = {},
			animations = {},
			loadMaterials = true,
			loadSkeletons = true,
			loadMeshes = true,
			loadAnimations = true
		} = data;

		const loader = new THREE.FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.setResponseType("json");

		loader.load(url, (text) => {
			try {
				onLoad(this.parse(text, { texturePath, materials, skeletons, meshes, animations, loadMaterials, loadSkeletons, loadMeshes, loadAnimations }));
			}
			catch (ex) {
				if (onError) {
					onError(ex);
				}
				else {
					console.error(ex);
				}

				scope.manager.itemError(url);
			}

		}, onProgress, onError);
	}

	#loadMultiParts(urls, data, onLoad, onProgress, onError) {
		this.load(urls.shift(), data, (urls.length ? (data) => this.#loadMultiParts(urls, data, onLoad, onProgress, onError) : onLoad), onProgress, onError);
	}

	parse(json, data) {
		if (json == null) {
			return data;
		}

		const { texturePath, materials, skeletons, meshes, animations, loadMaterials, loadSkeletons, loadMeshes, loadAnimations } = data;

		// MATERIALS
		if (loadMaterials && json.materials) {
			for (const matName in json.materials) {
				const jsonMat = json.materials[matName];
				const material = this.parseMaterial(jsonMat, texturePath);
				material.name = matName;
				materials[matName] = material;
			}

			for (const matName in json.materials) {
				const jsonMat = json.materials[matName];
				if (jsonMat.ml && jsonMat.ml.length > 0) {
					const materials2 = materials[matName];
					for (const matName2 of jsonMat.ml) {
						materials2.push(materials[matName2] ?? null);
					}
				}
			}
		}

		// SKELETONS
		if (loadSkeletons && json.skeletons) {
			for (const skeName in json.skeletons) {
				const jsonSkeleton = json.skeletons[skeName];
				const skeleton = this.parseSkeleton(jsonSkeleton);
				skeleton.name = skeName;
				skeletons[skeName] = skeleton;
			}
		}

		// MESHES
		if (loadMeshes && json.meshes) {
			for (const meshName in json.meshes) {
				const jsonMesh = json.meshes[meshName];
				const mesh = this.parseMesh(jsonMesh, materials, skeletons);
				mesh.name = meshName;
				meshes[meshName] = mesh;
			}
		}

		// ANIMATIONS
		if (loadAnimations && json.animations) {
			for (const animName in json.animations) {
				const jsonAnimation = json.animations[animName];
				const animation = this.parseAnimation(jsonAnimation, animName);
				animations[animName] = animation;
				if (jsonAnimation.ms) {
					const mesh = meshes[jsonAnimation.ms];
					mesh.animations.push(animation);
				}
			}
		}

		return data;
	}

	parseMaterial(jsonMat, texturePath) {
		let material;

		if (jsonMat.ml) {
			// MULTI-MATERIALS
			material = [];
		}
		else {
			material = new THREE.MeshPhongMaterial();

			// COLOR
			if (jsonMat.cl != null) {
				material.color.set(jsonMat.cl[0] / 255, jsonMat.cl[1] / 255, jsonMat.cl[2] / 255);
			}

			// SPECULAR
			if (jsonMat.sp != null) {
				material.specular.set(jsonMat.sp[0] / 255, jsonMat.sp[1] / 255, jsonMat.sp[2] / 255);
			}

			// OPACITY
			if (jsonMat.op != null) {
				material.opacity = jsonMat.op;
				if (material.opacity != 1) {
					material.transparent = true;
				}
			}

			// COLOR MAP (TEXTURE)
			if (jsonMat.cm != null) {
				const textureUrl = `${texturePath}/${jsonMat.cm}`;

				const onTextureLoaded = (texture) => {
					//console.debug(`Texture "${textureUrl}" loaded`);
					texture.wrapS = THREE.RepeatWrapping;
					texture.wrapT = THREE.RepeatWrapping;
				};

				const onTextureProgress = (xhr) => {
					//console.debug(`${textureUrl} (${xhr.loaded / xhr.total * 100}%)`);
				};

				const onTextureError = (xhr) => {
					console.debug(`Texture "${textureUrl}" load failed`);
				};

				material.map = (new THREE.TextureLoader()).load(textureUrl, onTextureLoaded, onTextureProgress, onTextureError);
			}

			if (jsonMat.sd != null) {
				if (jsonMat.sd == "double") {
					material.side = THREE.DoubleSide;
				}
				else if (jsonMat.sd == "back" || jsonMat.sd == "reverse") {
					material.side = THREE.BackSide;
				}
			}
		}

		return material;
	}

	parseSkeleton(jsonSkeleton) {
		const bones = [];

		for (const jsonBone of jsonSkeleton) {
			const bone = new THREE.Bone();
			bone.name = jsonBone.nm;
			if (jsonBone.pr != null) bone.userData.parent = jsonBone.pr;
			if (jsonBone.ps != null) bone.position.fromArray(jsonBone.ps);
			if (jsonBone.rt != null) bone.quaternion.fromArray(jsonBone.rt);
			if (jsonBone.sc != null) bone.scale.fromArray(jsonBone.sc);
			bones.push(bone);
		}

		for (const bone of bones) {
			if (bone.userData.parent != -1) {
				const parent = bones[bone.userData.parent];
				parent.add(bone);
			}
		}

		return new THREE.Skeleton(bones);
	}

	parseMesh(jsonMesh, materials, skeletons) {
		// MATERIAL
		let material = (jsonMesh.mt != null) ? (materials != null ? materials[jsonMesh.mt] : null) : null;
		if (material == null) {
			material = new THREE.MeshNormalMaterial();
		}

		// GEOMETRY
		const geometry = new THREE.BufferGeometry();

		const expandVertices = (jsonMesh.fn && jsonMesh.fn.length > 0)
			|| (jsonMesh.vn && jsonMesh.vn.length > 0)
			|| (jsonMesh.uv && jsonMesh.uv.length > 0);

		// VERTICES
		if (jsonMesh.vt != null && jsonMesh.vt.length > 0) {
			let vertices;
			if (jsonMesh.vi != null && jsonMesh.vi.length > 0) {
				// INDEXED
				// Groups
				let index = 0;
				let materialIndex = 0;
				for (const group of jsonMesh.vi) {
					geometry.addGroup(index, group.length, materialIndex);
					index += group.length;
					materialIndex++;
				}
				if (expandVertices) {
					// Vertices
					vertices = this.unindexData(jsonMesh.vt, jsonMesh.vi, true, 3);
				}
				else {
					// Indices
					const indices = this.mergeSubArrays(jsonMesh.vi, false, false);
					geometry.setIndex(indices);
					// Vertices
					vertices = new Float32Array(jsonMesh.vt);
				}
			}
			else {
				// NOT INDEXED
				// Groups
				let index = 0;
				let materialIndex = 0;
				for (const group of jsonMesh.vt) {
					geometry.addGroup((index / 3), (group.length / 3), materialIndex);
					index += group.length;
					materialIndex++;
				}
				// Vertices
				vertices = this.mergeSubArrays(jsonMesh.vt, true, true);
			}
			geometry.setAttribute('position', new THREE.BufferAttribute(vertices, 3));
		}

		// NORMALS
		if (jsonMesh.vn != null && jsonMesh.vn.length > 0) {
			// NOT INDEXED
			const normals2 = this.mergeSubArrays(jsonMesh.vn, true, true);
			geometry.setAttribute('normal', new THREE.BufferAttribute(normals2, 3));
		}
		else if (jsonMesh.fn != null && jsonMesh.fn.length > 0) {
			// INDEXED
			// Expand face normals for each vertex
			let bufferSize = 0
			for (const group of jsonMesh.fn) {
				bufferSize += group.length;
			}
			bufferSize *= 3;
			const normals = new Float32Array(bufferSize);
			let index = 0;
			for (const group of jsonMesh.fn) {
				for (let i = 0; i < group.length; i += 3) {
					const fnX = group[i];
					const fnY = group[i + 1];
					const fnZ = group[i + 2];
					normals[index++] = fnX;
					normals[index++] = fnY;
					normals[index++] = fnZ;
					normals[index++] = fnX;
					normals[index++] = fnY;
					normals[index++] = fnZ;
					normals[index++] = fnX;
					normals[index++] = fnY;
					normals[index++] = fnZ;
				}
			}
			geometry.setAttribute('normal', new THREE.BufferAttribute(normals, 3));
		}
		else {
			// NO NORMALS, COMPUTE
			geometry.computeVertexNormals();
		}

		// UVs
		if (jsonMesh.uv != null && jsonMesh.uv.length > 0) {
			let uvs;
			if (jsonMesh.ui != null && jsonMesh.ui.length > 0) {
				// INDEXED
				uvs = this.unindexData(jsonMesh.uv, jsonMesh.ui, true, 2);
			}
			else {
				// NOT INDEXED
				uvs = this.mergeSubArrays(jsonMesh.uv, true, true);
			}
			geometry.setAttribute('uv', new THREE.BufferAttribute(uvs, 2));
		}

		// SKIN INDICES / WEIGHTS
		let mesh;
		if (jsonMesh.sk != null && skeletons && skeletons[jsonMesh.sk] != null && jsonMesh.si != null && jsonMesh.si.length && jsonMesh.sw != null && jsonMesh.sw.length && jsonMesh.vi != null && jsonMesh.vi.length > 0) {
			let skinIndicesSize = 0;
			for (const skinIndices of jsonMesh.vi) {
				skinIndicesSize += skinIndices.length;
			}
			skinIndicesSize *= 4;
			const skinIndices = new Uint16Array(skinIndicesSize);
			const skinWeights = new Float32Array(skinIndicesSize);
			let index = 0;
			for (const groupVertexIndices of jsonMesh.vi) {
				for (const vertexIndex of groupVertexIndices) {
					const skinIndexPosition = vertexIndex * 4;
					const i0 = jsonMesh.si[skinIndexPosition];
					const i1 = jsonMesh.si[skinIndexPosition + 1];
					const i2 = jsonMesh.si[skinIndexPosition + 2];
					const i3 = jsonMesh.si[skinIndexPosition + 3];
					const w0 = jsonMesh.sw[skinIndexPosition];
					const w1 = jsonMesh.sw[skinIndexPosition + 1];
					const w2 = jsonMesh.sw[skinIndexPosition + 2];
					const w3 = jsonMesh.sw[skinIndexPosition + 3];
					const total = w0 + w1 + w2 + w3;
					if (total == 0) {
						console.warn(`skinIndexPosition=:${index} total=${total} indices=${i0},${i1},${i2},${i3} weights=${w0},${w1},${w2},${w3}`);
						total = Number.EPSILON;
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
			if (material instanceof Array) {
				for (const mat of material) {
					if (mat) {
						mat.skinning = true;
					}
				}
			}
			else {
				material.skinning = true;
			}

			// SKINNED_MESH
			mesh = new THREE.SkinnedMesh(geometry, material);

			// SKELETON
			const skeleton = skeletons[jsonMesh.sk];
			if (skeleton) {
				for (const bone of skeleton.bones) {
					if (bone.userData.parent == -1) {
						mesh.add(bone);
					}
				}
				mesh.bind(skeleton);
				mesh.userData.skeletonName = jsonMesh.sk;
			}
		}
		else {
			mesh = new THREE.Mesh(geometry, material);
		}

		if (jsonMesh.ps != null) {
			mesh.position.fromArray(jsonMesh.ps);
		}

		if (jsonMesh.rt != null) {
			mesh.quaternion.fromArray(jsonMesh.rt);
		}

		if (jsonMesh.sc != null) {
			mesh.scale.fromArray(jsonMesh.sc);
		}

		return mesh;
	}

	parseAnimation(jsonAnim, animName) {
		const tracks = [];

		for (const jsonTrack of jsonAnim.hr) {
			const boneName = jsonTrack.bn;
			const times = [];
			const positions = [];
			const orientations = [];
			const scales = [];

			for (const jsonFrame of jsonTrack.ky) {
				times.push(jsonFrame.tm);
				if (jsonFrame.ps != null) positions.push(...jsonFrame.ps);
				if (jsonFrame.rt != null) orientations.push(...jsonFrame.rt);
				if (jsonFrame.sc != null) scales.push(...jsonFrame.sc);
			}

			if (times.length > 0) {
				if (positions.length > 0) tracks.push(new THREE.VectorKeyframeTrack(`${boneName}.position`, times, positions));
				if (orientations.length > 0) tracks.push(new THREE.QuaternionKeyframeTrack(`${boneName}.quaternion`, times, orientations));
				if (scales.length > 0) tracks.push(new THREE.VectorKeyframeTrack(`${boneName}.scale`, times, scales));
			}
		}

		return new THREE.AnimationClip(animName, jsonAnim.dr, tracks);
	}

	mergeSubArrays(multiArrays, toTypedArray, toFloat32Array) {
		let bufferSize = 0;
		for (const oneArray of multiArrays) {
			bufferSize += oneArray.length;
		}
		const buffer = toTypedArray ? (toFloat32Array ? new Float32Array(bufferSize) : new Uint16Array(bufferSize)) : new Array(bufferSize);
		let index = 0;
		let materialIndex = 0;
		for (const oneArray of multiArrays) {
			if (toTypedArray) {
				buffer.set(oneArray, index);
			}
			else {
				buffer.splice(index, oneArray.length, ...oneArray);
			}
			index += oneArray.length;
			materialIndex++;
		}
		return buffer;
	}

	unindexData(dataIndexed, multiIndices, toFloat32Array, itemSize) {
		let bufferSize = 0
		for (const indices of multiIndices) {
			bufferSize += indices.length;
		}
		bufferSize *= itemSize;
		const buffer = toFloat32Array ? new Float32Array(bufferSize) : Uint16Array(bufferSize);
		let index = 0;
		for (const indices of multiIndices) {
			for (let i = 0; i < indices.length; i++) {
				for (let j = 0; j < itemSize; j++) {
					buffer[index] = dataIndexed[indices[i] * itemSize + j];
					index++;
				}
			}
		}
		return buffer;
	}

	static cloneAnimationData(data, newName) {
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

	static merge(geometry1, geometry2, materialIndexOffset) {
		if (materialIndexOffset === undefined) {
			materialIndexOffset = 0;
		}
		geometry1.merge(geometry2, null, materialIndexOffset);
		AnimationUtils.mergeBones(geometry1, geometry2);
		if (geometry2.name.length > 0) {
			if (geometry1.name.length > 0) {
				geometry1.name += "_";
			}
			geometry1.name += geometry2.name;
		}
		return geometry1;
	}

	static mergeBones(geometry1, geometry2) {
		if (typeof (geometry1.bones) == "undefined") {
			geometry1.bones = [];
			geometry1.skinIndices = [];
			geometry1.skinWeights = [];
		}

		let bl, GB = [];

		// enumerate bone names in geometry1
		bl = geometry1.bones.length;
		for (let i = 0; i < bl; i++) {
			GB.push(geometry1.bones[i].name);
		}

		// if bone doesn't exist in geometry1, we push it from geometry2
		bl = geometry2.bones.length;
		for (let i = 0; i < bl; i++) {
			if (GB.indexOf(geometry2.bones[i].name) == -1) {
				geometry1.bones.push(geometry2.bones[i]);
			}
		}

		function treatSkinIndex(skinIndex) {
			const name = geometry2.bones[skinIndex].name;
			return getBoneIdFromName(geometry1.bones, name);
		}

		for (let i = 0; i < geometry2.skinIndices.length; i++) {
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
