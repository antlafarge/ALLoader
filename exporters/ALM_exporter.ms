-- MESH EXPORTER (ALM)

clearListener()

struct subMesh (name = "", matID = undefined, material = undefined, indexCount = 0, materialName = "", vertices = #(), indices = #(), normals = #(), colors = #(), uvs = #(), skinIndices = #(), skinWeights = #(), skinNames = #(), skinIndices2 = #(), bones = #())

--global MAT_TRANSFORM = matrix3 [1,0,0] [0,0,-1] [0,1,0] [0,0,0]
global MAT_TRANSFORM = matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0]

function isGeometry o =
(
	return (((Superclassof o) == GeometryClass) and ((classof o) != BoneGeometry))
)

function isBone o =
(
	return ((classof o) == BoneGeometry)
)

function pf3 f =
(
	--return ((ceil (f * 10000)) / 10000) 
	return f
)

function formatVector3 v =
(
	x = pf3 v.x
	y = pf3 v.y
	z = pf3 v.z
	v3str = stringStream ""
	format "[%,%,%]" x y z to:v3str
	return (v3str as string)
)

function formatQuaternion q =
(
	x = pf3 q.x
	y = pf3 q.y
	z = pf3 q.z
	w = pf3 q.w
	qstr = stringStream ""
	format "[%,%,%,%]" x y z w to:qstr
	return (qstr as string)
)

function formatMatrix3 m =
(
	m1x = pf3 m.row1.x
	m1y = pf3 m.row1.y
	m1z = pf3 m.row1.z
	m2x = pf3 m.row2.x
	m2y = pf3 m.row2.y
	m2z = pf3 m.row2.z
	m3x = pf3 m.row3.x
	m3y = pf3 m.row3.y
	m3z = pf3 m.row3.z
	m4x = pf3 m.row4.x
	m4y = pf3 m.row4.y
	m4z = pf3 m.row4.z
	m3str = stringStream ""
	format "[%,%,%,%,%,%,%,%,%,%,%,%]" m1x m1y m1z m2x m2y m2z m3x m3y m3z m4x m4y m4z to:m3str
	return (m3str as string)
)

function formatMaterial mat str =
(
	if (str == undefined) then
	(
		str = stringStream ""
	)
	
	if ((classof mat) == MultiMaterial) then -- multi-material
	(
		for i = 1 to mat.numsubs do
		(
			if (i > 1) then
			(
				format ",\n" to:str
			)
			formatMaterial mat.materialList[i] str
		)
	)
	else -- standard material
	(
		format "\t\t{\n" to:str
		format "\t\t\t\"name\":\"%\",\n" mat.name to:str
		if (mat.diffuseMap != undefined) then
		(
			textureFilePath = mat.diffuseMap.bitmap.filename
			tokens = (filterString textureFilePath "\\")
			textureFileName = tokens[tokens.count]
			format "\t\t\t\"texture\":\"%\",\n" textureFileName to:str
		)
		format "\t\t\t\"ambient\":[%,%,%],\n" mat.ambient.r mat.ambient.g mat.ambient.b to:str
		format "\t\t\t\"diffuse\":[%,%,%],\n" mat.diffuse.r mat.diffuse.g mat.diffuse.b to:str
		format "\t\t\t\"specular\":[%,%,%],\n" mat.specular.r mat.specular.g mat.specular.b to:str
		format "\t\t\t\"opacity\":%\n" (mat.opacity / 100) to:str
		format "\t\t}" to:str
	)
	
	return (str as string)
)

function getBoneID thebones bonename =
(
	for tbi = 1 to thebones.count do
	(
		if (thebones[tbi].name == bonename) then
		(
			return (tbi - 1)
		)
	)
	
	return -1
)

global reindexer = #()

