fileIn "globals.mxs"
fileIn "tools.mxs"
fileIn "formatMaterial.mxs"
fileIn "export.mxs"

nl = "\n"
sp = " "
commasp = ", "

clearListener()

objectsToExport = objects
if ((classof $) == ObjectSet) then objectsToExport = $
else if ($ != undefined) then objectsToExport = #($)

export objectsToExport true false false false Listener
