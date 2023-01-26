package;

import flixel.util.FlxTimer;
import flixel.math.FlxPoint;
import lime.system.System;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.6.2'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;
	
	var optionShit:Array<String> = [
		'smash',
		//'story_mode',
		'freeplay',
		//#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		'options',
		#if !switch 'donate', #end
	];

	var descShit:Array<String> = [
		'The main campaign where it all begins!',
		'Quickly hop into a rap battle of your choice!',
		'Check out your sick achievements!',
		'The awesome people who made this mod possible!',
		'Tweak, modify, and stylize your gaming needs!',
		'Support the Funkin\' Crew on itch.io!',
	];

	var messages:Array<String> = CoolUtil.coolTextFile(Paths.txt('menuText'));

	var messageText:Alphabet;
	var descText1:Alphabet;
	var descText2:Alphabet;

	var icon:AttachedSprite;
	var delayTime:Float;
	var canChange:Bool = true;
	var curMessageIndex:Int;

	var colorTween:FlxTween;
	var cornerTween:FlxTween;
	var textTween:FlxTween;

	var blocks:FlxTypedGroup<FlxSprite>;
	var icons:FlxTypedGroup<FlxSprite>;
	var blockLayers:FlxTypedGroup<FlxSprite>;
	var dividers:FlxTypedGroup<FlxSprite>;
	var corners:FlxTypedGroup<FlxSprite>;
	var blockGradient:FlxSprite;
	var circle:FlxSprite;

	var gradientOptions:Array<Dynamic> = [
		[-659.4, -298.4, 0xFFFF5730], //smash
		[-658.15, -191.25, 0xFFAFFF94], //freeplay
		[-163.4, -377.2, 0xFF67B3FF], //awards
		[-163.4, -191.25, 0xFFFF77B1], //credits
		[-163.75, -191.65, 0xFFFFEC80], // options
		[381.25, 184.35, 0xFFFFEC80] //donate
	];

	var cornerPos:Array<Dynamic> = [
		[-640, -284], //smash
		[-640, 62], //freeplay
		[465, -359], //awards
		[485, -116], //credits
		[0, 0], // options
		[0, 0] //donate
	];

	override function create()
	{
		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end
		WeekData.loadTheFirstEnabledMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camGame];

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		//add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		//add(magenta);
		
		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		//add(menuItems);

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, 0);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			//menuItem.screenCenter(X);
			menuItems.add(menuItem);
			//var scr:Float = (optionShit.length - 4) * 0.135;
			//if(optionShit.length < 6) scr = 0;
			//menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));

			switch (optionShit[i])
			{
				case 'smash':
					menuItem.setGraphicSize(Std.int(menuItem.width * 0.75));
					menuItem.setPosition(-540, -100);

				case 'freeplay':
					menuItem.setGraphicSize(Std.int(menuItem.width * 0.55));
					menuItem.setPosition(-512, 205);

				case 'awards':
					menuItem.setGraphicSize(Std.int(menuItem.width * 0.6));
					menuItem.setPosition(200, -230);

				case 'credits':
					menuItem.setGraphicSize(Std.int(menuItem.width * 0.45));
					menuItem.setPosition(240, -15);

				case 'options':
					menuItem.setGraphicSize(Std.int(menuItem.width * 0.55));
					menuItem.setPosition(40, 205);

				case 'donate':
					menuItem.setGraphicSize(Std.int(menuItem.width * 1));
					menuItem.setPosition(0, 0);
					menuItem.visible = false;
			}

			menuItem.updateHitbox();
		}

		FlxG.camera.follow(camFollowPos, null, 1);

		// NG.core.calls.event.logEvent('swag').send();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		messageText = new Alphabet(0, 0, '', false, false, 0.05, 0.4, FlxColor.WHITE);
		add(messageText);

		blockGradient = new FlxSprite(0, 0);
		blockGradient.frames = Paths.getSparrowAtlas('mainmenu/block_gradients');
		blockGradient.animation.addByPrefix('0', "smash gradient", 24, false);
		blockGradient.animation.addByPrefix('1', "freeplay gradient", 24, false);
		blockGradient.animation.addByPrefix('2', "awards gradient", 24, false);
		blockGradient.animation.addByPrefix('3', "credits gradient", 24, false);
		blockGradient.animation.addByPrefix('4', "options gradient", 24, false);
		blockGradient.animation.addByPrefix('5', "donate gradient", 24, false);
		blockGradient.antialiasing = ClientPrefs.globalAntialiasing;
		add(blockGradient);

		blocks = new FlxTypedGroup<FlxSprite>();
		var smash:FlxSprite = new FlxSprite(0-FlxG.width/2, 76.65-FlxG.height/2).loadGraphic(Paths.image('mainmenu/blocks/smash block'));
		blocks.add(smash);
		var freeplay:FlxSprite = new FlxSprite(0-FlxG.width/2, 422.4-FlxG.height/2).loadGraphic(Paths.image('mainmenu/blocks/freeplay block'));
		blocks.add(freeplay);
		var awards:FlxSprite = new FlxSprite(632.6-FlxG.width/2, 0-FlxG.height/2).loadGraphic(Paths.image('mainmenu/blocks/awards block'));
		blocks.add(awards);
		var credits:FlxSprite = new FlxSprite(807.5-FlxG.width/2, 244.45-FlxG.height/2).loadGraphic(Paths.image('mainmenu/blocks/credits block'));
		blocks.add(credits);
		var options:FlxSprite = new FlxSprite(577.15-FlxG.width/2, 434.85-FlxG.height/2).loadGraphic(Paths.image('mainmenu/blocks/options block'));
		blocks.add(options);
		var donate:FlxSprite = new FlxSprite(1051.85-FlxG.width/2, 558-FlxG.height/2).loadGraphic(Paths.image('mainmenu/blocks/donate block'));
		blocks.add(donate);

		blocks.forEach(function(spr:FlxSprite)
		{
			spr.antialiasing = ClientPrefs.globalAntialiasing;
		});

		add(blocks);

		if (!ClientPrefs.lowQuality)
		{
			dividers = new FlxTypedGroup<FlxSprite>();
			dividers.add(new FlxSprite(300-FlxG.width/2, 76.65-FlxG.height/2).loadGraphic(Paths.image('mainmenu/block dividers/smash divider')));
			dividers.add(new FlxSprite(374.2-FlxG.width/2, 422.35-FlxG.height/2).loadGraphic(Paths.image('mainmenu/block dividers/freeplay divider')));
			dividers.add(new FlxSprite(632.6-FlxG.width/2, 0.05-FlxG.height/2).loadGraphic(Paths.image('mainmenu/block dividers/awards divider')));
			dividers.add(new FlxSprite(807.2-FlxG.width/2, 244.45-FlxG.height/2).loadGraphic(Paths.image('mainmenu/block dividers/credits divider')));
			dividers.add(new FlxSprite(577.15-FlxG.width/2, 434.7-FlxG.height/2).loadGraphic(Paths.image('mainmenu/block dividers/options divider')));
			dividers.add(new FlxSprite()); //empty space to use index lol

			dividers.forEach(function(spr:FlxSprite)
			{
				spr.antialiasing = ClientPrefs.globalAntialiasing;
			});

			add(dividers);

			corners = new FlxTypedGroup<FlxSprite>();
			corners.add(new FlxSprite(cornerPos[0][0], cornerPos[0][1]).loadGraphic(Paths.image('mainmenu/block corners/smash corner')));
			corners.add(new FlxSprite(cornerPos[1][0], cornerPos[1][1]).loadGraphic(Paths.image('mainmenu/block corners/freeplay corner')));
			corners.add(new FlxSprite(cornerPos[2][0], cornerPos[2][1]).loadGraphic(Paths.image('mainmenu/block corners/awards corner')));
			corners.add(new FlxSprite(cornerPos[3][0], cornerPos[3][1]).loadGraphic(Paths.image('mainmenu/block corners/credits corner')));
			corners.add(new FlxSprite(cornerPos[4][0], cornerPos[4][1])); //empty space to use index lol
			corners.add(new FlxSprite(cornerPos[5][0], cornerPos[5][1])); //empty space to use index lol

			corners.forEach(function(spr:FlxSprite)
			{
				spr.antialiasing = ClientPrefs.globalAntialiasing;
				spr.visible = false;
			});

			add(corners);
		}

		blockLayers = new FlxTypedGroup<FlxSprite>();
		blockLayers.add(new FlxSprite(-10.8-FlxG.width/2, 68.05-FlxG.height/2).loadGraphic(Paths.image('mainmenu/block white layers/smash white layer')));
		blockLayers.add(new FlxSprite(-10.4-FlxG.width/2, 412.45-FlxG.height/2).loadGraphic(Paths.image('mainmenu/block white layers/freeplay white layer')));
		blockLayers.add(new FlxSprite(621.6-FlxG.width/2, -11.9-FlxG.height/2).loadGraphic(Paths.image('mainmenu/block white layers/awards white layer')));
		blockLayers.add(new FlxSprite(767.95-FlxG.width/2, 233.35-FlxG.height/2).loadGraphic(Paths.image('mainmenu/block white layers/credits white layer')));
		blockLayers.add(new FlxSprite(566.95-FlxG.width/2, 424.2-FlxG.height/2).loadGraphic(Paths.image('mainmenu/block white layers/options white layer')));
		blockLayers.add(new FlxSprite(1032-FlxG.width/2, 549.5-FlxG.height/2).loadGraphic(Paths.image('mainmenu/block white layers/donate white layer')));

		blockLayers.forEach(function(spr:FlxSprite)
		{
			spr.antialiasing = ClientPrefs.globalAntialiasing;
			spr.visible = false;
		});

		add(blockLayers);

		add(menuItems);

		icons = new FlxTypedGroup<FlxSprite>();
		icons.add(new FlxSprite(-470, -270).loadGraphic(Paths.image('mainmenu/icons/smash icon')));
		icons.add(new FlxSprite(-440, 75).loadGraphic(Paths.image('mainmenu/icons/freeplay icon')));
		icons.add(new FlxSprite(270, -350).loadGraphic(Paths.image('mainmenu/icons/awards icon')));
		icons.add(new FlxSprite(280, -105).loadGraphic(Paths.image('mainmenu/icons/credits icon')));
		icons.add(new FlxSprite(135, 110).loadGraphic(Paths.image('mainmenu/icons/options icon')));
		icons.add(new FlxSprite(505, 210).loadGraphic(Paths.image('mainmenu/icons/donate icon')));

		icons.forEach(function(spr:FlxSprite)
		{
			spr.antialiasing = ClientPrefs.globalAntialiasing;
		});

		add(icons);

		var bottomBar:FlxSprite = new FlxSprite(-639, 283).loadGraphic(Paths.image('mainmenu/bottombar'));
		bottomBar.antialiasing = ClientPrefs.globalAntialiasing;
		add(bottomBar);

		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//add(versionShit);

		descText1 = new Alphabet(0, 210, descShit[curSelected], false, false, 0.05, 0.7, FlxColor.WHITE);
		add(descText1);
		descText2 = new Alphabet(0, 210, descShit[curSelected], false, false, 0.05, 0.7, FlxColor.WHITE);
		descText2.alpha = 0;
		add(descText2);

		changeDescription(false);

		circle = new BGSprite('mainmenu/circle_image', 481.3-FlxG.width/2, 173.45-FlxG.height/2, 1, 1, 
		['smash', 'freeplay', 'awards', 'credits', 'options', 'donate'], false);
		circle.animation.play(optionShit[curSelected]);
		circle.animation.finish();
		circle.antialiasing = ClientPrefs.globalAntialiasing;
		add(circle);

		//trace(System.userDirectory);

		changeItem(curSelected);

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				var num:Int;
				switch (curSelected)
				{
					case 1:
						num = 0;
					case 3:
						num = 2;
					case 4:
						num = 3;
					case 5:
						num = 3;
					default:
						num = curSelected;
				}
				num = (curSelected < 5 && curSelected != 0 && curSelected != 2) ? curSelected - 1 : (curSelected == 5) ? 3 : curSelected;
				if (num == curSelected) return;
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(num);
			}

			if (controls.UI_DOWN_P)
			{
				var num:Int;
				switch (curSelected)
				{
					case 0:
						num = 1;
					case 2:
						num = 3;
					case 3:
						num = 4;
					default:
						num = curSelected;
				}
				num = (curSelected < 4 && curSelected != 1) ? curSelected + 1 : curSelected;
				if (num == curSelected) return;
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(num);
			}

			if (controls.UI_LEFT_P)
			{
				var num:Int;
				switch (curSelected)
				{
					case 2:
						num = 0;
					case 3:
						num = 0;
					case 4:
						num = 1;
					case 5:
						num = 4;
					default:
						num = curSelected;
				}
				if (num == curSelected) return;
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(num);
			}

			if (controls.UI_RIGHT_P)
			{
				var num:Int;
				switch (curSelected)
				{
					case 0:
						num = 3;
					case 1:
						num = 4;
					case 4:
						num = 5;
					default:
						num = curSelected;
				}
				num = (curSelected < 2) ? curSelected + 3 : (curSelected == 4) ? 5 : curSelected;
				if (num == curSelected) return;
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(num);
			}


			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				FlxG.camera.zoom += 0.1;

				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					//if(ClientPrefs.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'story_mode' | 'smash':
										//MusicBeatState.switchState(new StoryMenuState());
										WeekData.reloadWeekFiles(true);
										var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[0]);
										WeekData.setDirectoryFromWeek(weekFile);

										trace(WeekData.weeksLoaded);

										var songArray:Array<String> = [];
										var leWeek:Array<Dynamic> = weekFile.songs;
										for (i in 0...leWeek.length) {
											songArray.push(leWeek[i][0]);
										}
										PlayState.storyPlaylist = songArray;
										PlayState.isStoryMode = true;

										CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
										var curDifficulty = 2;
										var diffic = CoolUtil.getDifficultyFilePath(curDifficulty);
										if(diffic == null) diffic = '';

										PlayState.storyDifficulty = curDifficulty;

										PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
										PlayState.campaignScore = 0;
										PlayState.campaignMisses = 0;
										LoadingState.loadAndSwitchState(new PlayState(), true);
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									#if MODS_ALLOWED
									case 'mods':
										MusicBeatState.switchState(new ModsMenuState());
									#end
									case 'awards':
										MusicBeatState.switchState(new AchievementsMenuState());
									case 'credits':
										MusicBeatState.switchState(new CreditsState());
									case 'options':
										LoadingState.loadAndSwitchState(new options.OptionsState());
								}
							});
						}
					});
				}
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		icons.forEach(function(spr:FlxSprite)
		{
			var mult:Float = FlxMath.lerp(1, spr.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
			spr.scale.set(mult, mult);
			//spr.updateHitbox();
		});

		FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, 1, 0.5/8);

		if(!ClientPrefs.lowQuality)
			dividers.members[curSelected].alpha += elapsed * 6;

		delayTime += elapsed;
		if (!messageText.isOnScreen())
		{
			if (delayTime >= 2) delayTime = 0;
			else if (delayTime >= 1.5)
			{
				changeMessage();
			}
		}
		else if (messageText.isOnScreen())
		{
			if (delayTime >= 2)
				messageText.velocity.x = -60;
		}

		//#if debug
		var multiplier = FlxG.keys.pressed.SHIFT ? 9 : 0;
		var temp = messageText;//corners.members[curSelected];

		if (FlxG.keys.justPressed.I)					
		{
			temp.y -= 1 + multiplier;
			trace(temp.x + ', ' + temp.y);
		}
		if (FlxG.keys.justPressed.K)
		{
			temp.y += 1 + multiplier;
			trace(temp.x + ', ' + temp.y);
		}
		if (FlxG.keys.justPressed.J)
		{
			temp.x -= 1 + multiplier;
			trace(temp.x + ', ' + temp.y);
		}
		if (FlxG.keys.justPressed.L)
		{
			temp.x += 1 + multiplier;
			trace(temp.x + ', ' + temp.y);
		}

		if (FlxG.keys.justPressed.C)
			changeMessage();
		//#end

		super.update(elapsed);
	}

	function changeLayerColor(spr:FlxSprite, a:FlxColor, b:FlxColor):Void
	{
		if (colorTween != null) colorTween.cancel();
		colorTween = FlxTween.color(spr, 0.3, a, b, {ease: FlxEase.smoothStepInOut, type: FlxTweenType.PINGPONG});
	}

	function changeDescription(?fadeIn:Bool = true):Void
	{	
		if (fadeIn) 
		{
			descText2.changeText(descText1.text, 0);
			descText2.updateHitbox();
			descText2.setPosition(descText1.x, descText1.y);
			descText2.alpha = 1;
			FlxTween.tween(descText2, {x: descText2.x - 30, alpha: 0}, 0.1, {ease: FlxEase.linear});
		}

		descText1.changeText(descShit[curSelected], 0);
		descText1.updateHitbox();
		descText1.setPosition(-descText1.width, 210);
		if (!fadeIn) descText1.alpha = 1;

		if (fadeIn) 
		{
			descText1.alpha = 0;
			descText1.x += 50;

			if (textTween != null) textTween.cancel();
			textTween = FlxTween.tween(descText1, {x: descText1.x - 50, alpha: 1}, 0.1, {ease: FlxEase.linear});
		}
	}

	function changeMessage()
	{
		delayTime = 0;
		messageText.velocity.x = 0;
		var messageIndex = FlxG.random.int(0, messages.length-1, [curMessageIndex]);
		var str:String = messages[messageIndex];
		str = checkSpecialText(str);

		messageText.changeText(str, 0);
		messageText.updateHitbox();
		messageText.setPosition(-FlxG.width/2 - messageText.width/2 + 20, -435);
		messageText.textColor = FlxColor.WHITE;

		if (icon != null) icon.destroy();

		if (str.indexOf('|') > -1)
		{
			var arr:Array<String> = str.split('|');

			messageText.changeText(arr[1], 0);
			messageText.updateHitbox();
			messageText.setPosition(-FlxG.width/2 - messageText.width/2 + 70, -435);
			icon = new AttachedSprite('credits/' + arr[0]);
			icon.setGraphicSize(Std.int(icon.width*0.5));
			icon.updateHitbox();
			icon.xAdd = messageText.width/2 - icon.width;
			icon.yAdd = icon.height;
			icon.sprTracker = messageText;
			add(icon);

			messageText.textColor = FlxColor.fromInt(CoolUtil.dominantColor(icon)).getLightened(0.5);
		}
		curMessageIndex = messageIndex;
	}

	function checkSpecialText(str:String):String
	{
		while (str.indexOf('[') > -1 && str.indexOf(']') > -1)
		{
			var s:String = str.substring(0, str.indexOf('['));
			var m:String = str.substring(str.indexOf('['), str.indexOf(']')+1);
			var e:String = str.substring(str.indexOf(']')+1);

			trace(s + m + e);

			var uppercase:Bool = (m == m.toUpperCase());

			switch (m.toLowerCase())
			{
				case '[user]':
					var dir:String = System.userDirectory;
					dir = dir.replace('\\', '/');
					dir = (dir.endsWith('/')) ? dir.substring(0, dir.length-1) : dir;

					while (dir.indexOf('/') > 0)
					{
						dir = dir.substring(dir.indexOf('/')+1);
					}
					m = dir;

				default:
					
			}
			
			if (uppercase)
				m = m.toUpperCase();

			str = s + m + e;
		}
		return str;
	}

	function changeItem(huh:Int = 0)
	{
		//if (curSelected == huh) return;
		curSelected = huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		changeDescription(!ClientPrefs.lowQuality);
		//changeMessage();

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				var lastMidpoint = spr.getMidpoint();

				spr.animation.play('selected');
				var add:Float = 0;
				if(menuItems.length > 4) {
					add = menuItems.length * 8;
				}
				//camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				//spr.centerOffsets();
				spr.updateHitbox();
				spr.offset.set(spr.offset.x + Math.abs(spr.getMidpoint().x - lastMidpoint.x), spr.offset.y + Math.abs(spr.getMidpoint().y - lastMidpoint.y));
			}
		});

		blockGradient.animation.play(Std.string(curSelected), true);
		blockGradient.setPosition(gradientOptions[curSelected][0], gradientOptions[curSelected][1]);
		blockGradient.color = FlxColor.fromInt(CoolUtil.dominantColor(blocks.members[curSelected]));
		changeLayerColor(blockGradient, blockGradient.color, gradientOptions[curSelected][2]);

		if(!ClientPrefs.lowQuality)
		{
			dividers.forEach(function(spr:FlxSprite)
			{
				spr.alpha = 0;
			});

			for (i in 0...corners.length)
			{
				corners.members[i].setPosition(cornerPos[i][0], cornerPos[i][1]);
				corners.members[i].visible = false;
			}
			if (cornerTween != null) cornerTween.cancel();
			var spr = corners.members[curSelected];
			spr.visible = true;
			var num:Int = (curSelected < 2) ? -20 : 20;
			spr.x += num;

			cornerTween = FlxTween.tween(spr, {x: spr.x + (-num)}, 0.2, {ease: FlxEase.quadOut});
		}
	
		blockLayers.forEach(function(spr:FlxSprite)
		{
			spr.visible = false;
		});
		blockLayers.members[curSelected].visible = true;

		icons.forEach(function(spr:FlxSprite)
		{
			spr.alpha = 0.75;
		});
		icons.members[curSelected].alpha = 1;
		icons.members[curSelected].scale.set(1.2, 1.2);

		circle.animation.play(optionShit[curSelected], true);
	}
}
