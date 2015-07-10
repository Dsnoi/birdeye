![http://birdeye.googlecode.com/svn/trunk/images/BirdEyeLogoRaVis100.png](http://birdeye.googlecode.com/svn/trunk/images/BirdEyeLogoRaVis100.png)

## Introduction ##

Component enabling users to create complex data visualization interfaces for the analysis of relational data sets such as social networks, organization trees, navigation systems, taxonomies, db schemas, and other link-based phenomena. The library is purposely extendable and provides for separation of base, interface, and layout code. Additional layout algorithms can be readily integrated as an extended class containing only the mathematical calculations and controls needed specifically for the layout.

## News ##

7 February 2011: Flex 4 support has been added (using Flex 3 compatibility mode), as well as the ability to listen to events on Edges, like EdgeClick etc and Edge rollovers.

14 December 2008:
Logging support has been added conforming to [Flex logging API](http://livedocs.adobe.com/flex/3/html/help.html?content=logging_09.html). Other trace targets such as [Thunderbolt](http://code.google.com/p/flash-thunderbolt) can also be used.

27 March 2008:
All code and development migrated from flexvizgraphlib project.

## Demos ##
  * Example code how to use the library can be found [here](http://birdeye.googlecode.com/svn/trunk/ravis/RaVisExamples/).

  * You can download a precompiled snapshot of the library (flex3 folder for Flex 3, flex4 for Flex 4) [here](http://birdeye.googlecode.com/svn/trunk/ravis/libRaVis/released-binaries).

  * Try the RaVis Explorer: [here](http://birdeye.googlecode.com/svn/trunk/ravis/RaVisExamples/example-binaries/RaVisExplorer.html)

## Enhancements ##
  * Useful Enhancement from Hung LE (letronghung@gmail.com). In this enhancements, I do some implementations to improve the Ravis Library for some requests from another members. These enhancements will be useful in your self business

  * Try the Enhancement Demo: [here](http://birdeye.googlecode.com/svn/trunk/ravis/RaVisExamples/example-binaries/EnhancedRavisGraph.html)

  * Features:
    1. Graph Data Interface
      * Initialize graph from ValueObject - Finished
      * Initialize NodeRenderer from ValueObject - Finished
      * Initialize EdgeRenderer from ValueObject - Finished
    1. Programming API
      * Support Edge, Node event seperately. - Finished
      * Keep the original FLEX Event in Graph, Node, Edge Event. - Finished
      * Support Add/Remove/Edit Node, Edge easier - (Finished Node API)
    1. Edge
      * Support Edge Renderer (similar to NodeRenderer) because in many case, we want to move, handle event, resize edge  - Finished (Cheating way)
      * Add control point to Edge (Edge Control Renderer) which is built from Straight Section (similar to Ms Power Point Line)  - Finished
    1. Node
      * Support Node Label Renderer (Similar to Edge Label Renderer)  - Finished
      * Node Renderer is another typed of Visual Graph (Sub-graph function)  - In Progress
    1. Enhanced Visual Graph
      * Support multiple drag on Node (Example: Drag node and its successors together)  - Finished
      * Support Adding Node Label Renderer  - Finished
      * Support Adding Edge Control Renderer  - Finished
      * Add one function to create VisualGraph from Data (XML, VO) - Finished
      * Edit Node/Edge style on the fly - Finished
      * Special API: Remove Sub Tree, Remove Node Children, Show Node with its related node

## Support ##
  * Check out the User Group: [here](http://groups.google.com/group/flexvizgraphlib)