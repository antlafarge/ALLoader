/**
 * @author ant-lafarge / http://ant.lafarge.free.fr/
 */

THREE.ALMLoader = function ( showStatus ) {

	THREE.Loader.call( this, showStatus );

};

THREE.ALMLoader.prototype = Object.create( THREE.Loader.prototype );

THREE.ALMLoader.prototype.load = function ( url, callback, texturePath ) {

	var scope = this;

	texturePath = texturePath ? texturePath : this.extractUrlBase( url );

	this.onLoadStart();
	this.loadAjaxJSON( this, url, callback, texturePath );

};

THREE.ALMLoader.prototype.loadAjaxJSON = function ( context, url, callback, texturePath, callbackProgress ) {

	var xhr = new XMLHttpRequest();

	var length = 0;

	xhr.onreadystatechange = function () {

		if ( xhr.readyState === xhr.DONE ) {

			if ( xhr.status === 200 || xhr.status === 0 ) {

				if ( xhr.responseText ) {
				
					var json = JSON.parse( xhr.responseText );
					context.createModel( json, callback, texturePath );

				} else {

					console.warn( "THREE.ALMLoader: [" + url + "] seems to be unreachable or file there is empty" );

				}

				// in context of more complex asset initialization
				// do not block on single failed file
				// maybe should go even one more level up

				context.onLoadComplete();

			} else {

				console.error( "THREE.ALMLoader: Couldn't load [" + url + "] [" + xhr.status + "]" );

			}

		} else if ( xhr.readyState === xhr.LOADING ) {

			if ( callbackProgress ) {

				if ( length === 0 ) {

					length = xhr.getResponseHeader( "Content-Length" );

				}

				callbackProgress( { total: length, loaded: xhr.responseText.length } );

			}

		} else if ( xhr.readyState === xhr.HEADERS_RECEIVED ) {

			length = xhr.getResponseHeader( "Content-Length" );

		}

	};

	xhr.open( "GET", url, true );
	xhr.send( null );

};

