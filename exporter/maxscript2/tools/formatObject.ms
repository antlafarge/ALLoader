include "globals.ms"

fn formatObject obj =
(
	format ("formatObject '" + obj.name + "'")

	format "%{%" (tabs 2) nl to:file

	format "%\"nam\":\"%\",%" (tabs 3) obj.name nl to:file

	if (obj.material != undefined) then
	(
		format "%\"mat\":\"%\",%" (tabs 3) obj.material.name nl to:file
	)
	
	format "%\"pos\":%,%" (tabs 3) (point3ForOpenGL obj.position) nl to:file
	format "%\"rot\":%,%" (tabs 3) (formatQuaternion (quatForOpenGL obj.rotation)) nl to:file
	format "%\"scl\":%,%" (tabs 3) (point3 obj.scale.x obj.scale.z obj.scale.y) nl to:file
	
	local objMesh = obj.mesh
    
	format "%\"vtx\":[" (tabs 3) to:file
	for v = 1 to objMesh.numverts do
	(
        if (v > 1) then
        (
            format "," to:file
        )
        format "%" (point3ForOpenGL (in coordsys local getVert objMesh v)) to:file
    )
	format "],%" nl to:file

	-- -- texture vertices
	-- for v = 1 to objMesh.numTVerts do
	-- (
	-- 	local tvert = getTVert objMesh v
	-- 	append meshData.uvs tvert
	-- )
	
	-- -- parse faces
	-- for f = 1 to objMesh.numfaces do
	-- (
	-- 	-- get face
	-- 	local face = getFace objMesh f
		
	-- 	-- processing for multi material
	-- 	local matID = getFaceMatID objMesh f
		
	-- 	-- create indices array of the meshData if not existing
	-- 	if (meshData.vertex_indices[matID] == undefined) then
	-- 	(
	-- 		meshData.vertex_indices[matID] = #()
	-- 		meshData.face_normals[matID] = #()
	-- 	)
		
	-- 	-- vertex indices
	-- 	append meshData.vertex_indices[matID] (face.x - 1)
	-- 	append meshData.vertex_indices[matID] (face.y - 1)
	-- 	append meshData.vertex_indices[matID] (face.z - 1)
		
	-- 	-- normals
	-- 	append meshData.face_normals[matID] (point3ForOpenGL (getfacenormal objMesh f))
		
	-- 	-- uv indices
	-- 	if (getNumTVerts objMesh > 0) then
	-- 	(
	-- 		local tvface = GetTVFace objMesh f
	-- 		append meshData.uv_indices (tvface.x - 1)
	-- 		append meshData.uv_indices (tvface.y - 1)
	-- 		append meshData.uv_indices (tvface.z - 1)
	-- 	)
	-- )
	
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
