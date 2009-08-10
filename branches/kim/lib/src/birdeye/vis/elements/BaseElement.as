/*  
 * The MIT License
 *
 * Copyright (c) 2008
 * United Nations Office at Geneva
 * Center for Advanced Visual Analytics
 * http://cava.unog.ch
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
 
package birdeye.vis.elements
{
	import birdeye.events.ElementDataItemsChangeEvent;
	import birdeye.vis.coords.Cartesian;
	import birdeye.vis.data.DataItemLayout;
	import birdeye.vis.elements.collision.StackElement;
	import birdeye.vis.interfaces.ICoordinates;
	import birdeye.vis.interfaces.IElement;
	import birdeye.vis.interfaces.IEnumerableScale;
	import birdeye.vis.interfaces.INumerableScale;
	import birdeye.vis.interfaces.IScale;
	import birdeye.vis.scales.BaseScale;
	import birdeye.vis.scales.MultiScale;
	
	import com.degrafa.GeometryGroup;
	import com.degrafa.IGeometry;
	import com.degrafa.IGraphic;
	import com.degrafa.Surface;
	import com.degrafa.core.IGraphicsFill;
	import com.degrafa.core.IGraphicsStroke;
	import com.degrafa.geometry.Circle;
	import com.degrafa.geometry.Geometry;
	import com.degrafa.geometry.RegularRectangle;
	import com.degrafa.paint.GradientStop;
	import com.degrafa.paint.LinearGradientFill;
	import com.degrafa.paint.SolidFill;
	import com.degrafa.paint.SolidStroke;
	
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.xml.XMLNode;
	
	import mx.collections.ArrayCollection;
	import mx.collections.CursorBookmark;
	import mx.collections.ICollectionView;
	import mx.collections.IViewCursor;
	import mx.collections.XMLListCollection;
	import mx.core.IFactory;
	import mx.core.IToolTip;
	import mx.events.ToolTipEvent;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;

	[Style(name="rendererSize",type="Number",inherit="no")]

	[Style(name="colors",type="Array",inherit="no")]

	[Style(name="gradientColors",type="Array",inherit="no")]
	[Style(name="gradientAlphas",type="Array",inherit="no")]

	[Style(name="fillColor",type="uint",inherit="no")]
	[Style(name="fillAlpha",type="Number",inherit="no")]

	[Style(name="strokeColor",type="uint",inherit="yes")]
	[Style(name="strokeAlpha",type="Number",inherit="no")]
	[Style(name="strokeWeight",type="uint",inherit="no")]
	
	[Style(name="labelFont",type="String",inherit="no")]
	[Style(name="labelSize",type="uint",inherit="no")]
	[Style(name="labelColor",type="uint",inherit="no")]

	[Exclude(name="chart", kind="property")]
	[Exclude(name="cursor", kind="property")]
	
	public class BaseElement extends Surface implements IElement
	{
		protected var _invalidatedElementGraphic:Boolean = false;
		
		private var _chart:ICoordinates;
		public function set chart(val:ICoordinates):void
		{
			_chart = val;
			invalidateProperties();
		}
		public function get chart():ICoordinates
		{
			return _chart;
		}
		
		private var _filter1:*;
		/** Implement filtering for data values on dim1. The filter can be a String an Array or a 
		 * function.*/
		public function set filter1(val:*):void
		{
			_filter1 = val;
			invalidatingDisplay();
		}

		private var _filter2:*;
		/** Implement filtering for data values on dim2. The filter can be a String an Array or a 
		 * function.*/
		public function set filter2(val:*):void
		{
			_filter2 = val;
			invalidatingDisplay();
		}

		public static const HORIZONTAL:String = "horizontal";
		public static const VERTICAL:String = "vertical";
		private var _collisionScale:String;
		/** Set the scale that defines the 'direction' of the stack. For ex. BarElements are stacked horizontally with 
		 * stack100 and vertically with normal stack. Columns (for both polar and cartesians)
		 * are stacked vertically with stack100, and horizontally for normal stack.*/
		public function set collisionScale(val:String):void
		{
			_collisionScale = val;
			invalidateProperties();
			invalidatingDisplay();
		}
		public function get collisionScale():String
		{
			return _collisionScale;
		}
		
		protected var _showFieldName:Boolean = false;
		public function set showFieldName(val:Boolean):void
		{
			_showFieldName = val;
			invalidatingDisplay();
		}
		public function get showFieldName():Boolean
		{
			return _showFieldName;
		}

		protected var _showItemRenderer:Boolean = false;
		[Inspectable(enumeration="true,false")]
		public function set showItemRenderer(val:Boolean):void
		{
			_showItemRenderer = val;
			invalidatingDisplay();
		}

		protected var _rendererSize:Number = 5;
		public function set rendererSize(val:Number):void
		{
			_rendererSize = val;
			invalidatingDisplay();
		}

		protected var _extendMouseEvents:Boolean = false;
		[Inspectable(enumeration="true,false")]
		public function set extendMouseEvents(val:Boolean):void
		{
			_extendMouseEvents = val;
			invalidatingDisplay();
		}
		
		protected var _showAllDataItems:Boolean = false;
		[Inspectable(enumeration="true,false")]
		public function set showAllDataItems(val:Boolean):void
		{
			_showAllDataItems = val;
			invalidatingDisplay();
		}

		protected var _showTipGeometry:Boolean = true;
		[Inspectable(enumeration="true,false")]
		public function set showTipGeometry(val:Boolean):void
		{
			_showTipGeometry = val;
			invalidatingDisplay();
		}

		private var _colorScale:INumerableScale;
		/** Define an axis to set the colorField for data items.*/
		public function set colorScale(val:INumerableScale):void
		{
			_colorScale = val;
			_colorScale.format = false;

			invalidatingDisplay();
		}
		public function get colorScale():INumerableScale
		{
			return _colorScale;
		}

		private var _sizeScale:INumerableScale;
		/** Define a scale to set the sizeField for data items.*/
		public function set sizeScale(val:INumerableScale):void
		{
			_sizeScale = val;
			_sizeScale.format = false;

			invalidatingDisplay();
		}
		public function get sizeScale():INumerableScale
		{
			return _sizeScale;
		}


		private var _dim1:Object;
		public function set dim1(val:Object):void
		{
			_dim1= val;
			invalidateProperties();
			invalidatingDisplay();
		}
		public function get dim1():Object
		{
			return _dim1;
		}
		
		private var _dim2:Object;
		public function set dim2(val:Object):void
		{
			_dim2= val;
			invalidateProperties();
			invalidatingDisplay();
		}
		public function get dim2():Object
		{
			return _dim2;
		}

		private var _dim3:String;
		public function set dim3(val:String):void
		{
			_dim3= val;
			invalidateProperties();
			invalidatingDisplay();
		}
		public function get dim3():String
		{
			return _dim3;
		}

		private var _scale1:IScale;
		public function set scale1(val:IScale):void
		{
			_scale1 = val;				

			invalidateProperties();
			invalidatingDisplay();
		}
		public function get scale1():IScale
		{
			return _scale1;
		}
		
		private var _scale2:IScale;
		public function set scale2(val:IScale):void
		{
			_scale2 = val;
			

/* 			if POLAR
			if (val is IScaleUI && IScaleUI(_scale2).placement != BaseScale.HORIZONTAL_CENTER 
								&& IScaleUI(_scale2).placement != BaseScale.VERTICAL_CENTER)
				IScaleUI(_scale2).placement = BaseScale.HORIZONTAL_CENTER;
 			if CARTESIAN
 			if (_scale2.placement != BaseScale.LEFT && _scale2.placement != BaseScale.RIGHT)
				_scale2.placement = BaseScale.LEFT;
 */			

			invalidateProperties();
			invalidatingDisplay();
		}
		public function get scale2():IScale
		{
			return _scale2;
		}
		
		private var _scale3:IScale;
		public function set scale3(val:IScale):void
		{
			_scale3 = val;

			invalidateProperties();
			invalidatingDisplay();
		}
		public function get scale3():IScale
		{
			return _scale3;
		}
		
		protected var _maxDim1Value:Number = NaN;
		public function get maxDim1Value():Number
		{
			if (! (scale1 is IEnumerableScale) && isNaN(_maxDim1Value))
				_maxDim1Value = getMaxValue(dim1);
			return _maxDim1Value;
		}

		protected var _maxDim2Value:Number = NaN;
		public function get maxDim2Value():Number
		{
			if (! (scale2 is IEnumerableScale) && isNaN(_maxDim2Value))
				_maxDim2Value = getMaxValue(dim2);
			return _maxDim2Value;
		}

		protected var _minDim1Value:Number = NaN;
		public function get minDim1Value():Number
		{
			if (! (scale1 is IEnumerableScale) && isNaN(_minDim1Value))
				_minDim1Value = getMinValue(dim1);
			return _minDim1Value;
		}

		protected var _minDim2Value:Number = NaN;
		public function get minDim2Value():Number
		{
			if (! (scale2 is IEnumerableScale) && isNaN(_minDim2Value))
				_minDim2Value = getMinValue(dim2);
			return _minDim2Value;
		}

		protected var _maxDim3Value:Number = NaN;
		public function get maxDim3Value():Number
		{
			if (! (scale3 is IEnumerableScale) && isNaN(_maxDim3Value))
				_maxDim3Value = getMaxValue(dim3);
			return _maxDim3Value;
		}

		private var _minDim3Value:Number = NaN;
		public function get minDim3Value():Number
		{
			if (! (scale3 is IEnumerableScale) && isNaN(_minDim3Value))
				_minDim3Value = getMinValue(dim3);
			return _minDim3Value;
		}

		private var _totalDim1PositiveValue:Number = NaN;
		public function get totalDim1PositiveValue():Number
		{
			if (! (scale1 is IEnumerableScale) && isNaN(_totalDim1PositiveValue))
				_totalDim1PositiveValue = getTotalPositiveValue(dim1);
			return _totalDim1PositiveValue;
		}
		
		protected var _maxColorValue:Number = NaN;
		public function get maxColorValue():Number
		{
			_maxColorValue = getMaxValue(colorField);
			return _maxColorValue;
		}

		private var _minColorValue:Number = NaN;
		public function get minColorValue():Number
		{
			_minColorValue = getMinValue(colorField);
			return _minColorValue;
		}

		private var _colorField:String;
		public function set colorField(val:String):void
		{
			_colorField = val;
			invalidatingDisplay();
		}
		public function get colorField():String
		{
			return _colorField;
		}

		protected var _maxSizeValue:Number = NaN;
		public function get maxSizeValue():Number
		{
			_maxSizeValue = getMaxValue(_sizeField);
			return _maxSizeValue;
		}

		private var _minSizeValue:Number = NaN;
		public function get minSizeValue():Number
		{
			_minSizeValue = getMinValue(_sizeField);
			return _minSizeValue;
		}

		private var _sizeField:Object;
		public function set sizeField(val:Object):void
		{
			_sizeField = val;
			invalidatingDisplay();
		}
		public function get sizeField():Object
		{
			return _sizeField;
		}

		private var _labelField:String;
		public function set labelField(val:String):void
		{
			_labelField = val;
			invalidatingDisplay();
		}
		public function get labelField():String
		{
			return _labelField;
		}

		private var _multiScale:MultiScale;
		public function set multiScale(val:MultiScale):void
		{
			_multiScale = val;
			invalidateProperties();
			invalidatingDisplay();
		}
		public function get multiScale():MultiScale
		{
			return _multiScale;
		}

		protected var _collisionType:String = StackElement.OVERLAID;
		/** Define the type of collisions in case the dimN involves more than one data.*/
		[Inspectable(enumeration="overlaid,stacked,stacked100")]
		public function set collisionType(val:String):void
		{
			_collisionType = val;
			invalidateDisplayList();
		}
		public function get collisionType():String
		{
			return _collisionType;
		}

		protected var gg:GeometryGroup;
