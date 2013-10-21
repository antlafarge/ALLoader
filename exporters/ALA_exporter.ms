-- ANIMATION EXPORTER (ALA)

clearListener()

--QUAT_TRANSFORM_1 = quat 90 [0,1,0]
--QUAT_TRANSFORM_2 = quat 180 [0,0,1]

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

function arrayToString arr separator =
(
	dzastr = string
	for c = 1 to arr.count do
	(
		if (c > 1) then
		(
			dzastr += separator
		)
		dzastr += arr[c]
	)
	return dzastr
)

function formatBone b =
(
	tmpStr = stringStream ""
	parentName = ""
	parent = b.parent
	if parent != undefined then
	(
		parentName = parent.name
	)
	
	format "\t\t{\n" to:tmpStr
	-- name
	format "\t\t\t\"name\":\"%\",\n" b.name to:tmpStr
	-- parent
	format "\t\t\t\"parent\":\"%\",\n" parentName to:tmpStr
	
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
		--sliderTime = keys[k]
		print keys[k]
		--im = copy b.transform
		--im = ( rotate im QUAT_TRANSFORM_1 )
		--im = ( rotate im QUAT_TRANSFORM_2 )

		if ( k > 1 ) then
		(
			format "\t\t\t,\n" to:tmpStr
		)
		format "\t\t\t{\n" to:tmpStr

		format "\t\t\t\t\"time\":%,\n" k to:tmpStr

		--format "\t\t\t\t\"transform\":%,\n" (formatMatrix3 im) to:file

		format "\t\t\t\t\"pos\":%,\n" (formatVector3 b.position) to:tmpStr
		format "\t\t\t\t\"rot\":%,\n" (formatQuaternion b.rotation) to:tmpStr
		format "\t\t\t\t\"rotq\":%,\n" (formatQuaternion b.rotation) to:tmpStr
		format "\t\t\t\t\"scl\":%\n" (formatVector3 b.scale) to:tmpStr

		/*format "\t\t\t\t\"posInParent\":%,\n" (formatVector3 b.posInParent) to:tmpStr
		format "\t\t\t\t\"rotInParent\":%,\n" (formatVector3 b.rotInParent) to:tmpStr
		format "\t\t\t\t\"scaleOrientInParent\":%,\n" (formatVector3 b.scaleOrientInParent) to:tmpStr
		format "\t\t\t\t\"scaleInParent\":%,\n" (formatVector3 b.scaleInParent) to:tmpStr*/

		format "\t\t\t}\n" to:tmpStr
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
	
	format "\t\t}\n" to:tmpStr

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
	
	return (tmpStr as string)
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

filepath = GetSaveFileName()
if (filepath == undefined) then
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
format "\t\"fps\":%,\n" frameRate to:file
format "\t\"length\":%,\n" (((animationRange.end - animationRange.start + 1) as float) / 4800) to:file
format "\t\"JIT\":0,\n" to:file
format "\t\"loop\":%,\n" timeConfiguration.playbackLoop to:file

global globalKeys = #()

myMesh = getnodebyname "gordon"
select myMesh
mySkin = myMesh.modifiers[#skin]
max modify mode

struct bonejs (bone=undefined, parent=-1, keys=#())
struct keyjs (time=0, pos=undefined, rot=undefined, scl=undefined)

myBones = #()
myBonesjs = #()
if (mySkin != undefined) then
(
	bonesCount = skinops.getnumberbones mySkin
	for i = 1 to bonesCount do
	(
		bname = skinops.getbonename mySkin i 1
		b = getnodebyname bname
		append myBones b
		
		parentBoneID = -1
		
		-- retrive parent boneID
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
		
		append myBonesjs (bonejs bone:b parent:parentBoneID)
	)
)

deselect myMesh

for k = 0 to 41 do
(
	sliderTime = k
	for i = 1 to myBones.count do
	(
		b = myBones[i]
		bjs = myBonesjs[i]
		
		append bjs.keys (keyjs time:k pos:b.position rot:b.rotation scl:b.scale)
	)
)
sliderTime = 0

-- FORMAT

function formatBonejs thebonejs =
(
	adqstr = stringStream ""
	
	format "\t\t{\n" to:adqstr
	
	format "\t\t\t\"parent\":%,\n" thebonejs.parent to:adqstr
	
	format "\t\t\t\"keys\":[\n" to:adqstr
	
	for kz = 1 to thebonejs.keys.count do
	(
		thekeyjs = thebonejs.keys[kz]
		if (kz != 1) then
		(
			format ",\n" to:adqstr
		)
		format "\t\t\t\t%" (formatKeyjs thekeyjs) to:adqstr
	)
	
	format "\n" to:adqstr
	format "\t\t\t]\n" to:adqstr
	
	format "\t\t}" to:adqstr

	return (adqstr as string)
)

function formatKeyjs thekeyjs =
(
	opxstr = stringStream ""
	
	format "{\n" to:opxstr
	format "\t\t\t\t\t\"time\":%,\n" (((thekeyjs.time as time) as float) / 4800) to:opxstr
	format "\t\t\t\t\t\"pos\":%,\n" (formatVector3 thekeyjs.pos) to:opxstr
	format "\t\t\t\t\t\"rot\":%,\n" (formatQuaternion thekeyjs.rot) to:opxstr
	format "\t\t\t\t\t\"scl\":%\n" (formatVector3 thekeyjs.scl) to:opxstr
	format "\t\t\t\t}" to:opxstr
	
	return (opxstr as string)
)

format "\t\"hierarchy\":[\n" to:file
for i = 1 to myBonesjs.count do
(
	bjs = myBonesjs[i]
	if (i != 1) then
	(
		format ",\n" to:file
	)
	format "%" (formatBonejs bjs) to:file
	/*for j = 1 to bjs.keys.count do
	(
		kjs = bjs.keys[j]
		if (j > 1) then
		(
			format "\t\t,\n" to:file
		)
		
		format "%" (formatBonejs obj) to:file
	)*/
)
format "\t]\n" to:file

--format "\t\"keyCount\":\"%\",\n" globalKeys.count to:file
--sort globalKeys
--keyTimeList = (arrayToString globalKeys.count " ")
--format "\t\"keyTimeList\":\"%\"\n" keyTimeList to:file

-- END FILE
format "}\n" to:file

-- CLOSE FILE
close file
