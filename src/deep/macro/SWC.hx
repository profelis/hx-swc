package deep.macro;

#if macro
import format.zip.Reader;
import haxe.io.Bytes;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.Stack;
import neko.FileSystem;
import neko.io.File;
import neko.io.Path;
#end

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */

class SWC 
{
	#if neko
	static function main()
	{
		SWC.watch();
	}
	#end

	@:macro public static function watch(paths:Array<String> = null, includeClassPath:Bool = true):Expr
	{
		var libs = new Array<String>();
		var crcs = new Array<String>();
		
		var crcName = ".swc.crc";
		var crc;
		
		if (paths == null) paths = new Array<String>();
		if (includeClassPath) paths = paths.concat(Context.getClassPath());
		
		if (FileSystem.exists(crcName))
		{
			crc = new Hash<String>();
			var content = File.getContent(crcName);
			var items = content.split("\n");
			for (item in items)
			{
				if (item.length > 0)
				{
					var a = item.split("~");
					crc.set(a[0], a[1]);
				}
			}
		}
		
		for (path in paths)
		{
			if (path.length == 0) continue;
			
			if (StringTools.endsWith(path, "\\") || StringTools.endsWith(path, "/"))
				path = path.substr(0, path.length - 1);
			
			if (!neko.FileSystem.exists(path))
			{
				Context.warning("'" + path + "' expected.", Context.currentPos());
				continue;
			}
			
			var allFiles;
			if (FileSystem.isDirectory(path))
			{
				allFiles = FileSystem.readDirectory(path);
				if (allFiles.length == 0) continue;
			}
			else
			{
				allFiles = [Path.withoutDirectory(path)];
				path = Path.directory(path);
			}
			
			var files = new Array<String>();
			
			for (f in allFiles) 
				if (StringTools.endsWith(f, ".swc")) files.push(f);
			
			if (files.length == 0) continue;
			
			
			
			for (f in files)
			{
				var swcFullName = path + "/" + f;
				var swfFullName = path + "/" + f + ".swf";
				
				var stat = FileSystem.stat(swcFullName);
				var signature = Std.string(stat.mtime);
				
				trace(swcFullName);
				
				crcs.push(swcFullName + "~" + signature + "~\n");
				libs.push("-swf-lib \"" + swfFullName + '"');
				
				if (crc != null)
				{
					if (crc.exists(swcFullName) && signature == crc.get(swcFullName)) continue;
				}
				
				var item = new Reader(File.read(swcFullName));
				for (i in item.read())
				{
					if (i.fileName == "library.swf")
					{
						var of = File.write(swfFullName);
						of.write(i.data);
						of.close();
					}
				}
			}
		}
		
		var crcFile = File.write(crcName, false);
		for (l in crcs) crcFile.writeString(l);
		crcFile.close();
		
		var libsListFile = File.write("swf-libs.txt");
		for (l in libs) libsListFile.writeString(l + "\n");
		libsListFile.close();
		
		return {expr:EConst(CString("null")), pos:Context.currentPos()};
	}
}