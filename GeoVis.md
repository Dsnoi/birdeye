![http://birdeye.googlecode.com/svn/trunk/images/BirdEyeLogoGeoVis100.png](http://birdeye.googlecode.com/svn/trunk/images/BirdEyeLogoGeoVis100.png)

### Introduction ###

Rendering of vector-based maps with control and functions to facilitate analysis of geospatial data.

### Status ###

Unstable: highly dynamic concept development (pre-Alpha): 19 March 2008

### Explorer ###

A GeoVis Explorer is available [here](http://birdeye.googlecode.com/svn/trunk/geovis/demo/GeoVisExplorer.html)
to monitor the progress of the component.

### Development Plan ###

**Phase I: Architecture and Base**
  * Logical architecture with a base US States and World Map vector dictionary;
    1. US States – Census Regions and Sub Regions
    1. World – Regions and Sub Regions
  * Multiple geographic projections
  * Features and Symbols
  * Events (featureClick, featureDoubleClick, featureRollOver, featureRollOut)
  * Styles (CSS styling of map objects and helper classes for RollOver, RollOut)
  * Controls  and Functions
    1. Autofit (for map to display properly in container space)
    1. Zoom and nearestNeighbor
    1. Flow
    1. Colorize
**Phase II:  Annotations and Surrounds**
  * Marker and Glyph objects (Bubble, map symbols, etc.)
  * Grids
  * Legend
  * Scale
**Phase III: 3D Rendering**
  * Plane based
  * Sphere based
  * 3D camera controls (pan, tilt, rotate, etc.)
**Phase IV: Coordinate Transforms**
  * Coordinate transforms for projections (Lat/Long)
  * Datums
**Phase V: GeoSpatial data readers**
  * ShapeFile
  * GML
  * KML
**Phase VI: Interface and Utility Classes**
  * Interface classes
  * Color Brewer
**Phase V: Tile and Raster Libs**