-- ANIMATION EXPORTER (ALA)

clearListener()

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

if (selection.count == 0) then
(
	exit
)

myObj = selection[1]
mySkin = myObj.modifiers[#skin]
max modify mode

struct bonejs (bone=undefined, parent=-1, keys=#())
struct keyjs (time=0, pos=undefined, rot=undefined, scl=undefined)

global timeFactor = 1

if (timeConfiguration.playbackSpeed == 1) then
(
	timeFactor = 4
)
else if (timeConfiguration.playbackSpeed == 2) then
(
	timeFactor = 2
)
else if (timeConfiguration.playbackSpeed == 3) then
(
	timeFactor = 1
)
else if (timeConfiguration.playbackSpeed == 4) then
(
	timeFactor = 0.5
)
else if (timeConfiguration.playbackSpeed == 5) then
(
	timeFactor = 0.25
)

-- START FILE
format "{\n" to:file

-- SKELETON NAME
animName = "animation"
animName = getKBLine prompt:"Enter animation name"
format "\t\"name\":\"%\",\n" animName to:file
format "\t\"fps\":%,\n" frameRate to:file
format "\t\"length\":%,\n" ((((animationRange.end - animationRange.start) as float) / 4800) * timeFactor) to:file
format "\t\"JIT\":0,\n" to:file
format "\t\"loop\":%,\n" timeConfiguration.playbackLoop to:file

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

keyStart = (animationRange.start as integer) / 160
keyEnd = (animationRange.end as integer) / 160
keyCount = keyEnd - keyStart + 1

function in_array arr needle =
(
	for ai = 1 to arr.count do
	(
		if (arr[ai] == needle) then
		(
			return true
		)
	)
	
	return false
)

function in_array_time arr needle =
(
	for ai = 1 to arr.count do
	(
		if (arr[ai].time == needle) then
		(
			return true
		)
	)
	
	return false
)

for k = keyStart to keyEnd do
(
	sliderTime = k
	for i = 1 to myBones.count do
	(
		b = myBones[i]
		bjs = myBonesjs[i]

		kastime = (k as time)
		
		createKey = false
		
		if (k == keyStart or k == keyEnd) then
		(
			createKey = true
		)
		else if (in_array_time b.position.controller.keys kastime) then
		(
			createKey = true
		)
		else if (in_array_time b.rotation.controller.keys kastime) then
		(
			createKey = true
		)
		else if (in_array_time b.rotation.controller.keys kastime) then
		(
			createKey = true
		)
		
		if (createKey == true) then
		(
			bpos = (in coordsys parent(b.position))
			brot = (in coordsys parent(b.rotation))
			bscl = (in coordsys parent(b.scale))
			btime = (((kastime as float) / 4800) * timeFactor)
			append bjs.keys (keyjs time:btime pos:bpos rot:brot scl:bscl)
		)
	)
)
sliderTime = 0

-- FORMAT

function formatKeyjs thekeyjs =
(
	opxstr = stringStream ""
	
	format "{\"time\":%, " thekeyjs.time to:opxstr
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
