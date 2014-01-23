# ALLoader  

ALLoader is a 3dsMax exporter and loader for three.js (webgl) in a simple custom JSON format, which supports rigged, skinned and animated meshes.  

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

_Thank you for your interest._  
