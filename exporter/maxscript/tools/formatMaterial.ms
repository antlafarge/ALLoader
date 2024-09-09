-- DEBUG
if (exporter != true) then
(
	fileIn "globals.ms"
	fileIn "tools.ms"
)

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
		format "%}%" (tabs 2) nl to:stream
	)
	else if ((classof mat) == MultiMaterial) then
	(
		-- Extract material names
		local materials = #()
		for index = 1 to mat.materialList.count do
		(
			if (mat.materialList[index] != undefined) then
			(
				append materials mat.materialList[index]
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
			for index = 1 to materials.count do
			(
				local mat = materials[index];
				format "%%%%" (tabs 4) (if mat != undefined then ("\"" + mat.name + "\"") else "null") (if index != materials.count then "," else "") nl to:stream
			)
		)

		format "%]%" (tabs 3) nl to:stream
		format "%}%" (tabs 2) nl to:stream

		-- recursive parse of sub-materials
		for index = 1 to materials.count do
		(
			if (materials[index] != undefined) then
			(
				format "%,%" (tabs 2) nl to:stream
				formatMaterial materials[index] stream
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
if (exporter != true) then
(
	clearListener()
	export objects true false false false Listener
)
