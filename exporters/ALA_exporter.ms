QUAT_TRANSFORM_1 = quat 90 [0,1,0]
QUAT_TRANSFORM_2 = quat 180 [0,0,1]

function pf3 f =
(
	ceil( f * 1000 ) / 1000
)

function formatMatrix3 m =
(
	m1x = m.row1.x
	m1y = m.row1.y
	m1z = m.row1.z
	m2x = m.row2.x
	m2y = m.row2.y
	m2z = m.row2.z
	m3x = m.row3.x
	m3y = m.row3.y
	m3z = m.row3.z
	m4x = m.row4.x
	m4y = m.row4.y
	m4z = m.row4.z
	format "%,%,%,%,%,%,%,%,%,%,%,%" m1x m1y m1z m2x m2y m2z m3x m3y m3z m4x m4y m4z to:file
)

function processBone b =
(
	format "%\n" b.name to:file
	
	format "\t%\n" b.position.controller.keys to:file
	
	format "\t%\n" b.position.controller to:file
	
	/*
	browse keys
	for i = 1 to keys.count do
	(
		sliderTime = keys[i]
		mesh = snapshotAsMesh selection[1]
	)
	*/
	--format "%\n" b.keys to:file
	/*parentName = ""
	parent = b.parent
	if parent != undefined then
	(
		parentName = parent.name
	)
	
	im = copy b.transform
	im = ( rotate im QUAT_TRANSFORM_1 )
	im = ( rotate im QUAT_TRANSFORM_2 )
	
	format "\t\t{\n" to:file
	-- name
	format "\t\t\t\"name\":\"%\",\n" b.name to:file
	-- parent
	format "\t\t\t\"parent\":\"%\",\n" parentName to:file
	
	-- data
	format "\t\t\t\"transform\":[" to:file
	formatMatrix3( im )
	format "],\n"  to:file
	format "\t\t\t\"pos\":[%,%,%],\n" b.pos.x b.pos.y b.pos.z to:file
	format "\t\t\t\"rotq\":[%,%,%,%],\n" b.rotation.x b.rotation.y b.rotation.z b.rotation.w to:file
	format "\t\t\t\"scl\":[%,%,%]\n" b.scale.x b.scale.y b.scale.z to:file
	
	/*format "\t\t\t\"objectTransform\":\"%\",\n" b.objectTransform to:file
	format "\t\t\t\"objectOffsetPos\":\"%\",\n" b.objectOffsetPos to:file
	format "\t\t\t\"objectOffsetRot\":\"%\",\n" b.objectOffsetRot to:file
	format "\t\t\t\"objectOffsetScale\":\"%\",\n" b.objectOffsetScale to:file
	format "\t\t\t\"dir\":\"%\",\n" b.dir to:file
	format "\t\t\t\"max\":\"%\",\n" b.max to:file
	format "\t\t\t\"min\":\"%\",\n" b.min to:file
	format "\t\t\t\"center\":\"%\",\n" b.center to:file
	format "\t\t\t\"pivot\":\"%\"\n" b.pivot to:file*/
	
	--format "\t\t}\n" to:file
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

-- FILE START
filename = "test.ala"
deleteFile filename
global file = createFile filename
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

-- FILE END
format "}\n" to:file
close file
