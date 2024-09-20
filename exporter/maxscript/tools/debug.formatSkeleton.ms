fileIn "globals.mxs"
fileIn "tools.mxs"
fileIn "formatSkeleton.mxs"
fileIn "export.mxs"

nl = "\n"
sp = " "
commasp = ", "

clearListener()

objectsToExport = objects
if ((classof $) == ObjectSet) then objectsToExport = $
else if ($ != undefined) then objectsToExport = #($)

export objectsToExport false true false false Listener