THREE.ALMLoader.prototype.createModel = function ( json, callback, texturePath ) {

	var materials = [];
	for ( var i=0 ; i < json.materials.length ; i++ )
	{
		materials.push( parseMaterial( json.materials[i] ) );
	}

	var meshes = [];
	for ( var i=0 ; i < json.meshes.length ; i++ )
	{
		meshes.push( parseMesh( json.meshes[i] ) );
	}

	function getMatIdFromName( name )
	{
		for ( var i=0 ; i < materials.length ; i++ )
		{
			if ( materials[i].name == name )
			{
				return i;
			}
		}
		return -1;
	}

	function parseMaterial( jsonMat )
	{
		// MATERIAL
		var material = new THREE.MeshPhongMaterial();
		material.name = jsonMat.name;
		
		var tex = jsonMat.texture;
		if ( tex )
		{
			material.map = THREE.ImageUtils.loadTexture( texturePath + '/' + tex );
			material.map.flipY = false;
		}
		
		return material;
	}

	function parseMesh( jsonMesh )
	{
		var geometry = new THREE.Geometry();
		var material = null;
		
		geometry.name = jsonMesh.name;
		
		var skinning = ( jsonMesh.skinWeights.length && jsonMesh.skinIndices.length );
		// There is only 1 material per mesh
		var materialId = getMatIdFromName( jsonMesh.material );
		if ( materialId === -1 )
		{
			material = new THREE.MeshNormalMaterial();
		}
		else
		{
			material = materials[ materialId ];
			geometry.materials.push( material );
			materialId = 0;
			if ( skinning )
			{
				material.skinning = true;
			}
		}
		
		// VERTICES
		for ( var i=0 ; i < jsonMesh.vertices.length ; i+=3 )
		{
			geometry.vertices.push( new THREE.Vector3( jsonMesh.vertices[i], jsonMesh.vertices[i+1], jsonMesh.vertices[i+2] ) );
		}
		
		// NORMALS
		geometry.normals = [];
		for ( var i=0 ; i < jsonMesh.normals.length ; i+=3 )
		{
			geometry.normals.push( new THREE.Vector3( jsonMesh.normals[i], jsonMesh.normals[i+1], jsonMesh.normals[i+2] ) );
		}
		
		// UVS
		geometry.uvs = [];
		for ( var i=0 ; i < jsonMesh.texcoord.length ; i+=2 )
		{
			geometry.uvs.push( new THREE.UV( jsonMesh.texcoord[i], jsonMesh.texcoord[i+1] ) );
		}
		
		// INDICES / FACES
		var n = 0;
		for ( var i=0 ; i < jsonMesh.indices.length ; i+=3 )
		{
			geometry.faces.push( new THREE.Face3( jsonMesh.indices[i], jsonMesh.indices[i+1], jsonMesh.indices[i+2], geometry.normals[n], null, materialId ) );
			if ( geometry.uvs.length )
			{
				geometry.faceVertexUvs[0].push( [ geometry.uvs[jsonMesh.indices[i]], geometry.uvs[jsonMesh.indices[i+1]], geometry.uvs[jsonMesh.indices[i+2]] ] );
			}
			n++;
		}
		
		if ( skinning )
		{
			// BONES
			//parseSkin( xmlMesh.querySelector( "Skin" ), geometry );
			
			// SKININDEX && SKINWEIGHT
			for ( var i=0 ; i < jsonMesh.skinIndices.length ; i+=4 )
			{
				var si0 = treatSkinIndex( jsonMesh.skinIndices[i  ] );
				var si1 = treatSkinIndex( jsonMesh.skinIndices[i+1] );
				//var si2 = treatSkinIndex( bi[i+2] );
				//var si3 = treatSkinIndex( bi[i+3] );
				//geometry.skinIndices.push( new THREE.Vector4( si0, si1, si2, si3 ) );
				geometry.skinIndices.push( new THREE.Vector4( si0, si1, 0, 0 ) );

				//geometry.skinWeights.push( new THREE.Vector4( bw[i], bw[i+1], bw[i+2], bw[i+3] ) );
				geometry.skinWeights.push( new THREE.Vector4( jsonMesh.skinWeights[i], jsonMesh.skinWeights[i+1], 0, 0 ) );
			}
		}
		
		function treatSkinIndex( skinIndex )
		{
			if ( skinIndex == -1 )
				return 0;
			return skinIndex;
		}
		
		// Post-processing
		if ( jsonMesh.normals.length === 0 )
		{
			geometry.computeFaceNormals();
		}
		geometry.computeCentroids();
		geometry.computeBoundingBox();
		
		var mesh;
		if ( skinning )
		{
			mesh = new THREE.SkinnedMesh( geometry, material );
		}
		else
		{
			mesh = new THREE.Mesh( geometry, material );
		}
		mesh.name = jsonMesh.name;

		return mesh;
	}
	
	function parseSkin( xmlSkin, geometry )
	{
		if ( geometry.bones == null )
			geometry.bones = [];
	
		for ( var i=0 ; i < xmlBones.length ; i++ )
		{
			var bone = {};
			bone.name = xmlBones[i].getAttribute( "Name" );
			bone.parent = -1;

			var im = xmlBones[i].getAttribute( "InitMatrix" ).split(' ');
			bone.initMatrix = new THREE.Matrix4( im[0],im[3],im[6],im[9], im[1],im[4],im[7],im[10], im[2],im[5],im[8],im[11], 0,0,0,1 );
			bone.invInitMatrix = new THREE.Matrix4().getInverse( bone.initMatrix );

			bone.pos = [ 0, 0, 0 ];
			bone.rotq = [ 0, 0, 0, 1 ];
			bone.scl = [ 1,1,1 ];

			geometry.bones.push( bone );
		}
	}
	
	var object3d = new THREE.Object3D();
	if ( meshes.length == 1 )
	{
		object3d = meshes[0];
	}
	else
	{
		object3d = new THREE.Object3D();
		for ( var i=0 ; i < meshes.length ; i++ )
		{
			object3d.add( meshes[i] );
		}
	}
	callback( object3d );
};
