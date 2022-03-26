# Clues Adventure

## Copyright (c) 2022 TigerPointe Software, LLC

Nothing makes me happier than to take a powerful administrative tool, like PowerShell, and completely misuse it for the purposes of entertainment.

This PowerShell script demonstrates how to write an "old school" text adventure game.  It is written much like the BASIC programs of the 1980's -- with no functions or variable scope.  Everything is global for simplicity.

The program first displays information about the current room, and then accepts two-word commands that are used to interact with the characters and objects.  Each command is split on the space, and the first three characters of each word are retrieved.  If a word is longer than three characters, the value is trimmed.  In this game, the three-characters must uniquely identify each room, object, character or command.

Information tables are used to define the rooms, objects, characters and commands.  In this script, two dimensional arrays have been implemented.  However, object-oriented classes could have just as easily been implemented, as well as database tables.  The important point here is to have your items represented as rows, with each column representing a different attribute of the item.

For example, a room might be composed of a friendly name, a three-character id, and the room numbers to which the player travels when moving North, South, West or East.  If the room does not have an adjoining location in a particular direction, -1 or null can be specified.  Optionally, you can add other attributes like climbing up or down, whether the room is locked, whether it is too dark to see, etc.

Remember, arrays in PowerShell are zero-based.  So, count the room number indexes as 0, 1, 2, 3 ...

An object might be composed of a friendly name, a three-character id, as well as the room number in which the object is found, whether it is broken, too heavy to lift, etc.

Similarly, the characters and commands can be so constructed.

Hash tables work just like arrays, except that instead of using a numeric index, an alphabetic id is used.  So, instead of your starting "Entrance" room being referenced as MAP[0], it can also be referenced as MAP-HASH["ENT"], where your "Entrance" has the three-character id of "ENT".  Hash tables allow you to connect the three-character item ids with what the player has entered in the command.  If the player enters "ENT", the MAP-HASH["ENT"] would return index 0, and MAP[0] references the room that the player typed.

Hash tables can also be used for handling synonyms.  If COMMAND-HASH["GO"], COMMAND-HASH["MOV"] and COMMAND-HASH["WAL"] all returned "WAL", whenever the player entered "GO" or "MOVE" or "WALK", the "WAL" command would be returned, and your code would only have to handle checking for "WAL".  Hash tables simplify the language processing.

If your game allows the player to carry an inventory, all that you need is a way of setting the room attribute on the object to some special "I'm carrying it" inventory value.  A "GET" command would set the room value on the object to that inventory value.  A "DROP" command would set the room value on the object to the current room and clear it from the inventory.

The program itself functions like one giant state machine, continually looping until you quit.  As the player types in commands, hash tables are used to translate those three-character ids into indexes within the information tables.  Each command simply updates some attribute of the information table (like an object room number or status) and then displays a message using the friendly name read from that same information table.  The goal is to create a generic command handler, for which most of the actual work is simply updating a value in the associated information table.  That's really all that needs to be done to create your own game.

Journey on, adventurer!
