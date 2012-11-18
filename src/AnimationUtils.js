/**
 * @author ant-lafarge / http://ant.lafarge.free.fr/
 */

AnimationUtils = {};

AnimationUtils.cube = 0;
AnimationUtils.sphere = 1;
AnimationUtils.arrow = 2;

AnimationUtils.boneColor = 0xff0000;
AnimationUtils.linkColor = 0xffff00;
AnimationUtils.wireColor = 0xffffff;
AnimationUtils.wireOpacity = 0.2;
AnimationUtils.boneSize = 0.1;
AnimationUtils.boneType = AnimationUtils.sphere;

AnimationUtils.createSkeleton = function( json, boneScale )
{
	if ( boneScale == null )
		boneScale = 1;

	// Construct the bones hierarchy with THREE.Object3D
	var threeObjects = {};
	var root = new THREE.Object3D();
	root.name = "root";
	threeObjects[-1] = root;

	// Create Object3D
	for ( var i=0 ; i < json.length ; i++ )
	{
		var bone = json[ i ];

		var obj = new THREE.Object3D();
		obj.name = bone.name;
		obj.bone = bone;
		obj.boneId = i;

		obj.position.set( bone.pos[0], bone.pos[1], bone.pos[2] );
		if ( bone.rotq )
		{
			obj.quaternion.set( bone.rotq[0], bone.rotq[1], bone.rotq[2], bone.rotq[3] );
			obj.useQuaternion = true;
		}
		else
		{
			obj.rotation.set( bone.rot[0], bone.rot[1], bone.rot[2] );
		}
		obj.scale.set( bone.scl[0], bone.scl[1], bone.scl[2] );

		threeObjects[ i ] = obj;
	}

	// Add Object3D to parent
	for ( var i=0 ; i < json.length ; i++ )
	{
		var bone = json[ i ];
		var obj = threeObjects[ i ];
		threeObjects[ bone.parent ].add( obj );
	}

	// Create skeleton by using this hiererchy
	var skeletonGeometry = new THREE.Geometry();
	skeletonGeometry.bones = [];
	skeletonGeometry.skinIndices = [];
	skeletonGeometry.skinWeights = [];
	skeletonGeometry.materials.push( new THREE.MeshLambertMaterial( { ambient:AnimationUtils.linkColor, wireframe:true, skinning:true } ) );

	// Copy bones
	for ( var i=0 ; i < json.length ; i++ )
	{
		var bone = json[ i ];
		var bone2 = {};
		bone2.name = bone.name;
		bone2.parent = bone.parent;
		bone2.pos = [ bone.pos[0], bone.pos[1], bone.pos[2] ];
		if ( bone.rot )
			bone2.rot = [ bone.rot[0], bone.rot[1], bone.rot[2] ];
		bone2.rotq = [ bone.rotq[0], bone.rotq[1], bone.rotq[2], bone.rotq[3] ];
		bone2.scl = [ bone.scl[0], bone.scl[1], bone.scl[2] ];
		skeletonGeometry.bones.push( bone2 );
	}

	function treatChild( obj )
	{
		// Retrieve the bone position
		obj.updateMatrix();
		obj.updateMatrixWorld();
		var position = obj.matrixWorld.getPosition().clone();

		// BONE
		// Create and merge the bone as a shpere in the skeleton
		var boneMesh;
		var bonesz = AnimationUtils.boneSize * boneScale;
		switch ( AnimationUtils.boneType )
		{
			case AnimationUtils.cube:
				boneMesh = new THREE.Mesh( new THREE.CubeGeometry( bonesz,bonesz,bonesz ), new THREE.MeshFaceMaterial() );
				break;
			case AnimationUtils.arrow:
				boneMesh = new THREE.Mesh( new THREE.CylinderGeometry( 0,bonesz/2,2*bonesz, 8,1, false ), new THREE.MeshFaceMaterial() );
				boneMesh.rotation.x = Math.PI;
				break;
			case AnimationUtils.sphere:
			default:
				boneMesh = new THREE.Mesh( new THREE.SphereGeometry( bonesz/2,8,8 ), new THREE.MeshFaceMaterial() );
				break;
		}
		boneMesh.geometry.materials.push( new THREE.MeshLambertMaterial( { ambient:AnimationUtils.boneColor, skinning:true } ) );
		for ( var i=0 ; i < boneMesh.geometry.faces.length ; i++ )
		{
			boneMesh.geometry.faces[ i ].materialIndex = 0;
		}
		boneMesh.position.set( position.x, position.y, position.z );
		THREE.GeometryUtils.merge( skeletonGeometry, boneMesh );
		// create skinIndices and skinWeights for this mesh
		for ( var i=0 ; i < boneMesh.geometry.vertices.length ; i++ )
		{
			skeletonGeometry.skinIndices.push( new THREE.Vector4( obj.boneId,0,0,0 ) );
			skeletonGeometry.skinWeights.push( new THREE.Vector4( 1,0,0,0 ) );
		}

		// process recursively the children
		for ( var i=0 ; i < obj.children.length ; i++ )
		{
			// LINK
			var child = obj.children[i];
			var childPosition = child.matrixWorld.getPosition().clone();

			var vl = skeletonGeometry.vertices.length;
			skeletonGeometry.vertices.push( position.clone(), childPosition.clone() );
			skeletonGeometry.faces.push( new THREE.Face3( vl, vl, vl+1, null, null, 0 ) );
			skeletonGeometry.skinIndices.push( new THREE.Vector4( obj.boneId,0,0,0 ) );
			skeletonGeometry.skinWeights.push( new THREE.Vector4( 1,0,0,0 ) );
			skeletonGeometry.skinIndices.push( new THREE.Vector4( child.boneId,0,0,0 ) );
			skeletonGeometry.skinWeights.push( new THREE.Vector4( 1,0,0,0 ) );

			treatChild( child );
		}
	}

	for ( var i=0 ; i < root.children.length ; i++ )
	{
		treatChild( root.children[i] );
	}

	var changes = mergeIndexedArray( skeletonGeometry.materials, compareLambertMaterials );
	for ( var i=0 ; i < skeletonGeometry.faces.length ; i++ )
	{
		var face = skeletonGeometry.faces[i];
		if ( changes[ face.materialIndex ] != null )
		{
			face.materialIndex = changes[ face.materialIndex ];
		}
	}

	var skeleton = new THREE.SkinnedMesh( skeletonGeometry, new THREE.MeshFaceMaterial() );
	skeleton.name = "skeleton";

	return skeleton;
}

