package deep.macro;

#if macro
import format.zip.Reader;
import haxe.io.Bytes;
import haxe.macro.Context;
import haxe.macro.Expr;
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
		SWC.watch();
	}

	@:macro public static function watch():Expr
	{
		var libs = new Array<String>();
		
		for (path in Context.getClassPath())
		{
			if (path.length == 0) continue;
			
			path = FileSystem.fullPath(path);
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
				crc = new Hash<Float>();
				var content = File.getContent(crcName);
				var items = content.split("\n");
				for (item in items)
				{
					var a = item.split(":");
					if (a[0].length > 0)
						crc.set(a[0], Std.parseFloat(a[1]));
				}
			}
			
			var crcFile = File.write(crcName, false);
			
			for (f in files)
			{
				var name = f + ".swf";
				var fullname = path + "/" + name;
				var item = new Reader(File.read(path + "/" + f));
				for (i in item.read())
				{
					if (i.fileName == "library.swf")
					{
						var signature = Std.parseFloat(Std.string(i.crc32));
						if (crc == null || !crc.exists(name) || signature != crc.get(name) || !FileSystem.exists(fullname))
						{
							var of = File.write(fullname);
							of.write(i.data);
							of.close();
						}
						libs.push("-swf-lib \"" + fullname + '"');
						crcFile.writeString(name + ":" + signature + "\n");
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