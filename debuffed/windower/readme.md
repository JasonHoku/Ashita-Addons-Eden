Windower compatibility shim for Ashita
--------------------------------------

This module tries to implement the lua environment
a Windower addon expects to find.

Only a small subset of the available functionality is implemented.
Most libraries and the resources are from Windower 4 itself.

It has been tested with only the addons in this repository so far.
As such it should be considered experimental software.

Many windower addons esp. use the packets library which is NOT YET IMPLEMENTED.
So if you encounter an require ('packets') line (with or without the parentheses)
the addon is not yet compatible.

How to use:

1. copy or link the windower folder inside the addon's folder.
For instance
* battlemod
  * windower
IMPORTANT: Everything in the windower folder including the subdirectories there is required.

2. add a require 'windower.shim' line to the main addon lua
   This line must be the first require statement in the lua code

See the battlemod addon included in this repo as example.
