/**
 * @author ant-lafarge / http://ant.lafarge.free.fr/
 */

THREE.OKALoader = function ( showStatus ) {

	THREE.Loader.call( this, showStatus );

};

THREE.OKALoader.prototype = Object.create( THREE.Loader.prototype );

THREE.OKALoader.prototype.load = function ( url, callback ) {

	var scope = this;

	this.onLoadStart();
	this.loadAjaxJSON( this, url, callback );

};

THREE.OKALoader.prototype.loadAjaxJSON = function ( context, url, callback, callbackProgress ) {

	var xhr = new XMLHttpRequest();

	var length = 0;
	
	var filename = url.split('/').pop().split('.')[0];

	xhr.onreadystatechange = function () {

		if ( xhr.readyState === xhr.DONE ) {

			if ( xhr.status === 200 || xhr.status === 0 ) {

				if ( xhr.responseText ) {
				
					var parser = new DOMParser();
					var xml = parser.parseFromString( xhr.responseText, "text/xml" );
					context.createAnimation( xml, filename, callback );

				} else {

					console.warn( "THREE.OKALoader: [" + url + "] seems to be unreachable or file there is empty" );

				}

				// in context of more complex asset initialization
				// do not block on single failed file
				// maybe should go even one more level up

				context.onLoadComplete();

			} else {

				console.error( "THREE.OKALoader: Couldn't load [" + url + "] [" + xhr.status + "]" );

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

THREE.OKALoader.prototype.createAnimation = function ( xml, animName, callback ) {

	var anim = new SkAnimation();
	
	anim.name = animName;
	
	var xmlKeyFrameList = xml.querySelector( "KeyFrameList" );
	anim.setFrameNum( parseFloat(xmlKeyFrameList.getAttribute("Count")) );

	var tick = parseFloat( xmlKeyFrameList.getAttribute( "Tick" ) );
	if ( ! tick )
	{
		tick = parseFloat( xmlKeyFrameList.getAttribute( "FrameTime" ) );
	}
	anim.setTickTime( tick );

    anim.loadKeyFrameList( xmlKeyFrameList.getAttribute("KeyTimeList").split(' ').map(parseFloat) );

	/*var keyCount = parseFloat( xmlKeyFrameList.getAttribute( "KeyCount" ) );
	anim.length = ( keyCount- 1 ) * tick / 1000;
	anim.fps = keyCount / anim.length;
	anim.hierarchy = [];*/
	
	var xmlBoneList = xml.querySelector( "BoneList" );
	var xmlBones = xmlBoneList.querySelectorAll( "Bone" );
	for ( var b=0 ; b < xmlBones.length ; b++ )
	{
		var xmlBone = xmlBones[ b ];
		var bone = new SkAnimBone();
		bone.sName = xmlBone.getAttribute( "Name" );
		// KEYS
		var xmlKeys = xmlBone.querySelectorAll( "Key" );
		var transArray = [];
		var quatArray = [];
		for ( var k=0 ; k < xmlKeys.length ; k++ )
		{
			var xmlKey = xmlKeys[ k ];
			
			var tra = xmlKey.getAttribute("Translation").split(' ').map(parseFloat);
			tra.map( parseFloat );

			var rot = xmlKey.getAttribute("Rotation").split(' ').map(parseFloat);
			rot.map( parseFloat );

			transArray.push( new THREE.Vector3( tra[0], tra[1], tra[2] ) );
            quatArray.push( new THREE.Quaternion( rot[1], rot[2], rot[3], rot[0] ) );
		}

        bone.loadKeyTranslateList( transArray );
        bone.loadKeyQuaternionList( quatArray );
    
        anim.addBone(bone);
	}

    //create parent-child links
	for ( var b=0 ; b < xmlBones.length ; b++ )
	{
		var xmlBone = xmlBones[ b ];
		var bone = anim.getBone(xmlBone.getAttribute("Name"));
		var parentName = xmlBone.getAttribute("Parent");
		if ( parentName != "" )
		{
			bone.setParent( anim.getBone( parentName ) );
		}
	}

	callback( anim );
};
