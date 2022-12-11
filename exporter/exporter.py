from pymxs import runtime
from PySide2.QtWidgets import QWidget
main_window_qwdgt = QWidget.find(runtime.windows.getMAXHWND())

from PySide2 import (QtCore, QtGui, QtWidgets)
import qtmax

def export():
    cyl = runtime.Cylinder(radius=10, height=30)
    runtime.redrawViews()

    return    

class PyMaxDockWidget(QtWidgets.QDockWidget):
    def __init__(self, parent=None):
        super(PyMaxDockWidget, self).__init__(parent)
        self.setWindowFlags(QtCore.Qt.Tool)
        self.setWindowTitle('ALLoader exporter')
        self.initUI()
        self.setAttribute(QtCore.Qt.WA_DeleteOnClose)

    def initUI(self):
        mainLayout = QtWidgets.QVBoxLayout()
        
		#label = QtWidgets.QLabel("Click button to create a cylinder in the scene")
        #main_layout.addWidget(label)
        
        meshCheckbox = QtWidgets.QCheckBox("Export meshes", self)
        meshCheckbox.setChecked(True)
        mainLayout.addWidget(meshCheckbox)
		
        matCheckbox = QtWidgets.QCheckBox("Export materials", self)
        matCheckbox.setChecked(True)
        mainLayout.addWidget(matCheckbox)
		
        skinCheckbox = QtWidgets.QCheckBox("Export skins", self)
        skinCheckbox.setChecked(True)
        mainLayout.addWidget(skinCheckbox)
		
        animCheckbox = QtWidgets.QCheckBox("Export animations", self)
        animCheckbox.setChecked(True)
        mainLayout.addWidget(animCheckbox)
		
        flipYZCheckbox = QtWidgets.QCheckBox("Flip YZ-axis (Poser-like)", self)
        flipYZCheckbox.setChecked(True)
        mainLayout.addWidget(flipYZCheckbox)
		
        minifyJsonCheckbox = QtWidgets.QCheckBox("Minify JSON", self)
        minifyJsonCheckbox.setChecked(False)
        mainLayout.addWidget(minifyJsonCheckbox)
        
        decimalsSliderLabel = QtWidgets.QLabel("Decimals of floats")
        mainLayout.addWidget(decimalsSliderLabel)
        
        decimalsSlider = QtWidgets.QSlider()
        decimalsSlider.setOrientation(QtCore.Qt.Horizontal)
        decimalsSlider.setTickPosition(QtWidgets.QSlider.TicksBothSides)
        decimalsSlider.setRange(0, 9)
        decimalsSlider.setValue(4)
        decimalsSlider.setSingleStep(1);
        label4 = QtWidgets.QLabel("4")
        mainLayout.addWidget(decimalsSlider)
        
        export_btn = QtWidgets.QPushButton("Export")
        export_btn.clicked.connect(export)
        mainLayout.addWidget(export_btn)
		
        widget = QtWidgets.QWidget()
        widget.setLayout(mainLayout)
        self.setWidget(widget)
        self.resize(250, 100)

def main():
    rt.resetMaxFile(runtime.name('noPrompt'))
    main_window = qtmax.GetQMaxMainWindow()
    w = PyMaxDockWidget(parent=main_window)
    w.setFloating(True)
    w.show()

if __name__ == '__main__':
    main()
