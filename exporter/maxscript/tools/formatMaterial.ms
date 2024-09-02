fileIn "globals.ms"
fileIn "tools.ms"

function formatMaterial mat stream =
(
	if ((classof mat) == PhysicalMaterial) then
	(
		format "%\"%\":%{%" (tabs 2) mat.name sp nl to:stream
		if (mat.base_color_map != undefined) then
		(
			textureFilePath = mat.base_color_map.bitmap.filename
			tokens = (filterString textureFilePath "\\")
			textureFileName = tokens[tokens.count]
			format "%\"cm\":%\"%\",%" (tabs 3) sp textureFileName nl to:stream -- Color Map
		)
		format "%\"cl\":%[%,%,%],%" (tabs 3) sp (fp mat.Base_Color.r) (fp mat.Base_Color.g) (fp mat.Base_Color.b) nl to:stream -- Color
		format "%\"sp\":%[%,%,%],%" (tabs 3) sp (fp mat.refl_color.r) (fp mat.refl_color.g) (fp mat.refl_color.b) nl to:stream -- Specular
		format "%\"op\":%%%" (tabs 3) sp (fp (1 - mat.Transparency)) nl to:stream -- Opacity
		format "%}" (tabs 2) to:stream
	)
	else if ((classof mat) == MultiMaterial) then
	(
		-- Extract material names
		local materials = #()
		for index = 1 to mat.materialList.count do
		(
			if (mat.materialList[index] != undefined) then
			(
				append materials mat.materialList[index].name
			)
			else
			(
				append materials undefined
			)
		)
		
		while (materials.count > 0 and materials[materials.count] == undefined) do
		(
			materials.count = materials.count - 1
		)
		
		format "%\"%\":%{%" (tabs 2) mat.name sp nl to:stream
		format "%\"ml\":%[%" (tabs 3) sp nl to:stream -- Multi
		-- display sub-material names
		if (materials.count > 1) then
		(
			if (materials[1] != undefined) then
			(
				format "%\"%\"" (tabs 4) materials[1] to:stream
			)
			else
			(
				format "%null" (tabs 4) to:stream
			)
			for index = 2 to materials.count do
			(
				if (materials[index] != undefined) then
				(
					format ",%%\"%\"" nl (tabs 4) materials[index] to:stream
				)
				else
				(
					format ",%%null" nl (tabs 4) to:stream
				)
			)
		)
		format "%%]%" nl (tabs 3) nl to:stream
		format "%}" (tabs 2) to:stream
		-- recursive parse of sub-materials
		for index = 1 to mat.numsubs do
		(
			if (mat.materialList[index] != undefined) then
			(
				format ",%" nl to:stream
				formatMaterial mat.materialList[index] stream
			)
		)
	)
	else if ((classof mat) == doubleSidedMat) then
	(
		local matName = mat.name
		if (mat.map1Enabled) then
		(
			mat = mat.material1
		)
		else if (mat.map2Enabled) then
		(
			mat = mat.material2
		)
		if (mat != undefined) then
		(
			format "%\"%\":%{%" (tabs 2) matName sp nl to:stream
			if (mat.base_color_map != undefined) then
			(
				textureFilePath = mat.base_color_map.bitmap.filename
				tokens = (filterString textureFilePath "\\")
				textureFileName = tokens[tokens.count]
				format "%\"cm\":%\"%\",%" (tabs 3) sp textureFileName nl to:stream -- Color Map
			)
			format "%\"cl\":%[%,%,%],%" (tabs 3) sp (fp mat.Base_Color.r) (fp mat.Base_Color.g) (fp mat.Base_Color.b) nl to:stream -- Color
			format "%\"sp\":%[%,%,%],%" (tabs 3) sp (fp mat.refl_color.r) (fp mat.refl_color.g) (fp mat.refl_color.b) nl to:stream -- Specular
			format "%\"op\":%%,%" (tabs 3) sp (fp (1 - mat.Transparency)) nl to:stream -- Opacity
			format "%\"sd\":%\"double\"%" (tabs 3) sp nl to:stream -- Side
			format "%}" (tabs 2) to:stream
		)
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
	format "%\"materials\": {%" (tabs 1) nl to:Listener
	local materials = #()
	for obj in objects do
	(
		if (isGeometry obj) then
		(
			select obj
			max modify mode
			appendIfUnique materials obj.material
		)
	)
	local firstMat = true
	for mat in materials do
	(
		if (firstMat == false) then
		(
			format ",%" nl to:Listener
		)
		formatMaterial mat Listener
		firstMat = false
	)
	format "%%}%" nl (tabs 1) nl to:Listener
	format "}%" nl to:Listener
)
resumeEditing()
enableSceneRedraw()