//		protected var dataItems:Array = [];
		protected var fill:IGraphicsFill;
		protected var stroke:IGraphicsStroke = new SolidStroke(0x888888,1,1);
		
		protected var invalidatedData:Boolean = false;
		private var _cursor:IViewCursor;
		protected var _dataProvider:Object=null;
		/** Set the data provider for the series, if the series doesn't have its own dataProvider
		 * than it will automatically take the chart data provider. It's not necessary
		 * to specify the chart data provider, and it's recommended not to do it. */
		public function set dataProvider(value:Object):void
		{
			//_dataProvider = value;
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
				if(XMLList(value).children().length()>0){
					value = new XMLListCollection(value.children() as XMLList);
				}else{
					value = new XMLListCollection(value as XMLList);
				}
			}
			else if(value is Array)
			{
				value = new ArrayCollection(value as Array);
			}
			
			if(value is XML)
			{
				var list:XMLList = new XMLList();
				list += value;
				this._dataProvider = new XMLListCollection(list.children());
			}
			//if already a collection dont make new one
	        else if(value is ICollectionView)
	        {
	            this._dataProvider = ICollectionView(value);
	        }else if(value is Object)
			{
				// convert to an array containing this one item
				this._dataProvider = new ArrayCollection( [value] );
	  		}
	  		else
	  		{
	  			this._dataProvider = new ArrayCollection();
	  		}

	  		if (ICollectionView(_dataProvider).length > 0)
	  		{
		  		_cursor = ICollectionView(_dataProvider).createCursor();
		  		
		  		// in case the chart is cartesian, we must invalidate 
		  		// also the chart properties and display list
		  		// to let the chart update with the element data provider change. in fact
		  		// the element dataprovider modifies the chart data and axes properties
		  		// therefore it modifies the chart properties and displaying
		  		if (chart is Cartesian)
		  		{
			  		Cartesian(chart).axesFeeded = false;
			  		Cartesian(chart).invalidateProperties();
			  		Cartesian(chart).invalidateDisplayList();
		  		}

	  			invalidatedData = true;
		  		invalidateSize();
		  		invalidateProperties();
				invalidatingDisplay();
	  		}
		}		
		/**
		* Set the dataProvider to feed the chart. 
		*/
		public function get dataProvider():Object
		{
			return _dataProvider;
		}
		
		protected var _dataItems:Vector.<Object>;

		public function set dataItems(items:Vector.<Object>):void
		{
			const oldVal:Vector.<Object> = _dataItems;
			if (items !== oldVal) {
				_dataItems = items;
				_maxDim1Value = _maxDim2Value = _maxDim3Value = _totalDim1PositiveValue = NaN;
				_minDim1Value = _minDim2Value = _minDim3Value = NaN;
				_minColorValue = _maxColorValue = _minSizeValue = _maxSizeValue = NaN;
				dispatchEvent(new ElementDataItemsChangeEvent(this, oldVal, items));
				invalidateProperties();
				invalidatingDisplay();
			}
		}

		public function get dataItems():Vector.<Object>
		{
			return _dataItems;
		}
		
		protected var _size:Number = 5;
		public function set size(val:Number):void
		{
			_size = val;
			invalidatingDisplay();
		}

		protected var _hitAreaSize:Number = 5;
		public function set hitAreaSize(val:Number):void
		{
			_hitAreaSize = val;
			invalidatingDisplay();
		}
		
		private var _randomColors:Boolean = false;
		[Inspectable(enumeration="true,false")]
		public function set randomColors(val:Boolean):void
		{
			_randomColors = val;
			invalidatingDisplay();
		}
		public function get randomColors():Boolean
		{
			return _randomColors;
		}
		
		private var _alphaFill:Number;
		/** Set the fill alpha.*/
		public function set alphaFill(val:Number):void
		{
			_alphaFill = val;
			invalidatingDisplay();
		}
		public function get alphaFill():Number
		{
			return _alphaFill;
		}
		
		private var _alphaStroke:Number;
		/** Set the stroke alpha.*/
		public function set alphaStroke(val:Number):void
		{
			_alphaStroke = val;
			invalidatingDisplay();
		}
		public function get alphaStroke():Number
		{
			return _alphaStroke;
		}

		private var _colorFill:Number;
		/** Set the fill color to be used for data items.*/
		public function set colorFill(val:Number):void
		{
			_colorFill = val;
			invalidatingDisplay();
		}
		public function get colorFill():Number
		{
			return _colorFill;
		}

		protected var _colorStroke:Number;
		/** Set the stroke color to be used for the data items.*/
		public function set colorStroke(val:Number):void
		{
			_colorStroke = val;
			invalidatingDisplay();
		}
		public function get colorStroke():Number
		{
			return _colorStroke;
		}
		
		protected var _weightStroke:Number;
		/** Set the stroke color to be used for the data items.*/
		public function set weightStroke(val:Number):void
		{
			_weightStroke = val;
			invalidatingDisplay();
		}
		public function get weightStroke():Number
		{
			return _weightStroke;
		}

		protected var _colors:Array;

		protected var _colorGradients:Array;
		/** Set the gradientColors to be used for the data items.*/
		public function set colorGradients(val:Array):void
		{
			_colorGradients = val;
			invalidatingDisplay();
		}
		public function get colorGradients():Array
		{
			return _colorGradients;
		}

		protected var _alphaGradients:Array;
		/** Set the gradientAlphas to be used for the data items.*/
		public function set alphaGradients(val:Array):void
		{
			_alphaGradients = val;
			invalidatingDisplay();
		}
		public function get alphaGradients():Array
		{
			return _alphaGradients;
		}

		protected var _fontLabel:String;
		/** Set the gradientAlphas to be used for the data items.*/
		public function set fontLabel(val:String):void
		{
			_fontLabel = val;
			invalidatingDisplay();
		}
		public function get fontLabel():String
		{
			return _fontLabel;
		}

		protected var _sizeLabel:Number;
		/** Set the gradientAlphas to be used for the data items.*/
		public function set sizeLabel(val:Number):void
		{
			_sizeLabel = val;
			invalidatingDisplay();
		}
		public function get sizeLabel():Number
		{
			return _sizeLabel;
		}

		protected var _colorLabel:Number;
		/** Set the gradientAlphas to be used for the data items.*/
		public function set colorLabel(val:Number):void
		{
			_colorLabel = val;
			invalidatingDisplay();
		}
		public function get colorLabel():Number
		{
			return _colorLabel;
		}

		protected var _sizeRenderer:uint;
		/** Set the _sizeRenderer to be used for the data items.*/
		public function set sizeRenderer(val:uint):void
		{
			_sizeRenderer = val;
			invalidatingDisplay();
		}
		public function get sizeRenderer():uint
		{
			return _sizeRenderer;
		}

		private var _mouseDoubleClickFunction:Function;
		/** Set the function that should be used when a mouse double click event is triggered.
		 * This function must accept an DataItemLayout as input value.
		 * The DataItemLayout object contains all information about the data value
		 * that has been clicked, particularly, its x-y-z coordinates, its data item, 
		 * it's positioning over the axes, its fills and strokes....*/
		public function set mouseDoubleClickFunction(val:Function):void
		{
			_mouseDoubleClickFunction = val;
		}
		public function get mouseDoubleClickFunction():Function
		{
			return _mouseDoubleClickFunction;
		}

		private var _mouseClickFunction:Function;
		/** Set the function that should be used when a mouse click event is triggered.
		 * This function must accept an DataItemLayout as input value.
		 * The DataItemLayout object contains all information about the data value
		 * that has been clicked, particularly, its x-y-z coordinates, its data item, 
		 * it's positioning over the axes, its fills and strokes....*/
		public function set mouseClickFunction(val:Function):void
		{
			_mouseClickFunction = val;
		}
		public function get mouseClickFunction():Function
		{
			return _mouseClickFunction;
		}
		
		private var _mouseOverFunction:Function;
		/** Set the function that should be used when a mouse over event is triggered.
		 * This function must accept an DataItemLayout as input value.
		 * The DataItemLayout object contains all information about the data value
		 * that has been clicked, particularly, its x-y-z coordinates, its data item, 
		 * it's positioning over the axes, its fills and strokes....*/
		public function set mouseOverFunction(val:Function):void
		{
			_mouseOverFunction = val;
		}
		public function get mouseOverFunction():Function
		{
			return _mouseOverFunction ;
		}
		
		private var _mouseOutFunction:Function;
		/** Set the function that should be used when a roll out event is triggered.
		 * This function must accept an DataItemLayout as input value.
		 * The DataItemLayout object contains all information about the data value
		 * that has been clicked, particularly, its x-y-z coordinates, its data item, 
		 * it's positioning over the axes, its fills and strokes....*/
		public function set mouseOutFunction(val:Function):void
		{
			_mouseOutFunction = val;
		}
		public function get mouseOutFunction():Function
		{
			return _mouseOutFunction ;
		}

		private var _displayName:String;
		/** Set the display name to be used for the legend.*/
		public function set displayName(val:String):void
		{
			_displayName= val;
		}
		public function get displayName():String
		{
			return _displayName;
		}
		
		private var _itemRenderer:IFactory;
		/** Set the item renderer to be used for both data items layout and related legend item.*/
		public function set itemRenderer(val:IFactory):void
		{
			_itemRenderer = val;
			invalidateProperties();
			invalidatingDisplay();
		}
		public function get itemRenderer():IFactory
		{
			return _itemRenderer;
		}
		
		protected var _source:Object;
		public function set source(val:Object):void
		{
			_source = val;
			invalidatingDisplay();
		}
		public function get source():Object
		{
			return _source;
		}
		
		private var _index:Number;
		public function set index(val:Number):void
		{
			_index = val;
		}

		public function get index():Number
		{
			return _index;
		}
		
		// UIComponent flow

		public function BaseElement()
		{
			super();
			collisionScale = VERTICAL;
		}

		override protected function createChildren():void
		{
			super.createChildren();
			createGlobalGeometryGroup();
		}
		
		protected function createGlobalGeometryGroup():void {
			// gg will be the GeometryGroup that will store the global series geometries
			// All hit area will be put in ttGeom
			// this increases performances in case the user doesn't set
			// showDataTips to true in the parent chart or interactive functions
			// Being gg a data item layout, it's still possible to add interactivity to gg
			// in this case there will be a gg instance for each data item 
			// if it's a 3D chart (apart from area and line series), 
			// than gg will be instantiated for each triple of datavalues
			gg = new DataItemLayout();
			gg.target = this;
			graphicsCollection.addItem(gg);
		}

		override protected function commitProperties():void
		{
			super.commitProperties();

			if (invalidatedData && _cursor)
				loadElementsValues();
			
			// since we use Degrafa, the background is needed in the element
			// to allow events for tooltips all over the element.
			// tooltips are triggered by ttGG objects. 
			// if showdatatips is true all interactivity events are triggered and
			// managed through ttGG.
			
			// if showDataTips is false than it's still possible to manage 
			// interactivity events thourgh gg, but in this case we must 
			// remove the background to allow these interactivities, since gg is at the element
			// level and not the chart one. if we don't remove the background, gg
			// belonging to other element could be covered by the background and 
			// interactivity becomes impossible
			// therefore background is created only if showDataTips is true
			if (chart && chart.customTooltTipFunction!=null && chart.showDataTips && !tooltipCreationListening)
			{
				initCustomTip();
			}
		}
		
		private var prevWidth:Number = NaN, prevHeight:Number = NaN;
		// Override updateDisplayList() to update the component
		// based on the style setting.
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void 
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
 
			if (_invalidatedElementGraphic)
				drawElement();
 		}

		// other methods

		private function loadElementsValues():void
		{
			_cursor.seek(CursorBookmark.FIRST);
			const items:Vector.<Object> = new Vector.<Object>;
			var j:uint = 0;
			while (!_cursor.afterLast)
			{
				items[j++] = _cursor.current;
				_cursor.moveNext();
			}
			dataItems = items;
		}

		/**
		* @Private 
		 * Triggered when a value is assigned to the UIComponent tooltip (String), 
		 * and the event target is the tooltip created during the assignement.
		 * Here we can change the created tooltip with a custom one.*/
		private function onTTCreate(e:ToolTipEvent):void
		{
			e.toolTip = myTT;
		}
		
		protected function invalidatingDisplay():void
		{
			_invalidatedElementGraphic = true;
			invalidateDisplayList();
		}
		
		public function draw():void
		{
			if (prevWidth != unscaledWidth || prevHeight != unscaledHeight)
			{
				prevWidth = unscaledWidth;
				prevHeight = unscaledHeight;
				_invalidatedElementGraphic = true;
			}
			
			if (_invalidatedElementGraphic)
				drawElement();
		}
		
		protected var dataFields:Array;
		public function drawElement():void
		{
			_invalidatedElementGraphic = false;
			
			dataFields = [];
			// prepare data for a standard tooltip message in case the user
			// has not set a dataTipFunction
			dataFields["dim1"] = dim1;
			dataFields["dim2"] = dim2;
			dataFields["dim3"] = dim3;
			dataFields["colorField"] = colorField;
			dataFields["sizeField"] = sizeField;

			if (stylesChanged)
			{
				// Redraw gradient fill only if style changed.
				if (!_colors)
					_colors = getStyle("colors");

				if (!_colorGradients)
					_colorGradients = getStyle("gradientColors");
				if (!_alphaGradients)
					_alphaGradients = getStyle("gradientAlphas");
				
				if (isNaN(_colorFill))
					_colorFill = getStyle("fillColor");
				if (!_alphaFill)
					_alphaFill = getStyle("fillAlpha");
				
				if (isNaN(_colorStroke))
					_colorStroke = getStyle("strokeColor");
				
				if (isNaN(_alphaStroke))
					_alphaStroke = getStyle("strokeAlpha");
				
				if (isNaN(_weightStroke))
					_weightStroke = getStyle("strokeWeight");

				if (!_fontLabel)
					_fontLabel = getStyle("labelFont");

				if (isNaN(_colorLabel))
					_colorLabel = getStyle("labelColor");

				if (isNaN(_sizeLabel))
					_sizeLabel = getStyle("labelSize");

				if (isNaN(_sizeRenderer))
					_sizeRenderer = getStyle("rendererSize");

 				stylesChanged = false;
			}

			if (colorGradients)
			{
				fill = new LinearGradientFill();
				var grStop:GradientStop = new GradientStop(colorGradients[0])
				grStop.alpha = alphaGradients[0];
				var g:Array = new Array();
				g.push(grStop);

				grStop = new GradientStop(colorGradients[1]);
				grStop.alpha = alphaGradients[1];
				g.push(grStop);

				LinearGradientFill(fill).gradientStops = g;
			} else if (!_colors)
				fill = new SolidFill(colorFill, alphaFill);
			
			stroke = new SolidStroke(colorStroke, alphaStroke, weightStroke);

			if (ggBackGround)
			{
				ggBackGround.target = this;
				rectBackGround.width = unscaledWidth;
				rectBackGround.height = unscaledHeight;
			}
			
			// to be overridden by each element implementation
		}
		
		protected function isReadyForLayout():Boolean
		{
			// verify than all element axes (or chart's if none owned by the element)
			// are ready. If they aren't the element can't be drawn, since data values
			// cannot be positioned yet in the axis.
			var axesCheck:Boolean = true;
			
			if (scale2)
			{
				if (scale2 is IEnumerableScale)
					axesCheck = Boolean(IEnumerableScale(scale2).dataProvider);
				
				axesCheck = axesCheck && (scale2.size>0);
			} 

			if (scale1)
			{
				if (scale1 is IEnumerableScale)
					axesCheck = axesCheck && Boolean(IEnumerableScale(scale1).dataProvider);

				axesCheck = axesCheck && (scale1.size>0);
			} 

			if ((multiScale && multiScale.scales) || (chart && chart.multiScale && chart.multiScale.scales))
				axesCheck = true;

			var colorsCheck:Boolean = 
				(fill || stroke || colorScale);

			var globalCheck:Boolean = 
				width>0 && height>0
				&& chart
				&& dataItems;
			
			return globalCheck && axesCheck && colorsCheck;
		}


		/** @Private 
		 * Custom tooltip variable.*/
		protected var myTT:IToolTip;
		/**
		* @private 
		 * Show/position tooltip and handle custom mouse over function.*/
		protected function handleRollOver(e:MouseEvent):void 
		{
			var extGG:DataItemLayout = DataItemLayout(e.target);

			if (chart.showDataTips) {
				if (chart.customTooltTipFunction != null)
				{
					myTT = chart.customTooltTipFunction(extGG);
		 			toolTip = myTT.text;
				} else {
					extGG.showToolTip();
					showGeometryTip(extGG);
				}
			}

			/*var tmpDim1:String;
				if (dim1 is Array)
					tmpDim1 = dim1[extGG.collisionTypeIndex];
				else 
					tmpDim1 = String(dim1);
				IScaleUI(scale1).pointerX = IScaleUI(scale1).getPosition(extGG.currentItem[tmpDim1]);
				IScaleUI(scale1).pointer.visible = true;
			}
			
			if (scale2 && scale2 is IScaleUI && IScaleUI(scale2).pointer && chart.coordType == VisScene.CARTESIAN)
			{
				var tmpDim2:String;
				if (dim2 is Array)
					tmpDim2 = dim2[extGG.collisionTypeIndex];
				else 
					tmpDim2 = String(dim2);
				IScaleUI(scale2).pointerY = IScaleUI(scale2).getPosition(extGG.currentItem[tmpDim2]);
				IScaleUI(scale2).pointer.visible = true;
			} 

			if (scale3 && scale3 is IScaleUI && IScaleUI(scale3).pointer && chart.coordType == VisScene.CARTESIAN)
			{
				IScaleUI(scale3).pointerY = extGG.posZ;
				IScaleUI(scale3).pointer.visible = true;
			}*/
			
			if (_mouseOverFunction != null)
				_mouseOverFunction(extGG);
		}

		/**
		* @private 
		 * Destroy/hide tooltip 
		 * 
		*/
		protected function handleRollOut(e:MouseEvent):void
		{ 
			var extGG:DataItemLayout = 	DataItemLayout(e.target);
			if (chart.showDataTips)
			{
				extGG.hideToolTip();
				hideGeometryTip(extGG);
				
				myTT = null;
				toolTip = null;
			}

			/*if (scale1 && scale1 is IAxis && IAxis(scale1).pointer)
				IAxis(scale1).pointer.visible = false;

			if (scale2 && scale2 is IAxis && IAxis(scale2).pointer)
				IAxis(scale2).pointer.visible = false;

			if (scale3 && scale3 is IAxis && IAxis(scale3).pointer)
				IAxis(scale3).pointer.visible = false;*/

			if (_mouseOutFunction != null)
				_mouseOutFunction(extGG);
		}
		
		
		/**
		* Show the tooltip shape associated to this DataItemLayout. 
		*/
		private function showGeometryTip(extGG:DataItemLayout):void
		{
			if (_showTipGeometry && !_showAllDataItems)
			{
				Geometry(extGG.hitMouseArea).alpha = 1;

			}		
		}
		
		/**
		* Hide the tooltip shape associated to this DataItemLayout. 
		*/
		private function hideGeometryTip(extGG:DataItemLayout):void
		{
			if (_showTipGeometry && !_showAllDataItems)
			{
				Geometry(extGG.hitMouseArea).alpha = 0;
			}
		}

		/** @Private
		 * Sort the surface elements according their z position.*/ 
		protected function zSort():void
		{
			var sortLayers:Array = new Array();
			var nChildren:int = numChildren;
			for(var i:int = 0; i < nChildren; i++) 
			{
				var child:* = getChildAt(0); 
				var zPos:uint = DataItemLayout(child).z;
				sortLayers.push([zPos, child]);
				removeChildAt(0);
			}
			// sort them and add them back
			sortLayers.sortOn("0", Array.NUMERIC);
			for (i = 0; i < nChildren; i++) 
				addChild(sortLayers[i][1]);
		}

		public var hitAreaFunction:Function;
		protected function createMouseHitArea(xPos:Number, yPos:Number, size:Number):IGeometry 
		{
			if (hitAreaFunction != null)
				return hitAreaFunction(xPos, yPos, size);
			else {
				var geom:Circle = new Circle(xPos, yPos, size); 
				geom.fill = fill;
				geom.stroke = stroke;
				
				if (!_showAllDataItems)
					geom.alpha = 0;

				return geom;
			}
		}
		
		protected var ggIndex:Number;
		/** @Private
		 * Override the creation of ttGeom in order to avoid the usage of gg also in case
		 * the showdatatips is false. In that case there will only be 1 instance of gg in the 
		 * AreaElement, thus improving performances.*/ 
		protected function createTTGG(item:Object, dataFields:Array, xPos:Number, yPos:Number, 
									zPos:Number, radius:Number, collisionIndex:Number = NaN, shapes:Array = null /* of IGeometry */, 
									ttXoffset:Number = NaN, ttYoffset:Number = NaN, showGeometry:Boolean = true):void
		{
			if (graphicsCollection.items && graphicsCollection.items.length > ggIndex)
				ttGG = graphicsCollection.items[ggIndex];
			else {
				ttGG = new DataItemLayout();
				graphicsCollection.addItem(ttGG);
			}
			ggIndex++;
			ttGG.target = chart.elementsContainer;
			ttGG.addEventListener(MouseEvent.ROLL_OVER, handleRollOver);
			ttGG.addEventListener(MouseEvent.ROLL_OUT, handleRollOut);
			
			ttGG.hitMouseArea = createMouseHitArea(xPos, yPos, _hitAreaSize);
			
 			if (chart.showDataTips || chart.showAllDataTips)
			{ 
				initGGToolTip();
				ttGG.create(item, dataFields, xPos, yPos, zPos, radius, collisionIndex, shapes, ttXoffset, ttYoffset, true, showGeometry);
			} else if (mouseClickFunction!=null || mouseDoubleClickFunction!=null)
			{
				// if no tips but interactivity is required than add roll over events and pass
				// data and positioning information about the current data item 
				ttGG.create(item, dataFields, xPos, yPos, zPos, NaN,collisionIndex,  null, NaN, NaN, false);
			} else {
				// if no tips and no interactivity than just add location info needed for pointers
				ttGG.create(null, null, xPos, yPos, zPos, NaN,collisionIndex, null, NaN, NaN, false);
			}

			if (chart.showAllDataTips)
			{
				ttGG.showToolTip();
			} 

			if (mouseClickFunction != null)
				ttGG.addEventListener(MouseEvent.CLICK, onMouseClick);

			if (mouseDoubleClickFunction != null)
				ttGG.addEventListener(MouseEvent.DOUBLE_CLICK, onMouseDoubleClick);
		}
		
		/** @Private
		 * Override the init initGGToolTip in order to avoid the usage of gg also in case
		 * the showdatatips is false. In that case there will only be 1 instance of gg in the 
		 * element, thus improving performances.*/ 
		protected function initGGToolTip():void
		{
			ttGG.toolTipFill = fill;
			ttGG.toolTipStroke = stroke;
 			if (chart.dataTipFunction != null)
				ttGG.dataTipFunction = chart.dataTipFunction;
			if (chart.dataTipPrefix!= null)
				ttGG.dataTipPrefix = chart.dataTipPrefix;
		}

		private var stylesChanged:Boolean = true;
		initializeStyles();
		public static function initializeStyles():void
		{
			var selector:CSSStyleDeclaration = StyleManager.getStyleDeclaration("BaseElement");
			if(!selector)
			{
				selector = new CSSStyleDeclaration();
			}
			selector.defaultFactory = function():void
			{
				this.gradientColors = null;
				this.gradientAlphas = [0.5, 0.5];

				this.fillColor = 0x000000;
				this.fillAlpha = 1;

				this.strokeColor = 0x111111;
				this.strokeAlpha = 1;
				this.strokeWeight = 1;

				this.labelFont = "verdana";
				this.labelSize = 9;
				this.labelColor = 0x000000;
				
				this.rendererSize = 10;

				this.stylesChanged = true;
			} 
			StyleManager.setStyleDeclaration("BaseElement", selector, true);
		}
		
		// Override the styleChanged() method to detect changes in your new style.
		override public function styleChanged(styleProp:String):void 
		{
			super.styleChanged(styleProp);
			// Check to see if style changed.
			switch(styleProp)
			{
				case "gradientColors":
				case "gradientAlphas":
				case "fillColor":
				case "fillAlpha":
				case "strokeColor":
				case "strokeAlpha":
				case "strokeWeight":
				case "labelFont":
				case "labelSize":
				case "labelColor":
					invalidateDisplayList();
				break;
			} 
		}
		
		private var currentValue:Number;
		protected function getTotalPositiveValue(field:Object):Number
		{
			var tot:Number = NaN;
			if (dataItems && field)
			{
				var currentItem:Object;
			
				for (var cursIndex:uint = 0; cursIndex<dataItems.length; cursIndex++)
				{
					currentItem = dataItems[cursIndex];
					var tmpArray:Array = (dim1 is Array) ? dim1 as Array : [String(dim1)];
					
					for (var i:Number = 0; i<tmpArray.length; i++)
					{
						currentValue = currentItem[tmpArray[i]];
						if (currentValue > 0)
						{
							if (isNaN(tot))
								tot = currentValue;
							else
								tot += currentValue;
						}
					}
				}
			}
			return tot;
		}

		protected function getMinValue(field:Object):Number
		{
			var min:Number = NaN;

			if (field is Array)
			{
				var dims:Array = field as Array
				for (var i:Number = 0; i< dims.length; i++)
				{
					var tmpMin:Number = getMinV(dims[i]);
					if (isNaN(min))
						min = tmpMin;
					else 
						min = Math.min(min, tmpMin);
				}
			} else 
				min = getMinV(String(field));

			return min;
		}

		protected function getMaxValue(field:Object):Number
		{
			var max:Number = NaN;
			if (field is Array)
			{
				var dims:Array = field as Array
				for (var i:Number = 0; i< dims.length; i++)
				{
					var tmpMax:Number = getMaxV(dims[i]);
					if (isNaN(max))
						max = tmpMax;
					else {
						if (collisionType == StackElement.STACKED100)
							max += Math.max(0,tmpMax);
						else 
							max = Math.max(max, tmpMax);
					}
				}
			} else 
				max = getMaxV(String(field));

			return max;
		}
		
		private function getMaxV(field:String):Number
		{
			var max:Number = NaN;
			if (dataItems && field)
			{
				var currentItem:Object;
			
				for (var cursIndex:uint = 0; cursIndex<dataItems.length; cursIndex++)
				{
					currentItem = dataItems[cursIndex];

					currentValue = currentItem[field];
					if (isNaN(max) || max < currentValue)
						max = currentValue;
				}
			}
			return max
		}

		private function getMinV(field:String):Number
		{
			var min:Number = NaN;

			if (dataItems && field)
			{
				var currentItem:Object;
			
				for (var cursIndex:uint = 0; cursIndex<dataItems.length; cursIndex++)
				{
					currentItem = dataItems[cursIndex];

					currentValue = currentItem[field];
					if (isNaN(min) || min > currentValue)
						min = currentValue;
				}
			}
			return min;
		}

		/** Remove all graphic elements of the series.*/
		public function removeAllElements():void
		{
 			// Iterating backwards here is essential, because during the 
 			// iteration we are modifying the collection we are iterating over.
 			var i:int;
			for (i = graphicsCollection.items.length - 1; i >= 0; i--) {
				const item:IGraphic = graphicsCollection.items[i];
				if (item is DataItemLayout) {
					item.removeEventListener(MouseEvent.ROLL_OVER, handleRollOver);
					item.removeEventListener(MouseEvent.ROLL_OUT, handleRollOut);
					item.removeEventListener(MouseEvent.DOUBLE_CLICK, onMouseDoubleClick);
					item.removeEventListener(MouseEvent.CLICK, onMouseClick);
					(item as DataItemLayout).removeAllElements();
				}
				graphicsCollection.removeItemAt(i);
			}
			for (i = numChildren - 1; i >= 0; i--) {
				removeChildAt(i);
			}
 		}

		protected var rectBackGround:RegularRectangle;
		protected var ggBackGround:GeometryGroup;
		protected var tooltipCreationListening:Boolean = false;
		/** @Private 
		 * Init the custom tooltip of the series in case showdatatips is true.*/
		protected function initCustomTip():void
		{
			addEventListener(ToolTipEvent.TOOL_TIP_CREATE, onTTCreate);
			toolTip = "";

			// background is needed on each series to allow custom tooltip events
			// all over the series space, mostly on those data items  
			// located at the border of the series or gg
			ggBackGround = new GeometryGroup();
			graphicsCollection.addItemAt(ggBackGround,0);
			rectBackGround = new RegularRectangle(0,0,0, 0);
			rectBackGround.fill = new SolidFill(0x000000,0);
			ggBackGround.geometryCollection.addItem(rectBackGround);
			
			// once this is true, the listener will not be added anymore
			tooltipCreationListening = true;
		}

		protected var ttGG:DataItemLayout;
		/** @Private
		 * Override the creation of ttGeom. This should be unified among polar and cartesian series.
		 * In order to improve performances in case the showdatatips is false
		 * the ttGG creation will not be called and there will be only 1 gg, unless
		 * interactivity is required or dim3 is not null and gg must be placed in the 3D space.*/ 
