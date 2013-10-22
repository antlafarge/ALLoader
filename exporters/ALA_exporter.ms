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

function isBone o =
(
	classof o == BoneGeometry
)

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

myMesh = getnodebyname "Gordon_Hi-ResDM1.smd"
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
		bname = skinops.getbonename mySkin i 0
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
		
		bpos = (in coordsys parent(b.position))
		brot = (in coordsys parent(b.rotation))
		bscl = (in coordsys parent(b.scale))
		append bjs.keys (keyjs time:k pos:bpos rot:brot scl:bscl)
	)
)
sliderTime = 0

-- FORMAT

function formatKeyjs thekeyjs =
(
	opxstr = stringStream ""
	
	format "{\"time\":%, " (((thekeyjs.time as time) as float) / 4800) to:opxstr
	format "\"pos\":%, " (formatVector3 thekeyjs.pos) to:opxstr
	format "\"rot\":%, " (formatQuaternion thekeyjs.rot) to:opxstr
	format "\"scl\":%}" (formatVector3 thekeyjs.scl) to:opxstr
	
	return (opxstr as string)
)

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

format "\t\"hierarchy\":[\n" to:file
for i = 1 to myBonesjs.count do
(
	bjs = myBonesjs[i]
	if (i != 1) then
	(
		format ",\n" to:file
	)
	format "%" (formatBonejs bjs) to:file
)
format "\n\t]\n" to:file

-- END FILE
format "}\n" to:file

-- CLOSE FILE
close file
