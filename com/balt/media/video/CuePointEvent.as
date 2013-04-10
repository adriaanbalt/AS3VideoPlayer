/**
 * @name AS3 Flash Video Player
 *
 * @author Adriaan Balt Louis Scholvinck
 * @version March 2008
 * @super com.balt.media.video.ParamEvent
 * @description cuepoint delegation event
 */



package com.balt.media.video {

	import com.balt.media.video.ParamEvent;
	/*
	Class
	*/
	public class CuePointEvent extends ParamEvent
	{
		/*
		Event variable declarations
		*/
		public static const CUE_POINT:String = "CuePointEvent.onCuePoint";

		public static const CUE_POINT_ADDED:String = "CuePointEvent.onAddCuePoint";
		public static const CUE_POINT_REMOVED:String = "CuePointEvent.onRemoveCuePoint";
		public static const ALL_CUE_POINTS_REMOVED:String = "CuePointEvent.onRemoveAllCuePoint";

		public static const CUE_POINT_MOVED:String = "CuePointEvent.onMoveCuePoint";
		/*
		Constructor
		*/
		
		/**
		 * CuePointEvent custom event class
		 * @param evt : any of the CuePointEvent static constan event variables

		 * @param params : an object containing data to be passed on to listeners
		 * 
		 */		
		public function CuePointEvent(evt:String, params:Object)
		{
			super(evt, params);
		}
	}
}
