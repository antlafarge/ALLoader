-- ANIMATION EXPORTER (ALA)

include "tools.ms"

QUAT_TRANSFORM_1 = quat 90 [0,1,0]
QUAT_TRANSFORM_2 = quat 180 [0,0,1]

function arrayToString array separator =
(
	string str
	for c = 1 to array.count do
	(
		if c > 1 then
		(
			str += separator
		)
		str += array[c]
	)
	str
)

function processBone b =
(
	parentName = ""
	parent = b.parent
	if parent != undefined then
	(
		parentName = parent.name
	)
	
	format "\t\t{\n" to:file
	-- name
	format "\t\t\t\"name\":\"%\",\n" b.name to:file
	-- parent
	format "\t\t\t\"parent\":\"%\",\n" parentName to:file
	
	-- keys
	keys = #()
	pkeys = b.position.controller.keys
	for k = 1 to pkeys.count do
	(
		appendIfUnique keys k
		appendIfUnique globalKeys k
	)
	rkeys = b.rotation.controller.keys
	for k = 1 to rkeys.count do
	(
		appendIfUnique keys k
		appendIfUnique globalKeys k
	)
	
	for k = 1 to keys.count do
	(
		sliderTime = keys[k]
		--im = copy b.transform
		--im = ( rotate im QUAT_TRANSFORM_1 )
		--im = ( rotate im QUAT_TRANSFORM_2 )

		if ( k > 1 ) then
		(
			format "\t\t\t,\n" to:file
		)
		format "\t\t\t{\n" to:file

		format "\t\t\t\t\"time\":%,\n" k to:file

		--format "\t\t\t\t\"transform\":%,\n" (formatMatrix3 im) to:file

		format "\t\t\t\t\"pos\":%,\n" (formatVector3 b.position) to:file
		format "\t\t\t\t\"rotq\":%,\n" (formatQuaternion b.rotation) to:file
		format "\t\t\t\t\"scl\":%\n" (formatVector3 b.scale) to:file

		format "\t\t\t\t\"posInParent\":%,\n" (formatVector3 b.posInParent) to:file
		format "\t\t\t\t\"rotInParent\":%,\n" (formatVector3 b.rotInParent) to:file
		format "\t\t\t\t\"scaleOrientInParent\":%,\n" (formatVector3 b.scaleOrientInParent) to:file
		format "\t\t\t\t\"scaleInParent\":%,\n" (formatVector3 b.scaleInParent) to:file

		format "\t\t\t}\n" to:file
	)

	/*format "\t\t\t\"objectTransform\":\"%\",\n" b.objectTransform to:file
	format "\t\t\t\"objectOffsetPos\":\"%\",\n" b.objectOffsetPos to:file
	format "\t\t\t\"objectOffsetRot\":\"%\",\n" b.objectOffsetRot to:file
	format "\t\t\t\"objectOffsetScale\":\"%\",\n" b.objectOffsetScale to:file
	format "\t\t\t\"dir\":\"%\",\n" b.dir to:file
	format "\t\t\t\"max\":\"%\",\n" b.max to:file
	format "\t\t\t\"min\":\"%\",\n" b.min to:file
	format "\t\t\t\"center\":\"%\",\n" b.center to:file
	format "\t\t\t\"pivot\":\"%\"\n" b.pivot to:file*/
	
	format "\t\t}\n" to:file

	/*
	format "%\n" b.name to:file
	
	format "\t%\n" b.position.controller.keys to:file
	
	--format "\t%\n" b.position.controller to:file
	--format "%\n" b.keys to:file
	
	browse keys
	for i = 1 to keys.count do
	(
		sliderTime = keys[i]
		mesh = snapshotAsMesh selection[1]
	)
	*/
	
)

function isGeometry o =
(
	Superclassof o == GeometryClass and classof o != BoneGeometry
)

function isBone o =
(
	classof o == BoneGeometry
)

-- MAIN
clearListener()

filepath = GetSaveFileName()
if filepath == undefined then
(
	exit
)

-- FILE START
deleteFile filepath
global file = createFile filepath

-- START FILE
format "{\n" to:file

-- SKELETON NAME
animName = "gordon.idle"
format "\t\"name\":\"%\",\n" animName to:file

globalKeys = #()

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
		
		b = processBone obj
		formatBone b
	)
)
format "\t],\n" to:file

format "\t\"keyCount\":\"%\",\n" globalKeys.count to:file
sort globalKeys
keyTimeList = (arrayToString globalKeys.count " ")
format "\t\"keyTimeList\":\"%\"\n" keyTimeList to:file

-- END FILE
format "}\n" to:file

// CLOSE FILE
close file
