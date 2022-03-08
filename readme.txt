LWScratch
	by loosewheel


Licence
=======
Code licence:
LGPL 2.1

Media licence:
CC-BY-SA 3.0


Version
=======
0.2.3


Minetest Version
================
This mod was developed on version 5.4.0


Dependencies
============


Optional Dependencies
=====================
default
intllib


Installation
============
Copy the 'lwscratch' folder to your mods folder.


Bug Report
==========
https://forum.minetest.net/viewtopic.php?f=9&t=26455


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

Each robot can be given a name, by entering the name in the Robot field and
clicking the Set button. The name will display when the robot is pointed
at or as the tool tip if it is in an inventory.

Each robot has a storage area (center right).

While a robot is running sneak + punch will open a form to stop it.

Robots are programmed graphically, by dragging a command from a pallet
(top right) to the program sheet (left). Items can be dragged from the
inventories. These are only markers, the item is not used. To remove an
item from the program sheet, drag it to an empty space in the command pallet.
To clear the whole program click the clear button. Commands are run in order,
left to right per line, then down the lines.

Block delimiting (for loop and if) is by indenting. When a following line
is indented to the same level or less, this marks the end of the block.

To run the program click the power button. If the program has an error a
red message below the program sheet details the error.

If a robot is left clicked with a cassette the robot's program is copied
to the cassette. Then the cassette can be right clicked in the air and
it's label can be changed, and it can be toggled read only. If read only
left clicking a robot will not overwrite the cassette. Right click + sneak a
robot to copy the program from the cassette to the robot. If a robot is
owned by another player it cannot be copied from or to.

On the rare occasion a program may be too large in data to be remembered
in the internal space. If this occurs, a cassette will not copy the
program and send a chat message to the player, and a robot will not dig
and send a chat message to the player. If it is too large it will be an
inventory item in the program sheet that's causing it. You could just
remove this item to retain the program.


See lwscratch.pdf in docs folder.


Command items are color coded by type:
Orange - Statement, controls program flow.
Green  - Value, represents a given value.
Yellow - Condition, results as true or false.
Blue   - Action, performs an action of some kind.
White  - Sheet action, used to edit the program sheet.


Working with variables:
All variable items, whether they are values, conditions or actions, must
be given a name. Set the name by placing it in the top slot, entering the
name in the Value field and clicking Set. All variable items with the same
name are the same variable value, whether being set with a value, testing
or using its value. Variables are never given a value in the top slot,
only a name. Their value is always set or changed in the program. The
Number and Text commands hold values.


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
	Can be set with a number value. To set the value, place it in the value
	slot at the top, enter the desired value in the Value field and click
	the Set button. Hovering over the number item, the tool tip displays its
	current value.

Text
	Can be set with a text value. To set the value, place it in the value
	slot at the top, enter the desired value in the Value field and click
	the Set button. Hovering over the text item, the tool tip displays its
	current value.

Variable
	Can be set with a name. To set the name, place it in the value slot at
	the top, enter the desired name in the Value field and click the Set
	button. Hovering over the variable item, the tool tip displays its
	current name.

Name
	Variants - up, down, forward, forward up, forward down, back, back up,
				  back down.

	Is the name of the node in the relevant direction. If no node is there
	it is blank text.


Conditions:

Counter
	Variants - is equal to, is less than, is greater than.

	Followed by a number or variable item, and results in true if the loop's
	counter is equal to|less than|greater than the number.

	*Outside of a loop the counter is always zero.

Counter is even
	Results in true if the counter is currently an even number.

Counter is odd
	Results in true if the counter is currently an odd number.

Variable is equal to
	If followed by a number, text, variable or name item
		Results in true if the variable is equal to than the following value.

	If followed by inventory item
		Results in true if the variables value equals the item's name.

	*Must be set with a name in the top slot.

Variable is less than
	Followed by a number or variable, and results in true if the variable
	is less than than the following value.

	*Must be set with a name in the top slot.

Variable is greater than
	Followed by a number or variable, and results in true if the variable
	is greater than the following value.

	*Must be set with a name in the top slot.

Variable is even
	Results in true if the variable is currently an even number (integer part).

	*Must be set with a name in the top slot.

Variable is odd
	Results in true if the variable is currently an odd number (integer part).

	*Must be set with a name in the top slot.

Detect
	Variants - up, down, forward, forward up, forward down, back, back up,
				  back down.

	If followed by an inventory item
		True if the node in the relevant direction match the inventory item.

	If followed by a text or variable item
		True if the node in the relevant direction match the text or
		variable's value.

	If followed by a blank space
		True if there is any node in the relevant direction.

Contains item
	If followed by an inventory item
		True if the robot's storage contains at least one of the inventory item.

	If followed by a text or variable item
		True if robot's storage contains at least one of the inventory items
		named in the text or variable's value.

	If followed by a blank space
		True if the robot's storage contains anything at all.

Item fits
	If followed by an inventory item
		True if one of the inventory item can fit in the robot's storage.

	If followed by a text or variable item
		True if one of the inventory item named in the text or variable's
		value can fit in the robot's storage.

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

	If followed by an inventory item
		Places the given inventory item in the relevant direction if there
		is nothing at that position.

	If followed by a text or variable item
		Places the inventory item named in the text or variable's value
		in the relevant direction if there is nothing at that position.

	*The item must be in the robot's storage.

