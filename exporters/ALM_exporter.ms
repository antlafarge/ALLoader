-- MESH EXPORTER (ALM)

include "tools.ms"

MAT_TRANSFORM = matrix3 [1,0,0] [0,0,-1] [0,1,0] [0,0,0]

function processMaterial mat =
(
	if (classof mat == Multimaterial) then -- multi material
	(
		for i = 1 to mat.numsubs do
		(
			if (i > 1) then
			(
				format ",\n" to:file
			)
			processMaterial mat.materialList[i]
		)
	)
	else -- standard material
	(
		textureFilePath = mat.diffuseMap.bitmap.filename
		tokens = (filterString textureFilePath "\\")
		textureFileName = tokens[tokens.count]
		
		format "\t\t{\n" to:file
		format "\t\t\t\"name\":\"%\",\n" mat.name to:file
		if (textureFileName != undefined) then
		(
			format "\t\t\t\"texture\":\"%\",\n" textureFileName to:file
		)
		format "\t\t\t\"ambient\":[%,%,%],\n" mat.ambient.r mat.ambient.g mat.ambient.b to:file
		format "\t\t\t\"diffuse\":[%,%,%],\n" mat.diffuse.r mat.diffuse.g mat.diffuse.b to:file
		format "\t\t\t\"specular\":[%,%,%],\n" mat.specular.r mat.specular.g mat.specular.b to:file
		format "\t\t\t\"opacity\":%\n" (mat.opacity / 100) to:file
		format "\t\t}" to:file
	)
)

function processMesh myMesh mat =
(
	/*skin = mymesh.skin
	numberBones = skinOps.GetNumberBones skin
	numberVertices = skinOps.GetNumberVertices skin*/
	
	/*skinOps.GetVertexWeight <Skin> <vertex_integer> <vertex_bone_integer>
	skinOps.GetVertexWeightBoneID <Skin> <vertex_integer> <vertex_bone_integer>
	skinOps.GetVertexWeightCount <Skin> <vertex_integer>
	skinOps.GetBoneName <Skin> <bone_integer> <nameflag_index>*/
	
	subMeshes = #()
	
	for f = 1 to myMesh.numfaces do
	(
		-- Face
		face = getFace myMesh f
		-- MatID
		matID = getFaceMatID myMesh f
		if (classof mat == Multimaterial) then
		(
			subMat = mat.materialList[matID]
		)
		else
		(
			subMat = mat
		)

		-- get / create submesh
		found = false
		for i = 1 to subMeshes.count do
		(
			if (subMeshes[i].matID == matID) then
			(
				subMesh = subMeshes[i]
				found = true
			)
		)
		if found == false then
		(
			struct SubMesh (matID = undefined, mat = undefined, indexCount = 0, materialName = "", vertices = #(), indices = #(), normals = #(), colors = #(), uvs = #(), skinIndices = #(), skinWeights = #())
			subMesh = SubMesh matID:matID mat:subMat
			append subMeshes subMesh
		)
		
		-- Vertices
		v1 = getVert myMesh face.x
		v2 = getVert myMesh face.y
		v3 = getVert myMesh face.z
		v1 = v1 * MAT_TRANSFORM
		v2 = v2 * MAT_TRANSFORM
		v3 = v3 * MAT_TRANSFORM
		append subMesh.vertices v1
		append subMesh.vertices v2
		append subMesh.vertices v3
		-- Indices
		append subMesh.indices subMesh.indexCount
		append subMesh.indices (subMesh.indexCount+1)
		append subMesh.indices (subMesh.indexCount+2)
		subMesh.indexCount += 3;
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
		append subMesh.normals normals[1]
		append subMesh.normals normals[2]
		append subMesh.normals normals[3]
		-- Colors
		append subMesh.colors (color 1 1 1 1)
		append subMesh.colors (color 1 1 1 1)
		append subMesh.colors (color 1 1 1 1)
		-- Texture Coord
		t1 = getTVert myMesh face.x
		t2 = getTVert myMesh face.y
		t3 = getTVert myMesh face.z
		append subMesh.uvs t1
		append subMesh.uvs t2
		append subMesh.uvs t3
	)
	
	for i = 1 to subMeshes.count do
	(
		if (i != 1) then
		(
			format ",\n" to:file
		)
		format "%" (formatSubMesh subMeshes[i] subMeshes[i].mat) to:file
	)
)

function formatSubMesh subMesh mat =
(
	str = stringStream ""
	
	format "\t\t{\n" to:str
	
	format "\t\t\t\"material\":\"%\",\n" mat.name to:str

	-- Write vertices
	format "\t\t\t\"vertices\":[" to:str
	for v = 1 to subMesh.vertices.count do
	(
		vert = subMesh.vertices[v]
		if (v != 1) then
			format "," to:str
		format "%,%,%" vert.x vert.y vert.z to:str
	)
	format "],\n" to:str

	-- Write indices
	format "\t\t\t\"indices\":[" to:str
	for i = 1 to subMesh.indices.count do
	(
		index = subMesh.indices[i]
		format "%" (index as integer) to:str
		if (i != subMesh.indices.count) then
			format "," to:str
	)
	format "],\n" to:str

	-- Write normals
	format "\t\t\t\"normals\":[" to:str
	for n = 1 to subMesh.normals.count do
	(
		normal = subMesh.normals[n]
		if (n != 1) then
			format "," to:str
		format "%,%,%" normal.x normal.y normal.z to:str
	)
	format "],\n" to:str

	-- Write colors
	format "\t\t\t\"colors\":[" to:str
	for c = 1 to subMesh.colors.count do
	(
		colo = subMesh.colors[c]
		if (c != 1) then
			format "," to:str
		format "%,%,%,%" colo.r colo.v colo.b colo.a to:str
	)
	format "],\n" to:str

	-- Write texture coords
	format "\t\t\t\"texcoord\":[" to:str
	for t = 1 to subMesh.uvs.count do
	(
		uv = subMesh.uvs[t]
		if ( t != 1 ) then
			format "," to:str
		format "%,%" uv.x uv.y to:str
	)
	format "]\n" to:str
	
	format "\t\t}" to:str
	
	(str as string)
)

-- MAIN
clearListener()

filepath = GetSaveFileName()
if (filepath == undefined) then
(
	exit
)

-- DELETE AND CREATE FILE
deleteFile filepath
global file = createFile filepath

-- START FILE
format "{\n" to:file

-- MATERIALS
format "\t\"materials\":[\n" to:file
matCount = 0
for i = 1 to objects.count do
(
	myobj = objects[ i ]
	mymesh = snapshotAsMesh myobj
	
	mat = myobj.material
	if mat != undefined then
	(
		if matCount > 1 then
		(
			format "\t\t,\n" to:file
		)
		
		processMaterial mat
		matCount = matCount + 1
	)
)
format "\n\t],\n" to:file

-- MESHES

format "\t\"meshes\":[\n" to:file
meshCount = 0
for i = 1 to objects.count do
(
	myObj = objects[i]
	myMesh = snapshotAsMesh myObj
	
	if (isBone myobj) == false then
	(
		if meshCount > 1 then
		(
			format "\t\t,\n" to:file
		)
	
		processMesh myMesh myobj.material
		meshCount = meshCount + 1
	)
)
format "\t]\n" to:file

-- END FILE
format "}\n" to:file

-- CLOSE FILE
close file
