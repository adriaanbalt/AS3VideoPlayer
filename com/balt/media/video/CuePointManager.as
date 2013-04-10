/**
 * @name AS3 Flash Video Player
 *
 * @author Adriaan Balt Louis Scholvinck
 * @version March 2008
 * @description Cuepoint manager
 */

package com.balt.media.video
{
	import flash.events.EventDispatcher;
	// import mx.events.VideoEvent;	// Not supported in Flash
	import com.balt.media.video.CuePointEvent;

	public class CuePointManager extends EventDispatcher
	{
		private var vidPlayer:*;
		private var arrCuePoints:Array;
		private var lastFiredCuePoint:String;
		public static const PLAYHEAD_UPDATE : String = "playheadUpdate";  // Same name used in mx.events.VideoEvent
	
		/**
		 * Constructor
		 * @param flvPlayer : FLVPlayer component that now listens to dynamic cuepoints
		 * 
		 */		
		public function CuePointManager(flvPlayer:*):void
		{
			this.vidPlayer = flvPlayer;
			this.arrCuePoints = new Array();
			this.vidPlayer.addEventListener(PLAYHEAD_UPDATE, cuePointListener);
		}
		/*
		functions
		*/
		
		/**
		 * Adds a cue point.
		 * @param cuePntObj : an object with two mandatory values:
		 * 
		 * <ul>
		 * <li><b>time</b> : Number - time in seconds of where to place the cure point</li>
		 * <li><b>name</b> : String - a unique name for the cue point being added</li>
		 * </ul>
		 * 
		 */		
		public function addCuePoint(cuePntObj:Object, fireEvent:Boolean = true):void
		{
			// needs to add to an array
			// should be all
			cuePntObj.type = "actionscript";
			var cuePoint:Object = this.vidPlayer.addASCuePoint(cuePntObj);
			this.arrCuePoints.push(cuePoint.name);
			if (fireEvent) {
				this.dispatchEvent(new CuePointEvent(CuePointEvent.CUE_POINT_ADDED, {name:cuePoint.name}));
			}
		}
		
		/**
		 * Removes a cue point added using the addCuePoint method.
		 * @param cuePointName : String - name of the cue point to be removed
		 * 
		 */		
		public function removeCuePoint(cuePointName:String, fireEvent:Boolean = true):void
		{
			this.vidPlayer.removeASCuePoint(cuePointName);
			var arrTemp:Array = new Array();
			for (var a:uint = 0; a<this.arrCuePoints.length; a++) {
				if (this.arrCuePoints[a] != cuePointName) {
					arrTemp.push(arrCuePoints);
				}
			}
			this.arrCuePoints = arrTemp;
			if (fireEvent) {
				this.dispatchEvent(new CuePointEvent(CuePointEvent.CUE_POINT_REMOVED, {name:cuePointName}));
			}
		}
		
		/**
		 * Removes all cue points set with the addCuePoint method
		 * 
		 */		
		public function removeAllCuePoints():void
		{
			for(var a:uint = 0; a<this.arrCuePoints.length; a++) {
				this.removeCuePoint(this.arrCuePoints[a].name, false);
			}
			this.arrCuePoints = new Array();
			this.dispatchEvent(new CuePointEvent(CuePointEvent.ALL_CUE_POINTS_REMOVED, {}));
		}
		
		/**
		 * Moves a cue point already added with the addCuePoint method to a new time.
		 * @param cuePointName : String - name of the cue point to move
		 * @param newTime : Number - new time to move the cue point to
		 * 
		 */		
		public function moveCuePoint(cuePointName:String, newTime:Number):void
		{
			this.removeCuePoint(cuePointName, false);
			this.addCuePoint({name:cuePointName, time:newTime}, false);
			this.dispatchEvent(new CuePointEvent(CuePointEvent.CUE_POINT_MOVED, {name:cuePointName}));
		}
		
		/**
		 * Returns the next cue point.
		 * @return : cue point object
		 * 
		 */		
		public function getNextCuePoint():Object
		{
			var cuePointToReturn:Object = this.getCuePoint(this.lastFiredCuePoint).array[this.getCuePoint(this.lastFiredCuePoint).index+1];
			if (cuePointToReturn) {
				return cuePointToReturn;
			} else {
				return new Object();
			}
		}
		
		/**
		 * Returns the requested cuepoint
		 * @param cuePointName : String - name of the cue point object to return
		 * @return 
		 * 
		 */		
		public function getCuePoint(cuePointName:String):Object
		{
			return this.vidPlayer.findCuePoint(cuePointName);
		}
		
		
		// FIXME - what is datatype here?
		private function cuePointListener(evt:*):void
		{
			var objParams:Object = new Object();
			this.lastFiredCuePoint = evt.info.name
			objParams.time = this.vidPlayer.playheadTime;
	        objParams.name = evt.info.name;
	        objParams.type = evt.info.type;
			this.dispatchEvent(new CuePointEvent(CuePointEvent.CUE_POINT, objParams));
		}
		
	}
}