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

License
-------
A 2-clause BSD license applies to the included source.

Copyright (c) 2010-2011 David Selassie. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

