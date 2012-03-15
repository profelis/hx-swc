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
	@:macro public static function watch(paths:Array<String> = null, includeClassPath:Bool = true):Expr
	{
		var libs = new StringBuf();
		var crcs = new StringBuf();
		
		var crcName = ".swc.crc";
		var crc:Hash<String>;
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
		
		if (paths == null) paths = new Array<String>();
		if (includeClassPath) paths = paths.concat(Context.getClassPath());
		
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
				var swfFullName = swcFullName + ".swf";
				
				var stat = FileSystem.stat(swcFullName);
				var signature = Std.string(stat.mtime);
				
				crcs.add(swcFullName + "~" + signature + "~\n");
				libs.add("-swf-lib " + swfFullName + '\n');
				
				if (crc != null && crc.exists(swcFullName) 
					&& signature == crc.get(swcFullName) && FileSystem.exists(swfFullName)) continue;
				
				for (i in new Reader(File.read(swcFullName)).read())
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
		crcFile.writeString(crcs.toString());
		crcFile.close();
		
		var libsListFile = File.write("swf-libs.txt", false);
		libsListFile.writeString(libs.toString());
		libsListFile.close();
		
		return {expr:EConst(CString("null")), pos:Context.currentPos()};
	}
}