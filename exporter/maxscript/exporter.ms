local exporter = true

fileIn "tools/globals.mxs"
fileIn "tools/tools.mxs"
fileIn "tools/formatMaterial.ms"
fileIn "tools/formatSkeleton.ms"
fileIn "tools/formatMesh.ms"
fileIn "tools/formatAnimation.ms"
fileIn "tools/export.mxs"

fn launchExport =
(
	local filepath = getSaveFileName caption:"File location" types:"JSON (json)|*.json|Plain Text (txt)|*.txt|All Files|*.*|"
	
	if (filepath != undefined) then
	(
		deleteFile filepath
		local file = createFile filepath
		
		local mySelection = getCurrentSelection()
        local objectsToExport = mySelection
		
        if (mySelection.count == 0) then
        (
            objectsToExport = objects
        )
		
		local startTime = timeStamp()
		
		export objectsToExport exportMaterials exportSkins exportMeshes exportAnimations file
		
		local endTime = timeStamp()
		
		close file
		
		clearselection
		select mySelection
		
		messageBox ("Export completed (" + (((endTime - startTime) / 1000.0) as string) + " seconds).") title:"ALLoader exporter" beep:false
	)
	else
	(
		messageBox "Export cancelled." title:"ALLoader exporter" beep:false
	)
)

rollout ALExporter "ALLoader exporter"
(
	checkbox flipYZCheckbox "Flip YZ-axis (Poser-like)" checked:true
	
	checkbox exportMaterialsCheckbox "Export materials" checked:true
	
	checkbox exportSkinsCheckbox "Export Skins" checked:true
	
	checkbox exportMeshesCheckbox "Export meshes" checked:true
	
	checkbox exportAnimationsCheckbox "Export Animations" checked:true
	
	edittext animNameTmp "Animation name" text:"Animation_1" labelOnTop:true
	
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
		
		exportMaterials = exportMaterialsCheckbox.checked
		
		exportSkins = exportSkinsCheckbox.checked
		
		exportMeshes = exportMeshesCheckbox.checked
		
		exportAnimations = exportAnimationsCheckbox.checked
		
		animName = animNameTmp.text
		
		formattedPrintFormat = "." + ((decimalsSpinner.value + 1) as string) + "g"
		
		launchExport()
		
		destroydialog ALExporter
	)
)

undo on
(
	clearListener()
	createdialog ALExporter
)

print "End of script"
