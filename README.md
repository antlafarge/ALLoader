# ALLoader  

ALLoader is a 3dsMax mesh exporter and loader for three.js (webgl) in a JSON simple custom format, which supports rigged, skinned and animated meshes.  

### Live demos  

http://ant.lafarge.free.fr/alloader/

### How to export meshes and animations  
- Open 3ds Max and your scene  
- Select the meshes you want to export  
- Open the **Utilities** tab in the right lateral tool bar  
- Clic on **MAXScript** button  
- Clic on **Run Script** button  
- Go to the exporters folder of ALLoader  
- Run the exporter.ms script  
- Follow the instructions  

_Note: For exporting an animation, select only one rigged mesh (that owns the skin modifier)_  

### Exported data  
- Mesh name  
- Vertices with indices  
- UVs with indices  
- Normals  
- Materials & multi-materials  
- skin indices & weights  
- skeleton hierarchy (bones)  
- time keys for animated skeleton  

### 3ds Max elements supported  
- Axis conversion (Z-up to Y-up)  
- Meshes  
- Materials  
- Material IDs  
- Standard material  
- Multi/Sub-Object material  
- Diffuse map (texture)  
- Wire  
- 2-Sided  
- Opacity  
- Timeline playback speed  

### Todo  
- Biped  
- Independent skeleton  
- Python implementation  

_Thank you for your interest._  
