function SkAnimChannel() {
    this.bActive = false;
    this.mainChannel = new SkAnimSubChannel();
    this.transChannel = new SkAnimSubChannel();
    this.iTransTime = 0;
    this.iCurTransTime = 0;
}

SkAnimChannel.prototype =
{
    clone: function(ret) {
        ret = ret ? ret : new SkAnimChannel();
        ret.bActive = this.bActive;
        this.mainChannel.clone(ret.mainChannel);
        this.transChannel.clone(ret.transChannel);
        ret.iTransTime = this.iTransTime;
        ret.iCurTransTime = this.iCurTransTime;
        return ret;
    },

    activate: function(bActive) {
        this.bActive = bActive;
    },

    isActive: function() {
        return this.bActive;
    },

    attachAnim: function(anim, iTransTime) {
		// invert channels
		var channelTmp = this.transChannel;
		this.transChannel = this.mainChannel;
		this.mainChannel = channelTmp;
        //this.mainChannel.clone(this.transChannel);
        this.iCurTransTime = 0;
        this.mainChannel.attachAnim(anim);
		this.mainChannel.bActive = true;
		if ( iTransTime > 0 ) {
			this.iTransTime = iTransTime;
			this.transChannel.bActive = true;
		}
    },

    getAnim: function() {
        return this.mainChannel.getAnim();
    },

    setSpeed: function(fSpeed) {
        this.mainChannel.setSpeed(fSpeed);
    },

    getSpeed: function() {
        return this.mainChannel.getSpeed();
    },

    enableLoop: function(bEnable) {
        this.mainChannel.enableLoop(bEnable);
    },

    isLoop: function() {
        return this.mainChannel.isLoop();
    },

    getTickTime: function() {
        if (this.mainChannel)
            return this.mainChannel.getTickTime();
        return 0;
    },

    setCurTime: function(iCurTime) {
        this.mainChannel.setCurTime(iCurTime);
    },

    update: function(iLastTime) {
        this.mainChannel.update(iLastTime);
        if ( this.transChannel.isActive() ) {
            this.transChannel.update(iLastTime);
			this.iCurTransTime = Math.min(this.iCurTransTime + iLastTime, this.iTransTime);
			if ( this.iCurTransTime >= this.iTransTime ) {
				this.transChannel.bActive = false;
			}
        }
    },

    getBoneMat43: function(sName) {
        var matMain = this.mainChannel.getBoneMat43(sName);
        if (this.iCurTransTime >= this.iTransTime || !this.transChannel.isActive()) //do not need to transmit
            return matMain;

        //blend to subchannels to implement fade in/out
        var matTrans = this.transChannel.getBoneMat43(sName);

        //var quatMain = Allocator.quat();
        //var quatTrans = Allocator.quat();
        var quatMain = new THREE.Quaternion();
        var quatTrans = new THREE.Quaternion();
        matMain.toQuat(quatMain);
        matTrans.toQuat(quatTrans);

        var fT = this.iCurTransTime / this.iTransTime;

        var quatBlend = QuatSlerp(quatTrans, quatMain, fT);
        var translateBlend = Vec3Lerp(matTrans.getColumn(3), matMain.getColumn(3), fT);
        var matBlend = Allocator.mat43();
        quatBlend.toMat43(matBlend);
        matBlend.setColumn(3, translateBlend);
		
		/*Allocator._mat43(matTrans);
		Allocator._quat(quatMain);
		Allocator._quat(quatTrans);
		Allocator._quat(quatBlend);
		Allocator._vec3(translateBlend);*/
		
        return matBlend;
    }
}
