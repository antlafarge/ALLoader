fileIn "globals.ms"
fileIn "tools.ms"

function formatMaterial mat stream =
(
	if ((classof mat) == PhysicalMaterial) then
	(
		format "%\"%\":%{%" (tabs 2) mat.name sp nl to:stream
		if (mat.base_color_map != undefined) then
		(
			textureFilePath = mat.base_color_map.bitmap.filename
			tokens = (filterString textureFilePath "\\")
			textureFileName = tokens[tokens.count]
			format "%\"texture\":%\"%\",%" (tabs 3) sp textureFileName nl to:stream
		)
		format "%\"ambient\":%[%,%,%],%" (tabs 3) sp (fp mat.Base_Color.r) (fp mat.Base_Color.g) (fp mat.Base_Color.b) nl to:stream
		format "%\"diffuse\":%[%,%,%],%" (tabs 3) sp (fp mat.Base_Color.r) (fp mat.Base_Color.g) (fp mat.Base_Color.b) nl to:stream
		format "%\"opacity\":%%%" (tabs 3) sp (fp (1 - mat.Transparency)) nl to:stream
		format "%}" (tabs 2) to:stream
	)
	else if ((classof mat) == MultiMaterial) then
	(
		format "%\"%\":%{%" (tabs 2) mat.name sp nl to:stream
		format "%\"multi\":%[%" (tabs 3) sp nl to:stream
		-- display sub-material names
		if (mat.numsubs > 1) then
		(
			format "%\"%\"" (tabs 4) mat.materialList[1].name to:stream
			for index = 2 to mat.numsubs do
			(
				if (mat.materialList[index] != undefined) then
				(
					format ",%%\"%\"" nl (tabs 4) mat.materialList[index].name to:stream
				)
			)
		)
		format "%%]%" nl (tabs 3) nl to:stream
		format "%}" (tabs 2) to:stream
		-- recursive parse of sub-materials
		for index = 1 to mat.numsubs do
		(
			if (mat.materialList[index] != undefined) then
			(
				format ",%" nl to:stream
				formatMaterial mat.materialList[index] stream
			)
		)
	)
	else if ((classof mat) == doubleSidedMat) then
	(
		local matName = mat.name
		if (mat.map1Enabled) then
		(
			mat = mat.material1
		)
		else if (mat.map2Enabled) then
		(
			mat = mat.material2
		)
		if (mat != undefined) then
		(
			format "%\"%\":%{%" (tabs 2) matName sp nl to:stream
			if (mat.base_color_map != undefined) then
			(
				textureFilePath = mat.base_color_map.bitmap.filename
				tokens = (filterString textureFilePath "\\")
				textureFileName = tokens[tokens.count]
				format "%\"texture\":%\"%\",%" (tabs 3) sp textureFileName nl to:stream
			)
			format "%\"ambient\":%[%,%,%],%" (tabs 3) sp (fp mat.Base_Color.r) (fp mat.Base_Color.g) (fp mat.Base_Color.b) nl to:stream
			format "%\"diffuse\":%[%,%,%],%" (tabs 3) sp (fp mat.Base_Color.r) (fp mat.Base_Color.g) (fp mat.Base_Color.b) nl to:stream
			format "%\"opacity\":%%,%" (tabs 3) sp (fp (1 - mat.Transparency)) nl to:stream
			format "%\"side\":%\"double\"%" (tabs 3) sp nl to:stream
			format "%}" (tabs 2) to:stream
		)
	)
)

