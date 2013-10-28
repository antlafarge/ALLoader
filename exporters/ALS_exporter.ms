-- SKELETON EXPORTER (ALS)

clearListener()

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

-- SAVE FILE EMPLACEMENT
filepath = GetSaveFileName()
if (filepath == undefined) then
(
	exit
)

-- CREATE FILE
deleteFile filepath
global file = createFile filepath

myObj = selection[1]
mySkin = myObj.modifiers[#skin]
max modify mode

-- START FILE
format "{\n" to:file

format "\t\"name\":\"%\",\n" myObj.name to:file

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

-- Write bones hierarchy
format "\t\"bones\":[\n" to:file
for bi = 1 to myBones.count do
(
	b = myBones[bi]
	if (bi != 1) then
	(
		format ",\n" to:file
	)
	
	-- retrive parent boneID
	parentBoneID = -1
	if (b.parent != undefined) then
	(
		for bi2 = 1 to myBones.count do
		(
			if (myBones[bi2].name == b.parent.name) then
			(
				parentBoneID = bi2 - 1
				break
			)
		)
	)
	
	format "\t\t{ \"name\":\"%\", " b.name to:file
	-- parent
	format "\"parent\":%, " parentBoneID to:file
	
	-- data
	format "\"pos\":%, " (in coordsys parent(formatVector3 b.position)) to:file
	format "\"rot\":[0,0,0], " to:file
	format "\"rotq\":%, " (in coordsys parent(formatQuaternion b.rotation)) to:file
	format "\"scl\":% }" (in coordsys parent(formatVector3 b.scale)) to:file
)
format "\n" to:file
format "\t]\n" to:file

-- END FILE
format "}\n" to:file

-- CLOSE FILE
close file
