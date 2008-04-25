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

package org.un.cava.birdeye.qavis.treemap.controls
{
	import org.un.cava.birdeye.qavis.treemap.controls.treeMapClasses.*;
	import org.un.cava.birdeye.qavis.treemap.events.TreeMapEvent;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	import flash.xml.XMLNode;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ICollectionView;
	import mx.collections.IViewCursor;
	import mx.collections.XMLListCollection;
	import mx.controls.treeClasses.DefaultDataDescriptor;
	import mx.controls.treeClasses.ITreeDataDescriptor;
	import mx.core.ClassFactory;
	import mx.core.IFactory;
	import mx.core.UIComponent;
	import mx.events.CollectionEvent;
	import mx.events.FlexEvent;
	import mx.utils.UIDUtil;

	//--------------------------------------
	//  Events
	//--------------------------------------
	
	/**
	 * Dispatched when the <code>selectedIndex</code> or <code>selectedItem</code> property
	 * changes as a result of user interaction.
	 *
	 * @eventType flash.events.event.CHANGE
	 */
	[Event(name="change", type="flash.events.Event")]
	
	/**
	 * Dispatched when the user rolls the mouse pointer over a leaf item in the control.
	 *
	 * @eventType org.un.cava.birdeye.qavis.treemap.events.TreeMapEvent.LEAF_ROLL_OVER
	 */
	[Event(name="leafRollOver", type="org.un.cava.birdeye.qavis.treemap.events.TreeMapEvent")]
	
	/**
	 * Dispatched when the user rolls the mouse pointer out of a leaf item in the control.
	 *
	 * @eventType org.un.cava.birdeye.qavis.treemap.events.TreeMapEvent.LEAF_ROLL_OUT
	 */
	[Event(name="leafRollOut", type="org.un.cava.birdeye.qavis.treemap.events.TreeMapEvent")]
	
	/**
	 * Dispatched when the user clicks on a leaf item in the control.
	 *
	 * @eventType org.un.cava.birdeye.qavis.treemap.events.TreeMapEvent.LEAF_CLICK
	 */
	[Event(name="leafClick", type="org.un.cava.birdeye.qavis.treemap.events.TreeMapEvent")]
	
	/**
	 * Dispatched when the user double-clicks on a leaf item in the control.
	 *
	 * @eventType org.un.cava.birdeye.qavis.treemap.events.TreeMapEvent.LEAF_DOUBLE_CLICK
	 */
	[Event(name="leafDoubleClick", type="org.un.cava.birdeye.qavis.treemap.events.TreeMapEvent")]

	//--------------------------------------
	//  Styles
	//--------------------------------------
	
include "../styles/metadata/TextStyles.inc"
	
	
	/**
	 * Sets the style name for all leaf nodes.
	 */
	[Style(name="leafStyleName", type="String", inherit="no")]
	
	
	/**
	 * Sets the style name for all branch nodes.
	 */
	[Style(name="branchStyleName", type="String", inherit="no")]
	
	/**
	 * A treemap is a space-constrained visualization of hierarchical
	 * structures. It is very effective in showing attributes of leaf nodes
	 * using size and color coding.
	 * 
	 * @author Josh Tynjala
	 * @see http://code.google.com/p/flex2treemap/
	 * @see http://en.wikipedia.org/wiki/Treemapping
	 * @see http://www.cs.umd.edu/hcil/treemap-history/
	 * @includeExample examples/TreeMapExample.mxml
	 */
	public class TreeMap extends UIComponent
	{
		
	//--------------------------------------
	//  Static Properties
	//--------------------------------------
		
		/**
		 * @private
		 * The default width of the TreeMap.
		 */
		private static const DEFAULT_MEASURED_WIDTH:Number = 300;
		
		/**
		 * @private
		 * The default height of the TreeMap.
		 */
		private static const DEFAULT_MEASURED_HEIGHT:Number = 200;
		
	//--------------------------------------
	//  Static Methods
	//--------------------------------------
		
		public static function initializeStyles():void
		{
			
		}
		initializeStyles();
		
	//--------------------------------------
	//  Constructor
	//--------------------------------------
	
		public function TreeMap()
		{
			super();
		}
		
	//--------------------------------------
	//  Properties
	//--------------------------------------
	
		private var _hasRoot:Boolean = false;
		
		public function get hasRoot():Boolean
		{
			return this._hasRoot;
		}
		
		private var _showRoot:Boolean = true;
		
		[Bindable]
		public function get showRoot():Boolean
		{
			return this._showRoot;
		}
		
		public function set showRoot(value:Boolean):void
		{
			this._showRoot = value;
			
			//TODO: Should this use its own flag?
			this.dataProviderChanged = true;
			this.invalidateProperties();
			this.invalidateDisplayList();
		}
	
		private var _discoveredRoot:Object = null;
		private var _displayedRoot:Object = null;
	
		protected var dataProviderChanged:Boolean = false;
	
		private var _dataProvider:ICollectionView = new ArrayCollection();
	
		public function get dataProvider():Object
		{
			return this._dataProvider;
		}
		
		public function set dataProvider(value:Object):void
		{
			if(this._dataProvider)
	        {
	        	this._dataProvider.removeEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler);
	        }
	
			//starting fresh with a new data provider
			this._hasRoot = false;
	
			//convert to data types that the treemap understands
	    	if(typeof(value) == "string")
	    	{
	    		//string becomes XML
	        	value = new XML(value);
	     	}
	        else if(value is XMLNode)
	        {
	        	//AS2-style XMLNodes become AS3 XML
				value = new XML(XMLNode(value).toString());
	        }
			else if(value is XMLList)
			{
				//XMLLists become XMLListCollections
				value = new XMLListCollection(value as XMLList);
			}
			else if(value is Array)
			{
				value = new ArrayCollection(value as Array);
			}
			
			if(value is XML)
			{
				this._hasRoot = true;
				var list:XMLList = new XMLList();
				list += value;
				this._dataProvider = new XMLListCollection(list);
			}
			//if already a collection dont make new one
	        else if(value is ICollectionView)
	        {
	            this._dataProvider = ICollectionView(value);
	    		if(this._dataProvider.length == 1)
	    		{
	    			this._hasRoot = true;
	    		}
	        }
			else if(value is Object)
			{
				// convert to an array containing this one item
				this._hasRoot = true;
	    		this._dataProvider = new ArrayCollection( [value] );
	  		}
	  		else
	  		{
	  			this._dataProvider = new ArrayCollection();
	  		}
	
	        this._dataProvider.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler, false, 0, true);
	        this._dataProvider.dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE));
	
			//it's a new data provider, so we can't have the same zoomed branch
			this.zoomedBranch = null;
	        
			this.invalidateProperties();
			this.invalidateDisplayList();
		}
		
		/**
		 * @private
		 * Storage for the data descriptor used to crawl the data.
		 */
		private var _dataDescriptor:ITreeDataDescriptor = new DefaultDataDescriptor();
	
		/**
		 * Returns the current ITreeDataDescriptor.
		 *
		 * @default DefaultDataDescriptor
		 */
		public function get dataDescriptor():ITreeDataDescriptor
		{
			return this._dataDescriptor;
		}

		/**
		 * TreeMap delegates to the data descriptor for information about the data.
		 * This data is then used to parse and move about the data source.
		 * <p>When you specify this property as an attribute in MXML you must
		 * use a reference to the data descriptor, not the string name of the
		 * descriptor. Use the following format for the property:</p>
		 *
		 * <pre>&lt;mx:TreeMap id="treemap" dataDescriptor="{new MyCustomTreeDataDescriptor()}"/&gt;></pre>
		 *
		 * <p>Alternatively, you can specify the property in MXML as a nested
		 * subtag, as the following example shows:</p>
		 *
		 * <pre>&lt;mx:TreeMap&gt;
		 * &lt;mx:dataDescriptor&gt;
		 * &lt;myCustomTreeDataDescriptor&gt;</pre>
		 *
		 * <p>The default value is an internal instance of the
		 * DefaultDataDescriptor class.</p>
		 *
		 */
		public function set dataDescriptor(value:ITreeDataDescriptor):void
		{
			this._dataDescriptor = value;
			this.invalidateProperties();
			this.invalidateDisplayList();
		}
		
		
		/**
		 * @private
		 * Storage for the strategy used for layout of nodes and branches.
		 */
		private var _layoutStrategy:ITreeMapLayoutStrategy = new SquarifyLayout();
	    
	    /**
	     * The custom layout algorithm for the control.
	     *
		 * <p>The default alogrithm is Squarify.</p>
	     */
	    public function get layoutStrategy():ITreeMapLayoutStrategy
	    {
	        return this._layoutStrategy;
	    }
	    
	    /**
		 * @private
		 */
	    public function set layoutStrategy(strategy:ITreeMapLayoutStrategy):void
	    {
	    	this._layoutStrategy = strategy;
	    	this.invalidateProperties();
		    this.invalidateDisplayList();
	    }
	    
	    /**
	     * @private
	     * Storage for the leafRenderer property.
	     */
	    private var _leafRenderer:IFactory = new ClassFactory(TreeMapLeafRenderer);
	
		protected var leafRendererChanged:Boolean = false;
	
	    /**
	     * The custom leaf renderer for the control.
	     * You can specify a drop-in, inline, or custom leaf renderer.
	     *
		 * <p>The default node renderer is TODO.</p>
	     */
	    public function get leafRenderer():IFactory
	    {
	        return _leafRenderer;
	    }
	
	    /**
		 * @private
		 */
	    public function set leafRenderer(value:IFactory):void
	    {
			this._leafRenderer = value;
	    	this.leafRendererChanged = true;
			this.invalidateProperties();
			this.invalidateDisplayList();
	    }
	
		/**
		 * @private
		 * Storage for the branchRenderer property.
		 */
		private var _branchRenderer:IFactory = new ClassFactory(TreeMapBranchRenderer);
		
		protected var branchRendererChanged:Boolean = false;
		
	    /**
	     * The custom branch renderer for the control. You can specify a drop-in,
	     * inline, or custom branch renderer. Unlike the renderers used by Tree
	     * components, nodes and branches in a TreeMap are quite different visually and
	     * functionally. As a result, it's easier to specify and customize seperate
	     * renderers for either type.
	     *
		 * <p>The default branch renderer is TreeMapBranchRenderer.</p>
	     */
	    public function get branchRenderer():IFactory
	    {
	        return this._branchRenderer;
	    }
	
	    /**
		 * @private
		 */
	    public function set branchRenderer(value:IFactory):void
	    {
			this._branchRenderer = value;
			this.branchRendererChanged = true;
			this.invalidateProperties();
			this.invalidateDisplayList();
	    }
		
	    /**
		 * @private
		 * The branch renderer for the root branch.
		 */
		protected var rootBranchRenderer:ITreeMapBranchRenderer;
		
	    /**
		 * @private
		 * The complete collection of item renderers, including branches and
		 * leaves. Not every item in the collection may have a renderer.
		 */
		protected var itemRenderers:Array = [];
		
	    /**
		 * @private
		 * The complete collection of leaf renderers. Not every leaf in the
		 * data provider may have a renderer.
		 */
		protected var leafRenderers:Array = [];
		
	    /**
		 * @private
		 * The complete collection of leaf renderers. Not every branch in the
		 * data provider may have a renderer.
		 */
		protected var branchRenderers:Array = [];
		
		/**
		 * @private
		 */
		private var _leafRendererCache:Array = [];
		
		/**
		 * @private
		 */
		private var _branchRendererCache:Array = [];
		
		/**
		 * @private
		 * Hash to covert from a UID to the renderer for an item.
		 */
		private var _uidToItemRenderer:Object;
	    
		/**
		 * @private
		 * Hash to covert from a UID to the children of a branch. We can't trust
		 * ICollectionView to return the same children every time.
		 */
	    private var _uidToChildren:Object;
	    
	//-- Weight
	
		/**
		 * @private
		 * A cache of weights for every item in the dataProvider. Performance boost.
		 */
		private var _uidToWeight:Object;
	
		/**
		 * @private
		 * Storage for the field used to calculate a node's weight.
		 */
		private var _weightField:String = "weight";
		[Bindable("weightFieldChanged")]
	    /**
	     * The name of the field in the data provider items to use in weight calculations.
	     */
	    public function get weightField():String
	    {
	    	return this._weightField;
	    }
	    
	    /**
		 * @private
		 */
	    public function set weightField(value:String):void
	    {
	    	this._weightField = value;
	    	this.invalidateProperties();
	    	this.invalidateDisplayList();
	    	this.dispatchEvent(new Event("weightFieldChanged"));
	    }
	    
		/**
		 * @private
		 * Storage for the function used to calculate a node's weight.
		 */
		private var _weightFunction:Function;
		
	    [Bindable("weightFunctionChanged")]
	    /**
	     * A user-supplied function to run on each item to determine its weight.
	     *
		 * <p>The weight function takes one arguments, the item in the data provider.
		 * It returns a Number.
		 * <blockquote>
		 * <code>weightFunction(item:Object):Number</code>
		 * </blockquote></p>
	     */
	    public function get weightFunction():Function
	    {
	    	return this._weightFunction;
	    }
	    
	    /**
		 * @private
		 */
	    public function set weightFunction(value:Function):void
	    {
		    this._weightFunction = value;
		    this.invalidateProperties();
		    this.invalidateDisplayList();
	    	this.dispatchEvent(new Event("weightFunctionChanged"));
	    }
	    
	//-- Color
	    
		/**
		 * @private
		 * Storage for the field used to calculate a node's color.
		 */
		private var _colorField:String = "color";
		
	    [Bindable("colorFieldChanged")]
	    /**
	     * The name of the field in the data provider items to use as the color.
	     */
	    public function get colorField():String
	    {
	    	return this._colorField;
	    }
	    
	    /**
		 * @private
		 */
	    public function set colorField(value:String):void
	    {
	    	this._colorField = value;
	    	this.invalidateProperties();
	    	this.dispatchEvent(new Event("colorFieldChanged"));
	    }
	    
		/**
		 * @private
		 * Storage for the function used to calculate a node's color.
		 */
		private var _colorFunction:Function;
		
	    [Bindable("colorFunctionChanged")]
	    /**
	     * A user-supplied function to run on each item to determine its color.
	     *
		 * <p>The color function takes one argument, the item in the data provider.
		 * It returns a uint.</p>
		 * 
		 * <blockquote>
		 * <code>colorFunction(item:Object):uint</code>
		 * </blockquote>
	     */
	    public function get colorFunction():Function
	    {
	    	return this._colorFunction;
	    }
	    
	    /**
		 * @private
		 */
	    public function set colorFunction(value:Function):void
	    {
			this._colorFunction = value;
			this.invalidateProperties();
	    	this.dispatchEvent(new Event("colorFunctionChanged"));
	    }
	    
	//-- Label
	    
		/**
		 * @private
		 * Storage for the field used to calculate a node's label.
		 */
		private var _labelField:String = "label";
		
	    [Bindable("labelFieldChanged")]
	    /**
	     * The name of the field in the data provider items to display as the label
	     * of the data renderer. As a special case, if the nodes are <code>TreeMap</code>
	     * components, this function applies to the TreeMap label.
	     */
	    public function get labelField():String
	    {
	    	return this._labelField;
	    }
	    
	    /**
		 * @private
		 */
	    public function set labelField(value:String):void
	    {
	    	this._labelField = value;
	    	this.invalidateProperties();
	    	this.dispatchEvent(new Event("labelFieldChanged"));
	    }
	    
		/**
		 * @private
		 * Storage for the function used to calculate a node's label.
		 */
		private var _labelFunction:Function;
		
	    [Bindable("labelFunctionChanged")]
	    /**
	     * A user-supplied function to run on each item to determine its label.
	     *
		 * <p>The label function takes one argument, the item in the data provider.
		 * It returns a String.
		 * <blockquote>
		 * <code>labelFunction(item:Object):String</code>
		 * </blockquote></p>
	     */
	    public function get labelFunction():Function
	    {
	    	return this._labelFunction;
	    }
	    
	    /**
		 * @private
		 */
	    public function set labelFunction(value:Function):void
	    {
			this._labelFunction = value;
			this.invalidateProperties();
	    	this.dispatchEvent(new Event("labelFunctionChanged"));
	    }
	    
	//-- ToolTip
	    
		/**
		 * @private
		 * Storage for the field used to calculate a node's datatip.
		 */
		private var _dataTipField:String = "dataTip";
		
	    [Bindable("dataTipFieldChanged")]
	    /**
	     * The name of the field in the data provider items to display as the datatip
	     * of the data renderer.
	     */
	    public function get dataTipField():String
	    {
	    	return this._dataTipField;
	    }
		
	    /**
		 * @private
		 */
	    public function set dataTipField(value:String):void
	    {
			this._dataTipField = value;
			this.invalidateProperties();
	    	this.dispatchEvent(new Event("dataTipFieldChanged"));
	    }
	    
		/**
		 * @private
		 * Storage for the function used to calculate a node's datatip.
		 */
		private var _dataTipFunction:Function;
		
		[Bindable("dataTipFunctionChanged")]
	    /**
	     * A user-supplied function to run on each item to determine its datatip.
	     *
		 * <p>The datatip function takes one argument, the item in the data provider.
		 * It returns a String.
		 * <blockquote>
		 * <code>dataTipFunction(item:Object):String</code>
		 * </blockquote></p>
	     */
	    public function get dataTipFunction():Function
	    {
	    	return this._dataTipFunction;
	    }
	    
	    /**
		 * @private
		 */
	    public function set dataTipFunction(value:Function):void
	    {
			this._dataTipFunction = value;
	    	this.invalidateProperties();
	    	this.dispatchEvent(new Event("dataTipFunctionChanged"));
	    }
		
	//-- Selection
	
		[Bindable]
		/**
		 * @private
		 * Storage for the selectable property.
		 */
		private var _selectable:Boolean = false;
		
	    /**
	     * Indicates if the node's within the TreeMap can be selected by the user.
		 */
		public function get selectable():Boolean
		{
			return this._selectable;
		}
		
	    /**
		 * @private
		 */
		public function set selectable(value:Boolean):void
		{
			this._selectable = value;
			this.invalidateProperties();
		}
	
		[Bindable]
		/**
		 * @private
		 * Storage for the branchesSelectable property.
		 */
		private var _branchesSelectable:Boolean = false;
		
	    /**
	     * Indicates if the node's within the TreeMap can be selected by the user.
		 */
		public function get branchesSelectable():Boolean
		{
			return this._branchesSelectable;
		}
		
	    /**
		 * @private
		 */
		public function set branchesSelectable(value:Boolean):void
		{
			this._branchesSelectable = value;
			if(!branchesSelectable && this.dataDescriptor.isBranch(this.selectedItem))
			{
				this.selectedItem = null;
			}
		}
		
		/**
		 * @private
		 * Storage for the selectedItem property.
		 */
		private var _selectedItem:Object;
		
		[Bindable("valueCommit")]
		/**
		 * The currently selected item.
		 */
		public function get selectedItem():Object
		{
			return this._selectedItem;
		}
		
		/**
		 * @private
		 */
		public function set selectedItem(value:Object):void
		{
			this._selectedItem = value;
			if(!this.branchesSelectable && this.dataDescriptor.isBranch(value))
			{
				this._selectedItem = null;
			}
			this.invalidateProperties();
			this.dispatchEvent(new FlexEvent(FlexEvent.VALUE_COMMIT));
		}
		
	//-- ZOOMING
		
		protected var zoomChanged:Boolean = false;
		
		/**
		 * @private
		 * The branches that are currently zoomed. Null if none are zoomed.
		 */
		private var _zoomedBranches:Array = [];
		
		/**
		 * The currently zoomed branch.
		 */
		public function get zoomedBranch():Object
		{
			if(this._zoomedBranches.length > 0)
			{
				return this._zoomedBranches[this._zoomedBranches.length - 1];
			}
			return null;
		}
		
		/**
		 * @private
		 */
		public function set zoomedBranch(value:Object):void
		{
			if(value)
			{
				this._zoomedBranches = [value];
			}
			else
			{
				this._zoomedBranches = [];
			}
			this.zoomChanged = true;
			this.invalidateProperties();
			this.invalidateDisplayList();
		}
		
		/**
		 * @private
		 * Storage for the zoomEnabled property.
		 */
		private var _zoomEnabled:Boolean = true;
		
		/**
		 * TODO: document
		 */
		public function get zoomEnabled():Boolean
		{
			return this._zoomEnabled;
		}
		
		/**
		 * @private
		 */
		public function set zoomEnabled(value:Boolean):void
		{
			this._zoomEnabled = value;
			this.invalidateProperties();
		}
		
		/**
		 * @private
		 * Storage for the zoomOutType property.
		 */
		private var _zoomOutType:String = TreeMapZoomOutType.PREVIOUS;
		
		/**
		 * Determines the way that zoom out actions work. Values are defined by the
		 * constants in the <code>TreeMapZoomOutType</code> class.
		 */
		public function get zoomOutType():String
		{
			return this._zoomOutType;
		}
		
		/**
		 * @private
		 */
		public function set zoomOutType(value:String):void
		{
			this._zoomOutType = value;
			//doesn't immediately affect anything, so we
			//don't need to invalidate.
		}
		
		/**
		 * @private
		 * Storage for the maximumDepth property.
		 */
		private var _maxDepth:int = -1;
		
		/**
		 * If value is >= 0, the treemap will only render branches to a specific depth.
		 */
		public function get maxDepth():int
		{
			return this._maxDepth;
		}
		
		/**
		 * @private
		 */
		public function set maxDepth(value:int):void
		{
			this._maxDepth = value;
			this.zoomChanged = true;
			this.invalidateProperties();
			this.invalidateDisplayList();
		}
	
	//--------------------------------------
	//  Public Methods
	//--------------------------------------
	
		/**
		 * Determines the label text for an item from the data provider.
		 * If no label is specfied, returns the result of the item's
		 * toString() method. If item is null, returns an empty string.
		 */
		public function itemToLabel(item:Object):String
		{
			if(item === null) return "";
			
			if(this.labelFunction != null)
			{
				return this.labelFunction(item);
			}
			else if(item.hasOwnProperty(this.labelField))
			{
				return item[this.labelField];
			}
			return item.toString();
		}
	
		/**
		 * Determines the datatip text for an item from the data provider.
		 * If no datatip is specified, returns an empty string.
		 */
		public function itemToDataTip(item:Object):String
		{
			if(item === null) return "";
			
			if(this.dataTipFunction != null)
			{
				return this.dataTipFunction(item);
			}
			else if(item.hasOwnProperty(this.dataTipField))
			{
				return item[this.dataTipField];
			}
			//normally, I'd do toString(), but I think an
			//empty string makes sense so that there's no dataTip.
			return "";
		}
	
		/**
		 * Determines the color value for an item from the data provider.
		 * If color not available, returns black (0x000000).
		 */
		public function itemToColor(item:Object):uint
		{
			if(item === null) return 0x000000;
			
			if(this.colorFunction != null)
			{
				return this.colorFunction(item);
			}
			else if(item.hasOwnProperty(this.colorField))
			{
				return item[this.colorField];
			}
			
			return 0x000000;
		}
	
		/**
		 * Determines the weight value for an item from the data provider.
		 */
		public function itemToWeight(item:Object):Number
		{
			if(item === null)
			{
				return 0;
			}
			
			var uid:String = this.itemToUID(item);
			var weight:Number = this._uidToWeight[uid];
			if(isNaN(weight))
			{
				//automatically determine branch weight from sum of children
				if(this.dataDescriptor.isBranch(item))
				{
					weight = 0;
					
					var children:ICollectionView = this.branchToChildren(item);
					var iterator:IViewCursor = children.createCursor();
					while(!iterator.afterLast)
					{
						var childItem:Object = iterator.current;
						weight += this.itemToWeight(childItem);
						iterator.moveNext();
					}
				}
				else if(this.weightFunction != null)
				{
					weight = this.weightFunction(item);
				}
				else if(item.hasOwnProperty(this.weightField))
				{
					weight = item[this.weightField];
				}
				else
				{
					weight = 0;
				}
				this._uidToWeight[uid] = weight;
			}
			return weight;
		}
	    
	    /**
	     * Returns the item renderer that displays specific data.
	     * 
	     * @param item				the data for which to find a matching item renderer
	     * @return					the item renderer that matches the data
	     */
	    public function itemToItemRenderer(item:Object):ITreeMapItemRenderer
	    {
	    	var uid:String = this.itemToUID(item);
	    	return this._uidToItemRenderer[uid];
	    }
	
	    /**
	     * Determines if an item is the root node
	     * 
	     * @param item				the data for which to check against the root
	     * @return					true if the item is the root data, false if not
	     */
		public function itemIsRoot(item:Object):Boolean
		{
			return item == this._discoveredRoot;
		}
	
		override public function styleChanged(styleProp:String):void
		{
			super.styleChanged(styleProp);
			
			var allStyles:Boolean = !styleProp || styleProp == "styleName";
			
			if(allStyles || styleProp == "leafStyleName")
			{
				var leafStyleName:String = this.getStyle("leafStyleName");
				var leafRendererCount:int = this.leafRenderers.length;
				for(var i:int = 0; i < leafRendererCount; i++)
				{
					var leafRenderer:ITreeMapLeafRenderer = ITreeMapLeafRenderer(this.leafRenderers[i]);
					leafRenderer.styleName = leafStyleName;
				}
			}
			
			if(allStyles || styleProp == "branchStyleName")
			{
				var branchStyleName:String = this.getStyle("branchStyleName");
				var branchRendererCount:int = this.branchRenderers.length;
				for(i = 0; i < branchRendererCount; i++)
				{
					var branchRenderer:ITreeMapBranchRenderer = ITreeMapBranchRenderer(this.branchRenderers[i]);
					branchRenderer.styleName = branchStyleName;
				}
			}
		}
	
	//--------------------------------------
	//  Protected Methods
	//--------------------------------------
		
		/**
		 * Determines the UID for a data provider item.  All items
		 * in a data provider must either have a unique ID (UID)
		 * or one will be generated and associated with it.  This
		 * means that you cannot have an object or scalar value
		 * appear twice in a data provider.  For example, the following
		 * data provider is not supported because the value "foo"
		 * appears twice and the UID for a string is the string itself
		 *
		 * <blockquote>
		 * 		<code>var sampleDP:Array = ["foo", "bar", "foo"]</code>
		 * </blockquote>
		 *
		 * Simple dynamic objects can appear twice if they are two
		 * separate instances.  The following is supported because
		 * each of the instances will be given a different UID because
		 * they are different objects.
		 *
		 * <blockquote>
		 * 		<code>var sampleDP:Array = [{label: "foo"}, {label: "foo"}]</code>
		 * </blockquote>
		 *
		 * Note that the following is not supported because the same instance
		 * appears twice.
		 *
		 * <blockquote>
		 * 		<code>var foo:Object = {label: "foo"};
		 * 		sampleDP:Array = [foo, foo];</code>
		 * </blockquote>
		 *
		 * @param item		The data provider item
		 *
		 * @return			The UID as a string
		 */
		protected function itemToUID(item:Object):String
		{
			if(!item)
			{
				return "null";
			}
			return UIDUtil.getUID(item);
		}
		
		protected function branchToChildren(branch:Object):ICollectionView
		{
			var uid:String = this.itemToUID(branch);
			return this._uidToChildren[uid];
		}
		
		/**
		 * @private
		 */
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if(this.dataProviderChanged)
			{
				this.initializeData();
			}
			
			//if something has changed in the data provider,
			//we need to update/create/destroy item renderers
			if(this.dataProviderChanged || this.zoomChanged)
			{
				this._displayedRoot = this._discoveredRoot;
				if(this.zoomedBranch)
				{
					this._displayedRoot = this.zoomedBranch;
				}
				this.createCache();
				if(this.dataProvider)
				{
					this.rootBranchRenderer = this.getBranchRenderer();
					this.refreshBranchChildRenderers(this.rootBranchRenderer, this._displayedRoot, 0, 0);
				}
				this.clearCache();
			}
			this.commitBranchProperties(this._displayedRoot, 0, 0);
			
			this.commitZoom();
			this.commitSelection();
			
			this.dataProviderChanged = false;
			this.zoomChanged = false;
		}
		
		/**
		 * @private
		 */
		override protected function measure():void
		{
			super.measure();
			
			this.measuredWidth = DEFAULT_MEASURED_WIDTH;
			this.measuredHeight = DEFAULT_MEASURED_HEIGHT;
		}
		
		/**
		 * @private
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var renderer:ITreeMapBranchRenderer = this.rootBranchRenderer;
			if(this.zoomedBranch)
			{
				//no need to draw nodes hidden behind the zoomed branch
				//they will be set invisible
				renderer = ITreeMapBranchRenderer(this.itemToItemRenderer(this.zoomedBranch));
			}
			
			if(renderer)
			{
				renderer.move(0, 0);
				renderer.setActualSize(unscaledWidth, unscaledHeight);
			}
		}
		
		/**
		 * @private
		 * Determines the true root of the tree and initializes the branch lookup.
		 */
		protected function initializeData():void
		{
			this._uidToChildren = {};
			this._uidToWeight = {};
			
			if(!this._dataProvider)
			{
				return;
			}
			
			//we want to find the root of the tree. it might be the data provider
			//but if the data provider has only a single child and that's a branch,
			//then the real root of the tree is that child branch
			this._discoveredRoot = this._dataProvider;
			if(this.hasRoot && this._dataProvider.length == 1)
			{
				var firstChild:Object = this._dataProvider[0];
				if(this.dataDescriptor.isBranch(firstChild))
				{
					this._discoveredRoot = firstChild;
				}
			}
			
			this.initializeBranch(this._discoveredRoot);
		}
		
		/**
		 * @private
		 * Because the reference to the each data item may change every time we call getChildren(),
		 * we need to cache the values returned from getChildren() for lookup every time we loop
		 * through a branch's children.
		 */
		private function initializeBranch(branch:Object):void
		{
			var uid:String = this.itemToUID(branch);
			var children:ICollectionView;
			if(branch is ICollectionView)
			{
				children = ICollectionView(branch);
			}
			else
			{
				children = this.dataDescriptor.getChildren(branch);
			}
			this._uidToChildren[uid] = children;
			
			var iterator:IViewCursor = children.createCursor();
			while(!iterator.afterLast)
			{
				var item:Object = iterator.current;
				if(this.dataDescriptor.isBranch(item))
				{
					this.initializeBranch(item);
				}
				iterator.moveNext();
			}
		}
		
		/**
		 * @private
		 * Creates caches to reuse leaf and branch renderers.
		 */
		protected function createCache():void
		{
			this._uidToItemRenderer = {};
			this.itemRenderers = [];
			
			if(!this.leafRendererChanged)
			{
				//reuse leaf renderers if the factory hasn't changed.
				//also keep anything that's already in the cache.
				//this condition may happen if maxDepth has been set
				//because we keep renderers around even when they're
				//outside the zoom range.
				this._leafRendererCache = this._leafRendererCache.concat(this.leafRenderers.concat());
			}
			this.leafRenderers = [];
			
			if(!this.branchRendererChanged)
			{
				//reuse branch renderers if the factory hasn't changed.
				//also keep anything that's already in the cache.
				//this condition may happen if maxDepth has been set
				//because we keep renderers around even when they're
				//outside the zoom range.
				this._branchRendererCache = this._branchRendererCache.concat(this.branchRenderers.concat());
			}
			this.rootBranchRenderer = null;
			this.branchRenderers = [];
		}
		
		/**
		 * @private
		 * Creates the child renderers of a branch and updates their data.
		 */
		protected function refreshBranchChildRenderers(renderer:ITreeMapBranchRenderer, branch:Object, depth:int, zoomDepth:int):void
		{
			renderer.data = branch;
			
			var uid:String = this.itemToUID(branch);
			this._uidToItemRenderer[uid] = renderer;
			
			depth++;
			if(this.isMaxDepthActive())
			{
				zoomDepth++;
				if(zoomDepth > this.maxDepth)
				{
					return;
				}
			}
			
			var children:ICollectionView = this.branchToChildren(branch);
			var iterator:IViewCursor = children.createCursor();
			while(!iterator.afterLast)
			{
				var item:Object = iterator.current;
				if(this.dataDescriptor.isBranch(item))
				{
					var childBranchRenderer:ITreeMapBranchRenderer = this.getBranchRenderer();
					this.refreshBranchChildRenderers(childBranchRenderer, item, depth, zoomDepth);
				}
				else
				{
					var leafUID:String = this.itemToUID(item);
					var childLeafRenderer:ITreeMapLeafRenderer = this.getLeafRenderer();
					childLeafRenderer.data = item;
					this._uidToItemRenderer[leafUID] = childLeafRenderer;
				}
				
				iterator.moveNext();
			}
		}
	
		/**
		 * @private
		 * Gets either a cached leaf or a new instance of the leaf renderer.
		 */
		protected function getLeafRenderer():ITreeMapLeafRenderer
		{
			var renderer:ITreeMapLeafRenderer;
			if(this._leafRendererCache.length > 0)
			{
				renderer = ITreeMapLeafRenderer(this._leafRendererCache.shift());
			}
			else
			{
				renderer = ITreeMapLeafRenderer(this.leafRenderer.newInstance());
				renderer.styleName = this.getStyle("leafStyleName");
				renderer.addEventListener(MouseEvent.CLICK, leafClickHandler, false, 0, true);
				renderer.addEventListener(MouseEvent.DOUBLE_CLICK, leafDoubleClickHandler, false, 0, true);
				renderer.addEventListener(MouseEvent.ROLL_OVER, leafRollOverHandler, false, 0, true);
				renderer.addEventListener(MouseEvent.ROLL_OUT, leafRollOutHandler, false, 0, true);
				this.addChild(UIComponent(renderer));
			}
			
			this.leafRenderers.push(renderer);
			this.itemRenderers.push(renderer);
			return renderer;
		}
		
		/**
		 * @private
		 * Gets either a cached branch or a new instance of the branch renderer.
		 */
		protected function getBranchRenderer():ITreeMapBranchRenderer
		{
			var renderer:ITreeMapBranchRenderer;
			if(this._branchRendererCache.length > 0)
			{
				renderer = ITreeMapBranchRenderer(this._branchRendererCache.shift());
			}
			else
			{
				renderer = ITreeMapBranchRenderer(this.branchRenderer.newInstance());
				renderer.styleName = this.getStyle("branchStyleName");
				renderer.addEventListener(TreeMapEvent.BRANCH_ZOOM, branchZoomHandler, false, 0, true);
				renderer.addEventListener(TreeMapEvent.BRANCH_SELECT, branchSelectHandler, false, 0, true);
				this.addChild(UIComponent(renderer));
			}
			
			this.branchRenderers.push(renderer);
			this.itemRenderers.push(renderer);
			return renderer;
		}
		
		/**
		 * @private
		 * If any renderers are left in the caches, remove them.
		 */
		protected function clearCache():void
		{
			//optimization when maxDepth is defined. we keep renderers
			//around even if they aren't being used. saves display list
			//manipulations. if the data provider changes, then we start
			//from scratch because it could have been a major change
			if(this.isMaxDepthActive() && !this.dataProviderChanged)
			{
				var itemCount:int = this._branchRendererCache.length;
				for(var i:int = 0; i < itemCount; i++)
				{
					var extraRenderer:UIComponent = UIComponent(this._branchRendererCache[i]);
					extraRenderer.visible = false;
				}
				
				itemCount = this._leafRendererCache.length;
				for(i = 0; i < itemCount; i++)
				{
					extraRenderer = UIComponent(this._leafRendererCache[i]);
					extraRenderer.visible = false;
				}
				return;
			}
			
			//remove branches from cache
			itemCount = this._branchRendererCache.length;
			for(i = 0; i < itemCount; i++)
			{
				var renderer:ITreeMapItemRenderer = ITreeMapItemRenderer(this._branchRendererCache.pop());
				renderer.removeEventListener(TreeMapEvent.BRANCH_ZOOM, branchZoomHandler);
				renderer.removeEventListener(TreeMapEvent.BRANCH_SELECT, branchSelectHandler);
				this.removeChild(UIComponent(renderer));
			}
			
			//remove leaves from cache
			itemCount = this._leafRendererCache.length;
			for(i = 0; i < itemCount; i++)
			{
				renderer = ITreeMapItemRenderer(this._leafRendererCache.pop());
				renderer.removeEventListener(MouseEvent.CLICK, leafClickHandler);
				renderer.removeEventListener(MouseEvent.DOUBLE_CLICK, leafDoubleClickHandler);
				renderer.removeEventListener(MouseEvent.ROLL_OVER, leafRollOverHandler);
				renderer.removeEventListener(MouseEvent.ROLL_OUT, leafRollOutHandler);
				this.removeChild(UIComponent(renderer));
			}
		}
	
		protected function commitBranchProperties(branch:Object, depth:int, zoomDepth:int):void
		{
			var branchData:TreeMapBranchData = new TreeMapBranchData(this);
			branchData.layoutStrategy = this.layoutStrategy;
			branchData.closed = this.isDepthClosed(zoomDepth);
			
			//only display a label on the branch renderer if it's not the root
			//or if the root is a true root and showRoot == true
			if(this.itemIsRoot(branch) && (!this.hasRoot || !this.showRoot))
			{
				branchData.showLabel = false;
			}
			else
			{
				branchData.showLabel = true;
			}
			
			this.commitItemProperties(branch, branchData, depth, zoomDepth);
			
			depth++
			if(this.isMaxDepthActive())
			{
				zoomDepth++;
				if(zoomDepth > this.maxDepth)
				{
					return;
				}
			}
			this.commitBranchChildProperties(branch, branchData, depth, zoomDepth);
		}
	
		protected function commitBranchChildProperties(branch:Object, branchData:TreeMapBranchData, depth:int, zoomDepth:int):void
		{
			var children:ICollectionView = this.branchToChildren(branch);
			var iterator:IViewCursor = children.createCursor();
			while(!iterator.afterLast)
			{
				var item:Object = iterator.current;
				if(this.dataDescriptor.isBranch(item))
				{
					this.commitBranchProperties(item, depth, zoomDepth);
				}
				else
				{
					var leafData:TreeMapLeafData = new TreeMapLeafData(this);
					leafData.color = this.itemToColor(item);
					leafData.dataTip = this.itemToDataTip(item);
					this.commitItemProperties(item, leafData, depth, zoomDepth);
				}
				
				var renderer:ITreeMapItemRenderer = this.itemToItemRenderer(item);
				
				var layoutData:TreeMapItemLayoutData = new TreeMapItemLayoutData(renderer);
				layoutData.weight = this.itemToWeight(item);
				layoutData.zoomed = this.zoomedBranch == item;
				branchData.addItem(layoutData);
				
				iterator.moveNext();
			}
		}
	
		protected function commitItemProperties(item:Object, treeMapData:BaseTreeMapData, depth:int, zoomDepth:int):void
		{
			var uid:String = this.itemToUID(item);
			treeMapData.uid = uid;
			treeMapData.depth = depth;
			treeMapData.weight = this.itemToWeight(item);
			treeMapData.label = this.itemToLabel(item);
			
			var renderer:ITreeMapItemRenderer = this.itemToItemRenderer(item);
			if(renderer is IDropInTreeMapItemRenderer)
			{
				IDropInTreeMapItemRenderer(renderer).treeMapData = treeMapData;
			}
			renderer.visible = this.isDepthVisible(zoomDepth);
			this.setChildIndex(UIComponent(renderer), this.numChildren - 1);
		}
		
		/**
		 * @private
		 * Handles the display of the zoomed renderer.
		 */
		protected function commitZoom():void
		{
			if(this.zoomedBranch)
			{
				this.updateDepthsForZoomedBranch(this.zoomedBranch);
			}
		}
		
		/**
		 * @private
		 * Puts a branch and all of its children at the highest depths
		 * so that they may be zoomed.
		 */
		protected function updateDepthsForZoomedBranch(branch:Object):void
		{
			var branchRenderer:ITreeMapBranchRenderer = ITreeMapBranchRenderer(this.itemToItemRenderer(branch));
			//the renderer may not have been created if maxDepth is set
			if(branchRenderer)
			{
				this.setChildIndex(UIComponent(branchRenderer), this.numChildren - 1);
			}
			
			var children:ICollectionView = this.branchToChildren(branch);
			var iterator:IViewCursor = children.createCursor();
			while(!iterator.afterLast)
			{
				var child:Object = iterator.current;
				if(this.dataDescriptor.isBranch(child))
				{
					this.updateDepthsForZoomedBranch(child);
				}
				else
				{
					var childRenderer:ITreeMapItemRenderer = this.itemToItemRenderer(child);
					//the child renderer may not exist if maxDepth is set
					if(childRenderer)
					{
						this.setChildIndex(UIComponent(childRenderer), this.numChildren - 1);
					}
				}
				iterator.moveNext();
			}
		}
		
		protected function isMaxDepthActive():Boolean
		{
			return this.zoomEnabled && this.maxDepth >= 0;
		}
		
		protected function isDepthVisible(depth:int):Boolean
		{
			if(!this.isMaxDepthActive())
			{
				return true;
			}
			
			if(depth >= 0 && depth <= this.maxDepth)
			{
				return true;
			}
			
			return false;
		}
		
		protected function isDepthClosed(depth:int):Boolean
		{
			if(!this.isMaxDepthActive())
			{
				return false;
			}
			
			if(depth < this.maxDepth)
			{
				return false;
			}
			
			return true; 
		}
		
		/**
		 * @private
		 * Sets the correct renderer to the selected state and removes selection
		 * from any others.
		 */
		protected function commitSelection():void
		{	
			var itemRendererCount:int = this.itemRenderers.length;
			for(var i:int = 0; i < itemRendererCount; i++)
			{
				var renderer:ITreeMapItemRenderer = ITreeMapItemRenderer(this.itemRenderers[i]);
				renderer.selected = this.selectable && renderer.data === this._selectedItem;
				
				if(!renderer.selected && renderer is ITreeMapBranchRenderer)
				{
					renderer.selected = this.selectable && this.branchContainsChild(renderer.data, this._selectedItem);
				} 
			}
		}
		
		/**
		 * @private
		 * Determines the immediate parent branch for a given leaf.
		 */
		protected function getParentBranch(item:Object):Object
		{
			//use the stored item renderers to find the correct item
			var renderer:ITreeMapItemRenderer = this.itemToItemRenderer(item);
			var index:int = this.itemRenderers.indexOf(renderer);
			for(var i:int = index - 1; i >= 0; i--)
			{
				//we know the order in this.itemRenderers, so we can "cheat"
				var parentRenderer:ITreeMapBranchRenderer = this.itemRenderers[i] as ITreeMapBranchRenderer;
				if(parentRenderer && this.branchContainsChild(parentRenderer.data, item))
				{
					return parentRenderer.data;
				}
			}
			return null;
		}
	
		/**
		 * @private
		 * Determines if a branch contains a given leaf.
		 */
		protected function branchContainsChild(branch:Object, childToFind:Object):Boolean
		{
			//make sure we at least have a branch and that the child isn't null
			if(!childToFind || !dataDescriptor.isBranch(branch))
			{
				return false;
			}
			
			var children:ICollectionView = this.branchToChildren(branch);
			var iterator:IViewCursor = children.createCursor();
			while(!iterator.afterLast)
			{
				var child:Object = iterator.current;
				if(child === childToFind)
				{
					return true;
				}
				if(this.dataDescriptor.isBranch(child) && this.branchContainsChild(child, childToFind))
				{
					return true;
				}
				iterator.moveNext();
			}
			return false;
		}
		
	//--------------------------------------
	//  Protected Event Handlers
	//--------------------------------------
		
		/**
		 * @private
		 * Refreshes the view if the dataProvider changes.
		 */
		protected function collectionChangeHandler(event:CollectionEvent):void
		{
			this.dataProviderChanged = true;
			this.invalidateProperties();
			this.invalidateDisplayList();
		}
		
		/**
		 * @private
		 * Handles the clicking of a leaf. If selection is enabled, updates
		 * the selectedItem.
		 */
		protected function leafClickHandler(event:MouseEvent):void
		{
			var renderer:ITreeMapLeafRenderer = ITreeMapLeafRenderer(event.currentTarget);
			var leafEvent:TreeMapEvent = new TreeMapEvent(TreeMapEvent.LEAF_CLICK, renderer);
			this.dispatchEvent(leafEvent);
			
			if(this._selectable)
			{
				this.selectedItem = renderer.data;
				this.dispatchEvent(new Event(Event.CHANGE));
			}
		}
		
		/**
		 * @private
		 */
		protected function leafDoubleClickHandler(event:MouseEvent):void
		{
			var renderer:ITreeMapLeafRenderer = ITreeMapLeafRenderer(event.currentTarget);
			var leafEvent:TreeMapEvent = new TreeMapEvent(TreeMapEvent.LEAF_DOUBLE_CLICK, renderer);
			this.dispatchEvent(leafEvent);
		}
		
		/**
		 * @private
		 */
		protected function leafRollOverHandler(event:MouseEvent):void
		{
			var renderer:ITreeMapLeafRenderer = ITreeMapLeafRenderer(event.currentTarget);
			var leafEvent:TreeMapEvent = new TreeMapEvent(TreeMapEvent.LEAF_ROLL_OVER, renderer);
			this.dispatchEvent(leafEvent);
		}
		
		/**
		 * @private
		 */
		protected function leafRollOutHandler(event:MouseEvent):void
		{
			var renderer:ITreeMapLeafRenderer = ITreeMapLeafRenderer(event.currentTarget);
			var leafEvent:TreeMapEvent = new TreeMapEvent(TreeMapEvent.LEAF_ROLL_OUT, renderer);
			this.dispatchEvent(leafEvent);
		}
		
		/**
		 * @private
		 * Handles a zoom request from a branch.
		 */
		protected function branchZoomHandler(event:TreeMapEvent):void
		{
			if(!this.zoomEnabled)
			{
				return;
			}
			
			var renderer:ITreeMapBranchRenderer = ITreeMapBranchRenderer(event.target);
			
			var branchToZoom:Object = renderer.data;
			if(this.zoomedBranch != branchToZoom) //zoom in
			{
				if(this.zoomOutType == TreeMapZoomOutType.PREVIOUS)
				{
					this._zoomedBranches.push(branchToZoom);
				}
				else this._zoomedBranches = [branchToZoom];
			}
			else //zoom out
			{
				switch(this.zoomOutType)
				{
					case TreeMapZoomOutType.PREVIOUS:
					{
						this._zoomedBranches.pop();
						break;
					}
					case TreeMapZoomOutType.PARENT:
					{
						var parentBranch:Object = this.getParentBranch(branchToZoom);
						if(parentBranch)
						{
							this._zoomedBranches = [parentBranch];
							break;
						}
						
						this._zoomedBranches = [];
						break;
					}
					default: //FULL
					{
						this._zoomedBranches = [];
						break;
					}
				}
			}
			
			this.zoomChanged = true;
			this.invalidateProperties();
			this.invalidateDisplayList();
		}
	
		/**
		 * @private
		 * Handles a selection request from a branch.
		 */
		protected function branchSelectHandler(event:TreeMapEvent):void
		{
			if(this.branchesSelectable)
			{
				this.selectedItem = ITreeMapBranchRenderer(event.target).data;
				this.dispatchEvent(new Event(Event.CHANGE));
			}
		}
	}
}