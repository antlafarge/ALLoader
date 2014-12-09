--  ANIMATION TOOLS

include "tools.ms"

-- STRUCTURES
struct animjs (name="anim", fps=frameRate, length=0, JIT=0, loop=true, hierarchy=#())
struct bonejs (bone=undefined, parent=-1, keys=#())
struct keyjs (time=0, pos=undefined, rot=undefined, scl=undefined)

-- FUNCTIONS
-- check if a key of the array of keys has the specified time
function in_array_time arr needle_time =
(
	for ai = 1 to arr.count do
	(
		if (arr[ai].time == needle_time) then
		(
			return true
		)
	)
	
	return false
)

-- process the object to extract the animation of bones of the skin
function processAnimatedObject myObj =
(
	local anim = animjs()
	local mySkin = myObj.modifiers[#skin]
	
	if (mySkin == undefined) then
	(
		return undefined
	)

	local timeFactor = 1
	
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
	
	max modify mode
	anim.length = ((((animationRange.end - animationRange.start) as float) / 4800) * timeFactor)
	anim.loop = timeConfiguration.playbackLoop
	
	local myBones = #()
	
	-- get bones
	local bonesCount = skinOps.GetNumberBones mySkin
	for bi = 1 to bonesCount do
	(
		local bname = skinOps.GetBoneName mySkin bi 1
		local b = getNodeByName bname
		append myBones b
	)
	
	-- retrive parent IDs
	for bi = 1 to myBones.count do
	(
		local b = myBones[bi]
		local parentBoneID = -1
		
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
		
		append anim.hierarchy (bonejs bone:b parent:parentBoneID)
	)
	
	-- get start and end of the animation
	local keyStart = (animationRange.start as integer) / 160
	local keyEnd = (animationRange.end as integer) / 160
	local keyCount = keyEnd - keyStart + 1
	
	-- browse timeline
	local initialSliderTimePos = sliderTime
	for k = keyStart to keyEnd do
	(
		sliderTime = k
		for i = 1 to myBones.count do
		(
			local b = myBones[i]
			local bjs = anim.hierarchy[i]
			local ktime = (k as time)
			local createKey = false
			
			-- check if a key has to be created
			if (k == keyStart or k == keyEnd) then
			(
				createKey = true
			)
			else if (in_array_time b.position.controller.keys ktime) then
			(
				createKey = true
			)
			else if (in_array_time b.rotation.controller.keys ktime) then
			(
				createKey = true
			)
			else if (in_array_time b.rotation.controller.keys ktime) then
			(
				createKey = true
			)
			
			if (createKey == true) then
			(
				local newTransform = (getRelativeTransformForOpenGL b)
				
				local bpos = newTransform.position
				-- quaternion is inversed because of rotations are inversed in maxscript
				-- cf. http://docs.autodesk.com/3DSMAX/15/ENU/MAXScript-Help/index.html?url=files/GUID-3B001F21-8FE9-4663-A972-E648682A0ACD.htm,topicNumber=d30e272529
				local brot = inverse newTransform.rotation
				local bscl = newTransform.scale
				
				local btime = (((ktime as float) / 4800) * timeFactor)
				append bjs.keys (keyjs time:btime pos:bpos rot:brot scl:bscl)
			)
		)
	)
	sliderTime = initialSliderTimePos
	
	return anim
)

function formatKeyjs thekeyjs =
(
	local myStringStream = stringStream ""
	
	format "{\"time\":%, " thekeyjs.time to:myStringStream
	format "\"pos\":%, " (formatVector3 thekeyjs.pos) to:myStringStream
	format "\"rot\":%, " (formatQuaternion thekeyjs.rot) to:myStringStream
	format "\"scl\":%}" (formatVector3 thekeyjs.scl) to:myStringStream
	
	return (myStringStream as string)
)

function formatBonejs thebonejs =
(
	local myStringStream = stringStream ""
	
	format "\t\t\t\t{\n" to:myStringStream
	
	format "\t\t\t\t\t\"parent\":%,\n" thebonejs.parent to:myStringStream
	
	format "\t\t\t\t\t\"keys\":[\n" to:myStringStream
	
	for kz = 1 to thebonejs.keys.count do
	(
		thekeyjs = thebonejs.keys[kz]
		if (kz != 1) then
		(
			format ",\n" to:myStringStream
		)
		format "\t\t\t\t\t\t%" (formatKeyjs thekeyjs) to:myStringStream
	)
	
	format "\n" to:myStringStream
	format "\t\t\t\t\t]\n" to:myStringStream
	
	format "\t\t\t\t}" to:myStringStream

	return (myStringStream as string)
)

function formatAnimatedObject anim file =
(
	format "\t\t{\n" to:file
	
	-- meta datas
	format "\t\t\t\"name\":\"%\",\n" anim.name to:file
	format "\t\t\t\"fps\":%,\n" anim.fps to:file
	format "\t\t\t\"length\":%,\n" anim.length to:file
	format "\t\t\t\"JIT\":%,\n" anim.JIT to:file
	format "\t\t\t\"loop\":%,\n" anim.loop to:file
	
	-- bone hierarchy
	format "\t\t\t\"hierarchy\":[\n" to:file
	for i = 1 to anim.hierarchy.count do
	(
		local bjs = anim.hierarchy[i]
		if (i != 1) then
		(
			format ",\n" to:file
		)
		format "%" (formatBonejs bjs) to:file
	)
	format "\n\t\t\t]\n" to:file
	
	format "\t\t}\n" to:file
)
