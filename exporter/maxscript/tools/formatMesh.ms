fileIn "globals.ms"
fileIn "tools.ms"

fn formatObject obj stream =
(
	--format ("formatObject '" + obj.name + "'\n") to:Listener

	format "%\"%\":%{%" (tabs 2) obj.name sp nl to:stream

	if (obj.material != undefined) then
	(
		format "%\"mt\":%\"%\",%" (tabs 3) sp obj.material.name nl to:stream -- Material
	)
	
	-- Position
	format "%\"ps\":%%,%" (tabs 3) sp (point3ForOpenGL obj.position) nl to:stream
	
	-- Rotation
	format "%\"rt\":%%,%" (tabs 3) sp (formatQuaternion (quatForOpenGL obj.rotation)) nl to:stream
	
	-- Scale
	format "%\"sc\":%%,%" (tabs 3) sp (formatPoint3 obj.scale) nl to:stream
	
	local objMesh = obj.mesh
    
	-- Faces
	local vertex_indices = #()
	local face_normals = #()
	local uv_indices = #()
	for f = 1 to objMesh.numfaces do
	(
		-- Get face
		local face = getFace objMesh f
		
		-- Processing for multi material
		local matID = getFaceMatID objMesh f
		
		-- Create indices array if not existing
		if (vertex_indices[matID] == undefined) then
		(
			vertex_indices[matID] = #()
			face_normals[matID] = #()
		)
		
		-- Vertex index
		append vertex_indices[matID] (face.x - 1)
		append vertex_indices[matID] (face.y - 1)
		append vertex_indices[matID] (face.z - 1)
	
		-- Normals
		local normal = (point3ForOpenGL (getfacenormal objMesh f))
		append face_normals[matID] (normal.x)
		append face_normals[matID] (normal.y)
		append face_normals[matID] (normal.z)
		
		-- UV indices
		if (getNumTVerts objMesh > 0) then
		(
			local tvface = GetTVFace objMesh f
			append uv_indices (tvface.x - 1)
			append uv_indices (tvface.y - 1)
			append uv_indices (tvface.z - 1)
		)
	)
	
	-- Vertex positions
	format "%\"vp\":%[" (tabs 3) sp to:stream
	for v = 1 to objMesh.numverts do
	(
		local vert = (point3ForOpenGL (in coordsys local getVert objMesh v))
		format "%,%,%%" (fp vert.x) (fp vert.y) (fp vert.z) (if v != objMesh.numverts then ("," + sp) else "") to:stream
	)
	format "]" to:stream
	
	-- Vertex indices
	if (vertex_indices.count > 0) then
	(
		format ",%%\"vi\":%[%" nl (tabs 3) sp nl to:stream
		for index = 1 to vertex_indices.count do
		(
			format "%[%]%%" (tabs 4) (formatArray vertex_indices[index]) (if index != vertex_indices.count then "," else "") nl to:stream
		)
		format "%]" (tabs 3) to:stream
	)
	
	-- Face normals
	if (face_normals.count > 0) then
	(
		format ",%%\"fn\":%[%" nl (tabs 3) sp nl to:stream
		for index = 1 to face_normals.count do
		(
			format "%[%]%%" (tabs 4) (formatArray face_normals[index]) (if index != face_normals.count then "," else "") nl to:stream
		)
		format "%]" (tabs 3) to:stream
	)
	
	-- Texture UV
	if (objMesh.numTVerts > 0) then
	(
		format ",%%\"uv\":%[" nl (tabs 3) sp to:stream
		local tvert = (getTVert objMesh 1)
		for v = 1 to objMesh.numTVerts do
		(
			local tvert = (getTVert objMesh v)
			format "%,%%" (fp tvert.x) (fp tvert.y) (if v != objMesh.numTVerts then ("," + sp) else "") to:stream
		)
		format "]" to:stream
	)
	
	-- Texture UV indices
	if (uv_indices.count > 0) then
	(
		format ",%%\"ui\":%[" nl (tabs 3) sp to:stream
		for index = 1 to uv_indices.count do
		(
			format "%%%" (uv_indices[index] as integer) (if index != uv_indices.count then "," else "") sp to:stream
		)
		format "]" to:stream
	)
	
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
		
		-- Skin indices
		if (skinIndices.count > 0) then
		(
			format ",%%\"si\":%[%" nl (tabs 3) sp (skinIndices[1] as integer) to:stream
			for skinIndex = 2 to skinIndices.count do
			(
				format ",%" (skinIndices[skinIndex] as integer) to:stream
			)
			format "]" to:stream
		)
		
		-- Skin Weights
		if (skinWeights.count > 0) then
		(
			format ",%%\"sw\":%[%" nl (tabs 3) sp (fp skinWeights[1]) to:stream
			for skinIndex = 2 to skinWeights.count do
			(
				format ",%" (fp skinWeights[skinIndex]) to:stream
			)
			format "]" to:stream
		)
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
--debug false false true false
