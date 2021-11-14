-- MESH EXPORTER (ALM)

include "tools/tools.ms"
include "tools/tools_mesh.ms"
include "tools/tools_anim.ms"

clearListener()

fn export =
(
	filepath = getSaveFileName caption:"Location for saving the Mesh file" types:"JSON (json)|*.json|Plain Text (txt)|*.txt|All Files|*.*|"
	
	if (filepath != undefined) then
	(
		deleteFile filepath
		file = createFile filepath
		
		mySelection = getCurrentSelection()
		
		startTime = timeStamp()
		
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
		
		endTime = timeStamp()
		
		close file
		
		clearselection
		select mySelection
		
		messageBox ("Export succeed (" + (((endTime - startTime) / 1000.0) as string) + " seconds).") title:"ALLoader exporter" beep:false
	)
	else
	(
		messageBox "Export canceled." title:"ALLoader exporter" beep:false
	)
)

rollout ALExporter "ALLoader exporter"
(
	checkbox flipYZCheckBox "Flip YZ-axis (Poser-like)" checked:true
	
	--checkbox exportMeshesCheckBox "Export meshes" checked:true
	
	--checkbox exportMaterialsCheckBox "Export materials" checked:true
	
	--checkbox exportSkinsCheckBox "Export Skins" checked:true
	
	checkbox customAnimNameCheckbox "Custom animation name" checked:customAnimName

	spinner decimalsSpinner "Decimals of floats" range:[0,10,4] type:#integer scale:1
	
	button exportButton "Export"
	
	on exportButton pressed do
	(
		flipYZ = flipYZCheckBox.checked
		
		--exportMeshes = exportMeshesCheckBox.checked
		
		--exportMaterials = exportMaterialsCheckBox.checked
		
		--exportSkins = exportSkinsCheckBox.checked
		
		customAnimName = customAnimNameCheckbox.checked
		
		formattedPrintFormat = "." + (decimalsSpinner.value as string) + "g"
		
		export()
		
		destroydialog ALExporter
	)
)

disableSceneRedraw()
suspendEditing()

undo on
(
	createdialog ALExporter
)

resumeEditing()
enableSceneRedraw()

print "Script ended"
