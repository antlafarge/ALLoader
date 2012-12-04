function SkAnimSubChannel() {
    this.bActive = false;
    this.attachedAnim = null;
    this.bLoop = false;
    this.fSpeed = 1.0;
    this.iCurTime = 0;
}

SkAnimSubChannel.prototype =
{
    clone: function(chRet) {
        var chRet = chRet ? chRet : new SkAnimSubChannel();
        chRet.attachedAnim = this.attachedAnim;
        chRet.bLoop = this.bLoop;
        chRet.fSpeed = this.fSpeed;
        chRet.iCurTime = this.iCurTime;
        chRet.bActive = this.bActive;
        return chRet;
    },

    attachAnim: function(anim) {
        this.attachedAnim = anim;
    },

    getAnim: function() {
        return this.attachedAnim;
    },

    isActive: function() {
        return (this.bActive) && (this.attachedAnim != null);// && (this.iC urTime < this.attachedAnim.getAnimLength());
    },

    setSpeed: function(fSpeed) {
        this.fSpeed = fSpeed;
    },

    getSpeed: function() {
        return this.fSpeed;
    },

    enableLoop: function(bEnable) {
        this.bLoop = bEnable;
    },

    isLoop: function() {
        return this.bLoop;
    },

    getTickTime: function() {
        if (this.attachedAnim)
            return this.attachedAnim.getTickTime();
        return 0;
    },

    setCurTime: function(iTime) {
        this.iCurTime = iTime;
        if (this.attachedAnim)
            this.attachedAnim.setCurTime(iTime);
    },

    update: function(iLastTime) {
        if (this.attachedAnim) {
            this.iCurTime += (iLastTime * this.fSpeed);
            this.attachedAnim.setCurTime(this.bLoop ? (this.iCurTime % this.attachedAnim.getAnimLength()) : this.iCurTime);
        }
    },

    getBoneMat43: function(sName) {
        if (this.attachedAnim)
            return this.attachedAnim.getBoneMat43(sName);
        return new THREE.Matrix4();
    }
}
