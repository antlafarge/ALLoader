/**
 * @author ant-lafarge / http://ant.lafarge.free.fr/
 */

THREE.ALALoader = function ( showStatus ) {

	THREE.Loader.call( this, showStatus );

};

THREE.ALALoader.prototype = Object.create( THREE.Loader.prototype );

THREE.ALALoader.prototype.load = function ( url, callback ) {

	var scope = this;

	this.onLoadStart();
	this.loadAjaxJSON( this, url, callback );

};

THREE.ALALoader.prototype.loadAjaxJSON = function ( context, url, callback, callbackProgress ) {

	var xhr = new XMLHttpRequest();

	var length = 0;
	
	xhr.onreadystatechange = function () {

		if ( xhr.readyState === xhr.DONE ) {

			if ( xhr.status === 200 || xhr.status === 0 ) {

				if ( xhr.responseText ) {
				
					var json = JSON.parse( xhr.responseText );
					context.createAnimation( json, callback );

				} else {

					console.warn( "THREE.ALALoader: [" + url + "] seems to be unreachable or file there is empty" );

				}

				// in context of more complex asset initialization
				// do not block on single failed file
				// maybe should go even one more level up

				context.onLoadComplete();

			} else {

				console.error( "THREE.ALALoader: Couldn't load [" + url + "] [" + xhr.status + "]" );

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

THREE.ALALoader.prototype.createAnimation = function ( json, callback ) {

	callback( json );
};