AnimationUtils.processInitMatrix = function( json )
{
	for ( var i in json )
	{
		var bone = json[ i ];
		//bone.parentName = bone.parent;
		bone.parent = getBoneIdFromName( json, bone.parent );

		var im = bone.initMatrix;
		bone.initMatrix = new THREE.Matrix4( im[0],im[3],im[6],im[9], im[1],im[4],im[7],im[10], im[2],im[5],im[8],im[11], 0,0,0,1 );
		bone.invInitMatrix = new THREE.Matrix4().getInverse( bone.initMatrix );
	}

	function getBoneIdFromName( bones, name)
	{
		for ( var i=0 ; i < bones.length ; i++ )
		{
			if ( bones[ i ].name == name )
				return i;
		}

		return -1;
	}

	for ( var i in json )
	{
		var bone = json[ i ];

		var parent = json[ bone.parent ];

		if ( parent )
		{
			bone.mat = parent.initMatrix.clone();
			bone.mat.multiplySelf( bone.invInitMatrix );
		}
		else
		{
			bone.mat = bone.invInitMatrix.clone();
		}

		// Extract components
		var pos = new THREE.Vector3();
		var rotq = new THREE.Quaternion();
		bone.mat.decompose( pos, rotq );
		bone.pos = [ pos.x, pos.y, pos.z ];
		bone.rotq = [ rotq.x, rotq.y, rotq.z, rotq.w ];
		bone.scl = [ 1, 1, 1 ];
	}

	// clean bones
	for ( var i in json )
	{
		var bone = json [ i ];
		//delete bone.initMatrix;
		//delete bone.invInitMatrix;
		//delete bone.mat;
	}
}

