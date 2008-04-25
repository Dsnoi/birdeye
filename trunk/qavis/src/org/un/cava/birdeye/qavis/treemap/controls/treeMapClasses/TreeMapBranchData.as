////////////////////////////////////////////////////////////////////////////////
//
//  Copyright (c) 2008 Josh Tynjala
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to 
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//
////////////////////////////////////////////////////////////////////////////////

package org.un.cava.birdeye.qavis.treemap.controls.treeMapClasses
{
	import org.un.cava.birdeye.qavis.treemap.controls.TreeMap;

	/**
	 * The data passed to drop-in TreeMap branch renderers.
	 * 
	 * @author Josh Tynjala
	 * @see org.un.cava.birdeye.qavis.treemap.controls.TreeMap
	 */
	public class TreeMapBranchData extends BaseTreeMapData
	{
		
	//--------------------------------------
	//  Constructor
	//--------------------------------------
	
		public function TreeMapBranchData(owner:TreeMap)
		{
			super(owner);
		}
		
	//--------------------------------------
	//  Properties
	//--------------------------------------
		
		protected var items:Array = [];
		
		public function get itemCount():int
		{
			return this.items.length;
		}
		
		private var _showLabel:Boolean = true;
		
		public function get showLabel():Boolean
		{
			return this._showLabel;
		}
		
		public function set showLabel(value:Boolean):void
		{
			this._showLabel = value;
		}
		
		private var _layoutStrategy:ITreeMapLayoutStrategy;
		
		public function get layoutStrategy():ITreeMapLayoutStrategy
		{
			return this._layoutStrategy;
		}
		
		public function set layoutStrategy(value:ITreeMapLayoutStrategy):void
		{
			this._layoutStrategy = value;
		}
		
		private var _closed:Boolean = false;
		
		public function get closed():Boolean
		{
			return this._closed;
		}
		
		public function set closed(value:Boolean):void
		{
			this._closed = value;
		}
		
		private var _zoomed:Boolean = false;
		
		public function get zoomed():Boolean
		{
			return this._zoomed;
		}
		
		public function set zoomed(value:Boolean):void
		{
			this._zoomed = value;
		}
		
	//--------------------------------------
	//  Public Methods
	//--------------------------------------
	
		public function getItemAt(index:int):TreeMapItemLayoutData
		{
			return this.items[index];
		}
	
		public function addItem(item:TreeMapItemLayoutData):void
		{
			this.items.push(item);
		}
	
		public function addItemAt(item:TreeMapItemLayoutData, index:int):void
		{
			this.items.splice(index, 0, item);
		}
	
		public function removeItem(item:TreeMapItemLayoutData):void
		{
			var index:int = this.items.indexOf(item);
			if(index >= 0)
			{
				this.items.splice(index, 1);
			}
		}
	
		public function removeItemAt(index:int):void
		{
			this.items.splice(index, 1);
		}
		
		public function removeAllItems():void
		{
			this.items = [];
		}
		
		public function itemsToArray():Array
		{
			return this.items.concat();
		}
		
	}
}