function processBoneForOneVertex mySkin mySubMesh vertID thebones =
(
	-- skin informations
	vertex_bone_count = skinOps.GetVertexWeightCount mySkin vertID
	if (vertex_bone_count > 4) then
	(
		vertex_bone_count = 4
	)
	
	bn2 = 1
	mySubMesh.skinIndices[reindexer[vertID]+1] = #()
	mySubMesh.skinWeights[reindexer[vertID]+1] = #()
	/*if (mySubMesh.skinNames[reindexer[vertID]+1] == undefined) then
	(
		mySubMesh.skinNames[reindexer[vertID]+1] = #()
	)
	mySubMesh.skinIndices2[reindexer[vertID]+1] = #()*/
	
	for bn1 = 1 to vertex_bone_count do
	(
		-- boneIndexes
		bindex = skinops.getvertexweightboneid mySkin vertID bn1
		append mySubMesh.skinIndices[reindexer[vertID]+1] (bindex - 1)
		
		-- skinWeights
		bweight = skinops.getvertexweight mySkin vertID bn1
		append mySubMesh.skinWeights[reindexer[vertID]+1] bweight
		
		-- bones
		/*bname = skinops.getbonename mySkin bn1 1
		b = getnodebyname bname
		append mySubMesh.skinNames[reindexer[vertID]+1] b.name
		bindex2 = getBoneID thebones bname
		append mySubMesh.skinIndices2[reindexer[vertID]+1] bindex2*/
		
		bn2 = bn1
	)
	while bn2 < 4 do -- padding empty unused bone slots
	(
		append mySubMesh.skinIndices[reindexer[vertID]+1] 0
		append mySubMesh.skinWeights[reindexer[vertID]+1] 0
		--append mySubMesh.skinNames[reindexer[vertID]+1] ""
		--append mySubMesh.skinIndices2[reindexer[vertID]+1] 0
		bn2 = bn2  + 1
	)
)

