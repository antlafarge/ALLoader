fileIn "tools/globals.mxs"
fileIn "tools/tools.mxs"
fileIn "tools/formatMaterial.mxs"
fileIn "tools/formatSkeleton.mxs"
fileIn "tools/formatMesh.mxs"
fileIn "tools/formatAnimation.mxs"
fileIn "tools/export.mxs"

fn launchExport =
(
	if (not compressJson) then
	(
		nl = "\n"
		sp = " "
		commasp = ", "
	)
	
	filepath = getSaveFileName caption:"File location" types:"JSON (json)|*.json|Plain Text (txt)|*.txt|All Files|*.*|"
	
	if (filepath != undefined) then
	(
		deleteFile filepath
		
		file = createFile filepath
		
		objectsToExport = #()
		
        if (exportSelection) then
		(
			if ((classof $) == ObjectSet) then objectsToExport = $
			else if ($ != undefined) then objectsToExport = #($)
		)
		else
		(
			objectsToExport = objects
		)
		
		disableSceneRedraw()
		
		suspendEditing()
		
		startTime = timeStamp()
		
		export objectsToExport exportMaterials exportSkins exportMeshes exportAnimations file
		
		endTime = timeStamp()
		
		resumeEditing()
		
		enableSceneRedraw()
		
		close file
		
		messageBox ("Export completed (" + (((endTime - startTime) / 1000.0) as string) + " seconds).") title:"ALLoader exporter" beep:false
	)
)

rollout RolloutMeshes ""
(
	checkbox exportMeshesCheckbox "Meshes" checked:exportMeshes
	
	Group ""
	(
		checkbox exportMeshAssociatedMaterialCheckbox "Associated material (mt)" checked:exportMeshAssociatedMaterial enabled:exportMeshes
		checkbox exportMeshPositionCheckbox "Position (ps)" checked:exportMeshPosition enabled:exportMeshes
		checkbox exportMeshRotationCheckbox "Rotation (rt)" checked:exportMeshRotation enabled:exportMeshes
		checkbox exportMeshScaleCheckbox "Scale (sc)" checked:exportMeshScale enabled:exportMeshes
		checkbox exportMeshVertexIndicesCheckbox "Vertex indices (vi)" checked:exportMeshVertexIndices enabled:exportMeshes
		checkbox exportMeshVertexPositionsCheckbox "Vertex positions (vp)" checked:exportMeshVertexPositions enabled:exportMeshes
		checkbox exportMeshVertexNormalsCheckbox "Vertex normals (vn)" checked:exportMeshVertexNormals enabled:exportMeshes
		checkbox exportMeshFaceNormalsCheckbox "Face normals (fn)" checked:exportMeshFaceNormals enabled:exportMeshes
		checkbox exportMeshVertexColorsCheckbox "Vertex colors (vc)" checked:exportMeshVertexColors enabled:exportMeshes
		checkbox exportMeshFaceColorsCheckbox "Face vertex colors (fc)" checked:exportMeshFaceVertexColors enabled:exportMeshes
		checkbox exportMeshUVsCheckbox "Texture coordinates (uv)" checked:exportMeshUVs enabled:exportMeshes
		checkbox exportMeshUVsIndexedCheckbox "Texture coordinates indexed (ui)" checked:exportMeshUVsIndexed enabled:exportMeshes
		checkbox exportMeshAssociatedSkinCheckbox "Associated skin (sk)" checked:exportMeshAssociatedSkin enabled:exportMeshes
		checkbox exportMeshSkinIndicesCheckbox "Skin indices (si)" checked:exportMeshSkinIndices enabled:exportMeshes
		checkbox exportMeshSkinWeightsCheckbox "Skin weights (sw)" checked:exportMeshSkinWeights enabled:exportMeshes
	)
	
	on exportMeshesCheckbox changed newValue do
	(
		exportMeshes = newValue
		exportMeshAssociatedMaterialCheckbox.enabled = exportMeshes
		exportMeshPositionCheckbox.enabled = exportMeshes
		exportMeshRotationCheckbox.enabled = exportMeshes
		exportMeshScaleCheckbox.enabled = exportMeshes
		exportMeshVertexPositionsCheckbox.enabled = exportMeshes
		exportMeshVertexIndicesCheckbox.enabled = exportMeshes
		exportMeshVertexNormalsCheckbox.enabled = exportMeshes
		exportMeshFaceNormalsCheckbox.enabled = exportMeshes
		exportMeshUVsCheckbox.enabled = exportMeshes
		exportMeshUVsIndexedCheckbox.enabled = exportMeshes
		exportMeshVertexColorsCheckbox.enabled = exportMeshes
		exportMeshFaceColorsCheckbox.enabled = exportMeshes
		exportMeshAssociatedSkinCheckbox.enabled = exportMeshes
		exportMeshSkinIndicesCheckbox.enabled = exportMeshes
		exportMeshSkinWeightsCheckbox.enabled = exportMeshes
	)
)

