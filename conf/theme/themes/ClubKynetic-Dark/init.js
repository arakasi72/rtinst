/*
 *  KlubKynetic skin for ruTorrent
 *  Author: b0ts37en - KyneticWeb
 */ 

plugin.kyneticwebAllDone = plugin.allDone;
plugin.allDone = function()
{
	plugin.kyneticwebAllDone.call(this);
	$.each(["diskspace","quotaspace","cpuload"], function(ndx,name)
	{
		var plg = thePlugins.get(name);
		if(plg && plg.enabled)
		{
			plg.prgStartColor = new RGBackground("#1E824C");
			plg.prgEndColor = new RGBackground("#96281B");
		}
	});
}

plugin.oldTableCreate = dxSTable.prototype.create;
dxSTable.prototype.create = function(ele, styles, aName)
{
	plugin.oldTableCreate.call(this, ele, styles, aName);
	this.prgStartColor = new RGBackground("#96281B");
	this.prgEndColor = new RGBackground("#1E824C");
}