/* 		protected function createTTGG(item:Object, dataFields:Array, xPos:Number, yPos:Number, 
									zPos:Number, radius:Number, shapes:Array = null /* of IGeometry , 
									ttXoffset:Number = NaN, ttYoffset:Number = NaN):void
		{
			// override
		}
 */		
		/** @Private
		 * Init the ttGG after its creation.*/ 
/* 		protected function initGGToolTip():void
		{
			// override
		}
 */		
		/** Implement function to manage mouse click events.*/
		public function onMouseClick(e:MouseEvent):void
		{
			var target:DataItemLayout;
			if (e.target is DataItemLayout)
			{
				target = DataItemLayout(e.target);
				 
				_mouseClickFunction(target);
			}
		}

		/** Implement function to manage mouse double click events.*/
		public function onMouseDoubleClick(e:MouseEvent):void
		{
			var target:DataItemLayout;
			if (e.target is DataItemLayout)
			{
				target = DataItemLayout(e.target);
				 
				_mouseDoubleClickFunction(target);
			}
		}
			
		public function getFill():IGraphicsFill
		{
			return fill;
		}

		public function getStroke():IGraphicsStroke
		{
			return stroke;
		}
		
		protected function prepareForItemDisplayObjectsCreation():void {
			removeAllElements();
		
			if (_itemDisplayObjects) {
				for (var itemId:Object in _itemDisplayObjects) {
					_itemDisplayObjects[itemId] = null;
				}
			} else {
				_itemDisplayObjects = new Dictionary();
			}
		}

		private var _itemDisplayObjects:Dictionary;

		public function getItemDisplayObject(itemId:Object):DisplayObject {
			return _itemDisplayObjects[itemId];
		}

		/**
		 * @param itemId
		 * @param geometries Array of IGeometry objects 
		 **/
		protected function createItemDisplayObject(pos:Position, itemId:Object, geometries:Array):DisplayObject {
			var group:GeometryGroup = new GeometryGroup();
	        group.target = this;
	        group.geometry = geometries;
	        group.x = pos.pos1; 
	        group.y = pos.pos2; 
        	graphicsCollection.addItem(group);
	        _itemDisplayObjects[itemId] = group;
			return group;
		}

		public function refresh():void
		{
			// for the moment only overridden by PolygonElement
		}
		
		public function clone():*
		{
            var c:Class = this['constructor'] as Class; 
            var instance:Object = new c(); 
            
            var classInfo:XML = describeType(this); 
            // List the object's variables, their values, and their types. 
            for each ( var v:XML in classInfo..variable ) { 
            	if (this[v.@name])
                	instance[v.@name] = this[v.@name]; 
            } 

            // List accessors as properties. 
            for each ( var a:XML in classInfo..accessor ) { 
                // Do not user the property if it can't be read or written 
                if( a.@access == 'readwrite' || a.@access == 'write') { 
                    if (this[a.@name])
                    	instance[ a.@name ] = this[a.@name]; 
                } 

            } 

            return instance; 
		}
	}
}
