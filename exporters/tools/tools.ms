-- GLOBAL TOOLS

-- GLOBAL VARIABLES
global FlipYZ_transform_nochange = matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0] -- 3dsmax axis (no change)
global FlipYZ_transform_opengl = matrix3 [1,0,0] [0,0,-1] [0,1,0] [0,0,0] -- openGL axis

global FlipYZ_transform = FlipYZ_transform_nochange

global exportMeshes = true
global exportMaterials = true
global exportSkins = true

global customAnimName = false

global decimalsOfFloats = 4

global TABS = 0

-- FUNCTIONS

function toFixed num digits:decimalsOfFloats =
(
	local mult = 10.0 ^ digits
	res = (floor((num * mult) + 0.5)) / mult
	return (trimRight (trimRight (res as string) "0") ".")
)

function formatVector3 v =
(
	("[" + (toFixed v.x) + "," + (toFixed v.y) + "," + (toFixed v.z) + "]")
)

function formatQuaternion q =
(
	("[" + (toFixed q.x) + "," + (toFixed q.y) + "," + (toFixed q.z) + "," + (toFixed q.w) + "]")
)

function implode glue pieces =
(
	local glueStr = (glue as string)
	local str = ""
	for i = 1 to pieces.count do
	(
		if (i > 1) then
		(
			str += glueStr
		)
		str += (pieces[i] as string)
	)
	return str
)

function implodeInteger glue pieces =
(
	local glueStr = (glue as string)
	local str = ""
	for i = 1 to pieces.count do
	(
		if (i > 1) then
		(
			str += glueStr
		)
		str += ((pieces[i] as integer) as string)
	)
	return str
)

function implodePoint3 glue pieces =
(
	local glueStr = (glue as string)
	local str = ""
	for i = 1 to pieces.count do
	(
		if (i > 1) then
		(
			str += glueStr
		)
		local p3 = pieces[i]
		str += ((toFixed p3.x) + glueStr + (toFixed p3.y) + glueStr + (toFixed p3.z))
	)
	return str
)

function implodeQuat glue pieces =
(
	local glueStr = (glue as string)
	local str = ""
	for i = 1 to pieces.count do
	(
		if (i > 1) then
		(
			str += glueStr
		)
		local q4 = pieces[i]
		str += ((toFixed q4.x) + glueStr + (toFixed q4.y) + glueStr + (toFixed q4.z) + glueStr + (toFixed q4.w))
	)
	return str
)

function isBone o =
(
	return ((classof o) == BoneGeometry)
)

function isGeometry o =
(
	return (((Superclassof o) == GeometryClass) and ((classof o) != BoneGeometry))
)

-- function that compute the relative (from parent) transform matrix and convert it to openGL axis
function getRelativeTransformForOpenGL myObject =
(
	-- transform of the object converted to OpenGL axis
	local myTransform = myObject.transform * FlipYZ_transform
	
	-- if a parent exists
	if (myObject.parent != undefined) then
	(
		myTransform *= inverse (myObject.parent.transform * FlipYZ_transform)
	)
	
	-- return converted transform
	return myTransform
)

-- convert a 3d point to openGL axis
function point3ForOpenGL myPoint3 =
(
	return (myPoint3 * FlipYZ_transform)
)

-- convert a quaternion orientation to openGL axis
function quatForOpenGL q =
(
	return (q * FlipYZ_transform)
)
