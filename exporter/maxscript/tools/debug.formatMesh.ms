fileIn "globals.mxs"
fileIn "tools.mxs"
fileIn "formatMesh.mxs"
fileIn "export.mxs"

nl = "\n"
sp = " "

clearListener()

objectsToExport = objects
if ((classof $) == ObjectSet) then objectsToExport = $
else if ($ != undefined) then objectsToExport = #($)

export objectsToExport false false true false Listener
