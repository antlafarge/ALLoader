-- SKELETON EXPORTER (ALS)

--include "tools.ms"
-- TOOLS FOR THE EXPORTERS

function isGeometry o =
(
	Superclassof o == GeometryClass and classof o != BoneGeometry
)

function isBone o =
(
	classof o == BoneGeometry
)

function pf3 f =
(
	--ceil( f * 1000 ) / 1000
	f
)

function formatVector3 v =
(
	x = pf3 v.x
	y = pf3 v.y
	z = pf3 v.z
	str = stringStream ""
	format "[%,%,%]" x y z to:str
	(str as string)
)

function formatQuaternion q =
(
	x = pf3 q.x
	y = pf3 q.y
	z = pf3 q.z
	w = pf3 q.w
	str = stringStream ""
	format "[%,%,%,%]" x y z w to:str
	(str as string)
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
	str = stringStream ""
	format "[%,%,%,%,%,%,%,%,%,%,%,%]" m1x m1y m1z m2x m2y m2z m3x m3y m3z m4x m4y m4z to:str
	(str as string)
)

-- end include "tools.ms"

QUAT_TRANSFORM_1 = quat 90 [1,0,0]
QUAT_TRANSFORM_2 = quat 90 [0,1,0]

function processBone b =
(
	parentName = ""
	parent = b.parent
	if parent != undefined then
	(
		parentName = parent.name
	)
	
	im = copy b.transform
	--im = (rotate im QUAT_TRANSFORM_1)
	--im = (rotate im QUAT_TRANSFORM_2)
	
	format "\t\t{\n" to:file
	-- name
	format "\t\t\t\"name\":\"%\",\n" b.name to:file
	-- parent
	format "\t\t\t\"parent\":\"%\",\n" parentName to:file
	
	-- data
	--format "\t\t\t\"transform\":%\n" (formatMatrix3 im) to:file
	format "\t\t\t\"pos\":%,\n" (formatVector3 b.position) to:file
	format "\t\t\t\"rot\": [0,0,0],\n" to:file
	format "\t\t\t\"rotq\":%,\n" (formatQuaternion b.rotation) to:file
	format "\t\t\t\"scl\":%\n" (formatVector3 b.scale) to:file
	
	/*
	format "\t\t\t\"objectTransform\":\"%\",\n" b.objectTransform to:file
	format "\t\t\t\"objectOffsetPos\":\"%\",\n" b.objectOffsetPos to:file
	format "\t\t\t\"objectOffsetRot\":\"%\",\n" b.objectOffsetRot to:file
	format "\t\t\t\"objectOffsetScale\":\"%\",\n" b.objectOffsetScale to:file
	format "\t\t\t\"dir\":\"%\",\n" b.dir to:file
	format "\t\t\t\"max\":\"%\",\n" b.max to:file
	format "\t\t\t\"min\":\"%\",\n" b.min to:file
	format "\t\t\t\"center\":\"%\",\n" b.center to:file
	format "\t\t\t\"pivot\":\"%\"\n" b.pivot to:file
	*/
	
	format "\t\t}\n" to:file
)

-- MAIN
clearListener()

filepath = GetSaveFileName()
if filepath == undefined then
(
	exit
)

-- CREATE FILE
deleteFile filepath
global file = createFile filepath

-- START FILE
format "{\n" to:file

-- SKELETON NAME
skeletonName = "gordon_skeleton"
format "\t\"name\":\"%\",\n" skeletonName to:file

function isBone o =
(
	classof o == BoneGeometry
)

-- SKELETON BONES
format "\t\"bones\":[\n" to:file
for i = 1 to objects.count do
(
	obj = objects[i]
	print obj
	if (isBone obj) then
	(
		if (i > 1) then
		(
			format "\t\t,\n" to:file
		)
		
		processBone obj
	)
)
format "\t]\n" to:file

-- END FILE
format "}\n" to:file

-- CLOSE FILE
close file
