package birdeye.vis.coords
{
	import __AS3__.vec.Vector;
	
	import birdeye.vis.VisScene;
	import birdeye.vis.data.DataItemLayout;
	import birdeye.vis.elements.BaseElement;
	import birdeye.vis.elements.collision.StackElement;
	import birdeye.vis.interfaces.ICoordinates;
	import birdeye.vis.interfaces.IElement;
	import birdeye.vis.interfaces.IEnumerableScale;
	import birdeye.vis.interfaces.INumerableScale;
	import birdeye.vis.interfaces.IScale;
	import birdeye.vis.interfaces.IStack;
	import birdeye.vis.interfaces.guides.IAxis;
	import birdeye.vis.interfaces.guides.IGuide;
	import birdeye.vis.scales.BaseScale;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	public class BaseCoordinates extends VisScene implements ICoordinates
	{
		
		
		
		public function BaseCoordinates()
		{
		}
		
		protected var _type:String = StackElement.OVERLAID;
		/** Set the type of stack, overlaid if the series are shown on top of the other, 
		 * or stacked if they appear staked one after the other (horizontally), or 
		 * stacked100 if the columns are stacked one after the other (vertically).*/
		[Inspectable(enumeration="overlaid,stacked,stacked100")]
		public function set type(val:String):void
		{
			_type = val;
			invalidateProperties();
			invalidateDisplayList();
		}

		/** Array of elements, mandatory for any coords scene.
		 * Each element must implement the IElement interface which defines 
		 * methods that allow to set fields, basic styles, axes, dataproviders, renderers,
		 * max and min values, etc. Look at the IElement for more details.
		 * Each element can define its own axes, which will have higher priority over the axes
		 * that are provided by the dataProvider (a cartesian chart). In case no axes are 
		 * defined for the element, than those of the data provider are used. 
		 * The data provider (cartesian chart) axes values (min, max, etc) are calculated 
		 * based on the group of element that share them.*/
        [Inspectable(category="General", arrayType="birdeye.vis.interfaces.IElement")]
        [ArrayElementType("birdeye.vis.interfaces.IElement")]
		override public function set elements(val:Array):void
		{
			_elements = val;
			_elementsPlaced = false;
			
			invalidateProperties();
			invalidateDisplayList();
		}
		
		override protected function commitProperties():void
		{
			if (active)
			{
				super.commitProperties();
				
				// replace elements AND guides if one of them is not placed
				if (!_elementsPlaced || !_guidesPlaced)
				{
					removeAllElements();
					_elementsPlaced = false;
					_guidesPlaced = false;
				}
				
				nCursors = 0;
				
				if (guides && !_guidesPlaced)
				{
	trace(getTimer(), "placing guides");
					placeGuides();
					_guidesPlaced = true;
	trace(getTimer(), "END placing guides");
				}
				
				
				// data structure to count different type of stackable elements		
				var countStackableElements:Array = [];
				
				if (elements)
				{
		
					if (!_elementsPlaced)
					{
	trace(getTimer(), "placing elements");
						placeElements();
						_elementsPlaced = true;
	trace(getTimer(), "END placing elements");	
					}
	
								
					var nCursors:uint = initElements(countStackableElements);
					
					if (nCursors == elements.length)
					{
						trace(getTimer(), "DATA INVALIDATED");
						invalidatedData = true;
					}
					else
					{
						invalidatedData = false;
					}
				}
				
				if (invalidatedData)
				{
	trace(getTimer(), "stack elements");
					initStackElements(countStackableElements);
	trace(getTimer(), "END stack elements");
	
				
					if (!axesFeeded)
					{
	trace(getTimer(), "feeding scales");
						feedScales();
	trace(getTimer(), "END feeding scales");
					}
				}
			}
			
			
		}
		
		/**
		 * This function loops all guides,</br>
		 * init's each guide</br>
		 * and calls the <code>placeGuide</code> function.
		 */
		protected function placeGuides():void
		{
			for each (var guide:IGuide in guides)
			{
				guide.coordinates = this;
				
				placeGuide(guide);

			}
		}
		
		/**
		 * At this level the guide is told to draw to the elementsContainer</br>
		 * Override this function if more detailed placement of a guide is possible.</br>
		 */		
		protected function placeGuide(guide:IGuide):void
		{
			// at this level only the elementsContainer is known
			// so that's where let the guide draw itself
			if (guide.targets.lastIndexOf(elementsContainer) == -1)
			{
				guide.targets.push(elementsContainer);
			}			
		}
		
		// temporary data structure to keep track of stacked elements
		protected var _stackedElements:Array = [];
		/**
		 * This functions loops all elements,</br>
		 * init's each element (by calling <code>initElement</code>)</br>
		 * and places the element (by calling <code>placeElement</code>)</br>
		 */
		protected function placeElements():void
		{
			for each (var element:IElement in elements)
			{	
				placeElement(element);
			}
			
		}
		
		protected function initElements(countStackableElements:Array):uint
		{
			_stackedElements = [];
			var nCursors:uint = 0;
			for each (var element:IElement in elements)
			{
				nCursors += initElement(element, countStackableElements);
			}
			
			return nCursors;
		}
		
		
		/**
		 * This function inits the specified element.</br>
		 * Override this function if extra functionality is needed.</br> 
		 */
		protected function initElement(element:IElement, countStackableElements:Array):uint
		{
			// if element dataprovider doesn' exist or it refers to the
			// chart dataProvider, than set its cursor to this chart cursor (this.cursor)
			if (dataItems && (! element.dataProvider 
							|| element.dataProvider == this.dataProvider))
				element.dataItems = dataItems;
				
			if (! element.chart)
					element.chart = this;
				
			if (element is IStack)
			{				
				_stackedElements.push(element);
				IStack(element).stackType = _type;
				// count all stackable elements according their type (overlaid, stacked100...)
				// and store its position. This allows to have a general CartesianChart 
				// elements that are stackable, where the type of stack used is defined internally
				// the elements itself. In case BarChart, AreaChart or ColumnChart are used, than
				// the elements stack type is definde directly by the chart.
				// however the following allows keeping the possibility of using stackable elements inside
				// a general cartesian chart
				if (isNaN(countStackableElements[IStack(element).elementType]) || countStackableElements[IStack(element).elementType] == undefined) 
					countStackableElements[IStack(element).elementType] = 1;
				else 
					countStackableElements[IStack(element).elementType] += 1;
					
				IStack(element).stackPosition = countStackableElements[IStack(element).elementType] - 1; // position is current total - 1 
			}
			
			// nCursors is used in feedAxes to check that all elements cursors are ready
			// and therefore check that axes can be properly feeded
			if (dataItems || element.dataItems)
				return 1;
				
			return 0;
		}
		
		/**
		 * This function places the specified element.</br>
		 * At this level the element is placed into the elementscontainer.</br>
		 * Override this function if extra functionality if needed.
		 */
		protected function placeElement(element:IElement):void
		{
			if (!_elementsContainer.contains(DisplayObject(element)) )
			{
				_elementsContainer.addChild(DisplayObject(element));
			}
		}
		
		
		/**
		 * This functions init the necessary datastructure in the stack elements</br>
		 * This function only executes if the type is stacked100.</br>
		 */
		protected function initStackElements(countStackableElements:Array):void
		{
			for each (var stackElement:IStack in _stackedElements)
			{
				// if an element is stackable, than its total property 
				// represents the number of all stackable elements with the same type inside the
				// same chart. This allows having multiple elements type inside the same chart (TODO) 
				stackElement.total = countStackableElements[stackElement.elementType];
			}
			
			// only execute the rest if the type is stacked100
			if (_type != StackElement.STACKED100) return;
			
			var allElementsBaseValues:Array = []; 
			for (var i:int=0;i<_stackedElements.length;i++)
				allElementsBaseValues[i] = {indexElements: i, baseValues: []};
			
			_maxStacked100 = NaN;
			
			// datastructure to keep track of the last processed stack element per
			// category or angle or ... 
			var lastProcessedStackElements:Array = new Array();
			var position:uint = 0;
			for each (stackElement in _stackedElements)
			{
				initStackElement(stackElement, position++, allElementsBaseValues, lastProcessedStackElements);
			}
			
			// set the base values that we're calculated 
			for (var s:uint = 0;s<_stackedElements.length; s++)
			{
				IStack(_stackedElements[s]).baseValues = allElementsBaseValues[s].baseValues;		
			}
		}
		
		/**
		 * Init a specific stack element.</br>
		 * @param stackElement The stack element to init
		 * @param elementPosition The position of the stack element
		 * @param countStackableElements The total number of stack elements per elementType
		 * @param allElementsBaseValues Data structure to keep track of all the base values per element
		 * @param lastProcessedStackElements Data structure to keep track of the last processed stack element per category or angle or...
		 */
		protected function initStackElement(stackElement:IStack, elementPosition:uint, allElementsBaseValues:Array, lastProcessedStackElements:Array):void
		{
			 	
			
			var usedDataItems:Vector.<Object> = dataItems;
			
			// change the used data items if the element has other data items than the main dataitems
			if (stackElement.dataItems && stackElement.dataItems != dataItems)
			{
				usedDataItems = stackElement.dataItems;
			}
			
			if (usedDataItems == null) return;
			
			// determine which dimension is used for the index of the element
			// and which dimension is used for plotting
			var dims:Object = determineStackedDimensions(stackElement);
			
			for (var cursIndex:uint = 0; cursIndex < usedDataItems.length; cursIndex++)
			{
				var currentItem:Object = usedDataItems[cursIndex];

				// TODO: if dim is an Array, than iterate through it
				// determine the value of the index dimension
				var indexValue:Object = currentItem[stackElement[dims.indexDim]];
				
				// determine which index of stack element was processed before at this index
				var lastProcessedStackElementIndex:Number = lastProcessedStackElements[indexValue];
				
				// if we are not the first and there was somebody before us
				// calculate new positions
				if (elementPosition>0 && lastProcessedStackElementIndex>=0)
				{
					// determine the previous stack element
					var lastProcessedStackElement:IStack = _stackedElements[lastProcessedStackElementIndex];
					
					// determine the new maximum	
					var maxCurrentD2:Number = getDimMaxValue(currentItem, lastProcessedStackElement[dims.valueDim], lastProcessedStackElement.collisionType == StackElement.STACKED100);
					
					// store this maximum in the basevalues of the element
					allElementsBaseValues[elementPosition].baseValues[indexValue] = allElementsBaseValues[lastProcessedStackElementIndex].baseValues[indexValue] + Math.max(0,maxCurrentD2);
				} 
				else
				{ 
					// no previous elements or we are first
					// set to 0
					allElementsBaseValues[elementPosition].baseValues[indexValue] = 0;
				}


				// determine the maximum of the current element
				maxCurrentD2 = getDimMaxValue(currentItem, stackElement[dims.valueDim], stackElement.collisionType == StackElement.STACKED100);

				var localMax:Number = allElementsBaseValues[elementPosition].baseValues[indexValue] + Math.max(0,maxCurrentD2);
				
				// update maxStacked100 if necessary
				if (isNaN(_maxStacked100))
				{
					_maxStacked100 = localMax;
				}
				else
				{
					_maxStacked100 = Math.max(_maxStacked100,localMax);
				}
				
				// store this element's position as the last processed stack element at index j	
				lastProcessedStackElements[indexValue] = elementPosition;	
				
			}
		}
		
		/**
		 * Return an object which describes which dimension is used for looking up the index of the IStack</br>
		 * and which dimension is used to look up the plot value.</br>
		 * @return Object.indexDim is the index dimension , Object.valueDim is the plotting dimension
		 */
		protected function determineStackedDimensions(stack:IStack):Object
		{
			var toReturn:Object = new Object();
			toReturn.indexDim = "dim1";
			toReturn.valueDim = "dim2";
			
			if (stack.collisionScale == BaseElement.HORIZONTAL)
			{
				toReturn.indexDim = "dim2";
				toReturn.valueDim = "dim1";		
			}
			
			return toReturn;
		}
		
		protected function feedScales():void
		{
			
			resetScales();
			
			// init axes of all elements that have their own axes
			// since these are children of each elements, they are 
			// for sure ready for feeding and it won't affect the axesFeeded status
			for (var i:Number = 0; i<elements.length; i++)
				initElementsScales(elements[i]);
						
			commitValidatingScales();
			
			axesFeeded = true;
				
		}
		
		/** @Private
		 * Init the axes owned by the Element passed to this method.*/
		protected function initElementsScales(element:IElement):void
		{
			if (element.dataItems)
			{
				var catElements:Array;
				var j:Number;

				var cursIndex:uint = 0;
				var currentItem:Object;
				
				if (element.scale1) updateScale(element.scale1, element, "Dim1");
				if (element.scale2) updateScale(element.scale2, element, "Dim2");
				if (element.scale3) updateScale(element.scale3, element, "Dim3");
				if (element.colorScale) updateScale(element.colorScale, element, "Color");
				if (element.sizeScale) updateScale(element.sizeScale, element, "Size");
								
			}
		}
		
		protected function updateScale(scale:IScale, element:IElement, dim:Object):void
		{	
			// nothing to update...
			if (!scale || !element) return;

			if (!scale.parent) scale.parent = this;
			
			if (dim == "Dim1")
			{
				scale.dimension = BaseScale.DIMENSION_1;
			}
			else if (dim == "Dim2")
			{
				scale.dimension = BaseScale.DIMENSION_2;	
			}
			else if (dim == "Dim3")
			{
				scale.dimension = BaseScale.DIMENSION_3;	
			}
				
			if (!scale.dataValues)
			{
				
				if (scale is IEnumerableScale)
				{
					var catElements:Array = [];
					var j:uint = 0;
					
					if (IEnumerableScale(scale).dataProvider)
					{
						catElements = IEnumerableScale(scale).dataProvider;
						j = catElements.length;
					}
						
					for (var cursIndex:uint = 0; cursIndex<element.dataItems.length; cursIndex++)
					{
						var currentItem:Object = element.dataItems[cursIndex];

						// if the category value already exists in the axis, than skip it
						if (catElements.indexOf(currentItem[IEnumerableScale(scale).categoryField]) == -1)
							catElements[j++] = 
								currentItem[IEnumerableScale(scale).categoryField];
					}
							
					// set the elements propery of the CategoryAxis owned by the current element
					if (catElements.length > 0)
						IEnumerableScale(scale).dataProvider = catElements;
	
				} 
				else if (scale is INumerableScale)
				{
					// if the y axis is numeric than set its maximum and minimum values 
					// if the max and min are not yet defined for the element, than they are calculated now
					// since the same scale can be shared among several elements, the precedent min and max
					// are also taken into account
					if (INumerableScale(scale).scaleType != BaseScale.PERCENT)
                    {                    
						if (isNaN(INumerableScale(scale).max))
						{
							INumerableScale(scale).max = element["max"+dim+"Value"]; // TODO change this to a 'cleaner' technique?
						}
						else 
						{
							INumerableScale(scale).max = Math.max(INumerableScale(scale).max, element["max"+dim+"Value"]);
						}
						
						if (isNaN(INumerableScale(scale).min))
						{
							INumerableScale(scale).min = element["min"+dim+"Value"];
						}	
						else
						{ 
							INumerableScale(scale).min = Math.min(INumerableScale(scale).min, element["min"+dim+"Value"]);
						}
                    }
                    else
                    {
                    	if (isNaN(INumerableScale(scale).totalPositiveValue))
                    	{
                            INumerableScale(scale).totalPositiveValue = element["total"+dim+"PositiveValue"];
                    	}
                        else
                        {
                            INumerableScale(scale).totalPositiveValue += element["total"+dim+"PositiveValue"];
                        }
 
                    }
				}
			}
		}
		
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			
			if (active)
			{		
		
				super.updateDisplayList(unscaledWidth, unscaledHeight);
				setActualSize(unscaledWidth, unscaledHeight);
	
				if (_elementsPlaced && _guidesPlaced && invalidatedData && dataItems)
				{
					trace("update display list", unscaledWidth, unscaledHeight, this);
						
					validateBounds(unscaledWidth, unscaledHeight);
					
					setBounds(unscaledWidth, unscaledHeight);
					
					updateElements(unscaledWidth, unscaledHeight);
					
					updateAndDrawGuides(unscaledWidth, unscaledHeight);
					
					drawElements(unscaledWidth, unscaledHeight);
					
					// listeners like legends will listen to this event
					dispatchEvent(new Event("ProviderReady"));
					
					setMask();
					
				}
			}
		}
		
		/**
		 * Override this function to validate bounds.</br>
		 * For example if you need place to set axes, this is the place to calculate their sizes.</br>
		 */
		protected function validateBounds(unscaledWidth:Number, unscaledHeight:Number):void
		{
			// nothing happens at this level, the whole area is used to create a visualization
			
		}
		
		/** 
		 * Override this function to set bounds.</br>
		 * For example if the sizes of the container for  the axes are calculated, here you can set,</br>
		 * other container's positions based on these sizes.</br>
		 */
		protected function setBounds(unscaledWidth:Number, unscaledHeight:Number):void
		{
			// nothing here at this level, whole area is for visualizing!
		}
		
		protected function updateElements(unscaledWidth:Number, unscaledHeight:Number):void
		{
			for (var i:Number = 0;i<_elements.length; i++)
			{
				updateElement(_elements[i], unscaledWidth, unscaledHeight);
			}
		}
		
		protected function updateElement(element:IElement, unscaledWidth:Number, unscaledHeight:Number):void
		{
			DisplayObject(element).width = unscaledWidth;
			DisplayObject(element).height = unscaledHeight;
		}
		
		protected function drawElements(unscaledWidth:Number, unscaledHeight:Number):void
		{
			for each (var element:IElement in elements)
			{
				drawElement(element, unscaledWidth, unscaledHeight);
			}
		}
		
		protected function drawElement(element:IElement, unscaledWidth:Number, unscaledHeight:Number):void
		{
			element.draw();
		}
		
		protected function updateAndDrawGuides(unscaledWidth:Number, unscaledHeight:Number):void
		{
			for each (var guide:IGuide in guides)
			{
				updateAndDrawGuide(guide, unscaledWidth, unscaledHeight);
			}
		}
		
		protected function updateAndDrawGuide(guide:IGuide, unscaledWidth:Number, unscaledHeight:Number):void
		{
			guide.drawGuide(new Rectangle(0,0, unscaledWidth, unscaledHeight));	
		}
		
		protected function setMask():void
		{
			if (_isMasked && _maskShape && !isNaN(_elementsContainer.width) && !isNaN(_elementsContainer.height))
			{
				if (!elementsContainer.contains(_maskShape))
					elementsContainer.addChild(_maskShape);
				maskShape.graphics.beginFill(0xffffff, 1);
				maskShape.graphics.drawRect(0,0,_elementsContainer.width, _elementsContainer.height);
				maskShape.graphics.endFill();
	  			elementsContainer.setChildIndex(_maskShape, 0);
				elementsContainer.mask = maskShape;
			}
		}
		
		/**
		 * Function to remove all elements.</br>
		 * @internal This is a function that deteriorates performance. In the future this should be used as less as possible.
		 */
		protected function removeAllElements():void
		{
			if (_elementsContainer)
			{
	  			var nChildren:int = _elementsContainer.numChildren;
				for (var i:int = 0; i<nChildren; i++)
				{
					var child:DisplayObject = _elementsContainer.getChildAt(0); 
					
					if (child is IElement)
						IElement(child).removeAllElements();
						
					if (child is IGuide)
						IGuide(child).removeAllElements();
						
					if (child is DataItemLayout)
					{
						DataItemLayout(child).removeAllElements();
						DataItemLayout(child).geometryCollection.items = [];
						DataItemLayout(child).geometry = [];
					}
					
					_elementsContainer.removeChildAt(0);
				}
			}			
		}
		
	}
}