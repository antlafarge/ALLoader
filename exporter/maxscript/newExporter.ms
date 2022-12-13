include "tools/globals.ms"
include "tools/tools.ms"
include "tools/formatObject.ms"

clearListener()

fn export =
(
	local filepath = getSaveFileName caption:"Location for saving the Mesh file" types:"JSON (json)|*.json|Plain Text (txt)|*.txt|All Files|*.*|"
	
	if (filepath != undefined) then
	(
		deleteFile filepath
		local file = createFile filepath
		
		local mySelection = getCurrentSelection()
        local mySelectionTmp = mySelection
		
        if (mySelection.count == 0) then
        (
            mySelectionTmp = objects
        )

		local startTime = timeStamp()
		
	    format "{%" nl to:file
	    format "%\"version\":%\"0.2\",%" (tabs 1) sp nl to:file
	    format "%\"data\":%[%" (tabs 1) sp nl to:file
	
		for obj in mySelectionTmp do
		(
			if (isGeometry obj) then
			(
                select obj
                max modify mode
				formatObject obj
			)
		)
	
        format "%%]%}%" nl (tabs 1) nl nl to:file
		
		local endTime = timeStamp()
		
		close file
		
		clearselection
		select mySelection
		
		messageBox ("Export complete (" + (((endTime - startTime) / 1000.0) as string) + " seconds).") title:"ALLoader exporter" beep:false
	)
	else
	(
		messageBox "Export cancel." title:"ALLoader exporter" beep:false
	)
)

rollout ALExporter "ALLoader exporter"
(
	checkbox flipYZCheckbox "Flip YZ-axis (Poser-like)" checked:true
	
	--checkbox exportMeshesCheckbox "Export meshes" checked:true
	
	--checkbox exportMaterialsCheckbox "Export materials" checked:true
	
	--checkbox exportSkinsCheckbox "Export Skins" checked:true
	
	checkbox customAnimNameCheckbox "Custom animation name" checked:false

	spinner decimalsSpinner "Decimals" range:[0,9,4] type:#integer scale:1
	
	checkbox compressJsonCheckbox "Compress JSON" checked:false

	button exportButton "Export"
	
	on exportButton pressed do
	(
		local compressJson = compressJsonCheckbox.checked

		if (not compressJson) then
		(
			nl = "\n"
            cnl = ",\n"
			sp = " "
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

print "Script end"
