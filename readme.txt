LWScratch
	by loosewheel


Licence
=======
Code licence:
LGPL 2.1


Version
=======
0.1.0


Minetest Version
================
This mod was developed on version 5.4.0


Dependencies
============
default
lwdrops


Optional Dependencies
=====================
intllib


Installation
============
Copy the 'lwscratch' folder to your mods folder.


Bug Report
==========



Description
===========
This mod provides scratch programmable robots.

The first time a robot is placed in the world a form opens asking the
player that placed it, if the machine is public or private. If private is
selected, the player becomes the owner and other players (except those
with protection_bypass privilege) cannot access it.

The persistence button toggles on and off. If persistence is on, the block
the robot is in remains loaded when out of range. This persistence is
retained across world startups. Robots retain their persistence state when
moved. The maximum force loaded blocks is limited to the
max_forceloaded_blocks setting (default is 16).

Each robot can be given a name, by entering the name in the name field and
clicking the Set button. The name will display when the robot is pointed
at or as the tool tip if it is in an inventory.

Each robot has a storage area (bottom left).

While a robot is running sneak + punch will open a form to stop it.

Robots are programmed graphically, by dragging a command from a pallet
(top left) to the program sheet (top right). Items can be dragged from the
inventories. These are only markers, the item is not used. To remove an
item from the program sheet, drag it to an empty space in the command pallet.
To clear the whole program click the clear button. Commands are run in order,
left to right per line, then down the lines.

Block delimiting (for loop and if) is by indenting. When a following line
is indented to the same level or less, this marks the end of the block.

To run the program click the power button. If the program has an error a
red message below the program sheet details the error.

Command items are color coded by type:
Orange - Statement, controls program flow.
Green  - Value, represents a given value.
Yellow - Condition, results as true or false.
Blue   - Action, performs an action of some kind.
White  - Sheet action, used to edit the program sheet.


Statements:

Loop
	Followed by a condition which evaluates to true or false. The following
	lines of commands indented greater than the loop statement will run
	repeatedly until the condition is false.

	Each loop has an internal counter, which starts at zero and increments
	by one every iteration.

If
	Followed by a condition which evaluates to true or false. The following
	lines of commands indented greater than the if statement will run once
	if the condition is true.


Values:

Number
	Can be set with an number value when placed (or moved) in the program
	sheet. An input field and button labelled Number appear. Set the value
	and click the button to set the value. Hovering over the number item
	the tool tip displays its current value.


Conditions:

Counter
	Variants - is equal to, is less than, is greater than.

	Followed by a number item, and results in true if the loop's counter
	is equal to|less than|greater than the number.

	*Outside of a loop the counter is always zero.

Detect
	Variants - up, down, forward, forward up, forward down, back, back up,
				  back down.

	If followed by an inventory item
		True if the node in the relevant direction match the inventory item.

	If followed by a blank space
		True if there is any node in the relevant direction.

Contains item
	If followed by an inventory item
		True if the robot's storage contains at least one of the inventory item.

	If followed by a blank space
		True if the robot's storage contains anything at all.

Item fits
	If followed by an inventory item
		True if one of the inventory item can fit in the robot's storage.

	If followed by a blank space
		True if the robot's storage has at least one empty slot (can fit
		anything).

Not
	Inverts the next condition result (true to false, or false to true).

And
	Placed between two conditions and is true only if both the left and
	right conditions are true.

Or
	Placed between two conditions and is true if either the left or right
	(or both) condition is true.


Actions:

Move
	Variants - forward, backward, up, down.

	Moves one node in the relevant direction, if nothing is there.

Turn
	Variants - left, right.

	Turns 90 degrees in the relevant direction.

Dig
	Variants - up, down, forward, forward up, forward down, back, back up,
				  back down.

	Digs the node in the relevant direction, if there is anything there.
	If dug node is placed in the robot's storage if there is room, otherwise
	it is dropped.

Place
	Variants - up, down, forward, forward up, forward down, back, back up,
				  back down.

	Followed by an inventory item. Places the given inventory item in the
	relevant direction if there is nothing at that position, and the item
	is in the robot's storage.

Pull
	If followed by an inventory item
		Moves one of the given inventory items from an inventory (chest)
		immediately in front of the robot, into the robot's storage if it
		can fit.

	If followed by a blank space
		Moves everything from an inventory (chest) immediately in front of
		the robot, into the robot's storage or as much as can fit.

Put
	If followed by an inventory item
		Moves one of the given inventory items from the robot's storage into
		an inventory (chest) immediately in front of the robot, if it can
		fit.

	If followed by a blank space
		Moves everything from the robot's storage into an inventory (chest)
		immediately in front of the robot, or as much as can fit.

Drop
	If followed by an inventory item
		Drops one of the given inventory items from the robot's storage into
		the world, if it contains one.

	If followed by a blank space
		Drops everything from the robot's storage into the world.

Trash
	If followed by an inventory item
		Destroys (gone forever) one of the given inventory items in the
		robot's storage, if it contains one.

	If followed by a blank space
		Destroys (gone forever) everything in the robot's storage.

Craft
	Followed by an inventory item. Crafts the given inventory item. The
	materials for the craft must be in the robot's storage.

Wait
	Followed by a number item. Pauses the robot's program by the number
	value in tenths of a second (10 = 1 second pause).

Stop
	Stops the robot's program.


Sheet actions:

Insert line
	Inserts a line in the program sheet where it is dropped. The last line
	of the sheet is lost.

Remove line
	Removes a line in the program sheet where it is dropped. The removed
	line of the sheet is lost.



The mod supports the following settings:

Running interval seconds (float)
	Seconds interval between running ticks.
	Default: 0.1

Robot's action delay (float)
	Delay (wait) in seconds for a robot's action. Enforced minimum of 0.1
	seconds.
	Default: 0.2

Robot's movement delay (float)
	Delay (wait) in seconds for a robot's movement. Enforced minimum of 0.1
	seconds.
	Default: 0.5



*	The file 'place_substitute.lua' in the mod folder contains a list of
	item/node substitutes, useful for farming etc. Modify this file for
	additional substitutes. The field name is the item/node to be
	substituted. The value is what it is substituted with.

*	The file 'crafting_mods.lua' in the mod folder contains a list of
	crafting modifications. Modify this file as necessary. The field name
	is the item being crafted. Each item in the add list is added to the
	robot's storage. Each item in the remove list is removed from the
	robot's storage.



------------------------------------------------------------------------
