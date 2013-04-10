/**
 * @name AS3 Flash Video Player
 *
 * @author Adriaan Balt Louis Scholvinck
 * @version March 2008
 * @description Interface for the FLVPlayer
 */

 package com.balt.media.video {
	import flash.display.DisplayObject;
	import flash.media.Video;	

	public interface IFLVPlayer
	{
		function playMovie( $url : String ) : void;
		function player() : Video;
		function VOLUME(newVolume:Number) : void;
		function TOGGLEPAUSE() : void;
		function STOP() : void;
		function destroy() :void;
	}
}