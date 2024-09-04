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
			format "%\"%\":%[%" (tabs 2) obj.name sp nl to:stream
			
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
				
				format "%{%\"nm\":\"%\",%\"pr\":%,%\"ps\":%,%\"rt\":%,%\"sc\":%%}%%" (tabs 3) sp b.name sp parentBoneID sp (formatPoint3 newTransform.position) sp (formatQuaternion (inverse newTransform.rotation)) sp (formatPoint3 newTransform.scale) sp (if bi != bonesCount then "," else "") nl to:stream
			)
			
			format "%%]%" nl (tabs 2) nl to:stream
		)
	)
)

-- DEBUG
--debug false true false false
