-- GLOBAL TOOLS

-- GLOBAL VARIABLES
global AXIS_TRANSFORM = matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0] -- no change
--global AXIS_TRANSFORM = matrix3 [1,0,0] [0,0,-1] [0,1,0] [0,0,0] -- openGL axis

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
