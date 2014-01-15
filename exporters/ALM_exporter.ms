-- MESH EXPORTER (ALM)

include "tools.ms"
include "ALM_tools.ms"

clearListener()

mySelection = getCurrentSelection()

if (mySelection.count > 0) then
(
	mesh_filepath = getSaveFileName caption:"Location for saving the Mesh file" types:"JSON (*.json)|*.json|Plain Text (*.txt)|*.txt|All Files (*.*)|*.*|"
	
	mySubMeshes = processObjects mySelection
	
	if (mesh_filepath != undefined) then
	(
		deleteFile mesh_filepath
		mesh_file = createFile mesh_filepath
		
		formatObjects mySubMeshes mesh_file
		
		close mesh_file
	)
)
else
(
	messageBox "No objects selected."
)

select mySelection
