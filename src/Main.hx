package ;

import com.junkbyte.console.Cc;
import flash.display.Bitmap;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.Lib;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */

class Main 
{
	
	static function main() 
	{
		SWCImport.main();
		
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		// entry point
		
		Cc.startOnStage(stage);
		Cc.visible = true;
		Cc.log("tada");
	}
	
}