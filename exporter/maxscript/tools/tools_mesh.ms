function formatMaterial mat file =
(
	if ((classof mat) == MultiMaterial) then
	(
		format "{%\"name\":\"%\",%" sp mat.name sp to:file
		format "\"multi\":[" to:file
		-- display sub-material names
		for index = 1 to mat.numsubs do
		(
			format "%\"%\"" (if (index > 1) then "," else "") mat.materialList[index].name to:file
		)
		format "]%}" sp to:file
		-- recursive parse of sub-materials
		for index = 1 to mat.numsubs do
		(
			format ",%%" nl (tabs 2) to:file
			formatMaterial mat.materialList[index] file
		)
	)
	else if ((classof mat) == PhysicalMaterial) then
	(
		format "{%\"name\":\"%\",%" sp mat.name sp to:file
		if (mat.base_color_map != undefined) then
		(
			textureFilePath = mat.base_color_map.bitmap.filename
			tokens = (filterString textureFilePath "\\")
			textureFileName = tokens[tokens.count]
			format "\"texture\":\"%\", " textureFileName to:file
		)
		format "\"ambient\":[%,%,%],%" (fp (mat.Base_Color.r * mat.base_weight)) (fp (mat.Base_Color.g * mat.base_weight)) (fp (mat.Base_Color.b * mat.base_weight)) sp to:file
		format "\"diffuse\":[%,%,%],%" (fp (mat.Base_Color.r * mat.base_weight)) (fp (mat.Base_Color.g * mat.base_weight)) (fp (mat.Base_Color.b * mat.base_weight)) sp to:file
		format "\"specular\":[%,%,%],%" (fp (mat.refl_color.r * mat.Reflectivity)) (fp (mat.refl_color.g * mat.Reflectivity)) (fp (mat.refl_color.b * mat.Reflectivity)) sp to:file
		format "\"opacity\":%" (fp (1 - mat.Transparency)) to:file
		format "%}" sp to:file
	)
	else if ((classof mat) == Standardmaterial) then
	(
		format "{%" sp to:file
		format "\"name\":\"%\",%" mat.name sp to:file
		if (mat.diffuseMap != undefined) then
		(
			textureFilePath = mat.diffuseMap.bitmap.filename
			tokens = (filterString textureFilePath "\\")
			textureFileName = tokens[tokens.count]
			format "\"texture\":\"%\",%" textureFileName sp to:file
		)
		if (mat.twoSided == true) then
		(
			format "\"side\":\"double\", " to:file
		)
		format "\"ambient\":[%,%,%]," (fp mat.ambient.r) (fp mat.ambient.g) (fp mat.ambient.b) to:file
		format "\"diffuse\":[%,%,%]," (fp mat.diffuse.r) (fp mat.diffuse.g) (fp mat.diffuse.b) to:file
		format "\"specular\":[%,%,%]," (fp mat.specular.r) (fp mat.specular.g) (fp mat.specular.b) to:file
		format "\"opacity\":" (fp (mat.opacity / 100)) to:file
		format "%}" sp to:file
	)
)

