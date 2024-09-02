fileIn "globals.ms"
fileIn "tools.ms"

fn formatSkeleton obj stream =
(
	local objSkin = obj.modifiers[#skin]
	if (objSkin != undefined) then
	(
		local allBones = skinOps.GetBoneNodes objSkin
		local bonesCount = allBones.count
		if (bonesCount > 0) then
		(
			format "%\"%\":%[" (tabs 2) obj.name sp to:stream
			
			local firstBone = true;
			for bi = 1 to bonesCount do
			(
				local b = allBones[bi]

				-- retrive parent boneID
				local parentBoneID = -1
				if (b.parent != undefined) then
				(
					for bi2 = 1 to bonesCount do
					(
						if (b.parent == allBones[bi2]) then
						(
							parentBoneID = bi2 - 1
							break
						)
					)
				)
				
				-- get the transform converted to OpenGL axis
				local newTransform = (getRelativeTransformForOpenGL b)
				
				-- quaternion is inversed because of rotations are inversed in maxscript
				-- cf. http://docs.autodesk.com/3DSMAX/15/ENU/MAXScript-Help/index.html?url=files/GUID-3B001F21-8FE9-4663-A972-E648682A0ACD.htm,topicNumber=d30e272529
				
				if (firstBone == false) then
				(
					format "," to:stream
				)
				
				format "%%{%\"nm\":\"%\",%\"pr\":%,%\"ps\":%,%\"rt\":%,%\"sc\":%%%}" nl (tabs 3) sp b.name sp parentBoneID sp (formatPoint3 newTransform.position) sp sp (formatQuaternion (inverse newTransform.rotation)) sp (formatPoint3 newTransform.scale) sp to:stream
				
				firstBone = false
			)
			
			format "%%]%" nl (tabs 2) nl to:stream
		)
	
		--local animName = "anim_" + (animCount as String)
		--if (customAnimName == true) then
		--(
		--	InputStringDialog = InputStringDialog()
		--	animName = InputStringDialog.stringQuery.launch label:"Enter the animation name"
		--)
		--else
		--(
		--	animCount += 1
		--)
		--meshData.animData = processAnimatedObject obj
		--meshData.animData.name = animName
	)
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
	format "%\"skeletons\":%{%" (tabs 1) sp nl to:Listener
	for obj in objects do
	(
		if (isGeometry obj) then
		(
			select obj
			max modify mode
			formatSkeleton obj Listener
		)
	)
	format "%}%" (tabs 1) nl to:Listener
	format "}%" nl to:Listener
)
resumeEditing()
enableSceneRedraw()
