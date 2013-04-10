/**
 * @name AS3 Flash Video Player
 *
 * @author Adriaan Balt Louis Scholvinck
 * @version March 2008
 * @description Demo of how to use the video player
 */

package com.balt.media.video {
	
	import flash.display.MovieClip;
	import flash.text.Font;
	import flash.text.FontType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import com.gs.TweenLite;
	
	
	public class FLVPlayerDemo extends FLVPlayer {
		
		private var animatedCuepoints : Array;
		private var currentindex : int = -1;
		
		public function FLVPlayerDemo( $parent : MovieClip, $path : String = "", $videoPath : String = ""){
			super( $parent, $path, $videoPath );
		}
		
		protected override function xmlComplete() : void {
//			loadFont();
			
			animatedCuepoints = new Array();
			
			var xmlSTRING : XML;
			var tweenObj : Object;
			var tweens_arr : Array;
			var container : MovieClip;
			
			for ( var i : int = 0; i < xmlDATA.strings.string.length(); i++ ){
				xmlSTRING = xmlDATA.strings.string[i];
				container = createContainer( xmlSTRING.value.toString(), xmlSTRING.fontsize.toString() ); 
				p.addChild( container );
				tweens_arr = new Array();
				for ( var j : int = 0; j < xmlSTRING.tween.length(); j++ ){
					tweenObj = new Object;
					tweenObj = {container : container,
								cuepoint : xmlSTRING.tween[j].@cuepoint,
								props : xmlSTRING.tween[j].@props,
								endVals : xmlSTRING.tween[j].@endVals,
								duration : xmlSTRING.tween[j].@duration,
								func : xmlSTRING.tween[j].@func,
								delay : xmlSTRING.tween[j].@delay};
					tweens_arr[i] = tweenObj;
					
					var cuepointID : Number = xmlSTRING.tween[j].@cuepoint;
					var arr : Array = animatedCuepoints[ cuepointID ];
					
					if ( !arr ) {
						arr = new Array();
						animatedCuepoints[ cuepointID ] = arr;
					}
					arr.push( tweenObj );
				}
			}
//			currentindex = super.getCuePointIndex(cuepoints, true, ns.time);
			updateCuepoint();
		}
		
		private function createContainer( $str : String = "", $size : Number = undefined ) : MovieClip {
			// we can return a tf or mc or somehting else
			
			var tMC : MovieClip = new MovieClip();
			p.addChild( tMC );
			
			var tf : TextField = new TextField();
			setText ( tf, $str, $size );
			tMC.addChild( tf );
			
			tMC.visible = false;
			tMC.alpha = 0;
			
			return tMC;
		}

		
		private function setText ( tf:TextField, str:String, size : Number = 20 ) : void {
			var font:Font = getAvailableFont ( new Array("Helvetica") , false, str );
			var format:TextFormat = new TextFormat();
			if ( font != null ) {
				format.font = "Helvetica";
				tf.embedFonts = true;
		   	} else {
				format.font = "_sans";
			   	tf.embedFonts = false;
		   	}
		   	format.color = 0xFFFFFF;
			format.size = size;
		   	tf.autoSize = TextFieldAutoSize.LEFT;
		   	tf.multiline = true;
		  // 	tf.wordWrap = true;
		   	tf.selectable = false;
			tf.defaultTextFormat = format;
			tf.htmlText = str;
		}
		
		private function getAvailableFont(p_fonts:Array, p_onlySystemFonts:Boolean=false, p_txt:String = null) : Font {
			var availableFonts:Array = Font.enumerateFonts(true);
			var fonts:Array = p_fonts;
			var font:Font;
			for (var i:int=0; i<fonts.length; i++) {
				var fontName:String = fonts[i];
				for(var j:int=0; j<availableFonts.length; j++) {
					font = availableFonts[j];
					
					if( !p_onlySystemFonts || font.fontType == FontType.DEVICE ) {
						if(font.fontName == fontName) {
							// change for China issues 
							if ( p_txt != null ) {
								if (  font.hasGlyphs( stripLowCharacters( p_txt ) ) ) {
									return font;
								}
							} else {
								return font;
							}
						}
					}
				}
			}
			return null;
		}
		
		private function stripLowCharacters( p_text: String ): String {
			if( p_text == null ) {
				return "";
			}
			
			var start: int = p_text.length - 1;
			for( var i: int = start; i >=0; i-- ) {
				if( p_text.charCodeAt( i ) < 32  ) {
					p_text = p_text.split( p_text.charAt( i ) ).join( " " );
				}
			}
			
			return p_text;
		}		
	
		protected override function updateCuepoint( $dataObj : Object = null ):void{
            var index : int = super.getCuePointIndex(cuepoints, true, ns.time);
			var tweens_arr : Array = animatedCuepoints[index] != null ? animatedCuepoints[index] : new Array();
			var previousTweens : Array;
			var tweenObj : Object;
			var i : int;
			if ( currentindex != index ) {
				// clears cues that are up
				for ( i = 0; i < index-1; i++ ) {
					previousTweens = animatedCuepoints[i];
					for ( var j :int = 0; j < previousTweens.length; j++ ){
						tweenObj = previousTweens[j];
						buildTween (tweenObj.container, 
									"alpha", 
									"0", 
									.5, 
									tweenObj.func,
									"0"); 
					}
				}
				
				currentindex = index;
				// run tween of the twene object that accounts
				for ( i = 0; i < tweens_arr.length; i++ ){
					tweenObj = tweens_arr[i];
					buildTween (tweenObj.container, 
								tweenObj.props, 
								tweenObj.endVals, 
								tweenObj.duration, 
								tweenObj.func,
								tweenObj.delay); 
				}
			}
		}

		private function buildTween( target:MovieClip, properties:String, endVals:String, duration:Number, func:String, delay:String ):void {
			//trace ( "buildTween target: " + target.name );
			var props_arr : Array = properties.split( "," );
			var endVals_arr : Array = endVals.split( "," );
			
			var obj : Object = new Object();
			obj.ease = func;
			for ( var i : int = 0; i < props_arr.length; i++ ){
				obj[props_arr[i]] = Number( endVals_arr[i] );
				//trace ( props_arr[i] + " __ " + endVals_arr[i]  );
			}
			target.visible = true;
			TweenLite.to(target, duration, obj );
		}

	}
}

