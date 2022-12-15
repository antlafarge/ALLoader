fileIn "globals.ms"

-- Return the cached number of tabulations if output is not compressed
fn tabs tab =
(
	format "tabs %" tab
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
	local count = pieces.count
	if (count > 0) then
	(
		format "%" (fp pieces[1]) to:stream
		for index = 2 to count do
		(
			format ",%" (fp pieces[index]) to:stream
		)
	)
	stream as string
)

fn formatArrayAsInteger pieces =
(
	local stream = stringstream ""
	local count = pieces.count
	if (count > 0) then
	(
		format "%" (pieces[1] as integer) to:stream
		for index = 2 to count do
		(
			format ",%" (pieces[index] as integer) to:stream
		)
	)
	stream as string
)

fn formatUvArray pieces =
(
	local stream = stringstream ""
	local count = pieces.count
	if (count > 0) then
	(
		local piece = pieces[1]
		format "%,%,%" (fp piece.x) (fp piece.y) to:stream
		for index = 2 to count do
		(
			piece = pieces[index]
			format ",%,%,%" (fp piece.x) (fp piece.y) to:stream
		)
	)
	stream as string
)

fn formatPoint3Array pieces =
(
	local stream = stringstream ""
	local count = pieces.count
	if (count > 0) then
	(
		local piece = pieces[1]
		format "%,%,%" (fp piece.x) (fp piece.y) (fp piece.z) to:stream
		for index = 2 to count do
		(
			piece = pieces[index]
			format ",%,%,%" (fp piece.x) (fp piece.y) (fp piece.z) to:stream
		)
	)
	stream as string
)

fn formatColorRgbaArray pieces =
(
	local stream = stringstream ""
	local count = pieces.count
	if (count > 0) then
	(
		local piece = pieces[1]
		format "%,%,%,%" (fp piece.r) (fp piece.g) (fp piece.b) (fp piece.a) to:stream
		for index = 2 to count do
		(
			piece = pieces[index]
			format ",%,%,%,%" (fp piece.r) (fp piece.g) (fp piece.b) (fp piece.a) to:stream
		)
	)
	stream as string
)

fn formatColorRgbArray pieces =
(
	local stream = stringstream ""
	local count = pieces.count
	if (count > 0) then
	(
		local piece = pieces[1]
		format "%,%,%" (fp piece.r) (fp piece.g) (fp piece.b) to:stream
		for index = 2 to count do
		(
			piece = pieces[index]
			format ",%,%,%" (fp piece.r) (fp piece.g) (fp piece.b) to:stream
		)
	)
	stream as string
)

fn formatQuatArray pieces =
(
	local stream = stringstream ""
	local count = pieces.count
	if (count > 0) then
	(
		local myQuat = pieces[1]
		format "%,%,%,%" (fp q4.x) (fp q4.y) (fp q4.z) (fp q4.w) to:stream
		for index = 2 to count do
		(
			myQuat = pieces[index]
			format ",%,%,%,%" (fp q4.x) (fp q4.y) (fp q4.z) (fp q4.w) to:stream
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
