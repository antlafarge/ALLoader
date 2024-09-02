fileIn "globals.ms"
fileIn "tools.ms"

fn formatAnimation obj stream =
(
	local objSkin = obj.modifiers[#skin]
	if (objSkin != undefined) then
	(
		--local animName = "anim_" + (animCount as String)
		--if (customAnimName == true) then
		--(
		--	InputStringDialog = InputStringDialog()
		--	animName = InputStringDialog.stringQuery.launch label:"Enter the animation name"
		--)
		--else
		--(
		--	animCount += 1
		--)
		--meshData.animData = processAnimatedObject obj
		--meshData.animData.name = animName
	)
)

-- DEBUG
disableSceneRedraw()
suspendEditing()
nl = "\n"
cnl = ",\n"
sp = " "
clearListener()
undo on
(
	format "{%" nl to:Listener
	format "%\"version\": \"0.1\",%" (tabs 1) nl to:Listener
	format "%\"animations\":%{%" (tabs 1) sp nl to:Listener
	for obj in objects do
	(
		if (isGeometry obj) then
		(
			select obj
			max modify mode
			formatAnimation obj Listener
		)
	)
	format "%}%" (tabs 1) nl to:Listener
	format "}%" nl to:Listener
)
resumeEditing()
enableSceneRedraw()
