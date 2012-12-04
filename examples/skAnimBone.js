function SkAnimBone() {
    this.sName = "";
    this.aKeyTransList = new Array;
    this.aKeyQuatList = new Array;
    this.parent = null;

    this.mCurMat = new THREE.Matrix4();
    this.bCurMatDirty = true;
}

SkAnimBone.prototype =
{
    clone: function() {
        var retBone = new SkAnimBone();
        retBone.sName = this.sName;

        for (var i = 0; i < this.mMtList.length; ++i) {
            retBone.aKeyTransList.push(this.aKeyTransList[i].clone());
            retBone.aKeyQuatList.push(this.aKeyQuatList[i].clone());
        }

        retBone.parent = this.parent;

        retBone.mCurMat = new THREE.Matrix4();
        retBone.bCurMatDirty = true;
    },

    clear: function() {
        this.sName = "";
        this.aKeyTransList.clear();
        this.aKeyQuatList.clear();
        this.parent = null;

        this.mCurMat.identity();
        this.bCurMatDirty = true;
    },

    setName: function(sName) {
        this.sName = sName;
    },

    getName: function() {
        return this.sName;
    },

    setParent: function(parent) {
        this.parent = parent;
    },

    getParent: function() {
        return this.parent;
    },

    loadKeyTranslateList: function(aTransArray) {
        this.aKeyTransList = new Array;
        for (var i = 0; i < aTransArray.length; ++i) {
            this.aKeyTransList.push(aTransArray[i].clone());
        }
    },

    loadKeyQuaternionList: function(aQuatArray) {
        this.aKeyQuatList = new Array;
        for (var i = 0; i < aQuatArray.length; ++i) {
            this.aKeyQuatList.push(aQuatArray[i].normalize());
        }
    },

    dirty: function() {
        this.bCurMatDirty = true;
    },

    update: function(iKey0, iKey1, fT) {
        if (this.bCurMatDirty) {
            var curTrans = Vec3Lerp(this.aKeyTransList[iKey0], this.aKeyTransList[iKey1], fT);
            var curQuat = QuatSlerp(this.aKeyQuatList[iKey0], this.aKeyQuatList[iKey1], fT);
            curQuat.normalize(1);

            //curQuat.toMat43(this.mCurMat);
            this.mCurMat.setRotationFromQuaternion( curQuat );

            this.mCurMat.m03 = curTrans.x;
            this.mCurMat.m13 = curTrans.y;
            this.mCurMat.m23 = curTrans.z;

            //Allocator._vec3(curTrans);
            //Allocator._quat(curQuat);

            if (this.parent) {
                if (this.parent.bCurMatDirty)
                    this.parent.update(iKey0, iKey1, fT);

                var temp = new THREE.Matrix4().multiply( this.parent.mCurMat, this.mCurMat );
                //Allocator._mat43(this.mCurMat);
                this.mCurMat = temp;
            }

            this.bCurMatDirty = false;
        }
    },

    getMat43: function() {
        return this.mCurMat.clone();
    },

    getMat4: function() {
        return this.mCurMat.clone();
    }
}
