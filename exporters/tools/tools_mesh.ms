--  MESH TOOLS

include "tools.ms"
include "tools_anim.ms"
include "InputStringDialog.ms"

-- STRUCTURES
struct meshjs (name="", material=undefined, vertices=#(), vertex_indices=#(), face_normals=#(), colors=#(), uvs=#(), uv_indices=#(), skinIndices=#(), skinWeights=#(), skinNames=#(), bones=#(), animData=undefined, position=point3, orientation=quat, scale=point3)

-- FUNCTIONS
function processBoneForOneVertex mySkin myMeshjs vertID =
(
	-- skin informations
	local vertex_bone_count = skinOps.GetVertexWeightCount mySkin vertID
	if (vertex_bone_count > 4) then
	(
		vertex_bone_count = 4
	)
	
	local bi = 1
	myMeshjs.skinIndices[vertID] = #()
	myMeshjs.skinWeights[vertID] = #()
	
	-- extract bone weight and index
	for bi = 1 to vertex_bone_count do
	(
		-- boneIndexes
		local bindex = skinOps.GetVertexWeightBoneID mySkin vertID bi
		append myMeshjs.skinIndices[vertID] (bindex-1)
		
		-- skinWeights
		local bweight = skinOps.GetVertexWeight mySkin vertID bi
		append myMeshjs.skinWeights[vertID] bweight
	)
	
	-- padding empty unused bone slots
	while bi < 4 do
	(
		append myMeshjs.skinIndices[vertID] 0
		append myMeshjs.skinWeights[vertID] 0
		bi += 1
	)
)

function processMesh myObj =
(
	local mySkin = myObj.modifiers[#skin]
	
	local myBones = #()
	if (mySkin != undefined) then
	(
		local bonesCount = skinOps.GetNumberBones mySkin
		for i = 1 to bonesCount do
		(
			local bname = skinOps.GetBoneName mySkin i 1
			local b = getNodeByName bname
			append myBones b
		)
	)
	
	local myMesh = myObj.mesh
	
	local myMeshjs = (meshjs name:myObj.name material:myObj.material bones:myBones)
	
	myMeshjs.position = (point3ForOpenGL myObj.position)
	myMeshjs.orientation = (quatForOpenGL myObj.rotation)
	myMeshjs.scale = (point3 myObj.scale.x myObj.scale.z myObj.scale.y)
	
	-- vertices
	for v = 1 to myMesh.numverts do
	(
		local vert = (point3ForOpenGL (in coordsys local getVert myMesh v))
		append myMeshjs.vertices (vert)
		
		-- skin indices / skin weights
		if (mySkin != undefined) then
		(
			processBoneForOneVertex mySkin myMeshjs v
		)
	)
	
	-- texture vertices
	for v = 1 to myMesh.numTVerts do
	(
		local tvert = getTVert myMesh v
		append myMeshjs.uvs tvert
	)
	
	-- parse faces
	for f = 1 to myMesh.numfaces do
	(
		-- get face
		local face = getFace myMesh f
		
		-- processing for multi material
		local matID = getFaceMatID myMesh f
		
		-- create indices array of the meshjs if not existing
		if (myMeshjs.vertex_indices[matID] == undefined) then
		(
			myMeshjs.vertex_indices[matID] = #()
			myMeshjs.face_normals[matID] = #()
		)
		
		-- vertex indices
		append myMeshjs.vertex_indices[matID] (face.x - 1)
		append myMeshjs.vertex_indices[matID] (face.y - 1)
		append myMeshjs.vertex_indices[matID] (face.z - 1)
		
		-- normals
		append myMeshjs.face_normals[matID] (point3ForOpenGL (getfacenormal myMesh f))
		
		-- uv indices
		if (getNumTVerts myMesh > 0) then
		(
			local tvface = GetTVFace myMesh f
			append myMeshjs.uv_indices (tvface.x - 1)
			append myMeshjs.uv_indices (tvface.y - 1)
			append myMeshjs.uv_indices (tvface.z - 1)
		)
	)
	
	return myMeshjs
)

function processObjects myObjects =
(
	local myMeshes = #()
	local animCount = 1
	
	for i = 1 to myObjects.count do
	(
		local myObj = myObjects[i]
		select myObj
		max modify mode
		
		local myMeshjs = processMesh myObj
		
		if (myObj.modifiers[#skin] != undefined) then
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
			myMeshjs.animData = processAnimatedObject myObj
			myMeshjs.animData.name = animName
		)
		
		append myMeshes myMeshjs
	)
	
	return myMeshes
)

function formatMaterial mat file =
(
	if ((classof mat) == MultiMaterial) then
	(
		format "{ " to:file
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
	else if ((classof mat) == PhysicalMaterial) then
	(
		format "{ " to:file
		format "\"name\":\"%\", " mat.name to:file
		if (mat.base_color_map != undefined) then
		(
			textureFilePath = mat.base_color_map.bitmap.filename
			tokens = (filterString textureFilePath "\\")
			textureFileName = tokens[tokens.count]
			format "\"texture\":\"%\", " textureFileName to:file
		)
		format "\"ambient\":[%,%,%], " (toFixed mat.Base_Color.r) (toFixed mat.Base_Color.g) (toFixed mat.Base_Color.b) to:file
		format "\"diffuse\":[%,%,%], " (toFixed mat.Base_Color.r) (toFixed mat.Base_Color.g) (toFixed mat.Base_Color.b) to:file
		format "\"opacity\":%" (toFixed (1 - mat.Transparency)) to:file
		format " }" to:file
	)
	else if ((classof mat) == Standardmaterial) then
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
		format "\"ambient\":[%,%,%], " (toFixed mat.ambient.r) (toFixed mat.ambient.g) (toFixed mat.ambient.b) to:file
		format "\"diffuse\":[%,%,%], " (toFixed mat.diffuse.r) (toFixed mat.diffuse.g) (toFixed mat.diffuse.b) to:file
		format "\"specular\":[%,%,%], " (toFixed mat.specular.r) (toFixed mat.specular.g) (toFixed mat.specular.b) to:file
		format "\"opacity\":%" (toFixed (mat.opacity / 100)) to:file
		format " }" to:file
	)
)

function formatMeshjs myMeshjs file =
(
	print ("write " + myMeshjs.name)
	format "\t\t{\n" to:file
	
	format "\t\t\t\"name\":\"%\",\n" myMeshjs.name to:file

	if (myMeshjs.material != undefined) then
	(
		format "\t\t\t\"material\":\"%\",\n" myMeshjs.material.name to:file
	)
	
	format "\t\t\t\"position\":%,\n" myMeshjs.position to:file
	format "\t\t\t\"orientation\":%,\n" (formatQuaternion myMeshjs.orientation) to:file
	format "\t\t\t\"scale\":%,\n" myMeshjs.scale to:file
	
	-- Write vertices
	format "\t\t\t\"vertex_positions\":[%],\n" (implodePoint3 "," myMeshjs.vertices) to:file

	-- Write indices
	format "\t\t\t\"vertex_indices\":[\n" to:file
	local arrCount = 0
	for i = 1 to myMeshjs.vertex_indices.count do
	(
		if (myMeshjs.vertex_indices[i] != undefined) then
		(
			if (arrCount != 0) then
			(
				format ",\n" to:file
			)
			format "\t\t\t\t[%]" (implodeInteger "," myMeshjs.vertex_indices[i]) to:file
			arrCount += 1
		)
	)
	format "\n\t\t\t],\n" to:file

	-- Write normals
	format "\t\t\t\"face_normals\":[\n" to:file
	local arrCount = 0
	for i = 1 to myMeshjs.face_normals.count do
	(
		if (myMeshjs.face_normals[i] != undefined) then
		(
			if (arrCount != 0) then
			(
				format ",\n" to:file
			)
			format "\t\t\t\t[%]" (implodePoint3 "," myMeshjs.face_normals[i]) to:file
			arrCount += 1
		)
	)
	format "\n\t\t\t]" to:file

	-- Write colors
	if (myMeshjs.colors.count > 0) then
	(
		format ",\n" to:file
		format "\t\t\t\"colors\":[" to:file
		for c = 1 to myMeshjs.colors.count do
		(
			local colo = myMeshjs.colors[c]
			if (c != 1) then
			(
				format "," to:file
			)
			format "%,%,%,%" colo.r colo.v colo.b colo.a to:file
		)
		format "]" to:file
	)

	-- Write texture coords
	if (myMeshjs.uvs.count > 0) then
	(
		format ",\n" to:file
		format "\t\t\t\"uv\":[" to:file
		for t = 1 to myMeshjs.uvs.count do
		(
			local uv = myMeshjs.uvs[t]
			if ( t != 1 ) then
			(
				format "," to:file
			)
			format "%,%" (toFixed uv.x) (toFixed uv.y) to:file
		)
		format "]" to:file
	)
	
	-- Write texture indices
	if (myMeshjs.uv_indices.count > 0) then
	(
		format ",\n" to:file
		format "\t\t\t\"uv_indices\":[" to:file
		for i = 1 to myMeshjs.uv_indices.count do
		(
			if (i != 1) then
			(
				format "," to:file
			)
			local index = myMeshjs.uv_indices[i]
			format "%" (index as integer) to:file
		)
		format "]" to:file
	)
	
	-- Write skinIndices
	if (myMeshjs.skinIndices.count != 0) then
	(
		format ",\n" to:file
		format "\t\t\t\"skin_indices\":[" to:file
		for si = 1 to myMeshjs.skinIndices.count do
		(
			local s = myMeshjs.skinIndices[si]
			if (si != 1) then
			(
				format "," to:file
			)
			format "%,%,%,%" s[1] s[2] s[3] s[4] to:file
		)
		format "]" to:file
	)
	
	-- Write skinWeights
	if (myMeshjs.skinWeights.count != 0) then
	(
		format ",\n" to:file
		format "\t\t\t\"skin_weights\":[" to:file
		for bwi = 1 to myMeshjs.skinWeights.count do
		(
			local bw = myMeshjs.skinWeights[bwi]
			if (bwi != 1) then
			(
				format "," to:file
			)
			format "%,%,%,%" (toFixed bw[1]) (toFixed bw[2]) (toFixed bw[3]) (toFixed bw[4]) to:file
		)
		format "]" to:file
	)
	
	if (myMeshjs.bones.count != 0) then
	(
		-- SKELETON IN A SEPARATE FILE?
		local skeleton_filepath = undefined
		local skeleton_file = file
		-- NOT YET IMPLEMENTED IN LOADER
		/*local separateSkeleton = queryBox ("Export the skeleton in a separate File?\n" + myMeshjs.name)
		if (separateSkeleton == true) then
		(
			skeleton_filepath = getSaveFileName caption:"Location for saving the Skeleton file" types:"JSON (*.json)|*.json|Plain Text (*.txt)|*.txt|All Files (*.*)|*.*|"
			skeleton_file = createFile skeleton_filepath
			format "{\n" to:skeleton_file
			format "\t\t\t\"name\":\"%\"" myMeshjs.name to:skeleton_file
		)*/
		
		-- Write bones hierarchy
		format ",\n" to:skeleton_file
		format "\t\t\t\"skin\":[\n" to:skeleton_file
		for bi = 1 to myMeshjs.bones.count do
		(
			local b = myMeshjs.bones[bi]
			if (bi != 1) then
			(
				format ",\n" to:skeleton_file
			)
			
			-- retrive parent boneID
			local parentBoneID = -1
			if (b.parent != undefined) then
			(
				for bi2 = 1 to myMeshjs.bones.count do
				(
					if (myMeshjs.bones[bi2].name == b.parent.name) then
					(
						parentBoneID = bi2 - 1
						break
					)
				)
			)
			
			-- get the transform converted to OpenGL axis
			local newTransform = (getRelativeTransformForOpenGL b)
			
			format "\t\t\t\t{ \"name\":\"%\", " b.name to:skeleton_file
			-- parent
			format "\"parent\":%, " parentBoneID to:skeleton_file
			-- data
			format "\"pos\":%, " (formatVector3 newTransform.position) to:skeleton_file
			format "\"rot\":[0,0,0], " to:skeleton_file
			-- quaternion is inversed because of rotations are inversed in maxscript
			-- cf. http://docs.autodesk.com/3DSMAX/15/ENU/MAXScript-Help/index.html?url=files/GUID-3B001F21-8FE9-4663-A972-E648682A0ACD.htm,topicNumber=d30e272529
			format "\"rotq\":%, " (formatQuaternion (inverse newTransform.rotation)) to:skeleton_file
			format "\"scl\":% }" (formatVector3 newTransform.scale) to:skeleton_file
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

function formatObjects myMeshes file =
(
	local someDataInserted = false
	
	format "{\n" to:file
	
	-- materials
	local materials = #()
	for i = 1 to myMeshes.count do
	(
		local myMeshjs = myMeshes[i]
		local mat = myMeshjs.material
		if (mat != undefined) then
		(
			append materials mat
		)
	)
	if (materials.count > 0) then
	(
		if (someDataInserted == true) then
		(
			format ",\n" to:file
		)
		format "\t\"materials\":[\n" to:file
		for i = 1 to materials.count do
		(
			local mat = materials[i]
			if (i > 1) then
			(
				format ",\n" to:file
			)
			format "\t\t" to:file
			formatMaterial mat file
		)
		format "\n\t]" to:file
		someDataInserted = true
	)
	
	-- meshes
	if (myMeshes.count > 0) then
	(
		if (someDataInserted == true) then
		(
			format ",\n" to:file
		)
		format "\t\"meshes\":[\n" to:file
		local meshCount = 0
		for i = 1 to myMeshes.count do
		(
			local myMeshjs = myMeshes[i]
			if ((isBone myMeshjs) == false) then
			(
				if (meshCount > 0) then
				(
					format ",\n" to:file
				)
				formatMeshjs myMeshjs file
				meshCount += 1
			)
		)
		format "\n\t]" to:file
		someDataInserted = true
	)
	
	-- animations
	local animations = #()
	for i = 1 to myMeshes.count do
	(
		local myMeshjs = myMeshes[i]
		if (((isBone myMeshjs) == false) and (myMeshjs.animData != undefined)) then
		(
			append animations myMeshjs.animData
		)
	)
	if (animations.count > 0) then
	(
		if (someDataInserted == true) then
		(
			format ",\n" to:file
		)
		format "\t\"animations\":[\n" to:file
		for i = 1 to animations.count do
		(
			local anim = animations[i]
			if (i > 1) then
			(
				format ",\n" to:file
			)
			formatAnimatedObject anim file
		)
		format "\t]" to:file
		someDataInserted = true
	)
	
	format "\n}\n" to:file
)
