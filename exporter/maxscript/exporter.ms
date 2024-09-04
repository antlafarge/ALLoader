clearListener()

fileIn "tools/globals.ms"
fileIn "tools/tools.ms"
fileIn "tools/formatMaterial.ms"
fileIn "tools/formatSkeleton.ms"
fileIn "tools/formatMesh.ms"
fileIn "tools/formatAnimation.ms"

fn export =
(
	local filepath = getSaveFileName caption:"File location" types:"JSON (json)|*.json|Plain Text (txt)|*.txt|All Files|*.*|"
	
	if (filepath != undefined) then
	(
		deleteFile filepath
		local file = createFile filepath
		
		--local stream = file
		local stream = listener
		
		local mySelection = getCurrentSelection()
        local mySelectionTmp = mySelection
		
        if (mySelection.count == 0) then
        (
            mySelectionTmp = objects
        )
		
		local startTime = timeStamp()
		format "%%" animName nl to:stream
	    format "{%" nl to:stream
	    format "%\"version\":%\"0.1\",%" (tabs 1) sp nl to:stream
	    format "%\"meshes\":%[%" (tabs 1) sp nl to:stream
		
		for obj in mySelectionTmp do
		(
			if (isGeometry obj) then
			(
                select obj
                max modify mode
				--formatObject obj stream
			)
		)
		
        format "%%]%}%" nl (tabs 1) nl nl to:stream
		
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

print "End of script"
