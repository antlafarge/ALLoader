function pf3 f =
(
	ceil( f * 1000 ) / 1000
)

function formatMatrix3 m =
(
	preRotateX m 90
	m = inverse m
	mr1x = pf3 m.row1.x
	mr1y = pf3 m.row1.y
	mr1z = pf3 m.row1.z
	mr2x = pf3 m.row2.x
	mr2y = pf3 m.row2.y
	mr2z = pf3 m.row2.z
	mr3x = pf3 m.row3.x
	mr3y = pf3 m.row3.y
	mr3z = pf3 m.row3.z
	mr4x = pf3 m.row4.x
	mr4y = pf3 m.row4.y
	mr4z = pf3 m.row4.z
	format "%,%,%,%,%,%,%,%,%,%,%,%" mr1x mr1y mr1z mr2x mr2y mr2z mr3x mr3y mr3z mr4x mr4y mr4z to:file
)

function processBone b =
(
	parentName = ""
	parent = b.parent
	if parent != undefined then
	(
		parentName = parent.name
	)
	
	im = b.transform
	
	format "\t\t{\n" to:file
	-- name
	format "\t\t\t\"name\":\"%\",\n" b.name to:file
	-- parent
	format "\t\t\t\"parent\":\"%\",\n" parentName to:file
	-- initMatrix
	format "\t\t\t\"initMatrix\":[" to:file
	formatMatrix3( copy im )
	format "],\n"  to:file
	
	-- extra info (to remove)
	format "\t\t\t\"transform\":\"%\",\n" b.transform to:file
	format "\t\t\t\"pos\":\"%\",\n" b.pos to:file
	format "\t\t\t\"rotation\":\"%\",\n" b.rotation to:file
	format "\t\t\t\"scale\":\"%\",\n" b.scale to:file
	format "\t\t\t\"objectTransform\":\"%\",\n" b.objectTransform to:file
	format "\t\t\t\"objectOffsetPos\":\"%\",\n" b.objectOffsetPos to:file
	format "\t\t\t\"objectOffsetRot\":\"%\",\n" b.objectOffsetRot to:file
	format "\t\t\t\"objectOffsetScale\":\"%\",\n" b.objectOffsetScale to:file
	format "\t\t\t\"dir\":\"%\",\n" b.dir to:file
	format "\t\t\t\"max\":\"%\",\n" b.max to:file
	format "\t\t\t\"min\":\"%\",\n" b.min to:file
	format "\t\t\t\"center\":\"%\",\n" b.center to:file
	format "\t\t\t\"pivot\":\"%\",\n" b.pivot to:file
	format "\t\t}\n" to:file
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
filename = "test.als"
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
