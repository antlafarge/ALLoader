-- MESH EXPORTER (ALM)

include "tools/tools.ms"
include "tools/tools_mesh.ms"
include "tools/tools_anim.ms"

clearListener()

function export =
(
	filepath = getSaveFileName caption:"Location for saving the Mesh file" types:"JSON (json)|*.json|Plain Text (txt)|*.txt|All Files|*.*|"
	
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
	
	checkbox customAnimNameCheckbox "Custom animation name" checked:customAnimName

	spinner decimalsSpinner "Decimals of floats" range:[0,10,decimalsOfFloats] type:#integer scale:1
	
	button exportButton "Export"
	
	on exportButton pressed do
	(
		if (flipYZCheckBox.checked) then
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

		customAnimName = customAnimNameCheckbox.checked

		decimalsOfFloats = decimalsSpinner.value
		
		result = export()
		
		destroydialog ALExporter
		
		if (result) then
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
