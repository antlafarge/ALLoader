-- Return the cached number of tabulations if output is not compressed
fn tabs tab =
(
	if (compressJson) then
	(
		""
	)
	else
	(
		local count = TAB_ARRAY.count
		if (tab > count) then
		(
			for tabIndex = count + 1 to tab do
			(
				TAB_ARRAY[tabIndex] = TAB_ARRAY[tabIndex - 1] + "\t"
			)
		)
		TAB_ARRAY[tab]
	)
)

fn fp value =
(
	formattedPrint value format:formattedPrintFormat
)

fn formatPoint3 myPoint3 =
(
	fp myPoint3
)

fn formatQuaternion myQuat =
(
	local stream = stringstream ""
	format "[%,%,%,%]" (fp myQuat.x) (fp myQuat.y) (fp myQuat.z) (fp myQuat.w) to:stream
	stream as string
)

fn formatArray pieces =
(
	local stream = stringstream ""
	if (pieces != undefined) then
	(
		local count = pieces.count
		for index = 1 to count do
		(
			format "%%" (fp pieces[index]) (if index != count then "," else "") to:stream
		)
	)
	stream as string
)

fn formatArrayAsInteger pieces =
(
	local stream = stringstream ""
	if (pieces != undefined) then
	(
		local count = pieces.count
		for index = 1 to count do
		(
			format "%%" (pieces[index] as integer) (if index != count then "," else "") to:stream
		)
	)
	stream as string
)

fn formatUvArray pieces =
(
	local stream = stringstream ""
	if (pieces != undefined) then
	(
		local count = pieces.count
		for index = 1 to count do
		(
			local piece = pieces[index]
			format "%,%,%%%" (fp piece.x) (fp piece.y) (if index != count then "," else "") sp to:stream
		)
	)
	stream as string
)

fn formatPoint3Array pieces =
(
	local stream = stringstream ""
	if (pieces != undefined) then
	(
		local count = pieces.count
		for index = 1 to count do
		(
			local piece = pieces[index]
			format "%,%,%%%" (fp piece.x) (fp piece.y) (fp piece.z) (if index != count then "," else "") sp to:stream
		)
	)
	stream as string
)

fn formatColorRgbaArray pieces =
(
	local stream = stringstream ""
	if (pieces != undefined) then
	(
		local count = pieces.count
		for index = 1 to count do
		(
			local piece = pieces[index]
			format "%,%,%,%%%" (fp piece.r) (fp piece.g) (fp piece.b) (fp piece.a) (if index != count then "," else "") sp to:stream
		)
	)
	stream as string
)

fn formatColorRgbArray pieces =
(
	local stream = stringstream ""
	if (pieces != undefined) then
	(
		local count = pieces.count
		for index = 1 to count do
		(
			local piece = pieces[index]
			format "%,%,%%%" (fp piece.r) (fp piece.g) (fp piece.b) (if index != count then "," else "") sp to:stream
		)
	)
	stream as string
)

fn formatQuatArray pieces =
(
	local stream = stringstream ""
	if (pieces != undefined) then
	(
		local count = pieces.count
		for index = 1 to count do
		(
			local myQuat = pieces[index]
			format "%,%,%,%%%" (fp q4.x) (fp q4.y) (fp q4.z) (fp q4.w) (if count != count then "," else "") sp to:stream
		)
	)
	stream as string
)

fn isBone o =
(
	(classof o) == BoneGeometry
)

fn isGeometry o =
(
	((Superclassof o) == GeometryClass) and ((classof o) != BoneGeometry)
)

-- function that compute the relative (from parent) transform matrix and convert it to openGL axis
fn getRelativeTransformForOpenGL myObject =
(
	-- transform of the object converted to OpenGL axis
	local myTransform = (if (flipYZ) then (myObject.transform * flipYZ_transform) else myObject.transform)
	
	local parent = myObject.parent
	
	-- if a parent exists
	if (parent != undefined) then
	(
		myTransform *= inverse (if (flipYZ) then (parent.transform * flipYZ_transform) else parent.transform)
	)
	
	-- return converted transform
	myTransform
)

-- convert a 3d point to openGL axis
fn point3ForOpenGL myPoint3 =
(
	if flipYZ then (myPoint3 * flipYZ_transform) else myPoint3
)

-- convert a quaternion orientation to openGL axis
fn quatForOpenGL myQuat =
(
	if flipYZ then (myQuat * flipYZ_transform) else myQuat
)

fn export objectsToExport exportMaterials exportSkins exportMeshes exportAnimations stream =
(
	disableSceneRedraw()
	suspendEditing()
	nl = "\n"
	cnl = ",\n"
	sp = " "
	undo on
	(
		format "{%" nl to:stream
		format "%\"version\":%\"0.1\"" (tabs 1) sp to:stream
		
		local started = false
		if (exportMaterials) then
		(
			format ",%%\"materials\":%{%" nl (tabs 1) sp nl to:stream
			local materials = #()
			for obj in objectsToExport do
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
					format ",%" nl to:stream
				)
				formatMaterial mat stream
				firstMat = false
			)
			format "%%}" nl (tabs 1) to:stream
			started = true
		)
		
		if (exportSkins) then
		(
			format ",%%\"skeletons\":%{%" nl (tabs 1) sp nl to:stream
			for obj in objectsToExport do
			(
				if (isGeometry obj) then
				(
					select obj
					max modify mode
					formatSkeleton obj stream
				)
			)
			format "%}" (tabs 1) to:stream
			started = true
		)
		
		if (exportMeshes) then
		(
			format ",%%\"meshes\":%{%" nl (tabs 1) sp nl to:stream
			for obj in objectsToExport do
			(
				if (isGeometry obj) then
				(
					select obj
					max modify mode
					formatObject obj stream
				)
			)
			format "%}" (tabs 1) to:stream
			started = true
		)
		
		if (exportAnimations) then
		(
			format ",%%\"animations\":%{%" nl (tabs 1) sp nl to:stream
			for obj in objectsToExport do
			(
				if (isGeometry obj) then
				(
					select obj
					max modify mode
					formatAnimation obj stream
				)
			)
			format "%}" (tabs 1) to:stream
			started = true
		)
		
		format "%}%" nl nl to:stream
	)
	resumeEditing()
	enableSceneRedraw()
)
