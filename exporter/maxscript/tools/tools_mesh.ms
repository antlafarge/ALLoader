--  MESH TOOLS

fileIn "tools.ms"
fileIn "tools_anim.ms"
fileIn "InputStringDialog.ms"

-- STRUCTURES
struct MeshDataStruct (name="", material=undefined, vertices=#(), vertex_indices=#(), face_normals=#(), colors=#(), uvs=#(), uv_indices=#(), skinIndices=#(), skinWeights=#(), skinNames=#(), bones=#(), animData=undefined, position=undefined, orientation=undefined, scale=undefined)

-- FUNCTIONS
function processBoneForOneVertex objSkin meshData vertexIndex =
(
	-- skin informations
	local weightCount = amin (skinOps.GetVertexWeightCount objSkin vertexIndex) 4
	
	meshData.skinIndices[vertexIndex] = #()
	meshData.skinWeights[vertexIndex] = #()
	
	-- extract bone weight and index
	for weightIndex = 1 to weightCount do
	(
		-- boneIndexes
		local boneIndex = skinOps.GetVertexWeightBoneID objSkin vertexIndex weightIndex
		append meshData.skinIndices[vertexIndex] (boneIndex - 1)
		
		-- skinWeights
		local boneWeight = skinOps.GetVertexWeight objSkin vertexIndex weightIndex
		append meshData.skinWeights[vertexIndex] boneWeight
	)
	
	-- padding empty unused bone slots
	while (meshData.skinIndices[vertexIndex].count < 4) do
	(
		append meshData.skinIndices[vertexIndex] 0
		append meshData.skinWeights[vertexIndex] 0
	)
)

function processMesh obj =
(
	local objSkin = obj.modifiers[#skin]
	
	local bones = #()
	if (objSkin != undefined) then
	(
		local bonesCount = skinOps.GetNumberBones objSkin
		for index = 1 to bonesCount do
		(
			local boneName = skinOps.GetBoneName objSkin index 1
			local bone = getNodeByName boneName
			append bones bone
		)
	)
	
	local objMesh = obj.mesh
	
	local meshData = MeshDataStruct name:obj.name
	meshData.bones = bones
	meshData.material = obj.material
	meshData.position = (point3ForOpenGL obj.position)
	meshData.orientation = (quatForOpenGL obj.rotation)
	meshData.scale = (point3 obj.scale.x obj.scale.z obj.scale.y)
	
	-- vertices
	for v = 1 to objMesh.numverts do
	(
		local vert = (point3ForOpenGL (in coordsys local getVert objMesh v))
		append meshData.vertices (vert)
		
		-- skin indices / skin weights
		if (objSkin != undefined) then
		(
			processBoneForOneVertex objSkin meshData v
		)
	)
	
	-- texture vertices
	for v = 1 to objMesh.numTVerts do
	(
		local tvert = getTVert objMesh v
		append meshData.uvs tvert
	)
	
	-- parse faces
	for f = 1 to objMesh.numfaces do
	(
		-- get face
		local face = getFace objMesh f
		
		-- processing for multi material
		local matID = getFaceMatID objMesh f
		
		-- create indices array of the meshData if not existing
		if (meshData.vertex_indices[matID] == undefined) then
		(
			meshData.vertex_indices[matID] = #()
			meshData.face_normals[matID] = #()
		)
		
		-- vertex indices
		append meshData.vertex_indices[matID] (face.x - 1)
		append meshData.vertex_indices[matID] (face.y - 1)
		append meshData.vertex_indices[matID] (face.z - 1)
		
		-- normals
		append meshData.face_normals[matID] (point3ForOpenGL (getfacenormal objMesh f))
		
		-- uv indices
		if (getNumTVerts objMesh > 0) then
		(
			local tvface = GetTVFace objMesh f
			append meshData.uv_indices (tvface.x - 1)
			append meshData.uv_indices (tvface.y - 1)
			append meshData.uv_indices (tvface.z - 1)
		)
	)
	
	meshData
)

function processObjects objs =
(
	local meshes = #()
	local animCount = 1
	
	local count = objs.count
	for index = 1 to count do
	(
		local obj = objs[index]
		select obj
		max modify mode
		
		local meshData = processMesh obj
		
		if (obj.modifiers[#skin] != undefined) then
		(
			local animName = "anim_" + (animCount as String)
			if (customAnimName == true) then
			(
				InputStringDialog = InputStringDialog()
				animName = InputStringDialog.stringQuery.launch label:"Enter the animation name"
			)
			else
			(
				animCount += 1
			)
			meshData.animData = processAnimatedObject obj
			meshData.animData.name = animName
		)
		
		append meshes meshData
	)
	
	return meshes
)

function formatMaterial mat file =
(
	if ((classof mat) == MultiMaterial) then
	(
		format "{%\"name\":\"%\",%" sp mat.name sp to:file
		format "\"multi\":[" to:file
		-- display sub-material names
		for index = 1 to mat.numsubs do
		(
			format "%\"%\"" (if (index > 1) then "," else "") mat.materialList[index].name to:file
		)
		format "]%}" sp to:file
		-- recursive parse of sub-materials
		for index = 1 to mat.numsubs do
		(
			format ",%%" nl (tabs 2) to:file
			formatMaterial mat.materialList[index] file
		)
	)
	else if ((classof mat) == PhysicalMaterial) then
	(
		format "{%\"name\":\"%\",%" sp mat.name sp to:file
		if (mat.base_color_map != undefined) then
		(
			textureFilePath = mat.base_color_map.bitmap.filename
			tokens = (filterString textureFilePath "\\")
			textureFileName = tokens[tokens.count]
			format "\"texture\":\"%\", " textureFileName to:file
		)
		format "\"ambient\":[%,%,%],%" (fp mat.Base_Color.r) (fp mat.Base_Color.g) (fp mat.Base_Color.b) sp to:file
		format "\"diffuse\":[%,%,%],%" (fp mat.Base_Color.r) (fp mat.Base_Color.g) (fp mat.Base_Color.b) sp to:file
		format "\"opacity\":%" (fp (1 - mat.Transparency)) to:file
		format "%}" sp to:file
	)
	else if ((classof mat) == Standardmaterial) then
	(
		format "{%" sp to:file
		format "\"name\":\"%\",%" mat.name sp to:file
		if (mat.diffuseMap != undefined) then
		(
			textureFilePath = mat.diffuseMap.bitmap.filename
			tokens = (filterString textureFilePath "\\")
			textureFileName = tokens[tokens.count]
			format "\"texture\":\"%\",%" textureFileName sp to:file
		)
		if (mat.twoSided == true) then
		(
			format "\"side\":\"double\", " to:file
		)
		format "\"ambient\":[%,%,%]," (fp mat.ambient.r) (fp mat.ambient.g) (fp mat.ambient.b) to:file
		format "\"diffuse\":[%,%,%]," (fp mat.diffuse.r) (fp mat.diffuse.g) (fp mat.diffuse.b) to:file
		format "\"specular\":[%,%,%]," (fp mat.specular.r) (fp mat.specular.g) (fp mat.specular.b) to:file
		format "\"opacity\":" (fp (mat.opacity / 100)) to:file
		format "%}" sp to:file
	)
)

function formatMeshData meshData file =
(
	format ("write " + meshData.name)

	format "%{%" (tabs 2) nl to:file
	format "%\"name\":\"%\",%" (tabs 3) meshData.name nl to:file

	if (meshData.material != undefined) then
	(
		format "%\"material\":\"%\",%" (tabs 3) meshData.material.name nl to:file
	)
	
	format "%\"position\":%,%" (tabs 3) meshData.position nl to:file
	format "%\"orientation\":%,%" (tabs 3) (formatQuaternion meshData.orientation) nl to:file
	format "%\"scale\":%,%" (tabs 3) meshData.scale nl to:file
	
	-- Write vertices
	format "%\"vertex_positions\":[%],%" (tabs 3) (formatPoint3Array meshData.vertices) nl to:file

	-- Write indices
	format "%\"vertex_indices\":[%" (tabs 3) nl to:file

	local arrCount = 0
	local count = meshData.vertex_indices.count
	local nl2 = "," + nl
	for index = 1 to count do
	(
		if (meshData.vertex_indices[index] != undefined) then
		(
			format "%%[%]" (if (arrCount > 0) then nl2 else "") (tabs 4) (formatArray meshData.vertex_indices[index]) to:file

			arrCount += 1
		)
	)

	format "%%],%" nl (tabs 3) nl to:file

	-- Write normals
	format "%\"face_normals\":[%" (tabs 3) nl to:file

	local arrCount = 0
	local count = meshData.face_normals.count
	local nl2 = "," + nl
	for index = 1 to count do
	(
		if (meshData.face_normals[index] != undefined) then
		(
			format "%%[%]" (if (arrCount > 0) then nl2 else "") (tabs 4) (formatPoint3Array meshData.face_normals[index]) to:file

			arrCount += 1
		)
	)
	
	format "%%]" nl (tabs 3) to:file

	-- Write colors
	local count = meshData.colors.count
	if (count > 0) then
	(
		format ",%%\"colors\":[" nl (tabs 3) to:file

		local colo
		for index = 1 to count do
		(
			colo = meshData.colors[index]
			
			format "%%,%,%,%" (if (index > 1) then "," else "") colo.r colo.v colo.b colo.a to:file
		)

		format "]" to:file
	)

	-- Write texture coords
	local count = meshData.uvs.count
	if (count > 0) then
	(
		format ",%%\"uv\":[" nl (tabs 3) to:file

		local uv
		for index = 1 to count do
		(
			uv = meshData.uvs[index]
			
			format "%%,%" (if (index > 1) then "," else "") (fp uv.x) (fp uv.y) to:file
		)

		format "]" to:file
	)
	
	-- Write texture indices
	local count = meshData.uv_indices.count
	if (count > 0) then
	(
		format ",%%\"uv_indices\":[" nl (tabs 3) to:file

		local uvIndex
		for index = 1 to count do
		(
			uvIndex = meshData.uv_indices[index]

			format "%%" (if (index > 1) then "," else "") (uvIndex as integer) to:file
		)

		format "]" to:file
	)
	
	-- Write skinIndices
	local count = meshData.skinIndices.count
	if (count > 0) then
	(
		format ",%%\"skin_indices\":[" nl (tabs 3) to:file

		local skin1
		for index = 1 to count do
		(
			skin1 = meshData.skinIndices[index]
			
			format "%%,%,%,%" (if (index > 1) then "," else "") skin1[1] skin1[2] skin1[3] skin1[4] to:file
		)

		format "]" to:file
	)
	
	-- Write skinWeights
	local count = meshData.skinWeights.count
	if (count > 0) then
	(
		format ",%%\"skin_weights\":[" nl (tabs 3) to:file

		local weights
		for index = 1 to count do
		(
			weights = meshData.skinWeights[index]
			
			format "%%,%,%,%" (if (index > 1) then "," else "") (fp weights[1]) (fp weights[2]) (fp weights[3]) (fp weights[4]) to:file
		)

		format "]" to:file
	)
	
	local count = meshData.bones.count
	if (count > 0) then
	(
		-- SKELETON IN A SEPARATE FILE?
		local skeleton_filepath = undefined
		local skeleton_file = file
		-- NOT YET IMPLEMENTED IN LOADER
		/*local separateSkeleton = queryBox ("Export the skeleton in a separate File?\n" + meshData.name)
		if (separateSkeleton == true) then
		(
			skeleton_filepath = getSaveFileName caption:"Location for saving the Skeleton file" types:"JSON (*.json)|*.json|Plain Text (*.txt)|*.txt|All Files (*.*)|*.*|"
			skeleton_file = createFile skeleton_filepath
			format "{\n" to:skeleton_file
			format "\t\t\t\"name\":\"%\"" meshData.name to:skeleton_file
		)*/
		
		-- Write bones hierarchy
		format ",%%\"skin\":[%" nl (tabs 3) nl to:skeleton_file

		for boneIndex = 1 to count do
		(
			local bone = meshData.bones[boneIndex]

			if (boneIndex > 1) then
			(
				format ",%" nl to:skeleton_file
			)
			
			-- retrive parent bone index
			local parentBoneIndex = -1
			if (bone.parent != undefined) then
			(
				local boneIndex2 = 1
				while ((boneIndex2 <= count) and (parentBoneIndex == -1)) do
				(
					if (meshData.bones[boneIndex2].name == bone.parent.name) then
					(
						parentBoneIndex = boneIndex2 - 1
					)
					boneIndex2 += 1
				)
			)
			
			-- get the transform converted to OpenGL axis
			local newTransform = (getRelativeTransformForOpenGL bone)
			
			format "%{%\"name\":\"%\",%" (tabs 4) sp bone.name sp to:skeleton_file
			-- parent
			format "\"parent\":%,%" parentBoneIndex sp to:skeleton_file
			-- data
			format "\"pos\":%,%" (formatPoint3 newTransform.position) sp to:skeleton_file
			format "\"rot\":[0,0,0],%" sp to:skeleton_file
			-- quaternion is inversed because of rotations are inversed in maxscript
			-- cf. http://docs.autodesk.com/3DSMAX/15/ENU/MAXScript-Help/index.html?url=files/GUID-3B001F21-8FE9-4663-A972-E648682A0ACD.htm,topicNumber=d30e272529
			format "\"rotq\":%,%" (formatQuaternion (inverse newTransform.rotation)) sp to:skeleton_file
			format "\"scl\":%%}" (formatPoint3 newTransform.scale) sp to:skeleton_file
		)

		format "%%]" nl (tabs 3) to:skeleton_file
		
		if (separateSkeleton == true) then
		(
			format "%}%" nl nl to:skeleton_file
			close skeleton_file
		)
	)
	
	format "%%}" nl (tabs 2) to:file
)

function formatObjects meshes file =
(
	local someDataInserted = false
	
	format "{%" nl to:file
	
	-- materials
	local materials = #()
	local count = meshes.count
	for index = 1 to count do
	(
		local meshData = meshes[index]
		local mat = meshData.material
		if (mat != undefined) then
		(
			append materials mat
		)
	)

	local count = materials.count
	local nl2 = "," + nl
	if (count > 0) then
	(
		format "%%\"materials\":[%" (if (someDataInserted == true) then nl2 else "") (tabs 1) nl to:file

		for index = 1 to count do
		(
			local mat = materials[index]

			format "%%" (if (index > 1) then nl2 else "") (tabs 2) to:file

			formatMaterial mat file
		)

		format "%%]" nl (tabs 1) to:file

		someDataInserted = true
	)
	
	-- meshes
	local count = meshes.count
	local nl2 = "," + nl
	if (count > 0) then
	(
		format "%%\"meshes\":[%" (if (someDataInserted == true) then nl2 else "") (tabs 1) nl to:file

		local meshCount = 0

		for index = 1 to count do
		(
			local meshData = meshes[index]
			if ((isBone meshData) == false) then
			(
				if (meshCount > 0) then
				(
					format ",%" nl to:file
				)
				formatMeshData meshData file
				meshCount += 1
			)
		)

		format "%%]" nl (tabs 1) to:file
		
		someDataInserted = true
	)
	
	-- animDatas
	local animDatas = #()
	local count = meshes.count
	for index = 1 to count do
	(
		local meshData = meshes[index]
		if (((isBone meshData) == false) and (meshData.animData != undefined)) then
		(
			append animDatas meshData.animData
		)
	)

	local count = animDatas.count
	if (count > 0) then
	(
		if (someDataInserted == true) then
		(
			format ",%" nl to:file
		)

		format "%\"animations\":[%" (tabs 1) nl to:file

		for index = 1 to count do
		(
			local animData = animDatas[index]
			if (index > 1) then
			(
				format ",%" nl to:file
			)
			formatAnimData animData file
		)

		format "%]" (tabs 1) to:file

		someDataInserted = true
	)
	
	format "%}%" nl nl to:file
)
