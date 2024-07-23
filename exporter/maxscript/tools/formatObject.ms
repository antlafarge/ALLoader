fileIn "globals.ms"
fileIn "tools.ms"

function formatMaterial mat stream =
(
	if ((classof mat) == MultiMaterial) then
	(
		format "%{%" (tabs 2) nl to:stream
		format "%\"name\":\"%\",%" (tabs 3) mat.name nl to:stream
		format "%\"multi\":[%" (tabs 3) nl to:stream
		-- display sub-material names
		if (mat.numsubs > 1) then
		(
			format "%\"%\"" (tabs 4) mat.materialList[1].name to:stream
			for index = 2 to mat.numsubs do
			(
				format ",%%\"%\"%" nl (tabs 4) mat.materialList[index].name nl to:stream
			)
		)
		format "%]%" (tabs 3) nl to:stream
		format "%}" (tabs 2) to:stream
		-- recursive parse of sub-materials
		for index = 1 to mat.numsubs do
		(
			format ",%" nl to:stream
			formatMaterial mat.materialList[index] stream
		)
		format "%" nl to:stream
	)
	else if ((classof mat) == PhysicalMaterial) then
	(
		format "%{%" (tabs 2) nl to:stream
		format "%\"name\":\"%\",%" (tabs 3) mat.name nl to:stream
		if (mat.base_color_map != undefined) then
		(
			textureFilePath = mat.base_color_map.bitmap.filename
			tokens = (filterString textureFilePath "\\")
			textureFileName = tokens[tokens.count]
			format "%\"texture\":\"%\",%" (tabs 3) textureFileName nl to:stream
		)
		format "%\"ambient\":[%,%,%],%" (tabs 3) (fp mat.Base_Color.r) (fp mat.Base_Color.g) (fp mat.Base_Color.b) nl to:stream
		format "%\"diffuse\":[%,%,%],%" (tabs 3) (fp mat.Base_Color.r) (fp mat.Base_Color.g) (fp mat.Base_Color.b) nl to:stream
		format "%\"opacity\":%%" (tabs 3) (fp (1 - mat.Transparency)) nl to:stream
		format "%}" (tabs 2) to:stream
	)
	else if ((classof mat) == Standardmaterial) then
	(
		format "%{%" (tabs 2) nl to:stream
		format "%\"name\":\"%\",%" (tabs 3) mat.name nl to:stream
		if (mat.diffuseMap != undefined) then
		(
			textureFilePath = mat.diffuseMap.bitmap.filename
			tokens = (filterString textureFilePath "\\")
			textureFileName = tokens[tokens.count]
			format "%\"texture\":\"%\",%" (tabs 3) textureFileName nl to:stream
		)
		if (mat.twoSided == true) then
		(
			format "%\"side\":\"double\",%" (tabs 3) nl to:stream
		)
		format "%\"ambient\":[%,%,%]," (tabs 3) (fp mat.ambient.r) (fp mat.ambient.g) (fp mat.ambient.b) nl to:stream
		format "%\"diffuse\":[%,%,%]," (tabs 3) (fp mat.diffuse.r) (fp mat.diffuse.g) (fp mat.diffuse.b) nl to:stream
		format "%\"specular\":[%,%,%]," (tabs 3) (fp mat.specular.r) (fp mat.specular.g) (fp mat.specular.b) nl to:stream
		format "%\"opacity\":%%" (tabs 3) (fp (mat.opacity / 100)) nl to:stream
		format "%}" (tabs 2) to:stream
	)
)

