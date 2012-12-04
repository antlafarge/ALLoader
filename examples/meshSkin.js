function MeshSkin()
{
    this.aBoneNameList = new Array;
    this.aBoneNameIdxMap = new Object;
    this.aBoneSkinMatList = new Array;
    this.sVertexBoneIdxAttribName = "";
    this.sVertexBoneWeightAttribName = "";
    this.boneCount = [];
    this.boneIndex = [];
    this.boneWeight = [];
}

MeshSkin.prototype.clear = function ()
{
	this.aBoneNameList = new Array;
	this.aBoneNameIdxMap = new Object;
	this.aBoneSkinMatList = new Array;
	this.sVertexBoneIdxAttribName = "";
	this.sVertexBoneWeightAttribName = "";
}
MeshSkin.prototype.addBone = function (c, a)
{
	this.aBoneNameIdxMap[c] = this.aBoneNameList.length;
	this.aBoneNameList.push(c);
	this.aBoneSkinMatList.push(a.clone());
}
MeshSkin.prototype.getBoneNum = function ()
{
    return this.aBoneNameList.length;
}
MeshSkin.prototype.setRefAttributeName = function (a, c)
{
	this.sVertexBoneIdxAttribName = a;
	this.sVertexBoneWeightAttribName = c;
}
MeshSkin.prototype.getVertexBoneIdxAttribName = function ()
{
	return this.sVertexBoneIdxAttribName;
}
MeshSkin.prototype.getVertexBoneWeightAttribName = function ()
{
	return this.sVertexBoneWeightAttribName;
}
MeshSkin.prototype.getBoneNameArray = function ()
{
	return this.aBoneNameList;
}
MeshSkin.prototype.getSkinMat = function (a)
{
	return this.aBoneSkinMatList[this.aBoneNameIdxMap[a]];
}
MeshSkin.prototype.getSkinMatArray = function ()
{
	return this.aBoneSkinMatList;
}
MeshSkin.prototype.getBoneCount = function()
{
	return this.boneCount;
}
MeshSkin.prototype.setBoneCount = function(a)
{
	this.boneCount = a;
}
MeshSkin.prototype.getBoneIndex = function()
{
	return this.boneIndex;
}
MeshSkin.prototype.setBoneIndex = function(a)
{
	this.boneIndex = a;
}
MeshSkin.prototype.getBoneWeight = function()
{
	return this.boneWeight;
}
MeshSkin.prototype.setBoneWeight = function(a)
{
	this.boneWeight = a;
}

