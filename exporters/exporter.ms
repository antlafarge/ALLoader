-- MESH EXPORTER (ALM)

include "tools.ms"
include "tools_mesh.ms"
include "tools_anim.ms"

clearListener()

mySelection = getCurrentSelection()

if (mySelection.count > 0) then
(
	filepath = getSaveFileName caption:"Location for saving the Mesh file" types:"JSON (*.json)|*.json|Plain Text (*.txt)|*.txt|All Files (*.*)|*.*|"
	
	mySubMeshes = processObjects mySelection
	
	if (filepath != undefined) then
	(
		deleteFile filepath
		file = createFile filepath
		
		formatObjects mySubMeshes file
		
		close file
	)
)
else
(
	messageBox "No objects selected."
)

select mySelection
