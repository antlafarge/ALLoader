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
	checkbox flipYZCheckbox "Flip YZ-axis (Poser-like)" checked:true
	
	--checkbox exportMeshesCheckbox "Export meshes" checked:true
	
	--checkbox exportMaterialsCheckbox "Export materials" checked:true
	
	--checkbox exportSkinsCheckbox "Export Skins" checked:true
	
	checkbox customAnimNameCheckbox "Custom animation name" checked:customAnimName

	spinner decimalsSpinner "Decimals of floats" range:[0,9,4] type:#integer scale:1
	
	checkbox compressJsonCheckbox "Compress JSON" checked:false

	button exportButton "Export"
	
	on exportButton pressed do
	(
		compressJson = compressJsonCheckbox.checked

		if (compressJson) then
		(
			nl = ""
			sp = ""
		)

		flipYZ = flipYZCheckbox.checked
		
		--exportMeshes = exportMeshesCheckbox.checked
		
		--exportMaterials = exportMaterialsCheckbox.checked
		
		--exportSkins = exportSkinsCheckbox.checked
		
		customAnimName = customAnimNameCheckbox.checked
		
		formattedPrintFormat = "." + ((decimalsSpinner.value + 1) as string) + "g"
		
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
