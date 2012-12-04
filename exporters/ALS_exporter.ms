-- SKELETON EXPORTER (ALS)

include "tools.ms"

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
	im = ( rotate im QUAT_TRANSFORM_1 )
	--im = ( rotate im QUAT_TRANSFORM_2 )
	
	format "\t\t{\n" to:file
	-- name
	format "\t\t\t\"name\":\"%\",\n" b.name to:file
	-- parent
	format "\t\t\t\"parent\":\"%\",\n" parentName to:file
	
	-- data
	format "\t\t\t\"transform\":%\n" (formatMatrix3 im) to:file
	--format "\t\t\t\"pos\":%,\n" (formatVector3 b.position) to:file
	--format "\t\t\t\"rotq\":%,\n" (formatQuaternion b.rotation) to:file
	--format "\t\t\t\"scl\":%\n" (formatVector3 b.scale) to:file
	
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

-- SKELETON BONES
format "\t\"bones\":[\n" to:file
for i = 1 to objects.count do
(
	obj = objects[ i ]
	if ( isBone obj ) then
	(
		if ( i > 1 ) then
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
