-- MESH EXPORTER (ALM)

include "tools.ms"
include "tools_mesh.ms"
include "tools_anim.ms"

clearListener()

function export =
(
	filepath = getSaveFileName caption:"Location for saving the Mesh file" types:"JSON (*.json)|*.json|Plain Text (*.txt)|*.txt|All Files (*.*)|*.*|"
	
	if (filepath == undefined) then
	(
		return false
	)
	
	deleteFile filepath
	file = createFile filepath

	mySelection = getCurrentSelection()

	myObjects = #()
	for o in objects do
	(
		if (isGeometry o) then
		(
			append myObjects o
		)
	)
	
	mySubMeshes = processObjects myObjects
	
	formatObjects mySubMeshes file
	
	close file

	clearselection
	select mySelection
	
	return true
)

rollout ALExporter "ALLoader exporter"
(
	checkbox flipYZCheckBox "Flip YZ-axis (Poser-like)" checked:false
	
	--checkbox exportMeshesCheckBox "Export meshes" checked:true
	
	--checkbox exportMaterialsCheckBox "Export materials" checked:true
	
	--checkbox exportSkinsCheckBox "Export Skins" checked:true
	
	button exportButton "Export"
	
	on exportButton pressed do
	(
		if (flipYZCheckBox.checked == true) then
		(
			FlipYZ_transform = FlipYZ_transform_opengl
		)
		else
		(
			FlipYZ_transform = FlipYZ_transform_nochange
		)
		
		--exportMeshes = exportMeshesCheckBox.checked
		
		--exportMaterials = exportMaterialsCheckBox.checked
		
		--exportSkins = exportSkinsCheckBox.checked
		
		result = export()
		
		destroydialog ALExporter
		
		if (result == true) then
		(
			messageBox "Export succeed." title:"ALLoader exporter" beep:false
		)
		else
		(
			messageBox "Export canceled." title:"ALLoader exporter" beep:false
		)
	)
)

createdialog ALExporter
