-- MESH EXPORTER (ALM)

include "tools.ms"
include "tools_mesh.ms"
include "tools_anim.ms"

clearListener()

function export =
(
	mySelection = getCurrentSelection()

	filepath = getSaveFileName caption:"Location for saving the Mesh file" types:"JSON (*.json)|*.json|Plain Text (*.txt)|*.txt|All Files (*.*)|*.*|"
	
	myObjects = #()
	for o in objects do
	(
		if (isGeometry o) then
		(
			append myObjects o
		)
	)
	
	mySubMeshes = processObjects myObjects
	
	if (filepath != undefined) then
	(
		deleteFile filepath
		file = createFile filepath
		
		formatObjects mySubMeshes file
		
		close file
	)
	
	clearselection
	select mySelection
)

rollout ALExporter "ALExporter"
(
	checkbox flipYZCheckBox "Flip YZ-axis (Poser-like)" checked:true
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
		export()
		destroydialog ALExporter
	)
)

createdialog ALExporter