Pull
	If followed by an inventory item
		Moves one of the given inventory items from an inventory (chest)
		immediately in front of the robot, into the robot's storage if it
		can fit.

	If followed by a text or variable item
		Moves one of the inventory items named in the text or variable's value
		from an inventory (chest) immediately in front of the robot, into
		the robot's storage if it can fit.

	If followed by a blank space
		Moves everything from an inventory (chest) immediately in front of
		the robot, into the robot's storage or as much as can fit.

Pull Stack
	If followed by an inventory item
		Moves up to a full stack of the given inventory items from an
		inventory (chest) immediately in front of the robot, into the
		robot's storage if it can fit.

	If followed by a text or variable item
		Moves up to a full stack of the inventory items named in the text
		or variable's value from an inventory (chest) immediately in front
		of the robot, into the robot's storage if it can fit.

Put
	If followed by an inventory item
		Moves one of the given inventory items from the robot's storage into
		an inventory (chest) immediately in front of the robot, if it can
		fit.

	If followed by a text or variable item
		Moves one of the inventory items named in the text or variable's value
		from the robot's storage into an inventory (chest) immediately in
		front of the robot, if it can fit.

	If followed by a blank space
		Moves everything from the robot's storage into an inventory (chest)
		immediately in front of the robot, or as much as can fit.

Put Stack
	If followed by an inventory item
		Moves up to a full stack of the given inventory items from the
		robot's storage into an inventory (chest) immediately in front of
		the robot, if it can fit.

	If followed by a text or variable item
		Moves up to a full stack of the inventory items named in the text
		or variable's value from the robot's storage into an inventory
		(chest) immediately in front of the robot, if it can fit.

Drop
	If followed by an inventory item
		Drops one of the given inventory items from the robot's storage into
		the world, if it contains one.

	If followed by a text or variable item
		Drops one of the inventory items named in the text or variable's value
		from the robot's storage into the world, if it contains one.

	If followed by a blank space
		Drops everything from the robot's storage into the world.

Drop Stack
	If followed by an inventory item
		Drops up to a full stack of the given inventory items from the
		robot's storage into the world, if it contains any.

	If followed by a text or variable item
		Drops up to a full stack of the inventory items named in the text
		or variable's value from the robot's storage into the world, if it
		contains any.

Trash
	If followed by an inventory item
		Destroys (gone forever) one of the given inventory items in the
		robot's storage, if it contains one.

	If followed by a text or variable item
		Destroys (gone forever) one of the inventory items named in the text
		or variable's value in the robot's storage, if it contains one.

	If followed by a blank space
		Destroys (gone forever) everything in the robot's storage.

Trash Stack
	If followed by an inventory item
		Destroys (gone forever) up to a full stack of the given inventory
		items in the robot's storage, if it contains any.

	If followed by a text or variable item
		Destroys (gone forever) up to a full stack of the inventory items
		named in the text or variable's value in the robot's storage, if
		it contains any.

Craft
	If followed by an inventory item
		Crafts the given inventory item. The materials for the craft must
		be in the robot's storage.

	If followed by a text or variable item
		Crafts the inventory item named in the text or variable's value.
		The materials for the craft must be in the robot's storage.

Wait
	Followed by a number or variable item. Pauses the robot's program by
	the number value in tenths of a second (10 = 1 second pause).

Stop
	Stops the robot's program.

Chat
	Followed by a text or variable item, the contents of which is sent to
	the chat. If the robot is private the message is only sent to the owner.
	If the robot is public and the Allow public chat setting is enabled
	the message is sent to all.

Variable assign
	If followed by a name
		Assigns the node name in the given direction to this variable.

	If followed by a number, text or variable
		Assigns the value in the following number, text or variable to this
		variable.

	If followed by inventory item
		Assigns the name of the inventory item to this variable.

	*The variable must be named.

Variable plus
	If followed by a name
		Adds the node name in the given direction to the end of this variable's
		current value.

	If followed by a number, text or variable
		If either of the values are text, adds the following value to the end
		of this variable's current value. Otherwise adds, as numbers, the
		two values and assigns the result to this variable.

	*The variable must be named.

Variable minus
	Followed by a number or variable. Subtracts the following value from
	this variables value and assigns the result to this variable.

	*The variable must be named.

Variable multiply
	Followed by a number or variable. Multiplies the following value with
	this variables value and assigns the result to this variable.

	*The variable must be named.

Variable divide
	Followed by a number or variable. Divides this variables value by the
	following value and assigns the result to this variable.

	*The variable must be named.


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

Allow public chat (bool)
	Allow chat command on public machines. If disabled the command is
	ignored.
	Default: true

Use mod on_place (bool)
	Attempt to use mod on_place handler to place nodes.
	Default: true

Alert handler errors
	Issue errors when handler's of other mods fail.
	Default: true



*	The file 'place_substitute.lua' in the mod folder contains a list of
	item/node substitutes, useful for farming etc. Modify this file for
	additional substitutes. The field name is the item/node to be
	substituted. The value can be a string or a table with one indexed string
	of the default substitute item. This table can optionally contain key
	values of strings for each direction. Recognised keys are "up", "down",
	"front", "back".

*	The file 'crafting_mods.lua' in the mod folder contains a list of
	crafting modifications. Modify this file as necessary. The field name
	is the item being crafted. Each item in the add list is added to the
	robot's storage. Each item in the remove list is removed from the
	robot's storage.



------------------------------------------------------------------------
