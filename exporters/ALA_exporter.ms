-- ANIMATION EXPORTER (ALA)

include "tools.ms"
include "ALA_tools.ms"

clearListener()

mySelection = getCurrentSelection()

if (mySelection.count == 1) then
(
	anim_filepath = getSaveFileName caption:"Location for saving the Animation file" types:"JSON (*.json)|*.json|Plain Text (*.txt)|*.txt|All Files (*.*)|*.*|"
	
	if (anim_filepath != undefined) then
	(
		animName = "anim"
		queryBoxRes = queryBox "Do you want to specify an animation name?"
		if (queryBoxRes == true) then
		(
			messageBox "The maxscript listener is waiting for the animation name.\nOpen the maxscript listener and enter the animation name."
			animName = getKBLine prompt:"Enter the animation name"
		)
		
		myObj = mySelection[1]
		animData = (processAnimatedObject myObj)
		animData.name = animName
		
		if (animData != undefined) then
		(
			deleteFile anim_filepath
			anim_file = createFile anim_filepath
			formatAnimatedObject animData anim_file
			close anim_file
		)
		else
		(
			messageBox "The object appears to be not animated of skinned/rigged."
		)
	)
)
else
(
	messageBox "You must only select the animated object."
)

select mySelection
