/**
 * @author ant-lafarge / http://ant.lafarge.free.fr/
 */

AnimationUtils = {};

AnimationUtils.cube = 0;
AnimationUtils.sphere = 1;
AnimationUtils.arrow = 2;

AnimationUtils.boneColor = 0x00ff00;
AnimationUtils.linkColor = 0xffff00;
AnimationUtils.wireColor = 0xffffff;
AnimationUtils.wireOpacity = 0.2;
AnimationUtils.boneSize = 0.1;
AnimationUtils.boneType = AnimationUtils.sphere;

AnimationUtils.createSkeleton = function( ske, boneScale )
{
	var skeletonGeometry = new THREE.Geometry();
	skeletonGeometry.materials.push( new THREE.MeshBasicMaterial( { color:AnimationUtils.linkColor, wireframe:true } ) );

	var skin = new MeshSkin();

	// treat transform
	for ( var i=0 ; i < ske.bones.length ; i++ )
	{
		var bone = ske.bones[ i ];
		var im = bone.transform;
		bone.transform = new THREE.Matrix4( im[0],im[3],im[6],im[9], im[1],im[4],im[7],im[10], im[2],im[5],im[8],im[11], 0,0,0,1 );
		bone.positionWorld = bone.transform.multiplyVector3( new THREE.Vector3() );

		// add bone in skin
		skin.addBone( bone.name, bone.transform );
	}

	for ( var i=0 ; i < ske.bones.length ; i++ )
	{
		var bone = ske.bones[ i ];

		// BONE MESH
		
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
		boneMesh.geometry.materials.push( new THREE.MeshBasicMaterial( { color:AnimationUtils.boneColor } ) );
		for ( var f=0 ; f < boneMesh.geometry.faces.length ; f++ )
		{
			boneMesh.geometry.faces[ f ].materialIndex = 0;
		}
		boneMesh.matrixAutoUpdate = false;
		boneMesh.matrixWorldNeedsUpdate = false;
		boneMesh.matrix = bone.transform.clone();

		THREE.GeometryUtils.merge( skeletonGeometry, boneMesh );

        // create skinIndices and skinWeights for this mesh
        for ( var v=0 ; v < boneMesh.geometry.vertices.length ; v++ )
        {
            skin.boneIndex.push( new THREE.Vector4( i,0,0,0 ) );
            skin.boneWeight.push( new THREE.Vector4( 1,0,0,0 ) );
        }

		// BONE LINK TO PARENT

		var parentId = getBoneIdFromName( ske.bones, bone.parent );
		if ( parentId != -1 )
		{
			var parent = ske.bones[ parentId ];
			var p1 = bone.positionWorld;
			var p2 = parent.positionWorld;

			//console.log( p1, p2 )

			var vl = skeletonGeometry.vertices.length;
			skeletonGeometry.vertices.push( p1, p2 );
			skeletonGeometry.faces.push( new THREE.Face3( vl, vl, vl+1, null, null, 0 ) );
			
			skin.boneIndex.push( new THREE.Vector4( i,0,0,0 ) );
			skin.boneIndex.push( new THREE.Vector4( parentId,0,0,0 ) );
			skin.boneWeight.push( new THREE.Vector4( 1,0,0,0 ) );
			skin.boneWeight.push( new THREE.Vector4( 1,0,0,0 ) );
		}
	}

	// Merge materials
    var changes = mergeIndexedArray( skeletonGeometry.materials, compareLambertMaterials );
    for ( var i=0 ; i < skeletonGeometry.faces.length ; i++ )
    {
		var face = skeletonGeometry.faces[i];
		if ( changes[ face.materialIndex ] != null )
		{
			face.materialIndex = changes[ face.materialIndex ];
		}
    }

    skeletonGeometry.faceVertexUvs[0].length = 0;

	var skeleton = new THREE.Mesh( skeletonGeometry, new THREE.MeshFaceMaterial() );
	skeleton.name = ske.name;
	skeleton.skin = skin;
	return skeleton;
}

AnimationUtils.applySkeleton = function( skinnedMesh, ske )
{
	skinnedMesh.geometry.bones = [];

	for ( var i in ske.bones )
	{
		var bone = ske.bones[ i ];
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

AnimationUtils.processInitMatrix = function( ske )
{
	for ( var i in ske.bones )
	{
		var bone = ske.bones[ i ];
		//bone.parentName = bone.parent;
		bone.parent = getBoneIdFromName( ske.bones, bone.parent );
		
		if ( bone.transform && ! bone.initMatrix )
			bone.initMatrix = bone.transform;

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

	for ( var i in ske.bones )
	{
		var bone = ske.bones[ i ];

		var parent = ske.bones[ bone.parent ];

		if ( parent )
		{
			// OKM
			bone.mat = parent.initMatrix.clone();
			bone.mat.multiplySelf( bone.invInitMatrix );
			// ALS
			//bone.mat = parent.invInitMatrix.clone();
			//bone.mat.multiplySelf( bone.initMatrix );
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
	for ( var i in ske.bones )
	{
		var bone = ske.bones [ i ];
		//delete bone.initMatrix;
		//delete bone.invInitMatrix;
		//delete bone.mat;
	}
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

function Vec3Lerp( vec0, vec1, fT )
{
	var fT0 = 1.0 - fT;
	var fT1 = fT;
	
	var ret = new THREE.Vector3();
	ret.x = vec0.x * fT0 + vec1.x * fT1;
	ret.y = vec0.y * fT0 + vec1.y * fT1;
	ret.z = vec0.z * fT0 + vec1.z * fT1;
	return ret;
}

function FloatEqual(fVal0, fVal1)
{
	if(Math.abs(fVal0 - fVal1) < 1e-6)
		return true;
	return false;
}

function QuatEqual(quat)
{
	return FloatEqual(this.s, quat.s) && FloatEqual(this.x, quat.x) && FloatEqual(this.y, quat.y) && FloatEqual(this.z, quat.z);
}

function QuatDot(quat0, quat1)
{
	return quat0.w * quat1.w + quat0.x * quat1.x + quat0.y * quat1.y + quat0.z * quat1.z;
}

function QuatSlerp(quat0, quat1, fT)
{
	if( QuatEqual( quat0, quat1 ) )
		return quat0.clone();
	
	var qTemp = new THREE.Quaternion();

	var fDot = QuatDot(quat0, quat1);
  
	if (fDot < 0.0) {
		fDot = -fDot;
		qTemp.w = -quat1.w;
		qTemp.x = -quat1.x;
		qTemp.y = -quat1.y;
		qTemp.z = -quat1.z;
	}
	else {
		qTemp.w = quat1.w;
		qTemp.x = quat1.x;
		qTemp.y = quat1.y;
		qTemp.z = quat1.z;
	}
	
	fDot = Math.min(1.0, fDot);
	
	var fScale0, fScale1;
	if (!FloatEqual(Math.abs(fDot), 1.0)) {
		var fAngl = Math.acos(fDot);
		var fPara = Math.sin(fAngl);
		
		fScale0 = Math.sin((1.0 - fT) * fAngl) / fPara;
		fScale1 = Math.sin(fT * fAngl) / fPara;
	}
	else
	{
		fScale0 = 1.0 - fT;
		fScale1 = fT;
	}
	
	var qRet = new THREE.Quaternion();
	qRet.w = fScale0 * quat0.w + fScale1 * qTemp.w;
	qRet.x = fScale0 * quat0.x + fScale1 * qTemp.x;
	qRet.y = fScale0 * quat0.y + fScale1 * qTemp.y;
	qRet.z = fScale0 * quat0.z + fScale1 * qTemp.z;

	return qRet;
}
		