--  ANIMATION TOOLS

fileIn "tools.ms"

-- STRUCTURES

struct AnimDataStruct (name="animData", fps=frameRate, length=0, jit=0, loop=true, hierarchy=#())
struct BoneDataStruct (bone=undefined, parentIndex=-1, keys=#())
struct KeyDataStruct (time=0, position=undefined, rotation=undefined, scale=undefined)

-- FUNCTIONS

-- check if a key of the array of keys has the specified time
fn findTime arr searchTime =
(
	local found = false
	local index = 1
	local count = arr.count
	while ((index <= count) and (found == false)) do
	(
		if (arr[index].time == searchTime) then
		(
			found = true
		)
		index += 1
	)
	
	found
)

-- process the object to extract the animation of bones of the skin
fn processAnimatedObject obj =
(
	local animData = AnimDataStruct()
	local skin1 = obj.modifiers[#skin]
	
	if (skin1 != undefined) then
	(
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

		animData.length = (((animationRange.end - animationRange.start) as float) / 4800) * timeFactor
		animData.loop = timeConfiguration.playbackLoop
		
		local bones = #()
		
		-- get bones
		local bonesCount = skinOps.GetNumberBones skin1
		for bindex = 1 to bonesCount do
		(
			local boneName = skinOps.GetBoneName skin1 bindex 1
			local bone = getNodeByName boneName
			append bones bone
		)
		
		-- retrive parent IDs
		local bonesCount = bones.count
		for bindex = 1 to bonesCount do
		(
			local bone = bones[bindex]
			local boneParentIndex = -1
			
			if (bone.parent != undefined) then
			(
				local boneParentName = bone.parent.name
				local bindex2 = 1
				while ((bindex2 <= bonesCount) and (boneParentIndex == -1)) do
				(
					if (bones[bindex2].name == boneParentName) then
					(
						boneParentIndex = bindex2 - 1
					)
					bindex2 += 1
				)
			)
			
			append animData.hierarchy (BoneDataStruct bone:bone parentIndex:boneParentIndex)
		)
		
		-- get start and end of the animation
		local keyStart = (animationRange.start as integer) / 160
		local keyEnd = (animationRange.end as integer) / 160
		local keyCount = keyEnd - keyStart + 1
		
		-- browse timeline
		local initialSliderTimePos = sliderTime
		for key = keyStart to keyEnd do
		(
			sliderTime = key
			for index = 1 to bones.count do
			(
				local bone = bones[index]
				local boneData = animData.hierarchy[index]
				local keyTime = (key as time)
				local createKey = false
				
				-- check if a key has to be created
				if (key == keyStart or key == keyEnd) then
				(
					createKey = true
				)
				else if (findTime bone.position.controller.keys keyTime) then
				(
					createKey = true
				)
				else if (findTime bone.rotation.controller.keys keyTime) then
				(
					createKey = true
				)
				else if (findTime bone.scale.controller.keys keyTime) then
				(
					createKey = true
				)
				
				if (createKey == true) then
				(
					local newTransform = (getRelativeTransformForOpenGL bone)
					
					local bonePosition = newTransform.position
					-- quaternion is inversed because of rotations are inversed in maxscript
					-- cf. http://docs.autodesk.com/3DSMAX/15/ENU/MAXScript-Help/index.html?url=files/GUID-3B001F21-8FE9-4663-A972-E648682A0ACD.htm,topicNumber=d30e272529
					local boneRotation = inverse newTransform.rotation
					local boneScale = newTransform.scale
					
					local boneTime = (((keyTime as float) / 4800) * timeFactor)
					append boneData.keys (KeyDataStruct time:boneTime position:bonePosition rotation:boneRotation scale:boneScale)
				)
			)
		)
		
		sliderTime = initialSliderTimePos
		
		animData
	)
	else
	(
		undefined
	)
)

fn formatKeyData keyData =
(
	local stream = stringStream ""
	format "{ \"time\":%, " (fp keyData.time) to:stream
	format "\"pos\":%, " (formatPoint3 keyData.position) to:stream
	format "\"rot\":%, " (formatQuaternion keyData.rotation) to:stream
	format "\"scl\":% }" (formatPoint3 keyData.scale) to:stream
	stream as string
)

fn formatBoneData boneData =
(
	local stream = stringStream ""
	format "%{%" (tabs 4) nl to:stream
	format "%\"parent\":%,%" (tabs 5) (formattedPrint boneData.parentIndex) nl to:stream
	format "%\"keys\":[%" (tabs 5) nl to:stream
	local count = boneData.keys.count
	local nl2 = "," + nl
	for index = 1 to count do
	(
		format "%%%" (if (index > 1) then nl2 else "") (tabs 6) (formatKeyData boneData.keys[index]) to:stream
	)
	format "%%]%" nl (tabs 5) nl to:stream
	format "%}" (tabs 4) to:stream
	stream as string
)

fn formatAnimData animData file =
(
	format "%{%" (tabs 2) nl to:file
	format "%\"name\":\"%\",%" (tabs 3) animData.name nl to:file
	format "%\"fps\":%,%" (tabs 3) (formattedPrint animData.fps) nl to:file
	format "%\"length\":%,%" (tabs 3) (formattedPrint animData.length) nl to:file
	format "%\"JIT\":%,%" (tabs 3) (formattedPrint animData.jit) nl to:file
	format "%\"loop\":%,%" (tabs 3) animData.loop nl to:file
	format "%\"hierarchy\":[%" (tabs 3) nl to:file
	local count = animData.hierarchy.count
	local nl2 = "," + nl
	for index = 1 to count do
	(
		format "%%" (if (index > 1) then nl2 else "") (formatBoneData animData.hierarchy[index]) to:file
	)
	format "%%]%" nl (tabs 3) nl to:file
	format "%}%" (tabs 2) nl to:file
)
