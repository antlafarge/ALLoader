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
		
        objectsToExport = (if (exportSelection and mySelection.count > 0) then mySelection else objects)
		
		startTime = timeStamp()
		
		export objectsToExport exportMaterials exportSkins exportMeshes exportAnimations file
		
		endTime = timeStamp()
		
		close file
		
		clearselection
		
		select mySelection
		
		messageBox ("Export completed (" + (((endTime - startTime) / 1000.0) as string) + " seconds).") title:"ALLoader exporter" beep:false
	)
)

rollout ALExporter "ALLoader exporter"
(
	radiobuttons exportObjectsRadiobuttons "Export" labels:#("selection", "all objects") default:1 columns:1

	checkbox exportMeshesCheckbox "Export meshes" checked:true

	Group "Meshes"
	(
		checkbox exportMeshAssociatedMaterialCheckbox "Associated material (mt)" checked:true enabled:false
		checkbox exportMeshPositionCheckbox "Position (ps)" checked:true enabled:false
		checkbox exportMeshRotationCheckbox "Rotation (rt)" checked:true enabled:false
		checkbox exportMeshScaleCheckbox "Scale (sc)" checked:true enabled:false
		checkbox exportMeshVerticesCheckbox "Vertices (vp)" checked:true enabled:false
		checkbox exportMeshIndexedVerticesCheckbox "Indexed vertices (vi)" checked:true enabled:false
		checkbox exportMeshFaceNormalsCheckbox "Face normals (fn)" checked:true enabled:false
		checkbox exportMeshUVsCheckbox "Texture coordinates (uv)" checked:true enabled:false
		checkbox exportMeshIndexedUVsCheckbox "Indexed texture coordinates UV (ui)" checked:true enabled:false
		checkbox exportMeshAssociatedSkinCheckbox "Associated skin (sk)" checked:true enabled:false
		checkbox exportMeshSkinIndicesCheckbox "Skin indices (si)" checked:true enabled:false
		checkbox exportMeshSkinWeightsCheckbox "Skin weights (sw)" checked:true enabled:false
	)
	
	checkbox exportMaterialsCheckbox "Export materials" checked:true

	Group "Materials"
	(
		checkbox exportMaterialBaseColorCheckbox "Base color (cl)" checked:true enabled:false
		checkbox exportMaterialBaseColorMapCheckbox "Base color map (cm)" checked:true enabled:false
		checkbox exportMaterialBaseColorIfNoBaseColorMapCheckbox "Base color only if no Base color map" checked:true enabled:false
		checkbox exportMaterialSpecularColorCheckbox "Specular color (sp)" checked:true enabled:false
		checkbox exportMaterialTransparencyCheckbox "Transparency (op)" checked:true enabled:false
	)
	checkbox exportSkinsCheckbox "Export Skins" checked:true
	
	Group "Skins"
	(
		checkbox exportSkinBoneParentCheckbox "Bone parent (pr)" checked:true enabled:false
		checkbox exportSkinBonePositionCheckbox "Bone position (ps)" checked:true enabled:false
		checkbox exportSkinBoneRotationCheckbox "Bone rotation (rt)" checked:true enabled:false
		checkbox exportSkinBoneScaleCheckbox "Bone scale (sc)" checked:true enabled:false
	)

	checkbox exportAnimationsCheckbox "Export Animations" checked:true

	Group "Animations"
	(
		edittext animNameEditText "Animation name" text:"Animation" labelOnTop:true
		checkbox exportAnimationAssociatedSkinCheckbox "Associated skin (sk)" checked:true enabled:false
		checkbox exportAnimationAssociatedMeshCheckbox "Associated mesh (ms)" checked:true enabled:false
		checkbox exportAnimationBonePositionCheckbox "Bone position (ps)" checked:true enabled:false
		checkbox exportAnimationBoneRotationCheckbox "Bone rotation (rt)" checked:true enabled:false
		checkbox exportAnimationBoneScaleCheckbox "Bone scale (sc)" checked:true enabled:false
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
		exportSelection = (if exportObjectsRadiobuttons.state == 1 then true else false)
		
		exportMeshes = exportMeshesCheckbox.checked
		exportMeshAssociatedMaterial = exportMeshAssociatedMaterialCheckbox.checked
		exportMeshPosition = exportMeshPositionCheckbox.checked
		exportMeshRotation = exportMeshRotationCheckbox.checked
		exportMeshScale = exportMeshScaleCheckbox.checked
		exportMeshVertices = exportMeshVerticesCheckbox.checked
		exportMeshIndexedVertices = exportMeshIndexedVerticesCheckbox.checked
		exportMeshFaceNormals = exportMeshFaceNormalsCheckbox.checked
		exportMeshUVs = exportMeshUVsCheckbox.checked
		exportMeshIndexedUVs = exportMeshIndexedUVsCheckbox.checked
		exportMeshAssociatedSkin = exportMeshAssociatedSkinCheckbox.checked
		exportMeshSkinIndices = exportMeshSkinIndicesCheckbox.checked
		exportMeshSkinWeights = exportMeshSkinWeightsCheckbox.checked

		exportMaterials = exportMaterialsCheckbox.checked
		exportMaterialBaseColor = exportMaterialBaseColorCheckbox.checked
		exportMaterialBaseColorMap = exportMaterialBaseColorMapCheckbox.checked
		exportMaterialBaseColorIfNoBaseColorMap = exportMaterialBaseColorIfNoBaseColorMapCheckbox.checked
		exportMaterialSpecularColor = exportMaterialSpecularColorCheckbox.checked
		exportMaterialTransparency = exportMaterialTransparencyCheckbox.checked
		
		exportSkins = exportSkinsCheckbox.checked
		exportSkinBoneParent = exportSkinBoneParentCheckbox.checked
		exportSkinBonePosition = exportSkinBonePositionCheckbox.checked
		exportSkinBoneRotation = exportSkinBoneRotationCheckbox.checked
		exportSkinBoneScale = exportSkinBoneScaleCheckbox.checked
		
		exportAnimations = exportAnimationsCheckbox.checked
		animName = animNameEditText.text
		exportAnimationAssociatedSkin = exportAnimationAssociatedSkinCheckbox.checked
		exportAnimationAssociatedMesh = exportAnimationAssociatedMeshCheckbox.checked
		exportAnimationBonePosition = exportAnimationBonePositionCheckbox.checked
		exportAnimationBoneRotation = exportAnimationBoneRotationCheckbox.checked
		exportAnimationBoneScale = exportAnimationBoneScaleCheckbox.checked
		
		flipAxis = flipYZCheckbox.checked
		formattedPrintFormat = "." + ((decimalsSpinner.value + 1) as string) + "g"
		compressJson = compressJsonCheckbox.checked
		
		if (not compressJson) then
		(
			nl = "\n"
			sp = " "
		)
		
		launchExport()
	)
)

undo on
(
	clearListener()
	createdialog ALExporter width:200
)
