-- GLOBAL TOOLS

-- GLOBAL VARIABLES

global flipYZ = true
global flipYZ_transform = matrix3 [1,0,0] [0,0,-1] [0,1,0] [0,0,0] -- matrix to transform to default opengl axis

global exportMeshes = true
global exportMaterials = true
global exportSkins = true

global customAnimName = false

global formattedPrintFormat = ".4g"

global tabs = 0

-- FUNCTIONS

fn fp v =
(
	formattedPrint v format:formattedPrintFormat
)

fn formatPoint3 myPoint3 =
(
	formattedPrint myPoint3
)

fn formatQuaternion myQuat =
(
	local ss = stringstream ""
	format "[%,%,%,%]" (fp myQuat.x) (fp myQuat.y) (fp myQuat.z) (fp myQuat.w) to:ss
	ss as string
)

fn formatArray pieces =
(
	local ss = stringstream ""
	local sz = pieces.count
	for i = 1 to sz do
	(
		format "%%" (if i > 1 then "," else "") pieces[i] to:ss
	)
	ss as string
)

fn formatPoint3Array pieces =
(
	local ss = stringstream ""
	local sz = pieces.count
	local myPoint3
	for i = 1 to sz do
	(
		myPoint3 = pieces[i]
		format "%%,%,%" (if i > 1 then "," else "") (fp myPoint3.x) (fp myPoint3.y) (fp myPoint3.z) to:ss
	)
	ss as string
)

fn formatQuatArray pieces =
(
	local ss = stringstream ""
	local sz = pieces.count
	local myQuat
	for i = 1 to sz do
	(
		myQuat = pieces[i]
		format "%%,%,%,%" (if i > 1 then "," else "") (fp q4.x) (fp q4.y) (fp q4.z) (fp q4.w) to:ss
	)
	ss as string
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
