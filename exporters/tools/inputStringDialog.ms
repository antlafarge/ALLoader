-- Usage :
-- InputStringDialog = InputStringDialog()
-- result = InputStringDialog.stringQuery.launch label:"Enter your name"

struct InputStringDialog
(
	labelStr,

	stringQuery = rollout stringQuery "String Query"
	(
		local result

		label labelHeader

		editText inputEvent

		fn launch label: =
		(
			destroyDialog InputStringDialog.stringQuery

			if (label != unsupplied) then
			(
				InputStringDialog.labelStr = label
			)
			else
			(
				InputStringDialog.labelStr = "Data :"
			)

			createDialog InputStringDialog.stringQuery modal:true

			result
		)

		on stringQuery open do
		(
			labelHeader.text = InputStringDialog.labelStr

			setFocus inputEvent
		)

		on inputEvent entered str do
		(
			destroyDialog InputStringDialog.stringQuery
			
			result = str
		)
	)
)
