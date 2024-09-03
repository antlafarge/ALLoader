fileIn "globals.ms"
fileIn "tools.ms"

fn formatAnimation obj stream =
(
	local objSkin = obj.modifiers[#skin]
	if (objSkin != undefined) then
	(
		format "%\"%\":%{%" (tabs 2) obj.name sp nl to:stream
		format "%\"sk\":%\"%\",%" (tabs 3) sp obj.name nl to:stream
		format "%\"ms\":%\"%\",%" (tabs 3) sp obj.name nl to:stream
		
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
		local duration = ((((animationRange.end - animationRange.start) as float) / 4800) * timeFactor)
		
		format "%\"dr\":%%,%" (tabs 3) sp duration nl to:stream
		format "%\"hr\":%[%" (tabs 3) sp nl to:stream
		
		-- get start and end of the animation
		local keyStart = (animationRange.start as integer) / 160
		local keyEnd = (animationRange.end as integer) / 160
		local keyCount = keyEnd - keyStart + 1
		
		local initialSliderTimePos = sliderTime
		
		local bonesCount = skinOps.GetNumberBones objSkin
		local comma = ""
		for i = 1 to bonesCount do
		(
			local bname = skinOps.GetBoneName objSkin i 1
			local b = getNodeByName bname
			
			format "%{%" (tabs 4) nl
			format "%\"bn\":%\"%\",%" (tabs 5) sp bname nl
			format "%\"ky\":%[%" (tabs 5) sp nl
			
			-- browse timeline
			for k = keyStart to keyEnd do
			(
				--format "% " k
				sliderTime = k
				local ktime = (k as time)
				
				-- check if a key has to be created
				if (
					k == keyStart or
					k == keyEnd or
					in_array_time b.position.controller.keys ktime or
					in_array_time b.rotation.controller.keys ktime or
					in_array_time b.scale.controller.keys ktime
				) then
				(
					local newTransform = (getRelativeTransformForOpenGL b)
					
					local bpos = newTransform.position
					-- quaternion is inversed because of rotations are inversed in maxscript
					-- cf. http://docs.autodesk.com/3DSMAX/15/ENU/MAXScript-Help/index.html?url=files/GUID-3B001F21-8FE9-4663-A972-E648682A0ACD.htm,topicNumber=d30e272529
					local brot = inverse newTransform.rotation
					local bscl = newTransform.scale
					
					local btime = (((ktime as float) / 4800) * timeFactor)
					format "%{%\"tm\":%,%\"ps\":%,%\"rt\":%,%\"sc\":%%}%%" (tabs 6) sp btime sp (formatPoint3 bpos) sp (formatQuaternion brot) sp (formatPoint3 bscl) sp (if k != keyEnd then "," else "") nl to:stream
				)
			)
			
			format "%]%" (tabs 5) nl
			format "%}%%" (tabs 4) (if i != bonesCount then "," else "") nl
		)
		
		sliderTime = initialSliderTimePos
		
		format "%]%" (tabs 3) nl to:stream
		
		format "%}%" (tabs 2) nl to:stream
	)
)

-- check if a key of the array of keys has the specified time
fn in_array_time arr needle_time =
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

-- DEBUG
disableSceneRedraw()
suspendEditing()
nl = "\n"
cnl = ",\n"
sp = " "
clearListener()
undo on
(
	format "{%" nl to:Listener
	format "%\"version\": \"0.1\",%" (tabs 1) nl to:Listener
	format "%\"animations\":%{%" (tabs 1) sp nl to:Listener
	for obj in objects do
	(
		if (isGeometry obj) then
		(
			select obj
			max modify mode
			formatAnimation obj Listener
		)
	)
	format "%}%" (tabs 1) nl to:Listener
	format "}%" nl to:Listener
)
resumeEditing()
enableSceneRedraw()
