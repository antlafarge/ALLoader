fileIn "tools/globals.mxs"
fileIn "tools/tools.mxs"
fileIn "tools/formatMaterial.mxs"
fileIn "tools/formatSkeleton.mxs"
fileIn "tools/formatMesh.mxs"
fileIn "tools/formatAnimation.mxs"
fileIn "tools/export.mxs"

fn launchExport =
(
	filepath = getSaveFileName caption:"File location" types:"JSON (json)|*.json|Plain Text (txt)|*.txt|All Files|*.*|"
	
	if (filepath != undefined) then
	(
		deleteFile filepath
		file = createFile filepath
		
		mySelection = getCurrentSelection()
        objectsToExport = mySelection
		
        if (mySelection.count == 0) then
        (
            objectsToExport = objects
        )
		
		startTime = timeStamp()
		
		export objectsToExport exportMaterials exportSkins exportMeshes exportAnimations file
		
		endTime = timeStamp()
		
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
	radiobuttons exportObjects "Export" labels:#("selection", "all objects") default:1 columns:1

	checkbox exportMeshesCheckbox "Export meshes" checked:true

	Group "Meshes"
	(
		checkbox exportMeshAssociatedMaterialCheckbox "Associated material (mt)" checked:true
		checkbox exportMeshPositionCheckbox "Position (ps)" checked:true
		checkbox exportMeshRotationCheckbox "Rotation (rt)" checked:true
		checkbox exportMeshScaleCheckbox "Scale (sc)" checked:true
		checkbox exportMeshVerticesCheckbox "Vertices (vp)" checked:true
		checkbox exportMeshIndexedVerticesCheckbox "Indexed vertices (vi)" checked:true
		checkbox exportMeshFaceNormalsCheckbox "Face normals (fn)" checked:true
		checkbox exportMeshUVsCheckbox "Texture coordinates (uv)" checked:true
		checkbox exportMeshIndexedUVsCheckbox "Indexed texture coordinates UV (ui)" checked:true
		checkbox exportMeshAssociatedSkinCheckbox "Associated skin (sk)" checked:true
		checkbox exportMeshSkinIndicesCheckbox "Skin indices (si)" checked:true
		checkbox exportMeshSkinWeightsCheckbox "Skin weights (sw)" checked:true
	)
	
	checkbox exportMaterialsCheckbox "Export materials" checked:true

	Group "Materials"
	(
		checkbox exportMaterialBaseColorCheckbox "Base color (cl)" checked:true
		checkbox exportMaterialBaseColorMapCheckbox "Base color map (cm)" checked:true
		checkbox exportMaterialBaseColorIfNoBaseColorMapCheckbox "Base color only if no Base color map" checked:true
		checkbox exportMaterialSpecularColorCheckbox "Specular color (sp)" checked:true
		checkbox exportMaterialTransparencyCheckbox "Transparency (op)" checked:true
	)
	checkbox exportSkinsCheckbox "Export Skins" checked:true
	
	Group "Skins"
	(
		checkbox exportSkinBoneParentCheckbox "Bone parent (pr)" checked:true
		checkbox exportSkinBonePositionCheckbox "Bone position (ps)" checked:true
		checkbox exportSkinBoneRotationCheckbox "Bone rotation (rt)" checked:true
		checkbox exportSkinBoneScaleCheckbox "Bone scale (sc)" checked:true
	)

	checkbox exportAnimationsCheckbox "Export Animations" checked:true

	Group "Animations"
	(
		edittext animNameEditText "Animation name" text:"Animation" labelOnTop:true
		checkbox exportAnimationAssociatedSkinCheckbox "Associated skin (sk)" checked:true
		checkbox exportAnimationAssociatedMeshCheckbox "Associated mesh (ms)" checked:true
		checkbox exportAnimationBonePositionCheckbox "Bone position (ps)" checked:true
		checkbox exportAnimationBoneRotationCheckbox "Bone rotation (rt)" checked:true
		checkbox exportAnimationBoneScaleCheckbox "Bone scale (sc)" checked:true
	)
	
	group "Options"
	(
		checkbox flipYZCheckbox "Flip YZ-axis (Poser-like)" checked:true
		spinner decimalsSpinner "Decimals count" range:[0,9,4] type:#integer scale:1	
		checkbox compressJsonCheckbox "Compress JSON" checked:false
	)
	
	button exportButton "Export"
	
	on exportButton pressed do
	(
		exportSelection = (if selectionGroup.state == "selection" then true else false)
		
		exportMaterials = exportMaterialsCheckbox.checked
		exportSkins = exportSkinsCheckbox.checked
		exportMeshes = exportMeshesCheckbox.checked
		exportAnimations = exportAnimationsCheckbox.checked
		
		animName = animNameEditText.text
		
		flipAxis = flipYZCheckbox.checked
		
		formattedPrintFormat = "." + ((decimalsSpinner.value + 1) as string) + "g"
		
		compressJson = compressJsonCheckbox.checked
		
		if (not compressJson) then
		(
			nl = "\n"
			sp = " "
		)
		
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
