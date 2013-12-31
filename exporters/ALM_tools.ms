--  MESH TOOLS

-- STRUCTURES
struct subMesh (name="", material=undefined, vertices=#(), vertex_indices=#(), normals=#(), colors=#(), uvs=#(), uv_indices=#(), skinIndices=#(), skinWeights=#(), bones=#())

-- FUNCTIONS
function processBoneForOneVertex mySkin mySubMesh vertID thebones =
(
	-- skin informations
	local vertex_bone_count = skinOps.GetVertexWeightCount mySkin vertID
	if (vertex_bone_count > 4) then
	(
		vertex_bone_count = 4
	)
	
	local bn2 = 1
	mySubMesh.skinIndices[vertID] = #()
	mySubMesh.skinWeights[vertID] = #()
	
	-- extract bone weight and index
	for bn1 = 1 to vertex_bone_count do
	(
		-- boneIndexes
		local bindex = skinops.getvertexweightboneid mySkin vertID bn1
		append mySubMesh.skinIndices[vertID] (bindex - 1)
		
		-- skinWeights
		local bweight = skinops.getvertexweight mySkin vertID bn1
		append mySubMesh.skinWeights[vertID] bweight
		
		--local bname = skinops.getbonename mySkin bn1 1
		--local b = getnodebyname bname
		
		bn2 = bn1
	)
	
	-- padding empty unused bone slots
	while bn2 < 4 do
	(
		append mySubMesh.skinIndices[vertID] 0
		append mySubMesh.skinWeights[vertID] 0
		bn2 = bn2  + 1
	)
)

function processMesh myObj =
(
	select myObj
	
	max modify mode
	
	local mySkin = myObj.modifiers[#skin]
	
	local myBones = #()
	if (mySkin != undefined) then
	(
		local bonesCount = skinops.getnumberbones mySkin
		for i = 1 to bonesCount do
		(
			local bname = skinops.getbonename mySkin i 1
			local b = getnodebyname bname
			append myBones b
		)
	)
	
	local myMesh = snapshotAsMesh myObj
	
	local mySubMesh = (subMesh name:myObj.name material:myObj.material bones:myBones)
	
	-- vertices
	for v = 1 to myMesh.numverts do
	(
		local vert = (getVert myMesh v) --* AXIS_TRANSFORM
		append mySubMesh.vertices (vert)
		
		-- skin indices / skin weights
		if (mySkin != undefined) then
		(
			processBoneForOneVertex mySkin mySubMesh v myBones
		)
	)
	
	-- texture vertices
	for v = 1 to myMesh.numTVerts do
	(
		local tvert = getTVert myMesh v
		append mySubMesh.uvs tvert
	)
	
	-- parse faces
	for f = 1 to myMesh.numfaces do
	(
		-- get face
		local face = getFace myMesh f
		
		-- processing for multi material
		local matID = getFaceMatID myMesh f
		
		-- create indices array of the submesh if not existing
		if (mySubMesh.vertex_indices[matID] == undefined) then
		(
			mySubMesh.vertex_indices[matID] = #()
		)
		
		-- vertex indices
		append mySubMesh.vertex_indices[matID] (face.x - 1)
		append mySubMesh.vertex_indices[matID] (face.y - 1)
		append mySubMesh.vertex_indices[matID] (face.z - 1)
		
		-- normals
		local normals = #()
		if (getfacesmoothgroup myMesh f) == 0 then
		(
			n = (in coordsys local getfacenormal myMesh f)
			normals = #(n, n, n)
		)
		else
		(
			normals = (in coordsys local meshop.getfacernormals myMesh f)
			
			if normals.count != 3 do
			(
				in coordsys local n = getfacenormal myMesh f
				normals = #(n, n, n)
			)
		)
		mySubMesh.normals[face.x] = normals[1]
		mySubMesh.normals[face.y] = normals[2]
		mySubMesh.normals[face.z] = normals[3]
		
		-- uv indices
		local tvface = GetTVFace myMesh f
		append mySubMesh.uv_indices (tvface.x - 1)
		append mySubMesh.uv_indices (tvface.y - 1)
		append mySubMesh.uv_indices (tvface.z - 1)
	)
	
	deselect myObj
	
	return mySubMesh
)

function processObjects myObjects =
(
	local mySubMeshes = #()
	
	for i = 1 to myObjects.count do
	(
		local myObj = myObjects[i]
		append mySubMeshes (processMesh myObj)
	)
	
	return mySubMeshes
)

function formatMaterial mat file =
(
	if ((classof mat) == MultiMaterial) then -- multi-material
	(
		format "\t\t{ " to:file
		format "\"name\":\"%\", " mat.name to:file
		format "\"multi\":[" to:file
		-- display sub-material names
		for i = 1 to mat.numsubs do
		(
			if (i > 1) then
			(
				format "," to:file
			)
			format "\"%\"" mat.materialList[i].name to:file
		)
		format "]" to:file
		format " }" to:file
		
		-- recursive parse of sub-materials
		for i = 1 to mat.numsubs do
		(
			format ",\n\t\t" to:file
			formatMaterial mat.materialList[i] file
		)
	)
	else -- standard material
	(
		format "{ " to:file
		format "\"name\":\"%\", " mat.name to:file
		if (mat.diffuseMap != undefined) then
		(
			textureFilePath = mat.diffuseMap.bitmap.filename
			tokens = (filterString textureFilePath "\\")
			textureFileName = tokens[tokens.count]
			format "\"texture\":\"%\", " textureFileName to:file
		)
		if (mat.twoSided == true) then
		(
			format "\"side\":\"double\", " to:file
		)
		format "\"ambient\":[%,%,%], " mat.ambient.r mat.ambient.g mat.ambient.b to:file
		format "\"diffuse\":[%,%,%], " mat.diffuse.r mat.diffuse.g mat.diffuse.b to:file
		format "\"specular\":[%,%,%], " mat.specular.r mat.specular.g mat.specular.b to:file
		format "\"opacity\":% " (mat.opacity / 100) to:file
		format "}" to:file
	)
)

function formatSubMesh mySubMesh file =
(	
	format "\t\t{\n" to:file
	
	format "\t\t\t\"name\":\"%\",\n" mySubMesh.name to:file

	if (mySubMesh.material != undefined) then
	(
		format "\t\t\t\"material\":\"%\",\n" mySubMesh.material.name to:file
	)
	
	-- Write vertices
	format "\t\t\t\"vertices\":[" to:file
	for v = 1 to mySubMesh.vertices.count do
	(
		local vert = mySubMesh.vertices[v]
		if (v != 1) then
		(
			format "," to:file
		)
		format "%,%,%" vert.x vert.y vert.z to:file
	)
	format "],\n" to:file

	-- Write indices
	format "\t\t\t\"vertex_indices\":[\n" to:file
	for i = 1 to mySubMesh.vertex_indices.count do
	(
		if (i != 1) then
		(
			format ",\n" to:file
		)
		format "\t\t\t\t[" to:file
		for j = 1 to mySubMesh.vertex_indices[i].count do
		(
			if (j != 1) then
			(
				format "," to:file
			)
			local index = mySubMesh.vertex_indices[i][j]
			format "%" (index as integer) to:file
		)
		format "]" to:file
	)
	format "\n\t\t\t]" to:file

	-- Write normals
	if (mySubMesh.normals.count > 0) then
	(
		format ",\n" to:file
		format "\t\t\t\"normals\":[" to:file
		for n = 1 to mySubMesh.normals.count do
		(
			local normal = mySubMesh.normals[n]
			if (n != 1) then
			(
				format "," to:file
			)
			format "%,%,%" normal.x normal.y normal.z to:file
		)
		format "]" to:file
	)

	-- Write colors
	if (mySubMesh.colors.count > 0) then
	(
		format ",\n" to:file
		format "\t\t\t\"colors\":[" to:file
		for c = 1 to mySubMesh.colors.count do
		(
			local colo = mySubMesh.colors[c]
			if (c != 1) then
			(
				format "," to:file
			)
			format "%,%,%,%" colo.r colo.v colo.b colo.a to:file
		)
		format "]" to:file
	)

	-- Write texture coords
	if (mySubMesh.uvs.count > 0) then
	(
		format ",\n" to:file
		format "\t\t\t\"uvs\":[" to:file
		for t = 1 to mySubMesh.uvs.count do
		(
			local uv = mySubMesh.uvs[t]
			if ( t != 1 ) then
			(
				format "," to:file
			)
			format "%,%" uv.x uv.y to:file
		)
		format "]" to:file
	)
	
	-- Write texture indices
	if (mySubMesh.uv_indices.count > 0) then
	(
		format ",\n" to:file
		format "\t\t\t\"uv_indices\":[" to:file
		for i = 1 to mySubMesh.uv_indices.count do
		(
			if (i != 1) then
			(
				format "," to:file
			)
			local index = mySubMesh.uv_indices[i]
			format "%" (index as integer) to:file
		)
		format "]" to:file
	)
	
	-- Write skinIndices
	if (mySubMesh.skinIndices.count != 0) then
	(
		format ",\n" to:file
		format "\t\t\t\"skinIndices\":[" to:file
		for bii = 1 to mySubMesh.skinIndices.count do
		(
			local bi = mySubMesh.skinIndices[bii]
			if (bii != 1) then
			(
				format "," to:file
			)
			format "%,%,%,%" bi[1] bi[2] bi[3] bi[4] to:file
		)
		format "]" to:file
	)
		
	-- Write skinWeights
	if (mySubMesh.skinWeights.count != 0) then
	(
		format ",\n" to:file
		format "\t\t\t\"skinWeights\":[" to:file
		for bwi = 1 to mySubMesh.skinWeights.count do
		(
			local bw = mySubMesh.skinWeights[bwi]
			if (bwi != 1) then
			(
				format "," to:file
			)
			format "%,%,%,%" bw[1] bw[2] bw[3] bw[4] to:file
		)
		format "]" to:file
	)
	
	if (mySubMesh.bones.count != 0) then
	(
		-- SKELETON IN A SEPARATE FILE?
		local skeleton_filepath = undefined
		local skeleton_file = file
		local separateSkeleton = queryBox ("Export the skeleton in a separate File?\n" + mySubMesh.name)
		if (separateSkeleton == true) then
		(
			skeleton_filepath = getSaveFileName caption:"Location for saving the Skeleton file" types:"JSON (*.json)|*.json|Plain Text (*.txt)|*.txt|All Files (*.*)|*.*|"
			skeleton_file = createFile skeleton_filepath
			format "{\n" to:skeleton_file
			format "\t\t\t\"name\":\"%\"" mySubMesh.name to:skeleton_file
		)
		
		-- Write bones hierarchy
		format ",\n" to:skeleton_file
		format "\t\t\t\"bones\":[\n" to:skeleton_file
		for bi = 1 to mySubMesh.bones.count do
		(
			local b = mySubMesh.bones[bi]
			if (bi != 1) then
			(
				format ",\n" to:skeleton_file
			)
			
			-- retrive parent boneID
			local parentBoneID = -1
			--local Mbone = (in coordsys parent b.transform)
			local Mbone = b.transform * AXIS_TRANSFORM
			local Mparent = undefined
			if (b.parent != undefined) then
			(
				Mparent = b.parent.transform * AXIS_TRANSFORM
				Mbone = (inverse Mparent) * Mbone
				for bi2 = 1 to mySubMesh.bones.count do
				(
					if (mySubMesh.bones[bi2].name == b.parent.name) then
					(
						parentBoneID = bi2 - 1
						break
					)
				)
			)
			
			format "\t\t\t\t{ \"name\":\"%\", " b.name to:skeleton_file
			-- parent
			format "\"parent\":%, " parentBoneID to:skeleton_file
			-- data
			/*format "\"pos\":%, " (formatVector3 Mbone.position) to:skeleton_file
			format "\"rot\":[0,0,0], " to:skeleton_file
			format "\"rotq\":%, " (formatQuaternion Mbone.rotation) to:skeleton_file
			format "\"scl\":% }" (formatVector3 Mbone.scale) to:skeleton_file*/
			format "\"pos\":%, " (in coordsys parent(formatVector3 b.position)) to:skeleton_file
			format "\"rot\":[0,0,0], " to:skeleton_file
			format "\"rotq\":%, " (in coordsys parent(formatQuaternion b.rotation)) to:skeleton_file
			format "\"scl\":% }" (in coordsys parent(formatVector3 b.scale)) to:skeleton_file
		)
		format "\n" to:skeleton_file
		format "\t\t\t]" to:skeleton_file
		
		if (separateSkeleton == true) then
		(
			format "\n" to:skeleton_file
			format "}\n" to:skeleton_file
			close skeleton_file
		)
	)
	
	format "\n" to:file
	format "\t\t}" to:file
)

function formatObjects mySubMeshes file =
(
	format "{\n" to:file
	
	-- materials
	format "\t\"materials\":[\n" to:file
	local matCount = 0
	for i = 1 to mySubMeshes.count do
	(
		local mySubMesh = mySubMeshes[i]
		local mat = mySubMesh.material
		if (mat != undefined) then
		(
			if (matCount > 1) then
			(
				format "\t\t,\n" to:file
			)
			
			format "\t\t"
			formatMaterial mat file
			matCount = matCount + 1
		)
	)
	format "\n\t],\n" to:file
	
	-- meshes
	format "\t\"meshes\":[\n" to:file
	local meshCount = 0
	for i = 1 to mySubMeshes.count do
	(
		local mySubMesh = mySubMeshes[i]
		if ((isBone mySubMesh) == false) then
		(
			if (meshCount > 1) then
			(
				format "\t\t,\n" to:file
			)
			
			formatSubMesh mySubMesh file
			meshCount = meshCount + 1
		)
	)
	format "\n" to:file
	format "\t]\n" to:file
	
	format "}\n" to:file
)
