package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class PilotWingsCloud extends FlxSprite
{
	public function new(x:Float, y:Float)
	{
		super(x, y);

		frames = Paths.getSparrowAtlas("pw/clouds", 'smash');
		animation.addByPrefix('cloud1', 'cloud1', 24, false);
		animation.addByPrefix('cloud2', 'cloud2', 24, false);
		animation.addByPrefix('cloud3', 'cloud3', 24, false);
		animation.addByPrefix('cloud4', 'cloud4', 24, false);
		animation.addByPrefix('cloud5', 'cloud5', 24, false);
		animation.play('cloud' + FlxG.random.int(1, 5));
	}

	override function update(elapsed:Float) {
		if(animation.curAnim.finished) kill();

		super.update(elapsed);
	}
}
