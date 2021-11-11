# ALLoader  

ALLoader is a 3dsMax exporter and loader for three.js (webgl) in a simple custom JSON format, which supports rigged, skinned and animated meshes.  

### Live demos  
http://antlafarge.github.io/ALLoader/  

Supported 3ds Max versions
- [2015](https://github.com/antlafarge/ALLoader/tree/3dsmax2015)
- [2022](https://github.com/antlafarge/ALLoader/tree/3dsmax2022)

### How to export meshes and animations  
- Open 3ds Max and your scene *(all meshes will be exported)*  
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

### FAQ
Q. Some objects in the scene are not well placed?  
A. Add a reset XForm on these objects and export.  

Q. I can't export a biped skeleton from 3DSMax?  
A. Export your scene using the FBX format, close your scene and open the FBX file. This action will convert the biped to a standart skeleton (tree of bones). You can now export your scene using the exporter.  

_Thank you for your interest._  