function formatMeshData meshData file =
(
	-- Write indices
	local count = meshData.vertex_indices.count
	if (count > 0) then
	(
		format "%\"vertex_indices\":[%" (tabs 3) nl to:file

		local arrCount = 0
		local nl2 = "," + nl
		for index = 1 to count do
		(
			if (meshData.vertex_indices[index] != undefined) then
			(
				format "%%[%]" (if (arrCount > 0) then nl2 else "") (tabs 4) (formatArrayAsInteger meshData.vertex_indices[index]) to:file

				arrCount += 1
			)
		)

		format "%%],%" nl (tabs 3) nl to:file
	)

	-- Write normals
	local count = meshData.face_normals.count
	if (count > 0) then
	(
		format "%\"face_normals\":[%" (tabs 3) nl to:file

		local arrCount = 0
		local nl2 = "," + nl
		for index = 1 to count do
		(
			if (meshData.face_normals[index] != undefined) then
			(
				format "%%[%]" (if (arrCount > 0) then nl2 else "") (tabs 4) (formatPoint3Array meshData.face_normals[index]) to:file

				arrCount += 1
			)
		)
		
		format "%%]" nl (tabs 3) to:file
	)

	-- Write colors
	local count = meshData.colors.count
	if (count > 0) then
	(
		format ",%%\"colors\":[%]" nl (tabs 3) (FormatColorRgbaArray meshData.colors) to:file
	)

	-- Write texture coords
	local count = meshData.uvs.count
	if (count > 0) then
	(
		format ",%%\"uv\":[%]" nl (tabs 3) (formatUvArray meshData.uvs) to:file
	)
	
	-- Write texture indices
	local count = meshData.uv_indices.count
	if (count > 0) then
	(
		format ",%%\"uv_indices\":[%]" nl (tabs 3) (formatArrayAsInteger meshData.uv_indices) to:file
	)
	
	-- Write skinIndices
	local count = meshData.skinIndices.count
	if (count > 0) then
	(
		format ",%%\"skinIndices\":[%]" nl (tabs 3) (formatArrayAsInteger meshData.skinIndices) to:file
	)
	
	-- Write skinWeights
	local count = meshData.skinWeights.count
	if (count > 0) then
	(
 		format ",%%\"skinWeights\":[%]" nl (tabs 3) (formatArray meshData.skinWeights) to:file
	)
	
	local count = meshData.bones.count
	if (count > 0) then
	(
		-- SKELETON IN A SEPARATE FILE?
		local skeleton_filepath = undefined
		local skeleton_file = file
		-- NOT YET IMPLEMENTED IN LOADER
		/*local separateSkeleton = queryBox ("Export the skeleton in a separate File?\n" + meshData.name)
		if (separateSkeleton == true) then
		(
			skeleton_filepath = getSaveFileName caption:"Location for saving the Skeleton file" types:"JSON (*.json)|*.json|Plain Text (*.txt)|*.txt|All Files (*.*)|*.*|"
			skeleton_file = createFile skeleton_filepath
			format "{\n" to:skeleton_file
			format "\t\t\t\"name\":\"%\"" meshData.name to:skeleton_file
		)*/
		
		-- Write bones hierarchy
		format ",%%\"skin\":[%" nl (tabs 3) nl to:skeleton_file

		for boneIndex = 1 to count do
		(
			local bone = meshData.bones[boneIndex]
			
			if (boneIndex > 1) then
			(
				format ",%" nl to:skeleton_file
			)
			
			-- retrive parent bone index
			local parentBoneIndex = -1
			if (bone.parent != undefined) then
			(
				local boneIndex2 = 1
				while ((boneIndex2 <= count) and (parentBoneIndex == -1)) do
				(
					if (meshData.bones[boneIndex2] == bone.parent) then
					(
						parentBoneIndex = boneIndex2 - 1
					)
					boneIndex2 += 1
				)
			)
			
			-- get the transform converted to OpenGL axis
			local newTransform = (getRelativeTransformForOpenGL bone)
			
			format "%{%\"name\":\"%\",%" (tabs 4) sp bone.name sp to:skeleton_file
			-- parent
			format "\"parent\":%,%" parentBoneIndex sp to:skeleton_file
			-- data
			format "\"pos\":%,%" (formatPoint3 newTransform.position) sp to:skeleton_file
			-- quaternion is inversed because of rotations are inversed in maxscript
			-- cf. http://docs.autodesk.com/3DSMAX/15/ENU/MAXScript-Help/index.html?url=files/GUID-3B001F21-8FE9-4663-A972-E648682A0ACD.htm,topicNumber=d30e272529
			format "\"rotq\":%,%" (formatQuaternion (inverse newTransform.rotation)) sp to:skeleton_file
			format "\"scl\":%%}" (formatPoint3 newTransform.scale) sp to:skeleton_file
		)

		format "%%]" nl (tabs 3) to:skeleton_file
		
		if (separateSkeleton == true) then
		(
			format "%}%" nl nl to:skeleton_file
			close skeleton_file
		)
	)
	
	format "%%}" nl (tabs 2) to:file
)

function formatObjects meshes file =
(
	local someDataInserted = false
	
	format "{%" nl to:file
	
	-- materials
	local materials = #()
	local count = meshes.count
	for index = 1 to count do
	(
		local meshData = meshes[index]
		local mat = meshData.material
		if (mat != undefined) then
		(
			append materials mat
		)
	)

	local count = materials.count
	local nl2 = "," + nl
	if (count > 0) then
	(
		format "%%\"materials\":[%" (if (someDataInserted == true) then nl2 else "") (tabs 1) nl to:file

		for index = 1 to count do
		(
			local mat = materials[index]

			format "%%" (if (index > 1) then nl2 else "") (tabs 2) to:file

			formatMaterial mat file
		)

		format "%%]" nl (tabs 1) to:file

		someDataInserted = true
	)
	
	-- meshes
	local count = meshes.count
	local nl2 = "," + nl
	if (count > 0) then
	(
		format "%%\"meshes\":[%" (if (someDataInserted == true) then nl2 else "") (tabs 1) nl to:file

		local meshCount = 0

		for index = 1 to count do
		(
			local meshData = meshes[index]
			if ((isBone meshData) == false) then
			(
				if (meshCount > 0) then
				(
					format ",%" nl to:file
				)
				formatMeshData meshData file
				meshCount += 1
			)
		)

		format "%%]" nl (tabs 1) to:file
		
		someDataInserted = true
	)
	
	-- animDatas
	local animDatas = #()
	local count = meshes.count
	for index = 1 to count do
	(
		local meshData = meshes[index]
		if (((isBone meshData) == false) and (meshData.animData != undefined)) then
		(
			append animDatas meshData.animData
		)
	)

	local count = animDatas.count
	if (count > 0) then
	(
		if (someDataInserted == true) then
		(
			format ",%" nl to:file
		)

		format "%\"animations\":[%" (tabs 1) nl to:file

		for index = 1 to count do
		(
			local animData = animDatas[index]
			if (index > 1) then
			(
				format ",%" nl to:file
			)
			formatAnimData animData file
		)

		format "%]" (tabs 1) to:file

		someDataInserted = true
	)
	
	format "%}%" nl nl to:file
)