AnimationUtils.applySkeleton = function( skinnedMesh, skeleton )
{
	skinnedMesh.geometry.bones = [];

	for ( var i in ske )
	{
		var bone = ske[ i ];
		var bone2 = {};
		bone2.name = bone.name;
		bone2.parent = bone.parent;
		bone2.pos = [ bone.pos[0], bone.pos[1], bone.pos[2] ];
		if ( bone.rot )
			bone2.rot = [ bone.rot[0], bone.rot[1], bone.rot[2] ];
		bone2.rotq = [ bone.rotq[0], bone.rotq[1], bone.rotq[2], bone.rotq[3] ];
		bone2.scl = [ bone.scl[0], bone.scl[1], bone.scl[2] ];
		skinnedMesh.geometry.bones.push( bone2 );
	}

	var newMesh = new THREE.SkinnedMesh( skinnedMesh.geometry, skinnedMesh.material );
	newMesh.name = skinnedMesh.name;
	return newMesh;
}

AnimationUtils.createWireframe = function( skinnedMesh )
{
	var material = new THREE.MeshLambertMaterial( { ambient:AnimationUtils.wireColor, opacity:AnimationUtils.wireOpacity, skinning:true, wireframe:true, transparent:true } );
	return new THREE.SkinnedMesh( skinnedMesh.geometry, material );
}

AnimationUtils.merge = function( geometry1, geometry2 )
{
	THREE.GeometryUtils.merge( geometry1, geometry2 );
	geometry1.skinIndices = geometry1.skinIndices.concat( geometry2.skinIndices );
	geometry1.skinWeights = geometry1.skinWeights.concat( geometry2.skinWeights );
	if ( geometry2.name.length )
	{
		if ( geometry1.name.length )
		{
			geometry1.name += "_";
		}
		geometry1.name += geometry2.name;
	}
	return geometry1;
}

function getBoneIdFromName( bones, name )
{
	var b = bones.length;
	while( b-- )
	{
		if ( bones[b].name == name )
		{
			return b;
		}
	}
	return -1;
}

function compareLambertMaterials( mat0, mat1 )
{
	for ( var name in mat0 )
	{
		var v0 = mat0[name];
		if ( name != "id" && typeof(v0) != "function" )
		{
			var v1 = mat1[name];
			if ( v0 == null && v1 != null )
				return false;
			else if ( ( typeof(v0) == "number" || v0 instanceof Number ) && v0 != v1 )
				return false;
			else if ( ( typeof(v0) == "boolean" || v0 instanceof Boolean ) && v0 != v1 )
				return false;
			else if ( v0 instanceof THREE.Color && v0.getHex() != v1.getHex() )
				return false;
			else if ( v0 instanceof THREE.Vector3 && ( v0.x!=v1.x || v0.y!=v1.y || v0.z!=v1.z ) )
				return false;
			else if ( v0 instanceof THREE.Texture && v0.image.src != v1.image.src )
				return false;
		}
	}

	return true;
}

// Function that merge the values of an array by using the compare function
// An array containing the trace of the the reindexed values is returned back for another processing
function mergeIndexedArray( array, compareFunction )
{
	var indicesToRemove = [];
	var indexChanges = {};
	
	var arrCount = array.length;
	
	// compute the values to remove
	for ( var i=0 ; i < arrCount-1 ; i++ )
	{
		var v0 = array[ i ];
		for ( var j=i+1 ; j < arrCount ; j++ )
		{
			if ( indicesToRemove.indexOf( j ) == -1 )
			{
				var v1 = array[ j ];
				if ( compareFunction( v0, v1 ) )
				{
					indicesToRemove.push( j );
					indexChanges[ j ] = i;
				}
			}
		}
	}

	// Create the reindexed values array
	var indexChanges2 = {};
	var decal = 0;
	var decalages = [];
	decalages.length = array.length;
	for ( var i=0 ; i < array.length ; i++ )
	{
		if ( indicesToRemove.indexOf( i ) != -1 )
		{
			decal++;
			var aimIndex = indexChanges[ i ];
			indexChanges2[ i ] = aimIndex - decalages[ aimIndex ];
		}
		else
		{
			decalages[ i ] = decal;
			if ( decal )
				indexChanges2[ i ] = i - decal;
		}
	}
	
	// process the changes in the array
	var i=0;
	while ( i < array.length )
	{
		if ( indexChanges2[ i ] )
		{
			array[ indexChanges2[ i ] ] = array[ i ];
		}
		i++;
	}
	
	array.length = array.length - decal;
	
	return indexChanges2;
}