rollout RolloutMaterials ""
(
	checkbox exportMaterialsCheckbox "Materials" checked:exportMaterials

	Group ""
	(
		checkbox exportMaterialBaseColorCheckbox "Base color (cl)" checked:exportMaterialBaseColor enabled:exportMaterials
		checkbox exportMaterialBaseColorMapCheckbox "Base color map (cm)" checked:exportMaterialBaseColorMap enabled:exportMaterials
		checkbox exportMaterialBaseColorOnlyIfNoBaseColorMapCheckbox "Base color only if no base color map" checked:exportMaterialBaseColorOnlyIfNoBaseColorMap enabled:exportMaterials
		checkbox exportMaterialSpecularColorCheckbox "Specular color (sp)" checked:exportMaterialSpecularColor enabled:exportMaterials
		checkbox exportMaterialTransparencyCheckbox "Transparency (op)" checked:exportMaterialTransparency enabled:exportMaterials
	)
	
	on exportMaterialsCheckbox changed newValue do
	(
		exportMaterials = newValue
		exportMaterialBaseColorCheckbox.enabled = exportMaterials
		exportMaterialBaseColorMapCheckbox.enabled = exportMaterials
		exportMaterialBaseColorOnlyIfNoBaseColorMapCheckbox.enabled = exportMaterials
		exportMaterialSpecularColorCheckbox.enabled = exportMaterials
		exportMaterialTransparencyCheckbox.enabled = exportMaterials
	)
)

rollout RolloutSkins ""
(
	checkbox exportSkinsCheckbox "Skins" checked:exportSkins
	
	Group ""
	(
		checkbox exportSkinBoneParentCheckbox "Bone parent (pr)" checked:exportSkinBoneParent enabled:exportSkins
		checkbox exportSkinBonePositionCheckbox "Bone position (ps)" checked:exportSkinBonePosition enabled:exportSkins
		checkbox exportSkinBoneRotationCheckbox "Bone rotation (rt)" checked:exportSkinBoneRotation enabled:exportSkins
		checkbox exportSkinBoneScaleCheckbox "Bone scale (sc)" checked:exportSkinBoneScale enabled:exportSkins
	)

	on exportSkinsCheckbox changed newValue do
	(
		exportSkins = newValue
		exportSkinBoneParentCheckbox.enabled = exportSkins
		exportSkinBonePositionCheckbox.enabled = exportSkins
		exportSkinBoneRotationCheckbox.enabled = exportSkins
		exportSkinBoneScaleCheckbox.enabled = exportSkins
	)
)

rollout RolloutAnimations ""
(
	checkbox exportAnimationsCheckbox "Animations" checked:exportAnimations

	Group ""
	(
		edittext exportAnimationsNameEditText "Animation name" text:exportAnimationsName labelOnTop:true enabled:exportAnimations
		checkbox exportAnimationAssociatedSkinCheckbox "Associated skin (sk)" checked:exportAnimationAssociatedSkin enabled:exportAnimations
		checkbox exportAnimationAssociatedMeshCheckbox "Associated mesh (ms)" checked:exportAnimationAssociatedMesh enabled:exportAnimations
		checkbox exportAnimationBonePositionCheckbox "Bone position (ps)" checked:exportAnimationBonePosition enabled:exportAnimations
		checkbox exportAnimationBoneRotationCheckbox "Bone rotation (rt)" checked:exportAnimationBoneRotation enabled:exportAnimations
		checkbox exportAnimationBoneScaleCheckbox "Bone scale (sc)" checked:exportAnimationBoneScale enabled:exportAnimations
	)

	on exportAnimationsCheckbox changed newValue do
	(
		exportAnimations = newValue
		exportAnimationsNameEditText.enabled = exportAnimations
		exportAnimationAssociatedSkinCheckbox.enabled = exportAnimations
		exportAnimationAssociatedMeshCheckbox.enabled = exportAnimations
		exportAnimationBonePositionCheckbox.enabled = exportAnimations
		exportAnimationBoneRotationCheckbox.enabled = exportAnimations
		exportAnimationBoneScaleCheckbox.enabled = exportAnimations
	)
)

