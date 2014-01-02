-- GLOBAL TOOLS

-- GLOBAL VARIABLES
--global AXIS_TRANSFORM = matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0] -- 3dsmax axis (no change)
global AXIS_TRANSFORM = matrix3 [1,0,0] [0,0,-1] [0,1,0] [0,0,0] -- openGL axis

-- FUNCTIONS
function formatVector3 v =
(
	local v3str = stringStream ""
	format "[%,%,%]" v.x v.y v.z to:v3str
	return (v3str as string)
)

function formatQuaternion q =
(
	local qstr = stringStream ""
	format "[%,%,%,%]" q.x q.y q.z q.w to:qstr
	return (qstr as string)
)

function arrayToString arr separator =
(
	local dzastr = string
	for c = 1 to arr.count do
	(
		if (c > 1) then
		(
			dzastr += separator
		)
		dzastr += arr[c]
	)
	return dzastr
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
	local myTransform = myObject.transform * AXIS_TRANSFORM
	
	-- if parent exists
	if (myObject.parent != undefined) then
	(
		-- transform og the parent converted to OpenGL axis
		local parentTransform = myObject.parent.transform * AXIS_TRANSFORM
		-- compute the "relative to parent" transform
		myTransform = myTransform * (inverse parentTransform)
	)
	-- if no parent
	else
	(
		myTransform = (inverse myTransform)
	)
	
	-- return converted transform
	return myTransform
)

-- convert a simple 3D point to openGL axis
function point3ForOpenGL myPoint3 =
(
	return (myPoint3 * AXIS_TRANSFORM)
)
