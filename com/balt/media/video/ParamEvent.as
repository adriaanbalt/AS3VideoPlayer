/**
 * @name Param Event
 *
 * @author Adriaan Balt Louis Scholvinck
 * @version March 2008
 * @description Helper for event delegation
 */

package com.balt.media.video {

	import flash.events.Event;

	public class ParamEvent extends Event
	{
		/*
		variables

		*/
		public var params:Object;
		/*
		Constructor
		*/
		
		/**
		 * Base event which all custom events must extend in order to have output functionality and be able to carry parameters onto listeners

		 * @param $type : the constant event 
		 * @param $params : an object containing any number of values to be sent to listeneers
		 * @return : a reference ot the event
		 * 
		 */		
		public function ParamEvent($type:String, $params:Object = null)

		{
			super($type, true, true);
			this.params = $params
		}
		
		/**
		 * Overrides the flash.events.Event's clone method
		 * @return Event
		 * 
		 */		
		public override function clone():Event

		{
			return new ParamEvent(this.type, this.params);
		}
		
	}

}

