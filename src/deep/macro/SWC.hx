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
	static function main()
	{
		//SWC.watch();
	}

	@:macro public static function watch():Expr
	{
		var libs = new Array<String>();
		
		for (path in Context.getClassPath())
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
			
			var crcName = path + "/.swc.crc";
			var crc;
			if (FileSystem.exists(crcName))
			{
				crc = new Hash<String>();
				var content = File.getContent(crcName);
				var items = content.split("\n");
				for (item in items)
				{
					var a = item.split("~");
					if (a[0].length > 0)
						crc.set(a[0], a[1]);
				}
			}
			
			var crcFile = File.write(crcName, false);
			for (f in files)
			{
				var swcFullName = path + "/" + f;
				var stat = FileSystem.stat(swcFullName);
				var signature = Std.string(stat.mtime);
				crcFile.writeString(f + "~" + signature + "~\n");
				if (crc != null)
				{
					if (crc.exists(swcFullName) && signature == crc.get(swcFullName)) continue;
				}
				
				var swfFullName = path + "/" + f + ".swf";
				
				var item = new Reader(File.read(swcFullName));
				for (i in item.read())
				{
					if (i.fileName == "library.swf")
					{
						var of = File.write(swfFullName);
						of.write(i.data);
						of.close();
						libs.push("-swf-lib \"" + swfFullName + '"');
					}
				}
			}
			crcFile.close();
		}
		
		var bf = File.write("swc-libs.txt");
		for (l in libs)
			bf.writeString(l + " ");
			
		bf.close();
		
		return {expr:EConst(CString("null")), pos:Context.currentPos()};
	}
}