fn formatObject obj stream =
(
	--format ("formatObject '" + obj.name + "'\n") to:Listener

	format "%\"%\":%{%" (tabs 2) obj.name sp nl to:stream

	if (obj.material != undefined) then
	(
		format "%\"material\":%\"%\",%" (tabs 3) sp obj.material.name nl to:stream
	)
	
	format "%\"position\":%%,%" (tabs 3) sp (point3ForOpenGL obj.position) nl to:stream
	format "%\"orientation\":%%,%" (tabs 3) sp (formatQuaternion (quatForOpenGL obj.rotation)) nl to:stream
	format "%\"scale\":%%,%" (tabs 3) sp (formatPoint3 obj.scale) nl to:stream
	
	local objMesh = obj.mesh
    
	-- faces
	local vertex_indices = #()
	local face_normals = #()
	local uv_indices = #()
	for f = 1 to objMesh.numfaces do
	(
		-- get face
		local face = getFace objMesh f
		
		-- processing for multi material
		local matID = getFaceMatID objMesh f
		
		-- create indices array if not existing
		if (vertex_indices[matID] == undefined) then
		(
			vertex_indices[matID] = #()
			face_normals[matID] = #()
		)
		
		-- vertex index
		append vertex_indices[matID] (face.x - 1)
		append vertex_indices[matID] (face.y - 1)
		append vertex_indices[matID] (face.z - 1)
	
		-- normals
		local normal = (point3ForOpenGL (getfacenormal objMesh f))
		append face_normals[matID] (normal.x)
		append face_normals[matID] (normal.y)
		append face_normals[matID] (normal.z)
		
		-- uv indices
		if (getNumTVerts objMesh > 0) then
		(
			local tvface = GetTVFace objMesh f
			append uv_indices (tvface.x - 1)
			append uv_indices (tvface.y - 1)
			append uv_indices (tvface.z - 1)
		)
	)
	
	-- vertex
	format "%\"vertex_positions\":%[" (tabs 3) sp to:stream
	if (objMesh.numverts > 0) then
	(
		local vert = (point3ForOpenGL (in coordsys local getVert objMesh 1))
		format "%,%,%" (fp vert.x) (fp vert.y) (fp vert.z) to:stream
		for v = 2 to objMesh.numverts do
		(
			vert = (point3ForOpenGL (in coordsys local getVert objMesh v))
			format ",%%,%,%" sp (fp vert.x) (fp vert.y) (fp vert.z) to:stream
		)
	)
	format "],%" nl to:stream

	-- vertex index
	format "%\"vertex_indices\":%[%" (tabs 3) sp nl to:stream
	if (vertex_indices.count > 0) then
	(
		format "%[%]" (tabs 4) (formatArray vertex_indices[1]) to:stream
		for index = 2 to vertex_indices.count do
		(
			format "%%[%]" cnl (tabs 4) (formatArray vertex_indices[index]) to:stream
		)
	)
	format "%%],%" nl (tabs 3) nl to:stream

	-- face normals
	format "%\"face_normals\":%[%" (tabs 3) sp nl to:stream
	if (face_normals.count > 0) then
	(
		format "%[%]" (tabs 4) (formatArray face_normals[1]) to:stream
		for index = 2 to face_normals.count do
		(
			format "%%[%]" cnl (tabs 4) (formatArray face_normals[index]) to:stream
		)
	)
	format "%%],%" nl (tabs 3) nl to:stream

	-- texture uvs
	format "%\"uv\":%[" (tabs 3) sp to:stream
	if (objMesh.numTVerts > 0) then
	(
		local tvert = (getTVert objMesh 1)
		format "%,%" (fp tvert.x) (fp tvert.y) to:stream
		for v = 2 to objMesh.numTVerts do
		(
			local tvert = (getTVert objMesh v)
			format ",%%,%" sp (fp tvert.x) (fp tvert.y) to:stream
		)
	)
	format "],%" nl to:stream

	-- texture indices
	format "%\"uv_indices\":%[" (tabs 3) sp to:stream
	if (uv_indices.count > 0) then
	(
		format "%" (uv_indices[1] as integer) to:stream
		for index = 2 to uv_indices.count do
		(
			format ",%" (uv_indices[index] as integer) to:stream
		)
	)
	format "]" to:stream

	local objSkin = obj.modifiers[#skin]
	if (objSkin != undefined) then
	(
		--local bones2 = skinOps.GetBoneNodes objSkin
		local skinIndices = #()
		local skinWeights = #()
	
		for vertexIndex = 1 to objMesh.numverts do
		(
			-- skin indices / skin weights
			processBoneForOneVertex objSkin vertexIndex skinIndices skinWeights
		)
		
		if (skinIndices.count > 0) then
		(
			format ",%%\"skin_indices\":%[%" nl (tabs 3) sp (skinIndices[1] as integer) to:stream
			for skinIndex = 2 to skinIndices.count do
			(
				format ",%" (skinIndices[skinIndex] as integer) to:stream
			)
			format "]" to:stream
		)
	
		if (skinWeights.count > 0) then
		(
			format ",%%\"skin_weights\":%[%" nl (tabs 3) sp (fp skinWeights[1]) to:stream
			for skinIndex = 2 to skinWeights.count do
			(
				format ",%" (fp skinWeights[skinIndex]) to:stream
			)
			format "]" to:stream
		)
		local allBones = skinOps.GetBoneNodes objSkin
		local bonesCount = bones.count
		if (bonesCount > 0) then
		(
			format ",%%\"skin\":%[" nl (tabs 3) sp to:stream
			local firstBone = true;
			for bi = 1 to bonesCount do
			(
				local b = allBones[bi]

				-- retrive parent boneID
				local parentBoneID = -1
				if (b.parent != undefined) then
				(
					for bi2 = 1 to bonesCount do
					(
						if (b.parent == allBones[bi2]) then
						(
							parentBoneID = bi2 - 1
							break
						)
					)
				)

				-- get the transform converted to OpenGL axis
				local newTransform = (getRelativeTransformForOpenGL b)
				
				-- quaternion is inversed because of rotations are inversed in maxscript
				-- cf. http://docs.autodesk.com/3DSMAX/15/ENU/MAXScript-Help/index.html?url=files/GUID-3B001F21-8FE9-4663-A972-E648682A0ACD.htm,topicNumber=d30e272529
				
				if (firstBone == false) then
				(
					format "," to:stream
				)
				
				format "%%{%\"name\":\"%\",%\"parent\":%,%\"pos\":%,%\"rot\":[0,0,0],%\"rotq\":%,%\"scl\":%%}" nl (tabs 4) sp b.name sp parentBoneID sp (formatPoint3 newTransform.position) sp sp (formatQuaternion (inverse newTransform.rotation)) sp (formatPoint3 newTransform.scale) sp to:stream
				
				firstBone = false
			)
			format "%%]" nl (tabs 3) to:stream
		)
	
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
		--meshData.animData = processAnimatedObject obj
		--meshData.animData.name = animName
	)
	
	format "%%}%" nl (tabs 2) nl to:stream
)

fn processBoneForOneVertex objSkin vertexIndex skinIndices skinWeights =
(
	local weightCountTotal = skinOps.GetVertexWeightCount objSkin vertexIndex
	local vertexSkinIndices = #()
	local vertexSkinWeights = #()
	local weightIndex = 1
	
	-- Retrieve BoneIndices and BoneWeights
	for weightIndex = 1 to weightCountTotal do
	(
		-- boneIndexes
		local boneIndex = skinOps.GetVertexWeightBoneID objSkin vertexIndex weightIndex
		append vertexSkinIndices (boneIndex - 1)
		
		-- skinWeights
		local boneWeight = skinOps.GetVertexWeight objSkin vertexIndex weightIndex
		append vertexSkinWeights boneWeight
	)
	
	-- padding empty unused bone slots
	while (weightIndex < 4) do
	(
		append vertexSkinIndices 0
		append vertexSkinWeights 0
		weightIndex += 1
	)
	
	-- Keep only 4 values
	while (vertexSkinIndices.count > 4) do
	(
		local minValue = amin vertexSkinWeights
		local index = findItem vertexSkinWeights minValue
		deleteItem vertexSkinIndices index
		deleteItem vertexSkinWeights index
	)
	
	join skinIndices vertexSkinIndices
	join skinWeights vertexSkinWeights
)

-- DEBUG
disableSceneRedraw()
suspendEditing()
nl = "\n"
cnl = ",\n"
sp = " "
clearListener()
undo on
(
	format "{%" nl to:Listener
	format "%\"version\": \"1\",%" (tabs 1) nl to:Listener
	format "%\"materials\": {%" (tabs 1) nl to:Listener
	local materials = #()
	for obj in objects do
	(
		if (isGeometry obj) then
		(
			select obj
			max modify mode
			appendIfUnique materials obj.material
		)
	)
	local firstMat = true
	for mat in materials do
	(
		if (firstMat == false) then
		(
			format ",%" nl to:Listener
		)
		formatMaterial mat Listener
		firstMat = false
	)
	format "%%},%" nl (tabs 1) nl to:Listener
	format "%\"meshes\":%{%" (tabs 1) sp nl to:Listener
	for obj in objects do
	(
		if (isGeometry obj) then
		(
			select obj
			max modify mode
			formatObject obj Listener
		)
	)
	format "%}%" (tabs 1) nl to:Listener
	format "}%" nl to:Listener
)
resumeEditing()
enableSceneRedraw()
