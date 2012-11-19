function processMaterial mat =
(
	textureFilePath = mat.diffuseMap.bitmap.filename
	tokens = ( filterString textureFilePath "\\" )
	textureFileName = tokens[ tokens.count ]
	if textureName == undefined then
	(
		textureName = ""
	)

	format "\t\t{\n" to:file
	format "\t\t\t\"name\":\"%\",\n" mat.name to:file
	format "\t\t\t\"texture\":\"%\"\n" textureFileName to:file
	format "\t\t}\n" to:file
)

function processMesh mymesh matName =
(
	format "\t\t{\n" to:file
	
	format "\t\t\t\"material\":\"%\",\n" matName to:file

	vertexBuffer = #()
	normalBuffer = #()
	indexBuffer = #()
	colorBuffer = #()
	textCoordBuffer = #()

	indexCount = 0
	for f = 1 to myMesh.numfaces do
	(
		-- Face
		face = getFace myMesh f
		-- Vertices
		v1 = getVert myMesh face.x
		v2 = getVert myMesh face.y
		v3 = getVert myMesh face.z
		append vertexBuffer v1
		append vertexBuffer v2
		append vertexBuffer v3
		-- Indices
		append indexBuffer indexCount
		append indexBuffer (indexCount+1)
		append indexBuffer (indexCount+2)
		indexCount += 3;
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
		append normalBuffer normals[1]
		append normalBuffer normals[2]
		append normalBuffer normals[3]
		-- Colors
		append colorBuffer (color 1 1 1 1)
		append colorBuffer (color 1 1 1 1)
		append colorBuffer (color 1 1 1 1)
		-- Texture Coord
		t1 = getTVert myMesh face.x
		t2 = getTVert myMesh face.y
		t3 = getTVert myMesh face.z
		append textCoordBuffer t1
		append textCoordBuffer t2
		append textCoordBuffer t3
	)

	-- Write vertices
	format "\t\t\t\"vertices\":[" to:file
	for v = 1 to vertexBuffer.count do
	(
		vert = vertexBuffer[v]
		if ( v != 1 ) then
			format "," to:file
		format "%,%,%" vert.x vert.y vert.z to:file
	)
	format "],\n" to:file

	-- Write indices
	format "\t\t\t\"indices\":[" to:file
	for i = 1 to indexBuffer.count do
	(
		index = indexBuffer[i]
		format "%" (index as integer) to:file
		if ( i != indexBuffer.count ) then
			format "," to:file
	)
	format "],\n" to:file

	-- Write normals
	format "\t\t\t\"normals\":[" to:file
	for n = 1 to normalBuffer.count do
	(
		normal = normalBuffer[n]
		if ( n != 1 ) then
			format "," to:file
		format "%,%,%" normal.x normal.y normal.z to:file
	)
	format "],\n" to:file

	-- Write colors
	format "\t\t\t\"colors\":[" to:file
	for c = 1 to colorBuffer.count do
	(
		colo = colorBuffer[c]
		if ( c != 1 ) then
			format "," to:file
		format "%,%,%,%" colo.r colo.v colo.b colo.a to:file
	)
	format "],\n" to:file

	-- Write texture coords
	format "\t\t\t\"texcoord\":[" to:file
	for t = 1 to textCoordBuffer.count do
	(
		texture = textCoordBuffer[t]
		if ( t != 1 ) then
			format "," to:file
		format "%,%" texture.x texture.y to:file
	)
	format "]\n" to:file

	format "\t\t}\n" to:file
)

-- MAIN
clearListener()

--filepath = GetSaveFileName()
filename = "model.alm"
/*
filepath = GetSaveFileName()
if filepath == undefined then
(
	exit
)
*/

-- FILE START
deleteFile filename
global file = createFile filename
format "{\n" to:file

-- MATERIALS
format "\t\"materials\":[\n" to:file
for i = 1 to selection.count do
(
	if i > 1 then
	(
		format "\t\t,\n" to:file
	)
	
	myobj = selection[i]
	mymesh = snapshotAsMesh myobj
	
	mat = myobj.material
	if mat != undefined then
	(
		processMaterial( mat )
	)
)
format "\t],\n" to:file
	
-- MESHES
format "\t\"meshes\":[\n" to:file
for i = 1 to selection.count do
(
	if i > 1 then
	(
		format "\t\t,\n" to:file
	)
	
	myobj = selection[i]
	mymesh = snapshotAsMesh myobj
	
	matName = ""
	mat = myobj.material
	if mat != undefined then
	(
		matName = mat.name
	)
	
	processMesh mymesh matName
	
)
format "\t]\n" to:file

-- FILE END
format "}\n" to:file
close file
