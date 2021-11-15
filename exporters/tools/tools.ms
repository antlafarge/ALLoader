-- GLOBAL TOOLS

-- GLOBAL VARIABLES

global flipYZ = true
global flipYZ_transform = matrix3 [1,0,0] [0,0,-1] [0,1,0] [0,0,0] -- matrix to transform to default opengl axis

global exportMeshes = true
global exportMaterials = true
global exportSkins = true

global customAnimName = false

global formattedPrintFormat = ".5g"

global compressJson = false

global TAB = 0

global TAB_ARRAY = #( "\t" )

global nl = "\n"

global sp = " "

-- FUNCTIONS

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
	local count = pieces.count
	for index = 1 to count do
	(
		format "%%" (if index > 1 then "," else "") (fp pieces[index]) to:stream
	)
	stream as string
)

fn formatPoint3Array pieces =
(
	local stream = stringstream ""
	local count = pieces.count
	local myPoint3
	for index = 1 to count do
	(
		myPoint3 = pieces[index]
		format "%%,%,%" (if index > 1 then "," else "") (fp myPoint3.x) (fp myPoint3.y) (fp myPoint3.z) to:stream
	)
	stream as string
)

fn formatQuatArray pieces =
(
	local stream = stringstream ""
	local count = pieces.count
	local myQuat
	for index = 1 to count do
	(
		myQuat = pieces[index]
		format "%%,%,%,%" (if index > 1 then "," else "") (fp q4.x) (fp q4.y) (fp q4.z) (fp q4.w) to:stream
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