fn formatObject obj stream =
(
	--format ("formatObject '" + obj.name + "'\n") to:Listener

	format "%{%" (tabs 2) nl to:stream

	format "%\"name\":\"%\",%" (tabs 3) obj.name nl to:stream

	if (obj.material != undefined) then
	(
		format "%\"material\":\"%\",%" (tabs 3) obj.material.name nl to:stream
	)
	
	format "%\"position\":%,%" (tabs 3) (point3ForOpenGL obj.position) nl to:stream
	format "%\"orientation\":%,%" (tabs 3) (formatQuaternion (quatForOpenGL obj.rotation)) nl to:stream
	format "%\"scale\":%,%" (tabs 3) (formatPoint3 obj.scale) nl to:stream
	
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
	format "%\"vertex_positions\":[" (tabs 3) to:stream
	if (objMesh.numverts > 0) then
	(
		local vert = (point3ForOpenGL (in coordsys local getVert objMesh 1))
		format "%,%,%" (fp vert.x) (fp vert.y) (fp vert.z) to:stream
		for v = 2 to objMesh.numverts do
		(
			vert = (point3ForOpenGL (in coordsys local getVert objMesh v))
			format ", %,%,%" (fp vert.x) (fp vert.y) (fp vert.z) to:stream
		)
	)
	format "],%" nl to:stream

	-- vertex index
	format "%\"vertex_indices\":[%" (tabs 3) nl to:stream
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
	format "%\"face_normals\":[%" (tabs 3) nl to:stream
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
	format "%\"uv\":[" (tabs 3) to:stream
	if (objMesh.numTVerts > 0) then
	(
		local tvert = (getTVert objMesh 1)
		format "%,%" (fp tvert.x) (fp tvert.y) to:stream
		for v = 2 to objMesh.numTVerts do
		(
			local tvert = (getTVert objMesh v)
			format ", %,%" (fp tvert.x) (fp tvert.y) to:stream
		)
	)
	format "],%" nl to:stream

	-- texture indices
	format "%\"uv_indices\":[" (tabs 3) to:stream
	if (uv_indices.count > 0) then
	(
		format "%" (uv_indices[1] as integer) to:stream
		for index = 2 to uv_indices.count do
		(
			format ",%" (uv_indices[index] as integer) to:stream
		)
	)
	format "],%" nl to:stream

	-- local objSkin = obj.modifiers[#skin]
	
	-- local bones = #()
	-- if (objSkin != undefined) then
	-- (
	-- 	meshData.bones = skinOps.GetBoneNodes objSkin
	-- )
	
	-- for v = 1 to objMesh.numverts do
	-- (
	-- 	-- skin indices / skin weights
	-- 	if (objSkin != undefined) then
	-- 	(
	-- 		processBoneForOneVertex objSkin meshData v
	-- 	)
	-- )
	
    -- if (obj.modifiers[#skin] != undefined) then
    -- (
    --     local animName = "anim_" + (animCount as String)
    --     if (customAnimName == true) then
    --     (
    --         InputStringDialog = InputStringDialog()
    --         animName = InputStringDialog.stringQuery.launch label:"Enter the animation name"
    --     )
    --     else
    --     (
    --         animCount += 1
    --     )
    --     meshData.animData = processAnimatedObject obj
    --     meshData.animData.name = animName
    -- )
	
	format "%}%" (tabs 2) nl to:stream
)

fn processBoneForOneVertex objSkin meshData vertexIndex =
(
	local weightCountTotal = skinOps.GetVertexWeightCount objSkin vertexIndex
	
	local skinIndices = #()
	local skinWeights = #()
	
	local weightIndex = 1
	
	-- Retrieve BoneIndices and BoneWeights
	for weightIndex = 1 to weightCountTotal do
	(
		-- boneIndexes
		local boneIndex = skinOps.GetVertexWeightBoneID objSkin vertexIndex weightIndex
		append skinIndices (boneIndex - 1)
		
		-- skinWeights
		local boneWeight = skinOps.GetVertexWeight objSkin vertexIndex weightIndex
		append skinWeights boneWeight
		
		if (meshData.skinIndices[vertexIndex].count < 8) then
		(
			format "Retrieve boneIndex %\n" boneIndex
			format "Retrieve boneWeight %\n" boneWeight
		)
	)
	
	-- padding empty unused bone slots
	while (weightIndex < 4) do
	(
		append skinIndices 0
		append skinWeights 0
		weightIndex += 1
		
		if (meshData.skinIndices[vertexIndex].count < 8) then
		(
			format "Padding boneIndex\n"
			format "Padding boneWeight\n"
		)
	)
	
	-- Keep only 4 values
	while (skinIndices.count > 4) do
	(
		local minValue = amin skinWeights
		local index = findItem skinWeights minValue
		
		if (meshData.skinIndices[vertexIndex].count < 8) then
		(
			format "Remove min boneWeight % (index=%)\n" minValue index
		)
		
		deleteItem skinIndices index
		deleteItem skinWeights index
	)
	
	if (meshData.skinIndices[vertexIndex].count < 8) then
	(
		format "Appening % (%) values\n" skinIndices.count skinWeights.count
	)
	
	join meshData.skinIndices[vertexIndex] skinIndices
	join meshData.skinWeights[vertexIndex] skinWeights
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
	format "%\"version\":\"1\",%" (tabs 1) nl to:Listener
	format "%\"materials\":[%" (tabs 1) nl to:Listener
	for obj in objects do
	(
		if (isGeometry obj) then
		(
			select obj
			max modify mode
			formatMaterial obj.material Listener
		)
	)
	format "%],%" (tabs 1) nl to:Listener
	format "%\"meshes\":[%" (tabs 1) nl to:Listener
	for obj in objects do
	(
		if (isGeometry obj) then
		(
			select obj
			max modify mode
			formatObject obj Listener
		)
	)
	format "%]%" (tabs 1) nl to:Listener
	format "}%" nl to:Listener
)
resumeEditing()
enableSceneRedraw()