rollout RolloutExport ""
(
	group "Options"
	(
		checkbox completeBoneStructureCheckbox "Complete bone structure" checked:completeBoneStructure
		checkbox flipYZCheckbox "Convert Z-Up to Y-Up" checked:flipAxis
		spinner decimalsSpinner "Decimals count" range:[0,9,4] type:#integer scale:1	
		checkbox compressJsonCheckbox "Compress JSON" checked:compressJson
	)
	
	group "Export"
	(
		radiobuttons exportObjectsRadiobuttons "" labels:#("selection", "all objects") default:1 columns:2 
		button exportButton "Export"
	)
	
	on exportButton pressed do
	(
		exportMeshes = RolloutMeshes.exportMeshesCheckbox.checked
		exportMeshAssociatedMaterial = RolloutMeshes.exportMeshAssociatedMaterialCheckbox.checked
		exportMeshPosition = RolloutMeshes.exportMeshPositionCheckbox.checked
		exportMeshRotation = RolloutMeshes.exportMeshRotationCheckbox.checked
		exportMeshScale = RolloutMeshes.exportMeshScaleCheckbox.checked
		exportMeshVertexPositions = RolloutMeshes.exportMeshVertexPositionsCheckbox.checked
		exportMeshVertexIndices = RolloutMeshes.exportMeshVertexIndicesCheckbox.checked
		exportMeshVertexNormals = RolloutMeshes.exportMeshVertexNormalsCheckbox.checked
		exportMeshFaceNormals = RolloutMeshes.exportMeshFaceNormalsCheckbox.checked
		exportMeshUVs = RolloutMeshes.exportMeshUVsCheckbox.checked
		exportMeshUVsIndexed = RolloutMeshes.exportMeshUVsIndexedCheckbox.checked
		exportMeshVertexColors = RolloutMeshes.exportMeshVertexColorsCheckbox.checked
		exportMeshFaceVertexColors = RolloutMeshes.exportMeshFaceColorsCheckbox.checked
		exportMeshAssociatedSkin = RolloutMeshes.exportMeshAssociatedSkinCheckbox.checked
		exportMeshSkinIndices = RolloutMeshes.exportMeshSkinIndicesCheckbox.checked
		exportMeshSkinWeights = RolloutMeshes.exportMeshSkinWeightsCheckbox.checked

		exportMaterials = RolloutMaterials.exportMaterialsCheckbox.checked
		exportMaterialBaseColor = RolloutMaterials.exportMaterialBaseColorCheckbox.checked
		exportMaterialBaseColorMap = RolloutMaterials.exportMaterialBaseColorMapCheckbox.checked
		exportMaterialBaseColorOnlyIfNoBaseColorMap = RolloutMaterials.exportMaterialBaseColorOnlyIfNoBaseColorMapCheckbox.checked
		exportMaterialSpecularColor = RolloutMaterials.exportMaterialSpecularColorCheckbox.checked
		exportMaterialTransparency = RolloutMaterials.exportMaterialTransparencyCheckbox.checked
		
		exportSkins = RolloutSkins.exportSkinsCheckbox.checked
		exportSkinBoneParent = RolloutSkins.exportSkinBoneParentCheckbox.checked
		exportSkinBonePosition = RolloutSkins.exportSkinBonePositionCheckbox.checked
		exportSkinBoneRotation = RolloutSkins.exportSkinBoneRotationCheckbox.checked
		exportSkinBoneScale = RolloutSkins.exportSkinBoneScaleCheckbox.checked
		
		exportAnimations = RolloutAnimations.exportAnimationsCheckbox.checked
		exportAnimationsName = RolloutAnimations.exportAnimationsNameEditText.text
		exportAnimationAssociatedSkin = RolloutAnimations.exportAnimationAssociatedSkinCheckbox.checked
		exportAnimationAssociatedMesh = RolloutAnimations.exportAnimationAssociatedMeshCheckbox.checked
		exportAnimationBonePosition = RolloutAnimations.exportAnimationBonePositionCheckbox.checked
		exportAnimationBoneRotation = RolloutAnimations.exportAnimationBoneRotationCheckbox.checked
		exportAnimationBoneScale = RolloutAnimations.exportAnimationBoneScaleCheckbox.checked
		
		exportSelection = (if RolloutExport.exportObjectsRadiobuttons.state == 1 then true else false)
		completeBoneStructure = RolloutExport.completeBoneStructureCheckbox.checked
		flipAxis = RolloutExport.flipYZCheckbox.checked
		formattedPrintFormat = "." + ((RolloutExport.decimalsSpinner.value + 1) as string) + "g"
		compressJson = RolloutExport.compressJsonCheckbox.checked
		
		launchExport()
	)
)

width = 512
meshesHeight = 374
materialsHeight = 174
skinsHeight = 154
animationsHeight = 214
exportHeight = 206
height = (amax (meshesHeight + materialsHeight) (skinsHeight + animationsHeight + exportHeight))
exportPosY = skinsHeight + animationsHeight

rollout RolloutALExporter "ALLoader exporter"
(
    subRollout subRolloutMeshes pos:[0,0] width:(width/2) height:meshesHeight
    subRollout subRolloutMaterials pos:[0,meshesHeight] width:(width/2) height:materialsHeight
    subRollout subRolloutSkins pos:[(width/2),0] width:(width/2) height:skinsHeight
    subRollout subRolloutAnimations pos:[(width/2),skinsHeight] width:(width/2) height:animationsHeight
    subRollout subRolloutExport pos:[(width/2),(exportPosY)] width:(width/2) height:exportHeight
)

clearListener()

createDialog RolloutALExporter width:width height:height

addSubRollout RolloutALExporter.subRolloutMeshes RolloutMeshes
addSubRollout RolloutALExporter.subRolloutMaterials RolloutMaterials
addSubRollout RolloutALExporter.subRolloutSkins RolloutSkins
addSubRollout RolloutALExporter.subRolloutAnimations RolloutAnimations
addSubRollout RolloutALExporter.subRolloutExport RolloutExport
