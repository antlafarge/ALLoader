# ALLoader  

ALLoader is a 3dsMax 2015 exporter and loader for three.js (webgl) in a simple custom JSON format, which supports rigged, skinned and animated meshes.  

### Live demos  
http://ant.lafarge.free.fr/alloader/  

### How to export meshes and animations  
- Open 3ds Max and your scene  
- Select the meshes you want to export  
- Open the **Utilities** tab in the right lateral tool bar  
- Clic on **MAXScript** button  
- Clic on **Run Script** button  
- Go to the **exporters** folder of ALLoader  
- Run the **exporter.ms** script  
- Follow the instructions  

### Exported data  
- Mesh name  
- Vertices with indices  
- UV with indices  
- Normals  
- Materials & multi-materials  
- skin indices & weights  
- skeleton hierarchy (skin, bones)  
- time keys for bones rigged on a mesh  

### 3ds Max elements supported  
- Axis conversion (Z-up to Y-up)  
- Meshes  
- Materials (Standard material, Multi/Sub-Object material)  
- Material IDs  
- Diffuse map (texture)  
- Wire  
- 2-Sided  
- Opacity  
- Timeline playback speed  

### Todo  
- Interface  
- Biped  
- Python implementation  

### How to use the exporter  
- Open 3dsmax
- Open your scene (all meshes will be exported)
- In right bar, go to Utilities tab
- Clic Maxscript button
- Clic Run Script
- Find and open the expoter.ms file
- Choose your options
- Clic Export
- Choose your target file
- Clic Save
- The meshes are exported !

### FAQ
Q. Some objects in the scene are not well placed?  
A. Add a reset XForm on these objects and export.  

_Thank you for your interest._  