function processMesh myObj mat =
(
	reindexer = #()
	
	myMesh = /*snapshotAsMesh*/ myObj
	
	select myMesh
	max modify mode
	
	mySkin = myMesh.modifiers[#skin]
	
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
	
	allSubMeshes = #()
	
	for f = 1 to myMesh.numfaces do
	(
		-- Face
		face = getFace myMesh f
		-- MatID
		matID = getFaceMatID myMesh f
		if (classof mat == Multimaterial) then
		(
			mySubMat = mat.materialList[matID]
		)
		else
		(
			mySubMat = mat
		)
		
		-- get / create submesh
		found = false
		mySubMesh = undefined
		for i = 1 to allSubMeshes.count do
		(
			if (allSubMeshes[i].matID == matID) then
			(
				mySubMesh = allSubMeshes[i]
				found = true
				break
			)
		)
		if (found == false) then
		(
			mySubMesh = (subMesh name:myMesh.name matID:matID material:mySubMat bones:myBones)
			append allSubMeshes mySubMesh
		)
		
		if ((mySkin != undefined) and (mySubMesh.bones == undefined)) then
		(
			mySubMesh.bones = bonesArray
		)
		
		-- Indices
		/*append mySubMesh.indices face.x
		append mySubMesh.indices face.y
		append mySubMesh.indices face.z*/
		
		append mySubMesh.indices (mySubMesh.indexCount  )
		reindexer[face.x] = mySubMesh.indexCount
		
		append mySubMesh.indices (mySubMesh.indexCount+1)
		reindexer[face.y] = mySubMesh.indexCount + 1
		
		append mySubMesh.indices (mySubMesh.indexCount+2)
		reindexer[face.z] = mySubMesh.indexCount + 2
		
		mySubMesh.indexCount += 3;
		
		-- Vertices
		v1 = getVert myMesh face.x
		v2 = getVert myMesh face.y
		v3 = getVert myMesh face.z
		v1 = v1 * MAT_TRANSFORM
		v2 = v2 * MAT_TRANSFORM
		v3 = v3 * MAT_TRANSFORM
		mySubMesh.vertices[reindexer[face.x]+1] = v1
		mySubMesh.vertices[reindexer[face.y]+1] = v2
		mySubMesh.vertices[reindexer[face.z]+1] = v3
		
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
		mySubMesh.normals[reindexer[face.x]+1] = normals[1]
		mySubMesh.normals[reindexer[face.y]+1] = normals[2]
		mySubMesh.normals[reindexer[face.z]+1] = normals[3]
		
		-- Colors
		mySubMesh.colors[reindexer[face.x]+1] = color 1 1 1 1
		mySubMesh.colors[reindexer[face.y]+1] =color 1 1 1 1
		mySubMesh.colors[reindexer[face.z]+1] = color 1 1 1 1
		
		-- UVs
		t1 = getTVert myMesh face.x
		t2 = getTVert myMesh face.y
		t3 = getTVert myMesh face.z
		mySubMesh.uvs[reindexer[face.x]+1] = t1
		mySubMesh.uvs[reindexer[face.y]+1] = t2
		mySubMesh.uvs[reindexer[face.z]+1] = t3
		
		if (mySkin != undefined) then
		(
			processBoneForOneVertex mySkin mySubMesh face.x myBones
			processBoneForOneVertex mySkin mySubMesh face.y myBones
			processBoneForOneVertex mySkin mySubMesh face.z myBones
		)
	)
	
	if (allSubMeshes.count > 1) then
	(
		for sm = 1 to allSubMeshes.count do
		(
			allSubMeshes[sm].name = (allSubMeshes[sm].name + "_" + (sm as string))
		)
	)
	
	deselect myMesh
	
	return allSubMeshes
)

function formatSubMesh mySubMesh mat =
(
	str = stringStream ""
	
	format "\t\t{\n" to:str
	
	format "\t\t\t\"name\":\"%\",\n" mySubMesh.name to:str

	if (mat != undefined) then
	(
		format "\t\t\t\"material\":\"%\",\n" mat.name to:str
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
	format "\t\t\t\"indices\":[" to:str
	for i = 1 to mySubMesh.indices.count do
	(
		index = mySubMesh.indices[i]
		format "%" (index as integer) to:str
		if (i != mySubMesh.indices.count) then
		(
			format "," to:str
		)
	)
	format "],\n" to:str

	-- Write normals
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
	format "],\n" to:str

	-- Write colors
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
	format "],\n" to:str

	-- Write texture coords
	format "\t\t\t\"texcoord\":[" to:str
	for t = 1 to mySubMesh.uvs.count do
	(
		uv = mySubMesh.uvs[t]
		if ( t != 1 ) then
		(
			format "," to:str
		)
		format "%,%" uv.x uv.y to:str
	)
	format "],\n" to:str
	
	if ((mySubMesh.skinIndices.count != 0) and (mySubMesh.skinWeights.count != 0) and (mySubMesh.bones.count != 0)) then
	(
		-- Write skinIndices
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
		format "],\n" to:str
		
		-- Write skinNames
		/*format "\t\t\t\"skinNames\":[" to:str
		for bni = 1 to mySubMesh.skinNames.count do
		(
			bn = mySubMesh.skinNames[bni]
			if (bni != 1) then
			(
				format "," to:str
			)
			format "\"%\",\"%\",\"%\",\"%\"" bn[1] bn[2] bn[3] bn[4] to:str
		)
		format "],\n" to:str*/
		
		-- Write skinIndices
		/*format "\t\t\t\"skinIndices\":[" to:str
		for bii = 1 to mySubMesh.skinIndices2.count do
		(
			bi = mySubMesh.skinIndices2[bii]
			if (bii != 1) then
			(
				format "," to:str
			)
			format "%,%,%,%" bi[1] bi[2] bi[3] bi[4] to:str
		)
		format "],\n" to:str*/
		
		-- Write skinWeights
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
		format "],\n" to:str
		
		-- Write bones hierarchy
		format "\t\t\t\"bones\":[\n" to:str
		for bi = 1 to mySubMesh.bones.count do
		(
			b = mySubMesh.bones[bi]
			if (bi != 1) then
			(
				format ",\n" to:str
			)
			
			parentBoneID = -1
			
			-- retrive parent boneID
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
			
			format "\t\t\t\t{\"name\":\"%\", " b.name to:str
			-- parent
			format "\"parent\":%, " parentBoneID to:str
			
			-- data
			format "\"pos\":%, " (in coordsys parent(formatVector3 b.position)) to:str
			format "\"rot\":[0,0,0], " to:str
			format "\"rotq\":%, " (in coordsys parent(formatQuaternion b.rotation)) to:str
			format "\"scl\":%}" (in coordsys parent(formatVector3 b.scale)) to:str
		)
	)
	format "\n" to:str
	format "\t\t\t]\n" to:str
	
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
	--myMesh = snapshotAsMesh myObj
	
	mat = myObj.material
	if mat != undefined then
	(
		if matCount > 1 then
		(
			format "\t\t,\n" to:file
		)
		
		format "%" (formatMaterial mat undefined) to:file
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
	--myMesh = snapshotAsMesh myObj
	
	ib = (isBone myObj) 
	if (ib == false) then
	(
		if meshCount > 1 then
		(
			format "\t\t,\n" to:file
		)
	
		subMeshes = (processMesh myObj myObj.material)
		
		for i = 1 to subMeshes.count do
		(
			mySubMesh = subMeshes[i]
			
			if (i != 1) then
			(
				format ",\n" to:file
			)
			format "%" (formatSubMesh mySubMesh mySubMesh.material) to:file
		)
		
		meshCount = meshCount + subMeshes.count
	)
)
format "\n" to:file
format "\t]\n" to:file

-- END FILE
format "}\n" to:file

-- CLOSE FILE
close file

select mySelection
