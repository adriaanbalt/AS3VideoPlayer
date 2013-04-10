/**
 * @name AS3 Flash Video Player
 *
 * @author Adriaan Balt Louis Scholvinck
 * @version March 2008
 * @description Meet of the video operations.  Handles custom cuepoints.
 */

 package com.balt.media.video {
	import com.balt.log.Log;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.Timer;

	public class FLVPlayer extends Sprite implements IFLVPlayer {
		
		public static var EVENT_ON_START : String = "onStart";
		public static var EVENT_ON_STOP : String = "onStop";
		public static var EVENT_ON_CUEPOINT : String = "onCuepoint";
		
		protected static const DEFAULT_VOLUME	:Number = .8;
		
		protected var flv_file_path : String;
		
		public var barWidth:int = 543;		
		protected var startPoint:int; // start point to pointer of scrubber
		
		protected var videowidth : int;
		protected var videoheight : int;
		
		protected var cuepointXML : XMLList;
		protected var cuepoints : Array;
		private var currentCuepoint : Object;
	    private var searchTolerance :int = 50;
	    
		protected var ns:NetStream;
		private var netStatusCache:String;
		
		protected var volumeTransform : SoundTransform;
		public var vplayer:Video;		
		protected var meta:Object;
		private var progress:int;
		private var bufferFlush:Boolean = false;
		private var invalidTime:Boolean = false;
		protected var seeking:Boolean = false;
		
		protected var loop : Boolean = false;
		protected var autoStart : Boolean = true;
		protected var videoPaused : Boolean = false;
	
		protected var progressBarTimer:Timer = new Timer(250);
		protected var playingBarTimer:Timer = new Timer(250);
		
		private var _videoWidth:Number = 400;
		private var _videoHeight:Number = 300;
			
		public function FLVPlayer( w : int, h : int ){
			videowidth  = w;
			videoheight = h;
		}
		
		public function setup( path : String = "", autoStart : Boolean = false, loop : Boolean = false, cuepointXML : XMLList = null ) : void {
			this.loop = loop;
			this.autoStart = autoStart;
			this.cuepointXML = cuepointXML != null ? cuepointXML : null;
			
			
			var connection:NetConnection = new NetConnection();
            connection.connect(null);
			ns = new NetStream(connection);
			ns.bufferTime = 3; // buffer time 5 sec.
			ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusEvent);	
			
			if (cuepointXML.length() > 0 ) {
				cuepointManagement();
			}
			
			volumeTransform = new SoundTransform();
			VOLUME( FLVPlayer.DEFAULT_VOLUME );

			initialize( path );
		}

// PUBLIC 

		public function stageResize(evt:Event) : void {
			
		    var widthRatio:Number = stage.stageWidth / _videoWidth;
		    var heightRatio:Number = ( stage.stageHeight ) / _videoHeight

		    var curScale : Number = 1;
		    var newScale : Number = curScale;
		    
		    if ( heightRatio >= 1 && widthRatio >= 1 ) {
				if ( heightRatio < widthRatio ) {
					newScale = ( curScale * heightRatio );	
				} else {
					newScale = ( curScale * widthRatio );
				}
		    } else if ( heightRatio > 1 && widthRatio < 1 ) {
				newScale = ( curScale * widthRatio );	
			} else if ( heightRatio < 1 && widthRatio > 1 ){
				newScale = ( curScale * heightRatio );
			} else if ( heightRatio < 1 && widthRatio < 1 ){
				if ( heightRatio < widthRatio ) {
					newScale = ( curScale * heightRatio );	
				} else {
					newScale = ( curScale * widthRatio );
				}
			}
			
			this.scaleY = this.scaleX = newScale;
			
			// position the player to center in it's region
			// Removed by Adriaan on 12/01/09 - why?
			//var xPos : int = (( stage.stageWidth - this.width ) / 2 ) < 0 ? 0 : (( stage.stageWidth - this.width ) / 2 ); 
			//var yPos : int = (( stage.stageHeight - this.height ) / 2 ) < 0 ? 0 : (( stage.stageHeight - this.height ) / 2 ); 
			//this.x = xPos;
			//this.y = yPos;

			
		}
		
		public function playMovie( url : String ) : void {
			initialize(url);
		}

		private function initialize( url : String = "" ) : void {
			flv_file_path = url;

			if ( vplayer == null ) vplayer = new Video();	
			vplayer.smoothing = true;			
			vplayer.width = videowidth;
			vplayer.height = videoheight;
			
			var customclient:Object = new Object();
			customclient.onMetaData = metaDataHandler;
			customclient.onCuePoint = cuePointHandler;
			ns.client = customclient;
			
			vplayer.attachNetStream(ns);
			ns.addEventListener(IOErrorEvent.IO_ERROR, flvLoadError);
			ns.addEventListener(NetStatusEvent.NET_STATUS, flvNetStatus);
			
			ns.play( flv_file_path ); // *** play FLV file
			this.addChild(vplayer);
			
			configControls();
		
			// PROGRESS
			progressBarTimer.addEventListener(TimerEvent.TIMER, progressBarTimerEvent);			
			progressBarTimer.start();
		}
		
		protected function flvLoadError (evt:IOErrorEvent):void {
			Log.traceMsg ("Video url flvLoadError: " + evt.text, Log.ERROR);	
		}
		
		protected function flvNetStatus (evt:NetStatusEvent):void {
			//trace ("Video net status " + evt.toString());
			if (evt.info.level == "error") {
				Log.traceMsg ("Video flvNetStatus error: " + this.flv_file_path + ": " + 
								evt.info.level + ": " + evt.info.code, Log.ERROR);
			}	
		}
		
		protected function configControls() : void {
			// override
		}
		
		public function player():Video {
			return vplayer;
		}
		
		public function VOLUME(newVolume:Number):void{
			volumeTransform.volume = newVolume;
			ns.soundTransform = volumeTransform;
		}
		public function TOGGLEPAUSE():void {
			if(invalidTime){
				ns.seek(0); 
				checkPlayhead();
				invalidTime = false;
			}
			ns.togglePause();
		}
		public function PAUSE():void {
			ns.pause();
		}
		public function RESUME():void {
			playingBarTimer.start();
			ns.resume();
		}
		public function STOP():void {
			if ( loop == false ) {
				// don't loop, we pause
				ns.pause(); 
			}
			ns.seek(0);
			
			//playingBarTimer.stop();
			progressBarTimer.stop();
			
			playingBarTimerEvent();
			
			checkPlayhead();
			
			dispatchEvent( new Event( EVENT_ON_STOP, true ));
		}
		
		public function START():void {
			playingBarTimer.start();
			dispatchEvent( new Event( EVENT_ON_START, true ));
			checkPlayhead();
		}
		
		public function SEEK( time : int ) : void {
			ns.seek( time );
		}
	
		public function destroy():void{
			//this._visible = false;
			if ( ns != null ) ns.close();
			if ( vplayer != null ) vplayer.clear();
			if ( playingBarTimer != null ) {
				playingBarTimer.stop();
				playingBarTimer.removeEventListener(TimerEvent.TIMER, playingBarTimerEvent );
			}
			if ( progressBarTimer != null ) progressBarTimer.stop();
			
			if (ns.hasEventListener(IOErrorEvent.IO_ERROR)) {
				ns.removeEventListener(IOErrorEvent.IO_ERROR, flvLoadError);
			}
			if (ns.hasEventListener(NetStatusEvent.NET_STATUS)) {
				ns.removeEventListener(NetStatusEvent.NET_STATUS, flvNetStatus);
			}
			
		}
		
// PRIVATE

		private function netStatusEvent(evt:NetStatusEvent):void {		
			if(netStatusCache != evt.info.code){
				switch (evt.info.code) {
					case "NetStream.Play.Start" :
						START();
						break;
					case "NetStream.Buffer.Empty" :
						break;
					case "NetStream.Buffer.Full" :
						break;
					case "NetStream.Buffer.Flush" :
						bufferFlush = true;
						break;
					case "NetStream.Seek.Notify" :
						invalidTime = false;				
						break;
					case "NetStream.Seek.InvalidTime" :
						bufferFlush = false;
						invalidTime = true;						
						break;
					case "NetStream.Play.Stop" :
						if(bufferFlush) STOP();			
					break;
				}
				netStatusCache = evt.info.code;
			}
		}
		
		private function metaDataHandler(data:Object):void {
			meta = data;
			playingBarTimer.addEventListener(TimerEvent.TIMER, playingBarTimerEvent);
			metaDataControls();
		}
		
		protected function metaDataControls() : void {
			// override
		}

		protected function progressBarTimerEvent( evt:TimerEvent = null):void {
			progress = (( ns.bytesLoaded / ns.bytesTotal * 100 ) >> 0);
			if(progress >= 100){
				progressBarTimer.stop();
			}
		}
		
		protected function playingBarTimerEvent(evt:TimerEvent = null):void {
			if (meta.duration && ns.time) {
				var percent:int = int( (ns.time / meta.duration * barWidth).toFixed(2) );
				checkPlayhead();
			}
		}
		
		private function cuepointManagement():void{
			setupCuepoints();
			cuepoints = new Array();
			var cuepoint:Object;
			for ( var i : uint = 0; i < cuepointXML.cuepoint.length(); i++ ){
				cuepoint = new Object();
				cuepoint = {	name: cuepointXML.cuepoint[i].name.toString(),
								data: cuepointXML.cuepoint[i].data.toString(),
								time: cuepointXML.cuepoint[i].time.toString()
								};
				cuepoints.push( cuepoint );
			}
		}
		
		protected function checkPlayhead():void{
			if (cuepointXML.length() > 0 ) {
	            var index : int = getCuePointIndex(cuepoints, true, ns.time);
				var nextCuepoint : Object = cuepoints[index];
				if ( nextCuepoint != currentCuepoint ) {
					currentCuepoint = nextCuepoint;
					updateCuepoint( nextCuepoint );
				}
			}
		}
		
	    protected function getCuePointIndex( cuePointArray :Array, closeIsOK :Boolean,
		                                   time :int, name :String = null,
		                                   start :int = 0, len :int = 0) :int {
	        // sanity checks
	        if (cuePointArray == null || cuePointArray.length < 1) {
	            return -1;
	        }
	        var timeUndefined :Boolean = (isNaN(time) || time < 0);
	        var nameUndefined :Boolean = (name == null);
	        if (timeUndefined && nameUndefined) {
	        	// throw error
	        }
	
	        if (len == 0) len = cuePointArray.length;
	
	        // name is passed in and time is undefined or closeIsOK is
	        // true, search for first name starting at either start
	        // parameter index or index at or after passed in time, respectively
	        if (!nameUndefined && (closeIsOK || timeUndefined)) {
	            var firstIndex :int;
	            var index :int;
	            if (timeUndefined) {
	                firstIndex = start;
	            } else {
	                firstIndex = getCuePointIndex(cuePointArray, closeIsOK, time);
	            }
	            for (index = firstIndex;index >= start; index--) {
	                if (cuePointArray[index].name == name) break;
	            }
	            if (index >= start) return index;
	            for (index = firstIndex + 1;index < len; index++) {
	                if (cuePointArray[index].name == name) break;
	            }
	            if (index < len) return index;
	            return -1;
	        }
	
	        var result :int;
	
	        // iteratively check if short length
	        if (len <= searchTolerance) {
	            var max :int = start + len;
	            for (var i :int = start;i < max; i++) {
	                result = cuePointCompare(time, name, cuePointArray[i]);
	                if (result == 0) return i;
	                if (result < 0) break;
	            }
	            if (closeIsOK) {
	                if (i > 0) return i - 1;
	                return 0;
	            }
	            return -1;
	        }
	
	        // split list and recurse
	        var halfLen :int = Math.floor(len / 2);
	        var checkIndex :int = start + halfLen;
	        result = cuePointCompare(time, name, cuePointArray[checkIndex]);
	        if (result < 0) {
	            return getCuePointIndex(cuePointArray, closeIsOK, time, name, start, halfLen);
	        }
	        if (result > 0) {
	            return getCuePointIndex(cuePointArray, closeIsOK, time, name, checkIndex + 1, halfLen - 1 + (len % 2));
	        }
	        return checkIndex;
	    }	
	    
	    private function cuePointCompare(time :int, name :String, cuePoint :Object) :int {
	        var compTime1 :int = Math.round(time * 1000);
	        var compTime2 :int = Math.round(cuePoint.time * 1000);
	        if (compTime1 < compTime2) return -1;
	        if (compTime1 > compTime2) return 1;
	        if (name != null) {
	            if (name == cuePoint.name) return 0;
	            if (name < cuePoint.name) return -1;
	            return 1;
	        }
	        return 0;
	    }
		
// FUNC ╠═════════════		 # SUBTITLE SUPPORT #		═════════════
		private function cuePointHandler(data:Object) : void {
			trace ( "cuepoint handler" + data.time + "name: " + data.name + " type= "  );
		}
		
		protected function updateCuepoint( dataObj : Object = null ):void{
			//overwriten
		}
		
		protected function setupCuepoints() : void {
			//overwriten
		}
		
		public function get videoWidth ():Number {
			return _videoWidth;
		}
		
		public function set videoWidth (value:Number):void {
			_videoWidth = value;
		}
		
		public function get videoHeight ():Number {
			return _videoHeight;
		}
		
		public function set videoHeight (value:Number):void {
			_videoHeight = value;
		}
		
	}
}