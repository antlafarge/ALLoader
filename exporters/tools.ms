-- TOOLS FOR THE EXPORTERS

function isGeometry o =
(
	return (((Superclassof o) == GeometryClass) and ((classof o) != BoneGeometry))
)

function isBone o =
(
	return ((classof o) == BoneGeometry)
)

function pf3 f =
(
	--return ((ceil (f * 10000)) / 10000) 
	return f
)

function formatVector3 v =
(
	x = pf3 v.x
	y = pf3 v.y
	z = pf3 v.z
	str = stringStream ""
	format "[%,%,%]" x y z to:str
	return (str as string)
)

function formatQuaternion q =
(
	x = pf3 q.x
	y = pf3 q.y
	z = pf3 q.z
	w = pf3 q.w
	str = stringStream ""
	format "[%,%,%,%]" x y z w to:str
	return (str as string)
)

function formatMatrix3 m =
(
	m1x = pf3 m.row1.x
	m1y = pf3 m.row1.y
	m1z = pf3 m.row1.z
	m2x = pf3 m.row2.x
	m2y = pf3 m.row2.y
	m2z = pf3 m.row2.z
	m3x = pf3 m.row3.x
	m3y = pf3 m.row3.y
	m3z = pf3 m.row3.z
	m4x = pf3 m.row4.x
	m4y = pf3 m.row4.y
	m4z = pf3 m.row4.z
	str = stringStream ""
	format "[%,%,%,%,%,%,%,%,%,%,%,%]" m1x m1y m1z m2x m2y m2z m3x m3y m3z m4x m4y m4z to:str
	return (str as string)
)
