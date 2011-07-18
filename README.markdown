Divided Edge Bundling
=====================
Here is an implementation of the physical simulation of Divided Edge Bundling in a basic graph viewer. 

Requirements
------------
- OS X 10.6+
- Xcode 4+

Supported File Types
--------------------
- GraphML
- GEXF

Loading of node positions, colors and edge weights is supported. Example graphs are available in the examples/ folder.

Graphs with up to ~2000 edges can bundle in real-time.

Usage
-----
Pan around the graph area by clicking and dragging the mouse. Zoom with the mouse wheel or command-+ or command--. Reset zoom with command-0. Zoom to a selection by shift-command-dragging. Select edges by shift-dragging. Select only edges with end nodes by alt-shift-dragging. Select mesh points by command-clicking. Move mesh points by command-alt-clicking and dragging.

To simply start running the physical simulation press spacebar or Run Edge Forcing; initially there are no movable mesh points in any edge, so no movement will occur. Press Double Mesh to add more points; the current number of mesh points is shown next to this button.
To simply bundle a graph, press Magic Iteration. This runs a set number of cycles of physical simulation frames with increasing granularity. To manually run these cycles you can choose the menu item Do Edge Cycle.

Very basic mesh and node point data can be seen by opening the inspector with command-I.

Tooltips are provided for the simulation parameters in the preferences.

About
-----
More information can be found at the [website](http://selassid.github.com/DividedEdgeBundling) or by looking at the original paper in IEEE InfoVis 2011.

