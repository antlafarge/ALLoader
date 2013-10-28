-- MESH EXPORTER (ALM)

clearListener()

struct subMesh (name = "", material = undefined, vertices = #(), indices = #(), normals = #(), colors = #(), uvs = #(), skinIndices = #(), skinWeights = #(), bones = #())

global MAT_TRANSFORM = matrix3 [1,0,0] [0,0,-1] [0,1,0] [0,0,0]

function isGeometry o =
(
	return (((Superclassof o) == GeometryClass) and ((classof o) != BoneGeometry))
)

function isBone o =
(
	return ((classof o) == BoneGeometry)
)

function formatVector3 v =
(
	v3str = stringStream ""
	format "[%,%,%]" v.x v.y v.z to:v3str
	return (v3str as string)
)

function formatQuaternion q =
(
	qstr = stringStream ""
	format "[%,%,%,%]" q.x q.y q.z q.w to:qstr
	return (qstr as string)
)

function formatMaterial mat str =
(
	if (str == undefined) then
	(
		str = stringStream ""
	)
	
	if ((classof mat) == MultiMaterial) then -- multi-material
	(
		format "{ " to:str
		format "\"name\":\"%\", " mat.name to:str
		format "\"multi\":[" to:str
		-- display sub-material names
		for i = 1 to mat.numsubs do
		(
			if (i > 1) then
			(
				format "," to:str
			)
			format "\"%\"" mat.materialList[i].name to:str
		)
		format "]" to:str
		format " }" to:str
		
		-- recursive parse of sub-materials
		for i = 1 to mat.numsubs do
		(
			format ",\n\t\t%" (formatMaterial mat.materialList[i] undefined) to:str
		)
	)
	else -- standard material
	(
		format "{ " to:str
		format "\"name\":\"%\", " mat.name to:str
		if (mat.diffuseMap != undefined) then
		(
			textureFilePath = mat.diffuseMap.bitmap.filename
			tokens = (filterString textureFilePath "\\")
			textureFileName = tokens[tokens.count]
			format "\"texture\":\"%\", " textureFileName to:str
		)
		if (mat.twoSided == true) then
		(
			format "\"side\":\"double\", " to:str
		)
		format "\"ambient\":[%,%,%], " mat.ambient.r mat.ambient.g mat.ambient.b to:str
		format "\"diffuse\":[%,%,%], " mat.diffuse.r mat.diffuse.g mat.diffuse.b to:str
		format "\"specular\":[%,%,%], " mat.specular.r mat.specular.g mat.specular.b to:str
		format "\"opacity\":% " (mat.opacity / 100) to:str
		format "}" to:str
	)
	
	return (str as string)
)

function processBoneForOneVertex mySkin mySubMesh vertID thebones =
(
	-- skin informations
	vertex_bone_count = skinOps.GetVertexWeightCount mySkin vertID
	if (vertex_bone_count > 4) then
	(
		vertex_bone_count = 4
	)
	
	bn2 = 1
	mySubMesh.skinIndices[vertID] = #()
	mySubMesh.skinWeights[vertID] = #()
	
	for bn1 = 1 to vertex_bone_count do
	(
		-- boneIndexes
		bindex = skinops.getvertexweightboneid mySkin vertID bn1
		append mySubMesh.skinIndices[vertID] (bindex - 1)
		
		-- skinWeights
		bweight = skinops.getvertexweight mySkin vertID bn1
		append mySubMesh.skinWeights[vertID] bweight
		
		--bname = skinops.getbonename mySkin bn1 1
		--b = getnodebyname bname
		
		bn2 = bn1
	)
	while bn2 < 4 do -- padding empty unused bone slots
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
	
	mySkin = myObj.modifiers[#skin]
	
	myBones = #()
	if (mySkin != undefined) then
	(
		bonesCount = skinops.getnumberbones mySkin
		for i = 1 to bonesCount do
		(
			bname = skinops.getbonename mySkin i 1
			b = getnodebyname bname
			append myBones b
		)
	)
	
	myMesh = snapshotAsMesh myObj
	
	mySubMesh = subMesh name:myObj.name material:myObj.material bones:myBones
	
	for f = 1 to myMesh.numfaces do
	(
		-- Face
		face = getFace myMesh f
		
		-- processing for multi material
		matID = getFaceMatID myMesh f
		
		-- create indices array of the submesh if not existing
		if (mySubMesh.indices[matID] == undefined) then
		(
			mySubMesh.indices[matID] = #()
		)
		
		-- Indices
		append mySubMesh.indices[matID] (face.x - 1)
		append mySubMesh.indices[matID] (face.y - 1)
		append mySubMesh.indices[matID] (face.z - 1)
		
		-- Vertices
		v1 = (getVert myMesh face.x) --* MAT_TRANSFORM
		v2 = (getVert myMesh face.y) --* MAT_TRANSFORM
		v3 = (getVert myMesh face.z) --* MAT_TRANSFORM
		mySubMesh.vertices[face.x] = v1
		mySubMesh.vertices[face.y] = v2
		mySubMesh.vertices[face.z] = v3
		
		-- Normals
		normals = #()
		if (getfacesmoothgroup myMesh f) == 0 then
		(
			in coordsys local n = getfacenormal myMesh f
			normals = #(n, n, n)
		)
		else
		(
			in coordsys local normals = (meshop.getfacernormals myMesh f)
			
			if normals.count != 3 do
			(
				in coordsys local n = getfacenormal myMesh f
				normals = #(n, n, n)
			)
		)
		mySubMesh.normals[face.x] = normals[1]
		mySubMesh.normals[face.y] = normals[2]
		mySubMesh.normals[face.z] = normals[3]
		
		-- Colors
		--mySubMesh.colors[face.x] = color 1 1 1 1
		--mySubMesh.colors[face.y] = color 1 1 1 1
		--mySubMesh.colors[face.z] = color 1 1 1 1
		
		-- UVs
		t1 = getTVert myMesh face.x
		t2 = getTVert myMesh face.y
		t3 = getTVert myMesh face.z
		mySubMesh.uvs[face.x] = t1
		mySubMesh.uvs[face.y] = t2
		mySubMesh.uvs[face.z] = t3
		
		if (mySkin != undefined) then
		(
			processBoneForOneVertex mySkin mySubMesh face.x myBones
			processBoneForOneVertex mySkin mySubMesh face.y myBones
			processBoneForOneVertex mySkin mySubMesh face.z myBones
		)
	)
	
	deselect myObj
	
	return mySubMesh
)

function formatSubMesh mySubMesh =
(
	str = stringStream ""
	
	format "\t\t{\n" to:str
	
	format "\t\t\t\"name\":\"%\",\n" mySubMesh.name to:str

	if (mySubMesh.material != undefined) then
	(
		format "\t\t\t\"material\":\"%\",\n" mySubMesh.material.name to:str
	)
	
	-- Write vertices
	format "\t\t\t\"vertices\":[" to:str
	for v = 1 to mySubMesh.vertices.count do
	(
		vert = mySubMesh.vertices[v]
		if (v != 1) then
		(
			format "," to:str
		)
		format "%,%,%" vert.x vert.y vert.z to:str
	)
	format "],\n" to:str

	-- Write indices
	format "\t\t\t\"indices\":[\n" to:str
	for i = 1 to mySubMesh.indices.count do
	(
		if (i != 1) then
		(
			format ",\n" to:str
		)
		format "\t\t\t\t[" to:str
		for j = 1 to mySubMesh.indices[i].count do
		(
			if (j != 1) then
			(
				format "," to:str
			)
			index = mySubMesh.indices[i][j]
			format "%" (index as integer) to:str
		)
		format "]" to:str
	)
	format "\n\t\t\t]" to:str

	-- Write normals
	if (mySubMesh.normals.count > 0) then
	(
		format ",\n" to:str
		format "\t\t\t\"normals\":[" to:str
		for n = 1 to mySubMesh.normals.count do
		(
			normal = mySubMesh.normals[n]
			if (n != 1) then
			(
				format "," to:str
			)
			format "%,%,%" normal.x normal.y normal.z to:str
		)
		format "]" to:str
	)

	-- Write colors
	if (mySubMesh.colors.count > 0) then
	(
		format ",\n" to:str
		format "\t\t\t\"colors\":[" to:str
		for c = 1 to mySubMesh.colors.count do
		(
			colo = mySubMesh.colors[c]
			if (c != 1) then
			(
				format "," to:str
			)
			format "%,%,%,%" colo.r colo.v colo.b colo.a to:str
		)
		format "]" to:str
	)

	-- Write texture coords
	if (mySubMesh.uvs.count > 0) then
	(
		format ",\n" to:str
		format "\t\t\t\"uvs\":[" to:str
		for t = 1 to mySubMesh.uvs.count do
		(
			uv = mySubMesh.uvs[t]
			if ( t != 1 ) then
			(
				format "," to:str
			)
			format "%,%" uv.x uv.y to:str
		)
		format "]" to:str
	)
	
	if ((mySubMesh.skinIndices.count != 0) and (mySubMesh.skinWeights.count != 0) and (mySubMesh.bones.count != 0)) then
	(
		-- Write skinIndices
		format ",\n" to:str
		format "\t\t\t\"skinIndices\":[" to:str
		for bii = 1 to mySubMesh.skinIndices.count do
		(
			bi = mySubMesh.skinIndices[bii]
			if (bii != 1) then
			(
				format "," to:str
			)
			format "%,%,%,%" bi[1] bi[2] bi[3] bi[4] to:str
		)
		format "]" to:str
		
		-- Write skinWeights
		format ",\n" to:str
		format "\t\t\t\"skinWeights\":[" to:str
		for bwi = 1 to mySubMesh.skinWeights.count do
		(
			bw = mySubMesh.skinWeights[bwi]
			if (bwi != 1) then
			(
				format "," to:str
			)
			format "%,%,%,%" bw[1] bw[2] bw[3] bw[4] to:str
		)
		format "]" to:str
		
		-- Write bones hierarchy
		format ",\n" to:str
		format "\t\t\t\"bones\":[\n" to:str
		for bi = 1 to mySubMesh.bones.count do
		(
			b = mySubMesh.bones[bi]
			if (bi != 1) then
			(
				format ",\n" to:str
			)
			
			-- retrive parent boneID
			parentBoneID = -1
			if (b.parent != undefined) then
			(
				for bi2 = 1 to mySubMesh.bones.count do
				(
					if (mySubMesh.bones[bi2].name == b.parent.name) then
					(
						parentBoneID = bi2 - 1
						break
					)
				)
			)
			
			format "\t\t\t\t{ \"name\":\"%\", " b.name to:str
			-- parent
			format "\"parent\":%, " parentBoneID to:str
			
			-- data
			format "\"pos\":%, " (in coordsys parent(formatVector3 b.position)) to:str
			format "\"rot\":[0,0,0], " to:str
			format "\"rotq\":%, " (in coordsys parent(formatQuaternion b.rotation)) to:str
			format "\"scl\":% }" (in coordsys parent(formatVector3 b.scale)) to:str
		)
		format "\n" to:str
		format "\t\t\t]" to:str
	)
	
	format "\n" to:str
	format "\t\t}" to:str
	
	return (str as string)
)

-- MAIN
--clearListener()

filepath = GetSaveFileName()
if (filepath == undefined) then
(
	exit
)

-- DELETE AND CREATE FILE
deleteFile filepath
global file = createFile filepath

mySelection = getCurrentSelection()

-- START FILE
format "{\n" to:file

-- MATERIALS
format "\t\"materials\":[\n" to:file
matCount = 0
for i = 1 to mySelection.count do
(
	myObj = mySelection[i]
	
	mat = myObj.material
	if mat != undefined then
	(
		if matCount > 1 then
		(
			format "\t\t,\n" to:file
		)
		
		format "\t\t%" (formatMaterial mat undefined) to:file
		matCount = matCount + 1
	)
)
format "\n\t],\n" to:file

-- MESHES
format "\t\"meshes\":[\n" to:file
meshCount = 0
for i = 1 to mySelection.count do
(
	myObj = mySelection[i]
	
	ib = (isBone myObj) 
	if (ib == false) then
	(
		if meshCount > 1 then
		(
			format "\t\t,\n" to:file
		)
	
		mySubMesh = processMesh myObj
		
		format "%" (formatSubMesh mySubMesh) to:file
	)
)
format "\n" to:file
format "\t]\n" to:file

-- END FILE
format "}\n" to:file

-- CLOSE FILE
close file

select mySelection
