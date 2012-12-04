/**
@class Skeleton animation  class.
@description Skeletal animation is a hierarchical set of interconnected bones (called the skeleton or rig) used to animate (pose and keyframe) the mesh.
@constructor

@param   

@return   {SkAnimation}   A new SkAnimation object

@see SkAnimPlayer
*/
function SkAnimation() {
    this.aKeyFrameList = new Array;

    this.aBoneList = new Object;
    this.iBoneNum = 0;
    
    this.iFrameNum = 0;
    this.iTick = 33; //ms
    
    this.iCurTime = -1;     

    //result container for _lerpFrame
    this.iLerpKeyStart = -1;
    this.iLerpKeyEnd = -1;
    this.fLerpT = 0.0;
}

SkAnimation.prototype =
{
    /**
    Clear this skeleton animation object.
    
    @description
     
    @param 
    
    @return   {Null}
    */
    clear: function() {
        this.aKeyFrameList = new Array;

        this.aBoneList = new Object;
        this.iBoneNum = 0;

        this.iFrameNum = 0;
        this.iTick = 33; //ms

        this.iCurTime = -1;

        //result container for _lerpFrame
        this.iLerpKeyStart = -1;
        this.iLerpKeyEnd = -1;
        this.fLerpT = 0.0;
    },

    loadKeyFrameList: function(aKeyFrameArray) {
        this.aKeyFrameList = new Array;
        for (var i = 0; i < aKeyFrameArray.length; ++i) {
            this.aKeyFrameList.push(aKeyFrameArray[i]);
        }
    },

    addBone: function(bone) {
        if (this.aBoneList[bone.getName()] == null)
            this.iBoneNum += 1;
        this.aBoneList[bone.getName()] = bone;
    },

    getBone: function(sBoneName) {
        return this.aBoneList[sBoneName];
    },

    getBoneMat43: function(sName) {
        return this.aBoneList[sName].getMat43();
    },

    getBoneMat4: function(sName) {
        return this.aBoneList[sName].getMat4();
    },

    getBoneNum: function() {
        return this.iBoneNum;
    },

    getBoneList: function() {
        return this.aBoneList;
    },

    setFrameNum: function(iFrameNum) {
        this.iFrameNum = iFrameNum;
    },

    getFrameNum: function() {
        return this.iFrameNum;
    },

    setTickTime: function(iTick) {
        this.iTick = iTick;
    },

    getTickTime: function() {
        return this.iTick;
    },

    getAnimLength: function() {
        return this.iFrameNum * this.iTick;
    },

    setCurTime: function(iCurTime/*ms*/) {
        if (this.iCurTime != iCurTime) {
            this.iCurTime = iCurTime;

            for (var boneName in this.aBoneList) {
                this.aBoneList[boneName].dirty();
            }

            this._updateBoneList(this.iCurTime / this.iTick);
        }
    },

    setCurFrame: function(fCurFrame) {
        if (this.iCurTime != fCurFrame * this.iTick) {
            this.iCurTime = fCurFrame * this.iTick;

            for (var boneName in this.aBoneList) {
                this.aBoneList[boneName].dirty();
            }

            this._updateBoneList(fCurFrame);
        }
    },

    getCurTime: function() {
        return this.iCurTime;
    },

    //////////////////////////////////  private  ////////////////////////////////////////////
    _lerpFrame: function(fFrame) {
        for (var i = 0; i < this.aKeyFrameList.length; ++i) {
            if (this.aKeyFrameList[i] > fFrame) {
                if (i > 0) {
                    this.iLerpKeyStart = i - 1;
                    this.iLerpKeyEnd = i;
                }
                else {
                    this.iLerpKeyStart = this.iLerpKeyEnd = 0;
                }
                this.fLerpT = (fFrame - this.aKeyFrameList[i - 1]) / (this.aKeyFrameList[i] - this.aKeyFrameList[i - 1]);
                return;
            }
        }

        this.iLerpKeyStart = this.iLerpKeyEnd = this.aKeyFrameList.length - 1;
        this.fLerpT = 0.0;
    },

    _updateBoneList: function(fFrame) {
        this._lerpFrame(fFrame);

        for (var boneName in this.aBoneList) {
            this.aBoneList[boneName].update(this.iLerpKeyStart, this.iLerpKeyEnd, this.fLerpT);
        }
    }
}
