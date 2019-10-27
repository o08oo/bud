package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxMath;

import openfl.Assets;
import flixel.tile.FlxTilemap;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.util.FlxColor;

import flixel.system.scaleModes.*;
import flixel.effects.particles.*;

import flash.display.BlendMode;

import flixel.tile.FlxTileblock;

import flixel.addons.ui.FlxUI9SliceSprite;
import flash.geom.Rectangle;

import flixel.util.FlxRandom;

import flixel.tweens.*;

import flixel.util.FlxSpriteUtil;

import flixel.system.FlxSound;


/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState
{
	private var tileMap:FlxTilemap;
	static var TILE_WIDTH:Int = 16;
	static var TILE_HEIGHT:Int = 16;
	
	static var LEVEL_WIDTH:Int = 50;
	static var LEVEL_HEIGHT:Int = 50;
	static var CAMERA_SPEED:Int = 100;
	private var camera:FlxCamera;
	private var cameraFocus:FlxSprite;
	
	var currentTime:Float;
	var delta:Float;
	var lastTimer:Float = 0;
	
	private var _emitter:FlxEmitter;
	private var _whitePixel:FlxParticle;
	
	
	var scrollinggroup:FlxGroup; // contains blockgroup and plantgroup
	var blockgroup:FlxGroup;
	var plantgroup:FlxGroup;
	 var plantcorners:FlxGroup;
	 var plantedgesup:FlxGroup;
	 var plantedgessides:FlxGroup;
	
	var bud:FlxSprite;
	
	var white:FlxSprite;
	
	var btn_replay:FlxButton;
	
	var tween:FlxTween;
	
	var mostRecentlyRevivedCorner:FlxSprite;
	
	var follow_edge_up:FlxUI9SliceSprite;
	var follow_edge_sides:FlxUI9SliceSprite;
	
	var btn_start:FlxButton;
	
	var _txtScore:FlxText;
	
	var basespeed:Float;
	var baselastblock_y:Float;
	
	public static var skipstart = false;
	
	var cursor:FlxSprite;
	
	 private var _sndMove:FlxSound;
	 private var _sndLose:FlxSound;
	
	//// gameplay vars ////
	
	var speed:Float = 90; // increases
	
	var gapsize = 30;
	
	var maxblockheight = 200; // slightly increases with speed
	var minblockheight = 20; // increases with speed
	var blockoffset = 5;
	var blockreverseoffset = 90 - 5; // calculated from game size
	
	var lastblockside = "left"; // for the next block to be placed on the opposite side. choose the initial one randomly
	var lastblock_y:Float = -90; // for the next block to be placed accordingly
	var numblocks = 10; // maximum blocks on screen at the same time
	
	var score = 0; // time alive
	
	var state = "menu"; // menu, playing, lost
	var budstate = "ready"; // ready, tweening, catching up
	var budside = "middle";
	var budmiddle_x = 42;
	var budleft_x = 15;
	var budright_x = 64;
	var bud_default_y = 100;
	
	//var numstems = 10; // maximum stem edges on screen at the same time
	var numcorners = 11; // maximum stem corners on screen at the same time
	
	
	/**
	 * Function that is called up when to state is created to set it up. 
	 */
	override public function create():Void
	{
		//basespeed = speed;
		
		lastblockside = FlxRandom.getObject(["left", "right"]);
		
		FlxG.autoPause = false;
		
		FlxG.scaleMode = new PixelPerfectScaleMode();
		FlxG.camera.fade(FlxColor.WHITE, .33, true);
		FlxG.camera.bgColor = 0xffffff;
		FlxG.mouse.visible = false;
		
		super.create();
		
		//FlxG.fixedTimestep = false;
		 _sndMove = FlxG.sound.load("assets/Jump23.wav");
		  _sndLose = FlxG.sound.load("assets/Explosion12.wav");
		
		tileMap = new FlxTilemap();
		tileMap.loadMap(Assets.getText("assets/map.csv"), "assets/tileset.png", TILE_WIDTH, TILE_HEIGHT, 0, 1);
		tileMap.setTileProperties(0, FlxObject.ANY); // void tile
		tileMap.setTileProperties(1, FlxObject.ANY); // floor
		tileMap.setTileProperties(2, FlxObject.NONE); // wall
		////add(tileMap);
		
		
		cameraFocus = new FlxSprite();
		//cameraFocus.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		cameraFocus.makeGraphic(3, 3, FlxColor.RED);
		////add(cameraFocus);
		//FlxG.followBounds(0,0,tileMap.width,tileMap.height); //the hard way 
		camera = FlxG.camera;
		camera.follow(cameraFocus, FlxCamera.STYLE_NO_DEAD_ZONE);
		tileMap.follow(); // lock the automatic camera to the map's edges
		FlxG.worldBounds.width = TILE_WIDTH * tileMap.width;
		FlxG.worldBounds.height = TILE_HEIGHT * tileMap.height;
		cameraFocus.x = 30;
         cameraFocus.y = 30;
		
		// particles
		
		_emitter = new FlxEmitter(10, FlxG.height / 2, 200);
		_emitter.setXSpeed(100, 200);
		_emitter.setYSpeed( -50, 50);
		_emitter.bounce = 0.8;
		////add(_emitter);
		for (i in 0...(Std.int(_emitter.maxSize / 2))) 
		{
			_whitePixel = new FlxParticle();
			_whitePixel.makeGraphic(2, 2, FlxColor.WHITE);
			// Make sure the particle doesn't show up at (0, 0)
			_whitePixel.visible = false; 
			_emitter.add(_whitePixel);
			_whitePixel = new FlxParticle();
			_whitePixel.makeGraphic(1, 1, FlxColor.WHITE);
			_whitePixel.visible = false;
			_emitter.add(_whitePixel);
		}
		// Params: Explode, Particle Lifespan, Emit rate (in seconds)
		//_emitter.start(false, 3, .01);
		
		
		// blend mode
		// 1
		var bmtest = new FlxSprite(10, 10, "assets/1.png");
		bmtest.scale.set(1, 1);
		////add(bmtest);
		// 2
		var bmtest = new FlxSprite(15, 15, "assets/1.png");
		#if !(cpp || neko || js)
		bmtest.blend = BlendMode.INVERT;
		#end
		bmtest.scale.set(2.5, 2.5);
		////add(bmtest);
		
		// tint
		var bmtest = new FlxSprite(30, 30, "assets/1.png");
		bmtest.scale.set(2, 2);
		bmtest.color = 0xff0000;
		////add(bmtest);
		
		// mockup
		var bmtest = new FlxSprite(0, 0, "assets/titlemock4.png");
		////add(bmtest);
		
		
		
		
		//var tempTileblock = new FlxTileblock(0, 3, 250, 36);
		//tempTileblock.loadTiles("assets/tiles3.png", 16, 16, 0);
		//add(tempTileblock);
		
		
		
		//setFacingFlip(FlxObject.LEFT, false, false);
		//setFacingFlip(FlxObject.RIGHT, true, false);
		
		//var _slice:Array<Int> = [16,16,32,32];
		//var _slice:Array<Int> = [1, 16, 16, 32];
		var _slice:Array<Int> = [2, 16, 17, 32];
		//var _slice2:Array<Int> = [16,16,31,47];
		var myCustomImage3 = new FlxUI9SliceSprite(-1, -10, "assets/tiles3_3.png", new Rectangle(0, 0, blockoffset+3, FlxG.height+20), _slice, FlxUI9SliceSprite.TILE_BOTH);
		var myCustomImage5 = new FlxUI9SliceSprite(blockreverseoffset-2, -10, "assets/tiles3_3.png", new Rectangle(0, 0, blockoffset+2, FlxG.height+20), _slice, FlxUI9SliceSprite.TILE_BOTH);
		//var myCustomImage4 = new FlxUI9SliceSprite(4, 54, "assets/tiles3_4.png", new Rectangle(0, 0, 50, 50), _slice2);
        //add(myCustomImage3);
		add(myCustomImage3);
		add(myCustomImage5);
		myCustomImage5.setFacingFlip(FlxObject.RIGHT, false, false);
		myCustomImage5.setFacingFlip(FlxObject.LEFT, true, false);
		myCustomImage5.facing = FlxObject.LEFT;
		
		//scrollinggroup = new FlxSpriteGroup();
		scrollinggroup = new FlxGroup();
		blockgroup = new FlxGroup();
		scrollinggroup.add(blockgroup);
		
		for (i in 0...numblocks) // create blocks
		{
			var height = FlxRandom.floatRanged(minblockheight, maxblockheight); // randomize height
			var y = lastblock_y - height - gapsize;
			// create block
			var myCustomImage3 = new FlxUI9SliceSprite(0, y, "assets/tiles3_3.png", new Rectangle(0, 0, 50, height), _slice, FlxUI9SliceSprite.TILE_BOTH);
			myCustomImage3.setFacingFlip(FlxObject.RIGHT, false, false);
			myCustomImage3.setFacingFlip(FlxObject.LEFT, true, false);
			
			// flip and set x
			if (lastblockside == "right") { 
				myCustomImage3.facing = FlxObject.LEFT;
				lastblockside = "left"; 
				myCustomImage3.x = blockreverseoffset-50;
			} else { 
				myCustomImage3.facing = FlxObject.RIGHT;
				lastblockside = "right"; 
				myCustomImage3.x = blockoffset;
			}
			
			lastblock_y = y;
			
			blockgroup.add(myCustomImage3);
		}
		//scrollinggroup.add(myCustomImage3);
		//scrollinggroup.add(myCustomImage5);
		//scrollinggroup.add(myCustomImage4);
		
		//var nestgroup = new FlxSpriteGroup();
		//nestgroup.add(myCustomImage5);
		//nestgroup.setFacingFlip(FlxObject.RIGHT, false, false);
		//nestgroup.setFacingFlip(FlxObject.LEFT, true, false);
		//nestgroup.facing = FlxObject.LEFT;
		//scrollinggroup.add(nestgroup);
		
		add(scrollinggroup);
		
		
		
		
		
		
		plantgroup = new FlxGroup();
		plantcorners = new FlxGroup();
		plantedgesup = new FlxGroup();
		plantedgessides = new FlxGroup();
		plantgroup.add(plantcorners);
		plantgroup.add(plantedgesup);
		plantgroup.add(plantedgessides);
		add(plantgroup);
		
		var _slice:Array<Int> = [1, 1, 4, 4];
		var _slice2:Array<Int> = [1, 1, 26, 24];
		for (i in 0...numcorners) // create plant parts. connected in update
		{
			// create edge
			var edge1 = new FlxUI9SliceSprite(0, 0, "assets/stemup.png", new Rectangle(0, 0, 1, 25), _slice2, FlxUI9SliceSprite.TILE_BOTH);
			var edge2 = new FlxUI9SliceSprite(0, 0, "assets/stemsides.png", new Rectangle(0, 0, 1, 5), _slice, FlxUI9SliceSprite.TILE_BOTH);
			edge1.kill();
			edge2.kill();
			plantedgesup.add(edge1);
			plantedgessides.add(edge2);
			/*var stem = new FlxSprite(0, 0);
			stem.loadGraphic("assets/stem.png", true, 5, 5);
			stem.animation.frameIndex = 0;
			stem.setFacingFlip(FlxObject.RIGHT, true, false);
			stem.setFacingFlip(FlxObject.LEFT, false, false);
			stem.kill();
			plantedges.add(stem);*/
			
			// create corner
			var corner = new FlxSprite(0, 0);
			corner.loadGraphic("assets/stemcorner.png", true, 5, 5);
			corner.animation.frameIndex = 0;
			corner.setFacingFlip(FlxObject.RIGHT, true, false);
			corner.setFacingFlip(FlxObject.LEFT, false, false);
			corner.kill();
			plantcorners.add(corner);
		}
		
		// edge that follows the player
		follow_edge_up = new FlxUI9SliceSprite(0, bud_default_y, "assets/stemup.png", new Rectangle(0, 0, 27, 25), _slice2, FlxUI9SliceSprite.TILE_BOTH);
		//follow_edge_up.kill();
		//plantgroup.add(follow_edge_up);
		add(follow_edge_up);
		follow_edge_sides = new FlxUI9SliceSprite(0, 0, "assets/stemsides.png", new Rectangle(0, 0, 5, 5), _slice, FlxUI9SliceSprite.TILE_BOTH);
		follow_edge_sides.kill();
		//plantgroup.add(follow_edge_sides);
		add(follow_edge_sides);
		
		bud = new FlxSprite();
		//cameraFocus.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		//bud.makeGraphic(10, 10, FlxColor.RED);
		//bud.loadGraphic("assets/bud.png");
		bud.loadGraphic("assets/bud.png", true, 11, 11);
		bud.animation.frameIndex = 0;
		bud.setFacingFlip(FlxObject.RIGHT, true, false);
		bud.setFacingFlip(FlxObject.LEFT, false, false);
		bud.facing = FlxObject.LEFT;
		add(bud);
		bud.x = budmiddle_x;
        bud.y = bud_default_y;
		
		btn_replay = new FlxButton(0, 0, "", replay);
		btn_replay.loadGraphic("assets/replay.png", false, 60, 24);
		btn_replay.x = FlxG.width / 2 - btn_replay.width / 2;
		btn_replay.y = FlxG.height / 2 + 1;
		btn_replay.kill();
		add(btn_replay);
		
		 _txtScore = new FlxText(16, 2, 0, " ", 8);
         _txtScore.setBorderStyle(FlxText.BORDER_OUTLINE, FlxColor.BLACK, 1, 1);
		 add(_txtScore);
		 
		 white = new FlxSprite();
		//cameraFocus.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		white.makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		add(white);
		 
		 btn_start = new FlxButton(0, 0, "", start);
		btn_start.loadGraphic("assets/start4.png", false, 74, 31);
		btn_start.x = FlxG.width / 2 - btn_start.width / 2;
		btn_start.y = FlxG.height / 2 - btn_start.height / 2;
		add(btn_start);
		
		cursor = new FlxSprite(0, 0, "assets/cursor.png");
		cursor.x = FlxG.mouse.x;
		cursor.y = FlxG.mouse.y;
		//cursor.blend = BlendMode.INVERT;
		add(cursor);
		
		if (skipstart==true) {
			start();
		}
		
	}
	
	/**
	 * Function that is called when this state is destroyed - you might want to 
	 * consider setting all objects this state uses to null to help garbage collection.
	 */
	override public function destroy():Void
	{
		super.destroy();
	}

	/**
	 * Function that is called once every frame.
	 */
	override public function update():Void
	{
		currentTime = flash.Lib.getTimer ();
		delta = (currentTime - lastTimer) / 1000;
		delta = delta * 10;
		
		delta = FlxG.elapsed;
		
		super.update();
		
		
cursor.x = FlxG.mouse.x;
cursor.y = FlxG.mouse.y;
		
		_txtScore.text = Std.string(score);
         _txtScore.x = FlxG.width/2 - _txtScore.width/2;
		
		if (state == "menu") {
			
			
		}
		
		if (state == "lost") {
			
			_txtScore.text = Std.string("score: "+score);
			 _txtScore.x = FlxG.width / 2 - _txtScore.width / 2;
			  _txtScore.y = FlxG.height / 2 - _txtScore.height ;
		}
		
		if (state == "playing") {
			
		
		
		if (state != "lost") { speed += 2*FlxG.elapsed; }
		
		//scrollinggroup.y += speed*FlxG.elapsed;
		
		/*
		// Camera movement
		if (FlxG.keys.anyPressed(["DOWN", "S"])) {
			cameraFocus.y += CAMERA_SPEED*FlxG.elapsed;
		}
		if (FlxG.keys.anyPressed(["UP", "W"])) {
			cameraFocus.y -= CAMERA_SPEED*FlxG.elapsed;
		}
		if (FlxG.keys.anyPressed(["RIGHT", "D"])) {
			cameraFocus.x += CAMERA_SPEED*FlxG.elapsed;
		}
		if (FlxG.keys.anyPressed(["LEFT", "A"])) {
			cameraFocus.x -= CAMERA_SPEED*FlxG.elapsed;
		}*/
		
		//if (mostRecentlyRevivedCorner != null) {
			//mostRecentlyRevivedCorner.color = 0xff0000;
		//}
		
		if (budstate == "ready") {
			
			bud.animation.frameIndex = 0;
			bud.facing = FlxObject.LEFT;
			
			// follower edge
			follow_edge_up.x = bud.x + bud.width/2 - follow_edge_up.width/2;
			follow_edge_up.y = bud.y + bud.height;
			//follow_edge_up.x = 10;
			var height:Float = FlxG.height;
			if (mostRecentlyRevivedCorner != null) { height = mostRecentlyRevivedCorner.y - bud.y - bud.height + 2; }
			if (height <= 0) { height = 1; }
			follow_edge_up.resize(27, height);
			
			if (FlxG.keys.anyPressed(["RIGHT", "D"])) {
				
				if (bud.x != budright_x) { // check if already on that side
					//bud.x = budright_x;
					
					_sndMove.play();
					
					follow_edge_up.kill();
					
					// put corner
					var corner = cast(plantcorners.getFirstAvailable(), FlxSprite);
					corner.animation.frameIndex = 0;
					corner.x = bud.x + bud.width/2 - corner.width/2;
					corner.y = bud.y;
					corner.facing = FlxObject.RIGHT;
					corner.revive();
					
					// put edge
					var edge = cast(plantedgesup.getFirstAvailable(), FlxUI9SliceSprite);
					edge.y = corner.y + corner.height;
					//edge.x = corner.x ;
					
					
					var height:Float = FlxG.height;
					if (mostRecentlyRevivedCorner != null) { height = mostRecentlyRevivedCorner.y - corner.y - corner.height+1; }
					if (height <= 0) { height = FlxG.height; }
					edge.resize(27, height);
					
					edge.x = corner.x + corner.width / 2 - edge.width / 2;
					if (bud.x == budmiddle_x) {
						//edge.x = bud.x + bud.width / 2 - edge.width / 2;
						edge.x = budmiddle_x + bud.width / 2 - edge.width/2;
					}
					//if (corner.facing == FlxObject.RIGHT) {
					//	edge.x = corner.x + corner.width;
						//edge.resize(mostRecentlyRevivedCorner.x - corner.x - corner.width, 5);
					//} else {
					//	edge.x = mostRecentlyRevivedCorner.x + mostRecentlyRevivedCorner.width;
						//edge.resize(corner.x - mostRecentlyRevivedCorner.x - corner.width, 5);
					//}
					edge.revive();
					
					follow_edge_sides.visible = false;
					follow_edge_up.visible = false;
					follow_edge_sides.revive();
					
					tween = FlxTween.tween(bud, { x:budright_x }, speed/1000, {complete:budtweendone}); // tween speed should depend on scroll speed (speed/1000)
					budstate = "tweening";
					
					mostRecentlyRevivedCorner = corner;
				}
				
			}
			if (FlxG.keys.anyPressed(["LEFT", "A"])) {
				
				if (bud.x != budleft_x) { 
					//bud.x = budleft_x;
					
					_sndMove.play();
					
					follow_edge_up.kill();
					
					// put corner
					var corner = cast(plantcorners.getFirstAvailable(), FlxSprite);
					corner.animation.frameIndex = 0;
					corner.x = bud.x + bud.width/2 - corner.width/2;
					corner.y = bud.y;
					corner.facing = FlxObject.LEFT;
					corner.revive();
					
					// put edge
					var edge = cast(plantedgesup.getFirstAvailable(), FlxUI9SliceSprite);
					edge.y = corner.y + corner.height;
					//edge.x = corner.x;
					
					if (bud.x == budmiddle_x) {
						//edge.x = bud.x + bud.width / 2 - edge.width / 2;
						//edge.x = 0;
					}
					var height:Float = FlxG.height;
					if (mostRecentlyRevivedCorner != null) { height = mostRecentlyRevivedCorner.y - corner.y - corner.height+1; }
					if (height <= 0) { height = FlxG.height; }
					edge.resize(27, height);
					
					edge.x = corner.x + corner.width / 2 - edge.width / 2;
					if (bud.x == budmiddle_x) {
						//edge.x = bud.x + bud.width / 2 - edge.width / 2;
						edge.x = budmiddle_x + bud.width / 2 - edge.width/2;
					}
					
					edge.revive();
					
					follow_edge_sides.visible = false;
					follow_edge_up.visible = false;
					follow_edge_sides.revive();
					
					tween = FlxTween.tween(bud, { x:budleft_x }, speed/1000, {complete:budtweendone});
					budstate = "tweening";
					
					mostRecentlyRevivedCorner = corner;
				}
			}
			
			
			
		} else if (budstate == "tweening") { // scroll down if tweening
			
			
			score += Math.floor((speed-80)/10);
			
			// move horizontal follower edge
			follow_edge_sides.y = mostRecentlyRevivedCorner.y;
			follow_edge_sides.y += speed * delta; // nudge it 
			if (mostRecentlyRevivedCorner.facing == FlxObject.RIGHT) {
				follow_edge_sides.x = mostRecentlyRevivedCorner.x + mostRecentlyRevivedCorner.width;
				//follow_edge_sides.resize(bud.x - mostRecentlyRevivedCorner.x - mostRecentlyRevivedCorner.width, 5);
				var width = bud.x - follow_edge_sides.x;
				if (width <= 0) { width = 1; }
				follow_edge_sides.resize( width , 5 );
				bud.animation.frameIndex = 1;
				bud.facing = FlxObject.RIGHT;
			} else {
				follow_edge_sides.x = bud.x + bud.width;
				//follow_edge_sides.resize(follow_edge_sides.x - (mostRecentlyRevivedCorner.x + mostRecentlyRevivedCorner.width) , 5);
				var width = mostRecentlyRevivedCorner.x - follow_edge_sides.x +1;
				if (width <= 0) { width = 1; }
				follow_edge_sides.resize( width , 5 );
				bud.animation.frameIndex = 1;
				bud.facing = FlxObject.LEFT;
			}
			follow_edge_sides.visible = true;
			/*follow_edge_sides.y = mostRecentlyRevivedCorner.y;
			follow_edge_sides.y += speed * delta; // nudge it 
			if (mostRecentlyRevivedCorner.facing == FlxObject.RIGHT) {
				follow_edge_sides.x = mostRecentlyRevivedCorner.x + mostRecentlyRevivedCorner.width;
				follow_edge_sides.resize(bud.x - mostRecentlyRevivedCorner.x - mostRecentlyRevivedCorner.width, 5);
			} else {
				follow_edge_sides.x = bud.x + bud.width;
				follow_edge_sides.resize(follow_edge_sides.x - (mostRecentlyRevivedCorner.x + mostRecentlyRevivedCorner.width) , 5);
			}
			follow_edge_sides.visible = true;*/
			
			//bud.y += (speed * delta)/2;
			bud.y += speed * delta;
			
		} else if (budstate == "catching up") {
			
			follow_edge_up.x = bud.x + bud.width/2 - follow_edge_up.width/2;
			follow_edge_up.y = bud.y + bud.height;
			//follow_edge_up.x = 10;
			var height:Float = FlxG.height;
			if (mostRecentlyRevivedCorner != null) { height = mostRecentlyRevivedCorner.y - bud.y - bud.height + 2; }
			if (height <= 0) { height = 1; }
			//follow_edge_up.resize(5, height);
			follow_edge_up.resize(27, 1);
			follow_edge_up.visible = true;
			
			
		}
		
		lastblock_y += speed*delta;
		for (i in 0...numblocks) 
		{
			var a = cast(blockgroup.members[i], FlxUI9SliceSprite);
			
			if (a.y > FlxG.height)
			{
				renewblock(a);
			}
			//a.resize(50, FlxRandom.floatRanged(minblockheight, maxblockheight));
			
			a.y += speed*delta;
		}
		
		// move plant corners
		plantcorners.forEachAlive(function(element) { 
			var corner = cast(element, FlxSprite);
			corner.y += speed * delta;
			if (corner.y > FlxG.height)
			{
				corner.kill();
			}
		});
		// move plant edges
		plantedgesup.forEachAlive(function(element) { 
			var edge = cast(element, FlxUI9SliceSprite);
			edge.y += speed * delta;
			if (edge.y > FlxG.height)
			{
				edge.kill();
			}
		});
		plantedgessides.forEachAlive(function(element) { 
			var edge = cast(element, FlxUI9SliceSprite);
			edge.y += speed * delta;
			if (edge.y > FlxG.height)
			{
				edge.kill();
			}
		});
		
		//FlxG.collide(cameraFocus, tileMap);
		//FlxG.collide(bud, blockgroup);
		if (state != "lost") { FlxG.overlap(bud, blockgroup, lose); }
		
		}
		
		lastTimer = currentTime;
	}	
	
	private function start():Void {
		//FlxG.camera.shake(0.004, 1.5);
		 
		//(function() { white.kill(); } );
		FlxSpriteUtil.fadeOut(white,0.3,false,function(tween:FlxTween) { white.kill(); });
		btn_start.kill();
		//FlxG.mouse.visible = false;
		cursor.kill();
		state = "playing";
	}
	
	private function lose(Object1:FlxObject, Object2:FlxObject):Void {
		_sndLose.play();
		if (tween != null && tween.active == true) {tween.cancel();}
		FlxG.camera.flash(0xFFFFFFFF, 0.15);
		FlxG.camera.shake((2 ^ Math.floor(speed)) / 10000, 0.15);
		//FlxG.mouse.visible = true;
		cursor.revive();
		state = "lost";
		speed = 0;
		btn_replay.revive();
		
		
		
       // _txtScore.kill();
	}
	
	private function replay():Void {
		//speed = basespeed;
		//state = "playing";
		skipstart = true;
		FlxG.camera.fade(FlxColor.WHITE,.33, false,function() {
			FlxG.switchState(new MenuState());
		});
	}
	
	private function renewblock(block:FlxUI9SliceSprite):Void {
		var height = FlxRandom.floatRanged(minblockheight, maxblockheight); // randomize height
		var y = lastblock_y - height - gapsize;
		// create block
		//var myCustomImage3 = new FlxUI9SliceSprite(0, y, "assets/tiles3_3.png", new Rectangle(0, 0, 50, height), _slice, FlxUI9SliceSprite.TILE_BOTH);
		//myCustomImage3.setFacingFlip(FlxObject.RIGHT, false, false);
		//myCustomImage3.setFacingFlip(FlxObject.LEFT, true, false);
		block.resize(50, height);
		block.y = y;
		
		// flip and set x
		if (lastblockside == "right") { 
			block.facing = FlxObject.LEFT;
			lastblockside = "left"; 
			block.x = blockreverseoffset-50;
		} else { 
			block.facing = FlxObject.RIGHT;
			lastblockside = "right"; 
			block.x = blockoffset;
		}
		
		lastblock_y = y;
	}
	
	
	private function budtweendone(tween:FlxTween):Void {
		budstate = "catching up";
		
		FlxTween.tween(bud, { y:bud_default_y }, speed/2500, {complete:catchingupdone}); 
	
		follow_edge_up.revive();
		follow_edge_up.visible = false;
		
		follow_edge_sides.visible = false;
		follow_edge_sides.kill();
		
		// put corner
		var corner = cast(plantcorners.getFirstAvailable(), FlxSprite);
		corner.x = bud.x + bud.width/2 - corner.width/2;
		corner.y = mostRecentlyRevivedCorner.y;
		//corner.scale.y *= -1;
		if (bud.x==budleft_x) {
			corner.facing = FlxObject.RIGHT;
		} else {
			corner.facing = FlxObject.LEFT;
		}
		//corner.angle = 90;
		//corner.angle = Math.PI*0.5;
		//corner.antialiasing = false;
		//corner.loadGraphic("asset/stemcornerup.png");
		corner.animation.frameIndex = 1;
		corner.revive();
		
		// put edge
		var edge = cast(plantedgessides.getFirstAvailable(), FlxUI9SliceSprite);
		edge.y = corner.y;
		if (corner.facing == FlxObject.RIGHT) {
			edge.x = corner.x + corner.width;
			edge.resize(mostRecentlyRevivedCorner.x - corner.x - corner.width, 5);
		} else {
			edge.x = mostRecentlyRevivedCorner.x + mostRecentlyRevivedCorner.width;
			edge.resize(corner.x - mostRecentlyRevivedCorner.x - corner.width, 5);
		}
		//edge.resize(mostRecentlyRevivedCorner.x - corner.x, 5);
		//edge.resize(10, 5);
		edge.revive();
		/*var edge = cast(plantedges.getFirstAvailable(), FlxSprite);
		edge.y = mostRecentlyRevivedCorner.y;
		edge.x = mostRecentlyRevivedCorner.x;
		//edge.width = mostRecentlyRevivedCorner.x - corner.x;
		corner.antialiasing = false;
		edge.animation.frameIndex = 1;
		edge.revive();
		//edge.scale.set(2, 1);
		//edge.updateHitbox();*/
		
		mostRecentlyRevivedCorner = corner;
	}
	private function catchingupdone(tween:FlxTween):Void {
		budstate = "ready";
	}
}