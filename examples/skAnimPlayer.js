EBlendMode = {
	SKBLEND_ACCUMULATE:1,
	SKBLEND_LERP:2
}

/**
@class Skeleton animation player class.
@description Skeleton animation player is used to play a animation and perform mesh skinning.
@constructor

@param   

@return   {SkAnimPlayer}   A new SkAnimPlayer object

@see SkAnimation
*/
function SkAnimPlayer() {
    this.skinInfo = null;
    
    this.aBoneMatList = new Array;
    this.bBoneMatDirty = false;
 
    this.aBoneFinalMatList = new Array; //transformMatrix x initMatrix
    this.bBoneFinalMatDirty = false;
 
    this.aChannelList = new Array;
    this.aChannelList.push(new SkAnimChannel());
    this.aChannelList.push(new SkAnimChannel());

    this.iBlendMode = EBlendMode.SKBLEND_LERP;
}


SkAnimPlayer.prototype =
{
    /**
    Reset this player to its default state.
    
    @description
     
    @param 
    
    @return   {Null}
    */
    clear: function() {
        this.skinInfo = null;

        this.aBoneMatList = new Array;
        this.bBoneMatDirty = false;

        this.aBoneFinalMatList = new Array; //transformMatrix x initMatrix
        this.bBoneFinalMatDirty = false;

        this.aChannelList = new Array;
        this.aChannelList.push(new SkAnimChannel());
        this.aChannelList.push(new SkAnimChannel());

        this.iBlendMode = 1;
    },

    /**
    Clone the skeleton animation player.
     
    @param   {SkAnimPlayer}  [CloneResult]  The container of the clone result, if this parameter is ignored then the method will create a new one and clone to it.
    
    @return   {SkAnimPlayer} The clone result. If the "CloneResult" isn't ignored, then the returnning object is a reference to the "CloneResult".
    */
    clone: function(ret) {
        ret = ret ? ret : new SkAnimPlayer();
        ret.skinInfo = this.skinInfo;
        ret.bBoneMatDirty = true;
        ret.bBoneFinalMatDirty = true;
        ret.aChannelList = [this.aChannelList[0].clone(), this.aChannelList[1].clone()];
        ret.iBlendMode = this.iBlendMode;
        return ret;
    },

    /**
    Set the mesh skin object.
    
    @description Mesh skin object contains the neccessary information to apply a skeleton animation to that mesh.
     
    @param   {MeshSkin}  Skin  The mesh skin object.
    
    @return   {Null} 
    */
    setSkin: function(skin) {
        this.skinInfo = skin;
        this.bBoneMatDirty = true;
        this.bBoneFinalMatDirty = true;
        this.update(-1, 0);
    },

    /**
    Get the currently attached mesh skin object.
    
    @description Mesh skin object contains the neccessary information to apply a skeleton animation to that mesh.
     
    @param   
    
    @return   {MeshSkin}  The currently attached mesh skin object of this player.
    */
    getSkin: function() {
        return this.skinInfo;
    },

    /**
    Activate/Deactivate an animation channel.
    
    @description Animation player allows playing 2 animations at one time. So there are 2 animation channels in the player.
     
    @param  {Number} ChannelIdx  The animation channel. The available number is [0, 1].
    @param  {Boolean} Active  Indicates if activating the channel.
    
    @return   {Null}
    */
    activateChannel: function(iChannel, bActive) {
        this.aChannelList[iChannel].activate(bActive);

        this.bBoneMatDirty = true;
        this.bBoneFinalMatDirty = true;
    },

    /**
    Check if an animation channel is active.
    
    @description Animation player allows playing 2 animations at one time. So there are 2 animation channels in the player.
     
    @param  {Number} ChannelIdx  The animation channel. The available number is [0, 1].
    @param  
    
    @return  {Boolean} True if the specified channel is active, otherwise, false.
    */
    isActive: function(iChannel) {
        return this.aChannelList[iChannel].isActive();
    },

    /**
    Attach an skeleton animation object to a specified channel.
    
    @description 
     
    @param  {Number} ChannelIdx  The animation channel. The available number is [0, 1].
    @param  {SkAnimation} Anim  The skeleton animation object.
    @param  {Number} TransTime  The transition time(counted by millisecond) from the old animation to the new one.
    
    @return   {Null}
    */
    attachAnim: function(iChannel, anim, iTransTime) {
        this.aChannelList[iChannel].attachAnim(anim, iTransTime);

        this.bBoneMatDirty = true;
        this.bBoneFinalMatDirty = true;
    },

    /**
    Get the attached skeleton animation object of the specified channel.
    
    @description 
     
    @param  {Number} ChannelIdx  The animation channel. The available number is [0, 1].
    @param  
    
    @return   {SkAnimation} The attached skeleton animation object.
    */
    getAnim: function(iChannel) {
        return this.aChannelList[iChannel].getAnim();
    },

    /**
    Set the speed of a specified channel.
    
    @description 
     
    @param  {Number} ChannelIdx  The animation channel. The available number is [0, 1].
    @param  {Number} Speed  The speed factor. A value less than 1 will make the animation playing slower than normal speed.
    And a value greater than 1 will make the animation playing faster than normal speed.
    
    @return   {Null}
    */
    setSpeed: function(iChannel, fSpeed) {
        this.aChannelList[iChannel].setSpeed(fSpeed);
    },

    /**
    Get the speed of a specified channel.
    
    @description 
     
    @param  {Number} ChannelIdx  The animation channel. The available number is [0, 1].
    
    @return   {Number} The speed factor of the specified channel.
    */
    getSpeed: function(iChannel) {
        return this.aChannelList[iChannel].getSpeed();
    },

    /**
    Enable/disable loop mode of a specified channel.
    
    @description 
     
    @param  {Number} ChannelIdx  The animation channel. The available number is [0, 1].
    @param  {Boolean} Enable  Indicates if enabling loop playing in the channel.
    
    @return   {Null}
    */
    enableLoop: function(iChannel, bEnable) {
        this.aChannelList[iChannel].enableLoop(bEnable);
    },

    /**
    Check if a specified channel is in loop mode.
    
    @description 
     
    @param  {Number} ChannelIdx  The animation channel. The available number is [0, 1].
    @param  
    
    @return   {Boolean} True if the channel is in loop mode, otherwise, false.
    */
    isLoop: function(iChannel) {
        return this.aChannelList[iChannel].isLoop();
    },

    setBlendMode: function(iMode) {
        this.iBlendMode = iMode;

        this.bBoneMatDirty = true;
        this.bBoneFinalMatDirty = true;
    },

    getBlendMode: function() {
        return this.iBlendMode;
    },

    getTickTime: function(iChannel) {
        if (this.aChannelList[iChannel]) {
            return this.aChannelList[iChannel].getTickTime();
        }

        return 0;
    },

    /**
    Set the time of the player.
    
    @description This method directly moves the playing animation to a specified time on the time line.
     
    @param  {Number} ChannelIdx  The animation channel. The available number is [-1, 0, 1]. -1 means set all channels.
    @param  {Number} Time  The setting time(counted by millisecond).
    
    @return   {Null}
    */
    setTime: function(iChannel, iCurTime) {
        if (iChannel == -1) {
            for (var i = 0; i < this.aChannelList.length; ++i) {
                if (this.aChannelList[i].isActive())
                    this.aChannelList[i].setCurTime(iCurTime);
            }
        }
        else
            this.aChannelList[iChannel].setCurTime(iCurTime);

        this.bBoneMatDirty = true;
        this.bBoneFinalMatDirty = true;
    },

    /**
    Update the time of the player.
    
    @description 
     
    @param  {Number} ChannelIdx  The animation channel. The available number is [-1, 0, 1]. -1 means set all channels.
    @param  {Number} LastingTime  The lasting time(counted by millisecond).
    
    @return   {Null}
    */
    update: function(iChannel, iLastTime) {
        if (iChannel == -1) {
            for (var i = 0; i < this.aChannelList.length; ++i) {
                if (this.aChannelList[i].isActive())
                    this.aChannelList[i].update(iLastTime);
            }
        }
        else
            this.aChannelList[iChannel].update(iLastTime);

        this.bBoneMatDirty = true;
        this.bBoneFinalMatDirty = true;
    },

    /**
    Get a transform 4x3 matrix of a specified bone.
    
    @description 
     
    @param  {String} BoneName  Bone name.
        
    @return   {Mat43} The transform 4x3 matrix of the bone.
    */
    getBoneMat43: function(sBoneName) {
        var active0 = this.aChannelList[0].isActive();
        var active1 = this.aChannelList[1].isActive();

        if (active0 && !active1)
            return this.aChannelList[0].getBoneMat43(sBoneName);
        else if (!active0 && active1)
            return this.aChannelList[1].getBoneMat43(sBoneName);
        else if (!active0 && !active1)
            return Allocator.mat4();

        var mRet = Allocator.mat43();

        //both channels are active so need blending
        if (this.iBlendMode == 1) {
            var mat0 = this.aChannelList[0].getBoneMat43(sBoneName);
            var mat1 = this.aChannelList[1].getBoneMat43(sBoneName);

            var trans0 = mat0.getColumn(3);
            var trans1 = mat1.getColumn(3);
            var trans = Vec3Add(trans0, trans1);

            var quat0 = Allocator.quat();
            var quat1 = Allocator.quat();
            mat0.toQuat(quat0);
            mat1.toQuat(quat1);
            var quat = QuatMul(quat1, quat0);

            quat.toMat43(mRet);
            mRet.setColumn(3, trans);
			
			Allocator._mat43(mat0);
			Allocator._mat43(mat1);
			Allocator._quat(quat0);
			Allocator._quat(quat1);
			Allocator._quat(quat);
			Allocator._vec3(trans0);
			Allocator._vec3(trans1);
			Allocator._vec3(trans);
        }
        else if (this.iBlendMode == 2) {
            var mat0 = this.aChannelList[0].getBoneMat43(sBoneName);
            var mat1 = this.aChannelList[1].getBoneMat43(sBoneName);

            var trans0 = mat0.getColumn(3);
            var trans1 = mat1.getColumn(3);
            var trans = Vec3Lerp(trans0, trans1, 0.5);

            var quat0 = Allocator.quat();
            var quat1 = Allocator.quat();
            mat0.toQuat(quat0);
            mat1.toQuat(quat1);
            var quat = QuatSlerp(quat1, quat0, 0.5);

            quat.toMat43(mRet);
            mRet.setColumn(3, trans);
			
			Allocator._mat43(mat0);
			Allocator._mat43(mat1);
			Allocator._quat(quat0);
			Allocator._quat(quat1);
			Allocator._quat(quat);
			Allocator._vec3(trans0);
			Allocator._vec3(trans1);
			Allocator._vec3(trans);
        }

        return mRet;
    },

    /**
    Get the transform 4x3 matrix array of the bones of the animation.
    
    @description This method will return the transform matrices of all bones referenced by the mesh. 
                        And the order of the matrix in the array is according to the mesh skin.
     
    @param 
        
    @return   {Array} The transform 4x3 matrix array of all bones referenced by the mesh.
    */
    getBoneMat43Array: function() {
        var boneNameArray = this.skinInfo.getBoneNameArray();

        if (this.bBoneMatDirty) {
            this.aBoneMatList.length = 0;
            for (var i = 0; i < boneNameArray.length; ++i)
                this.aBoneMatList.push(this.getBoneMat43(boneNameArray[i]));
            this.bBoneMatDirty = false;
        }

        return this.aBoneMatList;
    },

    /**
    Get the final transform 4x3 matrix of a specified bone.
    
    @description The final transform matrix can directly transform mesh vertices from their local space to the animation's final pose.
     
    @param  {String} BoneName  Bone name.
        
    @return   {Mat43} The final transform 4x3 matrix of the bone.
    */
    getBoneFinalMat43: function(sBoneName)
    {
        var active0 = this.aChannelList[0].isActive();
        var active1 = this.aChannelList[1].isActive();
		
        if (active0 && !active1)
		{
			var boneMat43 = this.aChannelList[0].getBoneMat43(sBoneName);
			var skinMat43 = this.skinInfo ? this.skinInfo.getSkinMat(sBoneName) : new THREE.Matrix4();
			var boneFinalMat43 = new THREE.Matrix4().multiply( boneMat43, skinMat43 );
			//Allocator._mat43(boneMat43);
			//Allocator._mat43(skinMat43); // Don't do this, that's the original ref
            return boneFinalMat43;
		}
        else if (!active0 && active1)
		{
			var boneMat43 = this.aChannelList[1].getBoneMat43(sBoneName);
			var skinMat43 = this.skinInfo ? this.skinInfo.getSkinMat(sBoneName) : new THREE.Matrix4();
			var boneFinalMat43 = Mat43Mul(boneMat43, skinMat43);
			//Allocator._mat43(boneMat43);
			//Allocator._mat43(skinMat43);
            return boneFinalMat43;
		}
        else if (!active0 && !active1)
		{
            return ( this.skinInfo ? this.skinInfo.getSkinMat(sBoneName) : new THREE.Matrix4() );
		}

        var mRet = new THREE.Matrix4();

        //both channels are active so need blending
        if (this.iBlendMode == 1) {
            var mat0 = this.aChannelList[0].getBoneMat43(sBoneName);
            var mat1 = this.aChannelList[1].getBoneMat43(sBoneName);

            var trans0 = mat0.getColumn(3);
            var trans1 = mat1.getColumn(3);
            var trans = Vec3Add(trans0, trans1);

            var quat0 = new THREE.Quaternion();
            var quat1 = new THREE.Quaternion();
            mat0.toQuat(quat0);
            mat1.toQuat(quat1);
            var quat = QuatMul(quat1, quat0);

            quat.toMat43(mRet);
            mRet.setColumn(3, trans);
			
			/*Allocator._mat43(mat0);
			Allocator._mat43(mat1);
			Allocator._quat(quat0);
			Allocator._quat(quat1);
			Allocator._quat(quat);
			Allocator._vec3(trans0);
			Allocator._vec3(trans1);
			Allocator._vec3(trans);*/
        }
        else if (this.iBlendMode == 2) {
            var mat0 = this.aChannelList[0].getBoneMat43(sBoneName);
            var mat1 = this.aChannelList[1].getBoneMat43(sBoneName);

            var trans0 = mat0.getColumn(3);
            var trans1 = mat1.getColumn(3);
            var trans = Vec3Lerp(trans0, trans1, 0.5);

            var quat0 = new THREE.Quaternion();
            var quat1 = new THREE.Quaternion();
            mat0.toQuat(quat0);
            mat1.toQuat(quat1);
            var quat = QuatSlerp(quat1, quat0, 0.5);

            quat.toMat43(mRet);
            mRet.setColumn(3, trans);
			
			/*Allocator._mat43(mat0);
			Allocator._mat43(mat1);
			Allocator._quat(quat0);
			Allocator._quat(quat1);
			Allocator._quat(quat);
			Allocator._vec3(trans0);
			Allocator._vec3(trans1);
			Allocator._vec3(trans);*/
        }

        if (this.skinInfo)
            return Mat43Mul(mRet, this.skinInfo.getSkinMat(sBoneName));
        else
            return mRet;
    },

    /**
    Get the final transform 4x3 matrix array of the bones of the animation.
    
    @description The final transform matrix can directly transform mesh vertices from their local space to the animation's final pose.
                        This method will return the final transform matrices of all bones referenced by the mesh. 
                        And the order of the matrix in the array is according to the mesh skin.
     
    @param 
        
    @return   {Array} The final transform 4x3 matrix array of all bones referenced by the mesh.
    */
    getBoneFinalMat43Array: function()
    {
        var boneNameArray = this.skinInfo.getBoneNameArray();

        if (this.bBoneFinalMatDirty)
        {
			/*
            for (var i=0 ; i<this.aBoneFinalMatList.length ; ++i)
            {
				Allocator._mat43(this.aBoneFinalMatList[i]);
            }
            */
            this.aBoneFinalMatList.length = 0;
            for (var i = 0; i < boneNameArray.length; ++i)
            {
                this.aBoneFinalMatList.push( this.getBoneFinalMat43( boneNameArray[i] ) );
            }
            this.bBoneFinalMatDirty = false;
        }

        return this.aBoneFinalMatList;
    }
}
