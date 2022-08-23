# Clues Adventure
## Create a Text Adventure With PowerShell

### Copyright (c) 2022 TigerPointe Software, LLC

[Home](https://tigerpointe.github.io/Clues-Adventure) on GitHub Pages.

[Download Clues Adventure](https://github.com/tigerpointe/Clues-Adventure) from GitHub.

## Introduction

Nothing makes me happier than to take a powerful administrative tool, like PowerShell, and completely misuse it for the purposes of entertainment.

This PowerShell script demonstrates how to write an "old school" text adventure game, sometimes known as Interactive Fiction (IF).  It is written much like the BASIC programs of the 1980s -- with no functions or variable scope.  Everything is global for simplicity.

## Setup

To enable PowerShell scripts, you may need to update your execution policy.  Find the PowerShell icon on your system, right-click and select the "Run as administrator" option.  Then, type ...

        Set-ExecutionPolicy -ExecutionPolicy Unrestricted

... and press the enter key.  Type "Y" and press the enter key again.  When the execution policy is set as "Unrestricted", PowerShell will still prompt you for a confirmation before running any untrusted scripts.  By default, PowerShell will not run any scripts downloaded from the Internet (unless digitally signed).

More secure PowerShell options exist that involve unblocking or bypassing the individual script file.  Before making any changes, a detailed understanding of PowerShell security is highly recommended.  In Windows 11, you can simply right-click on the game script and select the "Run as PowerShell" option.

## Game

The text adventure game first displays information about the current room, and then accepts two-word commands that are used to interact with the characters and objects.  Each command is split on the space, and the first three characters of each word are retrieved.  If a word is longer than three characters, the value is trimmed.  In this game, the three-characters must uniquely identify a room, object, character or command.

A player would enter the two-word (verb and noun) commands as follows:

        WALK NORTH
        EXAMINE ROPE

Alternatively, a player could enter the equivalent three-character commands:

        WAL NOR
        EXA ROP

Compass directions can be simplified and entered as a single word or letter.  So, "WALK NORTH" would be equivalent to "NORTH" or "N".

More complicated commands can be constructed to prompt the player for additional information.  For example, entering "ACCUSE COLONEL" might then ask the player to identify a specific murder weapon.

Be creative and try different commands until the mystery is solved.

## Code

Information tables are used to define the rooms, objects, characters and commands.  In this script, two dimensional arrays have been implemented.  However, object-oriented classes could have just as easily been implemented, as well as database tables.  The important point here is to have your items represented as rows, with each column representing a different attribute of the item.

For example, a room might be composed of a friendly name, a three-character id, and the room numbers to which the player travels when moving North, South, West or East.  If the room does not have an adjoining location in a particular direction, -1 or null can be specified.  Optionally, you can add other attributes like climbing up or down, whether the room is locked, whether it is too dark to see, etc.

Remember, arrays in PowerShell are zero-based.  So, count the room number indexes as 0, 1, 2, 3 ...

An object might be composed of a friendly name, a three-character id, as well as the room number in which the object is found, whether it is broken, too heavy to lift, etc.

Similarly, the characters and commands can be so constructed.

Hash tables work just like arrays, except that instead of using a numeric index, an alphabetic id is used.  So, instead of the first room "Kitchen" being referenced as MAP[0], it can also be referenced as MAP-HASH["KIT"], where the "Kitchen" has a three-character id of "KIT".  Hash tables allow you to connect the three-character item ids with what the player has entered in the command.  If the player enters "KIT", the MAP-HASH["KIT"] would return index 0, and MAP[0] references the "Kitchen" data in the information table.

Hash tables can also be used for handling synonyms.  If COMMAND-HASH["GO"], COMMAND-HASH["MOV"] and COMMAND-HASH["WAL"] all returned "WAL", whenever the player entered "GO" or "MOVE" or "WALK", the "WAL" command would be returned, and your code would only have to handle checking for "WAL".  Hash tables simplify the language processing.

If your game allows the player to carry an inventory, all that you need is a way of setting the room attribute on the object to some special "I'm carrying it" inventory value.  A "GET" command would set the room value on the object to that inventory value.  A "DROP" command would set the room value on the object to the current room and clear it from the inventory.

Similarly, objects can be "hidden" until some future event occurs by setting an invalid room value.  For example, a rare gem may remain hidden until the treasure chest is opened.  Once the chest is opened, the invalid room value on the gem can be set to the room value of the chest, thereby bringing the rare gem into the game.

The program itself functions like one giant state machine, continually looping until you quit.  As the player types in commands, hash tables are used to translate those three-character ids into indexes within the information tables.  Each command simply updates some attribute of the information table (like an object room number or status) and then displays a message using the friendly name read from that same information table.  The goal is to create a generic command handler, for which most of the actual work is simply updating a value in the associated information table.

That's really all that needs to be done to create your own game.

A sample batch file script launcher has been included with this project, as many players may not know how to start PowerShell.  The launcher allows players to easily start the game by double-clicking on the batch file.

I've also included a batch file that attempts to set the PowerShell execution policy to "RemoteSigned" and unblock the game script (as an alternative to setting the execution policy to "Unrestricted").  The batch file must be started with the right-click "Run as administrator" option.  Be sure to extract all files from this project into the same folder.

Journey on, adventurer!

## Make a Difference

If you found this tutorial useful, please consider a donation to any charity of your choice.  If you or a loved one has ever been affected by cancer, please consider one of the following:

[American Cancer Society](https://www.cancer.org)

[National Brain Tumor Society](https://braintumor.org)