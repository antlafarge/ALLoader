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

	-- MESHES
	
	checkbox exportMeshesCheckbox "Export meshes" checked:exportMeshes

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
	
	-- MATERIALS
	
	checkbox exportMaterialsCheckbox "Export materials" checked:exportMaterials

	Group "Materials"
	(
		checkbox exportMaterialBaseColorCheckbox "Base color (cl)" checked:exportMaterialBaseColor enabled:exportMaterials
		checkbox exportMaterialBaseColorMapCheckbox "Base color map (cm)" checked:exportMaterialBaseColorMap enabled:exportMaterials
		checkbox exportMaterialBaseColorOnlyIfNoBaseColorMapCheckbox "Base color only if no base color map" checked:exportMaterialBaseColorOnlyIfNoBaseColorMap enabled:exportMaterials
		checkbox exportMaterialSpecularColorCheckbox "Specular color (sp)" checked:exportMaterialSpecularColor enabled:exportMaterials
		checkbox exportMaterialTransparencyCheckbox "Transparency (op)" checked:exportMaterialTransparency enabled:exportMaterials
	)
	
	on exportMaterialsCheckbox changed exportMaterials do
	(
		exportMaterialBaseColorCheckbox.enabled = exportMaterials
		exportMaterialBaseColorMapCheckbox.enabled = exportMaterials
		exportMaterialBaseColorOnlyIfNoBaseColorMapCheckbox.enabled = exportMaterials
		exportMaterialSpecularColorCheckbox.enabled = exportMaterials
		exportMaterialTransparencyCheckbox.enabled = exportMaterials
	)
	
	-- SKINS
	
	checkbox exportSkinsCheckbox "Export Skins" checked:exportSkins
	
	Group "Skins"
	(
		checkbox exportSkinBoneParentCheckbox "Bone parent (pr)" checked:exportSkinBoneParent enabled:exportSkins
		checkbox exportSkinBonePositionCheckbox "Bone position (ps)" checked:exportSkinBonePosition enabled:exportSkins
		checkbox exportSkinBoneRotationCheckbox "Bone rotation (rt)" checked:exportSkinBoneRotation enabled:exportSkins
		checkbox exportSkinBoneScaleCheckbox "Bone scale (sc)" checked:exportSkinBoneScale enabled:exportSkins
	)

	on exportSkinsCheckbox changed exportSkins do
	(
		exportSkinBoneParentCheckbox.enabled = exportSkins
		exportSkinBonePositionCheckbox.enabled = exportSkins
		exportSkinBoneRotationCheckbox.enabled = exportSkins
		exportSkinBoneScaleCheckbox.enabled = exportSkins
	)
	
	-- ANIMATIONS
	
	checkbox exportAnimationsCheckbox "Export Animations" checked:exportAnimations

	Group "Animations"
	(
		edittext exportAnimationsNameEditText "Animation name" text:exportAnimationsName labelOnTop:true enabled:exportAnimations
		checkbox exportAnimationAssociatedSkinCheckbox "Associated skin (sk)" checked:exportAnimationAssociatedSkin enabled:exportAnimations
		checkbox exportAnimationAssociatedMeshCheckbox "Associated mesh (ms)" checked:exportAnimationAssociatedMesh enabled:exportAnimations
		checkbox exportAnimationBonePositionCheckbox "Bone position (ps)" checked:exportAnimationBonePosition enabled:exportAnimations
		checkbox exportAnimationBoneRotationCheckbox "Bone rotation (rt)" checked:exportAnimationBoneRotation enabled:exportAnimations
		checkbox exportAnimationBoneScaleCheckbox "Bone scale (sc)" checked:exportAnimationBoneScale enabled:exportAnimations
	)

	on exportAnimationsCheckbox changed exportAnimations do
	(
		exportAnimationsNameEditText.enabled = exportAnimations
		exportAnimationAssociatedSkinCheckbox.enabled = exportAnimations
		exportAnimationAssociatedMeshCheckbox.enabled = exportAnimations
		exportAnimationBonePositionCheckbox.enabled = exportAnimations
		exportAnimationBoneRotationCheckbox.enabled = exportAnimations
		exportAnimationBoneScaleCheckbox.enabled = exportAnimations
	)
	
	-- OPTIONS
	
	group "Options"
	(
		checkbox flipYZCheckbox "Flip YZ-axis (Poser-like)" checked:true
		spinner decimalsSpinner "Decimals count" range:[0,9,4] type:#integer scale:1	
		checkbox compressJsonCheckbox "Compress JSON" checked:false
	)

	-- EXPORT BUTTON
	
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
		exportMaterialBaseColorOnlyIfNoBaseColorMap = exportMaterialBaseColorOnlyIfNoBaseColorMapCheckbox.checked
		exportMaterialSpecularColor = exportMaterialSpecularColorCheckbox.checked
		exportMaterialTransparency = exportMaterialTransparencyCheckbox.checked
		
		exportSkins = exportSkinsCheckbox.checked
		exportSkinBoneParent = exportSkinBoneParentCheckbox.checked
		exportSkinBonePosition = exportSkinBonePositionCheckbox.checked
		exportSkinBoneRotation = exportSkinBoneRotationCheckbox.checked
		exportSkinBoneScale = exportSkinBoneScaleCheckbox.checked
		
		exportAnimations = exportAnimationsCheckbox.checked
		exportAnimationsName = exportAnimationsNameEditText.text
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
	createdialog ALExporter width:208
)
