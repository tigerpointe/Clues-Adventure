<#

.SYNOPSIS
Starts a new tiny text adventure inspired by a well-known mystery board game.

.DESCRIPTION
Solve the murder mystery by deducing the correct suspect, room and weapon.
Move around the manor by entering compass directions (n, s, w, e, u and d).
Interact with the suspects and weapons by entering two-word text commands.
Most text commands are constructed as a verb followed by a noun.
Suggest possible suspects, rooms and weapons to collect hints about the crime.
Various other objects may provide important clues, such as the motive.
When you are ready, accuse your suspect to finish the game.

Please give to cancer research!

.PARAMETER difficulty
Specifies a difficulty level for the random game elements (0-99).

.INPUTS
None.

.OUTPUTS
None.

.EXAMPLE
.\Start-CluesAdventure.ps1
Starts a new game with the default difficulty level.

.EXAMPLE
.\Start-CluesAdventure.ps1 -difficulty 10
Starts a new game with a lower difficulty level.

.EXAMPLE
.\Start-CluesAdventure.ps1 -difficulty 90
Starts a new game with a higher difficulty level.

.NOTES
MIT License

Copyright (c) 2022 TigerPointe Software, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

If you enjoy this game, please do something kind for free.

Dedicated to the memory of Tim Hartnell, Master Gamesman (1951-1991)
Read "Creating Adventure Games on Your Computer" ISBN 0-345-31883-8

History:
01.00 2022-Mar-18 Scott S. Initial release.
01.01 2022-Mar-28 Scott S. Added requires version.
01.02 2022-Mar-29 Scott S. Added ambiguous object handling.
01.03 2022-Apr-01 Scott S. Added spontaneous object handling.
01.04 2022-Apr-06 Scott S. Added roaming non-player characters.
01.05 2022-Apr-07 Scott S. Fixed typos.
01.06 2022-Apr-08 Scott S. Added outdoor locations.

.LINK
https://en.wikipedia.org/wiki/Cluedo

.LINK
https://braintumor.org/

#>
#Requires -Version 5.1
param
(

  # Default difficulty level (0=Easy; 99=Hard)
  [int]$difficulty = 85

)

# Sanity check (valid difficulty range)
if ($difficulty -lt 0)  { $difficulty = 0;  }
if ($difficulty -gt 99) { $difficulty = 99; }

# Display a vintage style splash page
Clear-Host;
Write-Host "                                                           ";
Write-Host "                                                           ";
Write-Host "      .oooooo.   oooo                                      ";
Write-Host "     d8P'  'Y8b  '888                                      ";
Write-Host "    888           888  oooo  oooo   .ooooo.    .oooo.o     ";
Write-Host "    888           888  '888  '888  d88' '88b  d88(  '8     ";
Write-Host "    888           888   888   888  888ooo888  '^Y88b.      ";
Write-Host "    '88b    ooo   888   888   888  888    .o  o.  )88b     ";
Write-Host "     'Y8bood8P'  o888o  'V88V^V8P' 'Y8bod8P'  8^^888P'     ";
Write-Host "                                                           ";
Write-Host "             _                     _                       ";
Write-Host "   __ _   __| |__   __ ___  _ __  | |_  _   _  _ __   ___  ";
Write-Host "  / _' | / _' |\ \ / // _ \| '_ \ | __|| | | || '__| / _ \ ";
Write-Host " | (_| || (_| | \ V /|  __/| | | || |_ | |_| || |   |  __/ ";
Write-Host "  \__,_| \__,_|  \_/  \___||_| |_| \__| \__,_||_|    \___| ";
Write-Host "                                                           ";
Write-Host "                                                           ";
Read-Host  "            Press the <Enter> Key to Start ...";

# Map structure:
# Name, North, South, West, East, Up, Down, Secret Door, Lock, Dark, Id, Check
# Use the Study index and lower to identify the original game locations
# Use the Attic index and lower to identify the indoor game locations
$map = @(

("Kitchen"         , 16,  3, -1,  1, 12,  4,  9, 0, 0, "kit", 0),
("Ballroom"        , -1, -1,  0,  2, -1, -1, -1, 0, 0, "bal", 0),
("Conservatory"    , -1,  5,  1, -1, -1, -1,  7, 0, 0, "con", 0),
("Dining Room"     ,  0,  7, -1, -1, -1, -1, -1, 0, 0, "din", 0),
("Cellar"          , -1, 10, -1, -1,  0, -1, -1, 1, 1, "cel", 1),
("Billiard Room"   ,  2,  6, -1, -1, -1, -1, -1, 0, 0, "bil", 0),
("Library"         ,  5,  9, -1, -1, -1, -1, -1, 0, 0, "lib", 0),
("Lounge"          ,  3, -1, -1,  8, -1, -1,  2, 0, 0, "lou", 0),
("Great Hall"      , -1, 19,  7,  9, 13, -1, -1, 0, 0, "gre", 0),
("Study"           ,  6, -1,  8, -1, -1, -1,  0, 0, 0, "stu", 0),

("Crypt"           ,  4, -1, -1, -1, -1, -1, -1, 1, 1, "cry", 1),
("Master Bedroom"  , -1, 13, -1, -1, -1, -1, -1, 0, 0, "mas", 0),
("Servant Bedroom" , -1, -1, -1, 13, -1,  0, -1, 0, 0, "ser", 0),
("Upstairs Hall"   , 11, -1, 12, 14, 15,  8, -1, 0, 0, "ups", 0),
("Bath"            , -1, -1, 13, -1, -1, -1, -1, 0, 0, "bat", 0),
("Attic"           , -1, -1, -1, -1, -1, 13, -1, 0, 1, "att", 0),

("Secret Garden"   , -1,  0, -1, -1, -1, -1, -1, 0, 0, "sec", 1),
("Overgrown Forest", 17, 17, 17, 19, -1, -1, -1, 0, 0, "wof", 1),
("Overgrown Forest", 18, 18, 19, 18, -1, -1, -1, 0, 0, "eof", 1),
("Front Courtyard" ,  8, -1, 17, 18, -1, -1, -1, 0, 0, "fro", 1)


);
$mapName = "Raven Manor";

# Map hash allows the array indexes to be found by the id
$maph = @{};
for ($i = 0; $i -lt $map.Length; $i++)
{
  $maph[$map[$i][10]] = $i;
}

# Non-player character structure:
# Name, Id, Room, Active, Description, Check
$npc = @(

("Mr. Mortem"     ,"mor",0,0,"You observe a dead body."               ,1),

("Mr. Brown"      ,"bro",0,1,"He's a politician with a shady past."   ,0),
("Colonel Custard","cus",2,1,"He's an adventurer in the military."    ,0),
("Father Green"   ,"gre",1,1,"He's a minister who spent time in jail.",0),
("Dr. Lotus"      ,"lot",3,1,"She holds a PhD in plant toxicology."   ,0),
("Professor Peach","pea",6,1,"He has an IQ of 162 and a poor memory." ,0),
("Mrs. Pheasant"  ,"phe",5,1,"She's a retired actress and socialite." ,0),
("Miss Scarlett"  ,"sca",7,1,"She's as dangerous as she is beautiful.",0),
("Mrs. Silver"    ,"sil",8,1,"She's the widow of a multi-billionaire.",0),
("Mrs. White"     ,"whi",9,1,"She's the caretaker of $mapName."       ,0)

);

# Non-player character hash allows the array indexes to be found by the id
$npch = @{};
for ($i = 0; $i -lt $npc.Length; $i++)
{
  $npch[$npc[$i][1]] = $i;
}

# Non-player character text replies
$txt = @(

"Well, it sure wasn't a suicide.",

"Nah, I wouldn't wanna snuff out a voter.",
"I didn't kill that rotten braggart!",
"No, I did not give into temptation.",
"I didn't do it.",
"I certainly don't remember murdering anybody today.",
"I could never intentionally hurt one of my fans.",
"My dearest, I wouldn't even hurt a fly.",
"Not I ... wealthy families pay others to do the dirty work.",
"It wasn't me -- I don't wanna mop up all of that mess!"

);

# Object structure:
# Name, Id, Room, Active, Description, Weapon, Fixed, Check
# Objects can be "hidden" by setting the room number to an invalid value
$obj = @(

("axe"          ,"axe", 0,1,"It's dull and covered with rust."        ,1,0,0),
("bomb"         ,"bom", 1,1,"It smells like a fertilizer explosive."  ,1,0,0),
("candlestick"  ,"can", 3,1,"It's made of silver with a lit candle."  ,1,0,0),
("dagger"       ,"dag", 5,1,"The blade is razor sharp."               ,1,0,0),
("lead pipe"    ,"pip", 6,1,"It's heavy and made of lead."            ,1,0,0),
("poison bottle","poi", 2,1,"It's marked with a skull and crossbones.",1,0,0),
("revolver"     ,"rev", 7,1,"It contains only a single bullet."       ,1,0,0),
("rope"         ,"rop", 8,1,"The end is tied into a noose."           ,1,0,0),
("wrench"       ,"wre", 9,1,"It's covered with dried blood."          ,1,0,0),

("bed"          ,"bed",11,1,"The linen needs to be cleaned."          ,0,1,0),
("book"         ,"boo", 6,1,"It's `"Leo Tolstoy`" by Warren Peace."   ,0,0,0),
("dining table" ,"din", 3,1,"It looks really old."                    ,0,1,0),
("document"     ,"doc",11,1,"It's {0}'s `"{1}`"."                     ,0,0,0),
("exotic plant" ,"exo",15,1,"It's carnivorous and bites your finger." ,0,0,0),
("pretty flower","pre",16,1,"It's vibrant purple with white splashes.",0,0,0),
("lock"         ,"loc", 0,1,"The {0} lock is rusted and weakened."    ,0,1,0),
("old mattress" ,"mat",12,1,"It's very stained."                      ,0,0,0),
("paper"        ,"pap", 4,1,"It's {0}'s updated `"{1}`"."             ,0,0,0),
("pool table"   ,"poo", 5,1,"The felt is badly worn."                 ,0,1,0),
("rubber ducky" ,"rub",99,1,"It's yellow and makes a quacking sound." ,0,0,0),
("stove"        ,"sto", 0,1,"The gas has been disconnected."          ,0,1,0),
("towel"        ,"tow",14,1,"It's blue with yellow duckies."          ,0,0,0),
("tub"          ,"tub",14,1,"It's gross and filled with dirty water." ,0,1,0)

);

# Object hash allows the array indexes to be found by the id
$objh = @{};
for ($i = 0; $i -lt $obj.Length; $i++)
{
  $objh[$obj[$i][1]] = $i;
}

# Command structure
# Verb, Id, Usage, Visible
# The "help" command is an alias for "check commands"
$cmd = @(

("accuse" , "acc", "accuse  [suspect] (while at crime scene)"         , 1),
("ask"    , "ask", "ask     [suspect]"                                , 1),
("break"  , "bre", "break   [object]"                                 , 1),
("call"   , "cal", "call    [suspect]"                                , 1),
("check"  , "che", "check   ['commands'|'rooms'|'suspects'|'weapons']", 1),
("debug"  , "deb", "debug"                                            , 0),
("drain"  , "dra", "drain   [object]"                                 , 0),
("drink"  , "dri", "drink   [object]"                                 , 0),
("drop"   , "dro", "drop    [object]"                                 , 1),
("examine", "exa", "examine [object|suspect]"                         , 1),
("get"    , "get", "get     [object]"                                 , 1),
("kill"   , "kil", "kill    [suspect] (while holding a weapon)"       , 0),
("kiss"   , "kis", "kiss    [suspect]"                                , 0),
("quit"   , "qui", "quit"                                             , 1),
("read"   , "rea", "read    [object]"                                 , 1),
("suggest", "sug", "suggest [suspect] (while at crime scene)"         , 1),
("use"    , "use", "use     [object]"                                 , 1),
("walk"   , "wal", "walk    [direction]"                              , 1)
);

# Command hash allows the array indexes to be found by the id
$cmdh = @{};
for ($i = 0; $i -lt $cmd.Length; $i++)
{
  $cmdh[$cmd[$i][1]] = $i;
}

# Command synonyms hash
$synch = @{};

$synch["acc"] = "acc"; # accuse

$synch["ask"] = "ask"; # ask
$synch["inq"] = "ask"; # inquire
$synch["que"] = "ask"; # question/query
$synch["tal"] = "ask"; # talk

$synch["bre"] = "bre"; # break
$synch["ope"] = "bre"; # open

$synch["cal"] = "cal"; # call
$synch["req"] = "cal"; # request
$synch["sum"] = "cal"; # summon

$synch["che"] = "che"; # check
$synch["hel"] = "che"; # help
$synch["lis"] = "che"; # list
$synch["sho"] = "che"; # show

$synch["deb"] = "deb"; # debug
$synch["sol"] = "deb"; # solve

$synch["dra"] = "dra"; # drain
$synch["emp"] = "dra"; # empty

$synch["dri"] = "dri"; # drink
$synch["sip"] = "dri"; # sip
$synch["swa"] = "dri"; # swallow

$synch["dis"] = "dro"; # discard
$synch["dro"] = "dro"; # drop
$synch["put"] = "dro"; # put

$synch["exa"] = "exa"; # examine
$synch["loo"] = "exa"; # look
$synch["obs"] = "exa"; # observe
$synch["tou"] = "exa"; # touch
$synch["vie"] = "exa"; # view

$synch["get"] = "get"; # get
$synch["gra"] = "get"; # grab
$synch["tak"] = "get"; # take

$synch["bea"] = "kil"; # beat
$synch["kil"] = "kil"; # kill
$synch["mur"] = "kil"; # murder

$synch["kis"] = "kis"; # kiss

$synch["exi"] = "qui"; # exit
$synch["qui"] = "qui"; # quit

$synch["rea"] = "rea"; # read

$synch["sug"] = "sug"; # suggest
$synch["sus"] = "sug"; # suspect

$synch["use"] = "use"; # use

$synch["ent"] = "wal"; # enter
$synch["go"]  = "wal"; # go
$synch["mov"] = "wal"; # move
$synch["nav"] = "wal"; # navigate
$synch["run"] = "wal"; # run
$synch["wal"] = "wal"; # walk

# Other object synonyms hash
$synoh = @{};

$synoh["com"] = "com"; # command
$synoh["not"] = "com"; # notebook
$synoh["ver"] = "com"; # verb

$synoh["exo"] = "exo"; # exotic
$synoh["pla"] = "exo"; # plant

$synoh["cel"] = "loc"; # cellar
$synoh["loc"] = "loc"; # lock

$synoh["map"] = "map"; # map
$synoh["roo"] = "map"; # room
$synoh["whe"] = "map"; # where

$synoh["old"] = "mat"; # old
$synoh["mat"] = "mat"; # mattress

$synoh["npc"] = "npc"; # non-player character
$synoh["peo"] = "npc"; # people
$synoh["per"] = "npc"; # person
$synoh["sus"] = "npc"; # suspect
$synoh["who"] = "npc"; # who

$synoh["ite"] = "obj"; # item
$synoh["obj"] = "obj"; # object
$synoh["wea"] = "obj"; # weapon
$synoh["wha"] = "obj"; # what

$synoh["lea"] = "pip"; # lead
$synoh["pip"] = "pip"; # pipe

$synoh["poi"] = "poi"; # poison
$synoh["bot"] = "poi"; # bottle

$synoh["pre"] = "pre"; # pretty
$synoh["flo"] = "pre"; # flower

$synoh["gun"] = "rev"; # gun
$synoh["rev"] = "rev"; # revolver

$synoh["rub"] = "rub"; # rubber
$synoh["duc"] = "rub"; # ducky

$synoh["ove"] = "sto"; # oven
$synoh["sto"] = "sto"; # stove

$synoh["tub"] = "tub"; # tub
$synoh["wat"] = "tub"; # water

# Non-player character titles synonyms hash
$synoh["bod"] = "mor"; # body
$synoh["mor"] = "mor"; # mortem

$synoh["fat"] = "gre"; # father
$synoh["gre"] = "gre"; # green

$synoh["col"] = "cus"; # colonel
$synoh["cus"] = "cus"; # custard

$synoh["pro"] = "pea"; # professor
$synoh["pea"] = "pea"; # peach

# Frequently used data indexes
$attic       = $maph["att"];
$billiard    = $maph["bil"];
$cellar      = $maph["cel"];
$crypt       = $maph["cry"];
$dining      = $maph["din"];
$kitchen     = $maph["kit"];

$body        = $npch["mor"];

$axe         = $objh["axe"];
$bomb        = $objh["bom"];
$candlestick = $objh["can"];
$pipe        = $objh["pip"];
$poison      = $objh["poi"];
$wrench      = $objh["wre"];

$book        = $objh["boo"];
$document    = $objh["doc"];
$ducky       = $objh["rub"];
$lock        = $objh["loc"];
$mattress    = $objh["mat"];
$paper       = $objh["pap"];
$tub         = $objh["tub"];

# Initialization
$dead      =  $npc[$body][4]; # dead body message
$count     =  0;              # move count
$room      =  $maph["gre"];   # starting room (Great Hall)
$inventory = -1;              # no object currently being carried

# Configure the mystery motive description
$docType           = "Last Will and Testament";
$obj[$document][4] = ($obj[$document][4] -f $npc[$body][0], $docType);
$obj[$paper][4]    = ($obj[$paper][4]    -f $npc[$body][0], $docType);
$motive            = 0; # bitwise initial 0x00
$allbits           = 3; # bitwise total   0x11

# Configure the lock type description
$obj[$lock][4] = ($obj[$lock][4] -f $map[$cellar][0]);

# Swap random non-player character locations (other than the body)
for ($i = 0; $i -lt 100; $i++)
{
  $x = (Get-Random -Maximum $npc.Length);
  $y = (Get-Random -Maximum $npc.Length);
  if (($x -ne $body) -and ($y -ne $body))
  {
    $z = $npc[$x][2];
    $npc[$x][2] = $npc[$y][2];
    $npc[$y][2] = $z;
  }
}

# Send a random non-player character to the crypt (other than the body)
$murderer = (Get-Random -Maximum $npc.Length);
while ($murderer -eq $body)
{
  $murderer = (Get-Random -Maximum $npc.Length);
}
$npc[$murderer][2] = $crypt;

# Swap random object locations (weapons only)
for ($i = 0; $i -lt 100; $i++)
{
  $x = (Get-Random -Maximum $obj.Length);
  $y = (Get-Random -Maximum $obj.Length);
  if (($obj[$x][5] -gt 0) -and ($obj[$y][5] -gt 0))
  {
    $z = $obj[$x][2];
    $obj[$x][2] = $obj[$y][2];
    $obj[$y][2] = $z;
  }
}

# Send a random object to the crypt (weapon only)
$weapon = (Get-Random -Maximum $obj.Length);
while ($obj[$weapon][5] -eq 0)
{
  $weapon = (Get-Random -Maximum $obj.Length);
}
$obj[$weapon][2] = $crypt;

# Create the body description hash
$deadh = @{};

$deadh["axe"] = "You observe a sizable amount of damage.";
$deadh["bom"] = "You observe a sizable amount of damage.";

$deadh["poi"] = "You note some skin discoloration.";
$deadh["rop"] = "You note some skin discoloration.";

$deadh["can"] = "You see a large bump on the head.";
$deadh["pip"] = "You see a large bump on the head.";
$deadh["wre"] = "You see a large bump on the head.";

$deadh["dag"] = "You spot a small hole in the chest.";
$deadh["rev"] = "You spot a small hole in the chest.";

# Set the body description based on the random object
switch($weapon)
{

  $objh["axe"] { $npc[$body][4] = $deadh["axe"]; break; }
  $objh["bom"] { $npc[$body][4] = $deadh["bom"]; break; }

  $objh["poi"] { $npc[$body][4] = $deadh["poi"]; break; }
  $objh["rop"] { $npc[$body][4] = $deadh["rop"]; break; }

  $objh["can"] { $npc[$body][4] = $deadh["can"]; break; }
  $objh["pip"] { $npc[$body][4] = $deadh["pip"]; break; }
  $objh["wre"] { $npc[$body][4] = $deadh["wre"]; break; }

  $objh["dag"] { $npc[$body][4] = $deadh["dag"]; break; }
  $objh["rev"] { $npc[$body][4] = $deadh["rev"]; break; }
   
}

# Choose a random body location (indoor room, but not the cellar or crypt)
$location = (Get-Random -Maximum ($attic + 1));
while (($location -eq $cellar) -or ($location -eq $crypt))
{
  $location = (Get-Random -Maximum $map.Length);
}
$npc[$body][2] = $location;

# Start the main loop
$readcmd = "";
$reply   = "";
$running = $true;
while ($running)
{

  # Instant death (murderer in the current room)
  if ($npc[$murderer][2] -eq $room) # murderer in room?
  {
    $who   = $npc[$murderer][0];
    $where = $map[$room][0];
    $what  = $obj[$weapon][0];
    Write-Host "`nA screaming figure suddenly leaps from the shadows ... ";
    Write-Host "$who kills you in the $where with the $what.";
    Write-Host "You are dead.";
    $running = $false;
    continue;
  }

  # Choose a roaming non-player character; the chosen character cannot be the
  # body or the murderer; do not move the chosen character into the current
  # room, the crypt, or a locked room; also, do not move the chosen character
  # out of the current room
  $chance = (Get-Random -Maximum 100);
  if ($chance -ge $difficulty)
  {
    $roam = (Get-Random -Maximum $npc.Length);
    while (($roam -eq $body) -or ($roam -eq $murderer))
    {
      $roam = (Get-Random -Maximum $npc.Length);
    }
    $escape = (Get-Random -Maximum $map.Length);
    if (($escape -ne $room) -and ($escape -ne $crypt) -and `
      ($map[$escape][8] -eq 0) -and ($npc[$roam][2] -ne $room))
    {
      $npc[$roam][2] = $escape;
    }
  }

  # Write the status information
  Clear-Host;
  $darkness = ($map[$room][9] -gt 0); # room is dark?  candlestick is ...
  if ($inventory -eq $candlestick) { $darkness = $false; }      # carried?
  if ($room  -eq $obj[$candlestick][2]) { $darkness = $false; } # in room?
  if ($crypt -eq $obj[$candlestick][2]) { $darkness = $false; } # unreachable?
  Write-Host "==================================================";
  if ($count -eq 0)
  {

    # Write the starting message
    Write-Host " Welcome to $mapName.";
    Write-Host " Be very afraid of the dark and good luck.";
    Write-Host " You can always begin by entering `"help`".`n";

  }
  if ($darkness)
  {

    # Write the darkness message (objects can still be used)
    Write-Host " You are in the dark.";

  }
  else
  {

    # Write the room name
    Write-Host " You are in the $($map[$room][0]).";

    # Write the exits
    Write-Host "`n You see the following exit(s):";
    $found = $false;
    $next  = -1;
    $name  = "";
    if ($map[$room][1] -ge 0)   # go north?
    {
      $next = $map[$room][1];
      $name = $map[$next][0];
      if ($map[$next][8] -gt 0) # room is locked?
      {
        Write-Host "  North ($name - Locked)";
      }
      else
      {
        Write-Host "  North ($name)";
      }
      $found = $true;
    }
    if ($map[$room][2] -ge 0)   # go south?
    {
      $next = $map[$room][2];
      $name = $map[$next][0];
      if ($map[$next][8] -gt 0) # room is locked?
      {
        Write-Host "  South ($name - Locked)";
      }
      else
      {
        Write-Host "  South ($name)";
      }
      $found = $true;
    }
    if ($map[$room][3] -ge 0)   # go west?
    {
      $next = $map[$room][3];
      $name = $map[$next][0];
      if ($map[$next][8] -gt 0) # room is locked?
      {
        Write-Host "  West  ($name - Locked)";
      }
      else
      {
        Write-Host "  West  ($name)";
      }
      $found = $true;
    }
    if ($map[$room][4] -ge 0)   # go east?
    {
      $next = $map[$room][4];
      $name = $map[$next][0];
      if ($map[$next][8] -gt 0) # room is locked?
      {
        Write-Host "  East  ($name - Locked)";
      }
      else
      {
        Write-Host "  East  ($name)";
      }
      $found = $true;
    }
    if ($map[$room][5] -ge 0)   # go up?
    {
      $next = $map[$room][5];
      $name = $map[$next][0];
      if ($map[$next][8] -gt 0) # room is locked?
      {
        Write-Host "  Up    ($name - Locked)";
      }
      else
      {
        Write-Host "  Up    ($name)";
      }
      $found = $true;
    }
    if ($map[$room][6] -ge 0)   # go down?
    {
      $next = $map[$room][6];
      $name = $map[$next][0];
      if ($map[$next][8] -gt 0) # room is locked?
      {
        Write-Host "  Down  ($name - Locked)";
      }
      else
      {
        Write-Host "  Down  ($name)";
      }
      $found = $true;
    }
    if (-not $found)          { Write-Host "  No exits"; }
    if ($map[$room][7] -ge 0) { Write-Host " You see a secret door."; }

    # Write the objects
    Write-Host "`n You see the following object(s):";
    $found = $false;
    foreach ($o in $obj)
    {
      if ($o[2] -eq $room) # object in room?
      {
        if ($o[3] -gt 0)   # object is active?
        {
          Write-Host "  $($o[0])";
        }
        else
        {
          Write-Host "  broken $($o[0])";
        }
        $found = $true;
      }
    }
    if (-not $found) { Write-Host "  No objects"; }

    # Write the non-player characters
    Write-Host "`n You see the following suspect(s):";
    $found = $false;
    foreach ($n in $npc)
    {
      if ($n[2] -eq $room) # npc in room?
      {
        if ($n[3] -gt 0)   # npc is active?
        {
          Write-Host "  $($n[0])";
        }
        else
        {
          Write-Host "  $($n[0])'s deceased remains";
        }     
        $found = $true;
      }
    }
    if (-not $found) { Write-Host "  No bodies"; }

    # Write the inventory
    if ($inventory -ge 0) # have inventory?
    {
      Write-Host "`n You are carrying the $($obj[$inventory][0]).";
    }

  }
  Write-Host "==================================================`n";

  # Show the text reply of the previous command
  if ($reply.Length -gt 0)
  {
    Write-Host "> $reply";
    $reply = "";
  }

  # Show the lost message
  if (($map[$room][10] -eq "wof") -or ($map[$room][10] -eq "eof"))
  {
    "> You appear to be lost in the $($map[$room][0]).";
  }

  # Read and parse the next command (first three characters only)
  $parsed  = $false;
  $readcmd = Read-Host "> What do you want to do?";
  $object  = "";
  $command = $readcmd.Trim().ToLower();
  $index   = $command.IndexOf(" ");
  if ($index -ge 0)
  {
    $object  = $command.Substring(($index + 1)).Trim();
    $command = $command.Substring(0, $index).Trim();
  }
  if ($object.Length  -ge 3) { $object  = $object.Substring(0, 3);  }
  if ($command.Length -ge 3) { $command = $command.Substring(0, 3); }
  Start-Sleep -Seconds 0.55; # it feels just like the 1980s again!

  # Check for ambiguous "table" objects
  if (($object -eq "tab") -and ($room -eq $billiard)) { $object = "poo"; }
  if (($object -eq "tab") -and ($room -eq $dining))   { $object = "din"; }

  # Check for command synonyms
  $synonym = $synch[$command];
  if ($synonym -ne $null) { $command = $synonym; }

  # Check for object synonyms
  $synonym = $synoh[$object];
  if ($synonym -ne $null) { $object  = $synonym; }

  # Accuse command (accuses a non-player character of the crime)
  if ($command -eq "acc")
  {
    $score = 0;
    $total = 4;
    if ($location -eq $room) { $score++; }        # correct location?
    $where = $map[$room][0];
    $key   = $npch[$object];
    if ($key -ne $null)
    {
      if ($murderer -eq $key) { $score++; }       # correct murderer?
      $who = $npc[$key][0];
      Write-Host "`nAn accusation has been made:  $who in the $where";
      $object = Read-Host "Which weapon was used in the murder?";
      $object = $object.Trim();
      if ($object.Length -gt 3) { $object = $object.Substring(0, 3); }
      $synonym = $synoh[$object];
      if ($synonym -ne $null)   { $object = $synonym; }
      $key = $objh[$object];
      if ($key -ne $null)
      {
        $count++;
        if ($obj[$key][5] -gt 0)                  # object is weapon?
        {
          if ($weapon -eq $key)     { $score++; } # correct weapon?
          if ($motive -ge $allbits) { $score++; } # found motive?
          $what = $obj[$key][0];
          Write-Host `
            "`nYou accuse `"$who did it in the $where with the $what.`"";
          Write-Host "The correct solution was:";
          Write-Host "  Murderer:  $($npc[$murderer][0])";
          Write-Host "  Room:      $($map[$location][0])";
          Write-Host "  Weapon:    $($obj[$weapon][0])";
          if ($motive -ge $allbits)               # found motive?
          {
            Write-Host "  Motive:    $($npc[$body][0])'s `"$docType`"";
          }
          else
          {
            Write-Host "  Motive:    A clear motive was never established";
          }
          Write-Host "You scored:  $score/$total points";
          Write-Host "             $($count.ToString("#,#")) move(s)";
          if ($score -eq $total)        # all correct?
          {
            if ($obj[$weapon][3] -gt 0) # object is active?
            {
              Write-Host "`nCONGRATULATIONS!  You just solved the case.";
            }
            else
            {
              Write-Host "`nUnfortunately, the $what was broken.";
              Write-Host "$who was released due to lack of evidence.";
            }
          }
          $running = $false;
          continue;
        }
      }
    }
  }

  # Ask command (asks about a non-player character)
  if ($command -eq "ask")
  {
    $key = $npch[$object];
    if ($key -ne $null)
    {
      $reply = $npc[$key][0];
      if ($npc[$key][2] -eq $room) # npc is in room?
      {
        if ($npc[$key][3] -gt 0)   # npc is active?
        {
          $reply = "$reply replies `"$($txt[$key])`"";
        }
        else
        {
          $reply = "$reply does not reply.";
        }
      }
      else
      {
        $reply = "$reply is not here.";
      }
      $parsed = $true;
    }
  }

  # Break command (breaks an object)
  if ($command -eq "bre")
  {
    $key = $objh[$object];
    if ($key -ne $null)
    {

      # Special processing for locks
      if ($key -eq $lock)                     # object is lock?
      {
        if ($room -eq $kitchen)               # room is kitchen?
        {
          if ($map[$cellar][8] -gt 0)         # cellar is locked?
          {
            if ((($inventory -eq $axe) -or `  # object is blunt instrument?
              ($inventory -eq $pipe) -or `     
              ($inventory -eq $wrench))) 
            {

              # Some objects break locks
              $reply = $obj[$inventory][0];
              $reply = "Okay, the lock was broken with the $reply.";
              $map[$cellar][8]    =  0;
              $map[$crypt][8]     =  $map[$cellar][8];
              $obj[$inventory][2] =  $room;
              $obj[$inventory][3] =  0;
              $obj[$key][3]       =  0;
              $inventory          = -1;

            }
            else
            {
              $reply = "You aren't carrying anything that can break a lock.";
            }
          }
          else
          {
            $reply = "It's already unlocked.";
          }
        }
        else
        {
          $reply = "You don't see a lock here.";
        }
      }
      else
      {

        # Break any other object
        $reply = $obj[$key][0];
        if (($obj[$key][2] -eq $room) -or `
          ($key -eq $inventory))              # object is in room or carried?
        {
          if ($obj[$key][3] -gt 0)            # object is active?
          {
            $obj[$key][2] =  $room;
            $obj[$key][3] =  0;
            $inventory    = -1;
            $reply = "Okay, you broke the $reply and it fell to the ground.";
          }
          else
          {
            $reply = "The $reply is already broken.";
          }
        }
        else
        {
          $reply = "The $reply is not here.";
        }
      }
      $parsed = $true;

    }
  }

  # Call command (calls a non-player character into the room)
  if ($command -eq "cal")
  {
    $key = $npch[$object];
    if ($key -ne $null)
    {
      $reply = $npc[$key][0];
      if ($npc[$key][2] -ne $crypt)    # npc is not in crypt?
      {
        if ($npc[$key][3] -gt 0)       # npc is active?
        {
          if ($npc[$key][2] -ne $room) # npc is not in room?
          {
            $npc[$key][2] = $room;
            $reply        = "$reply has now arrived.";
          }
          else
          {
            $reply = "$reply is already here.";
          }
        }
        else
        {
          $reply = "$reply has been murdered and did not respond.";
        }
      }
      else
      {
        $reply = "$reply seems to have vanished.";
      }
      $parsed = $true;
    }
  }

  # Check command (checks the status of game elements)
  if ($command -eq "che")
  {

    # List map (indoor locations only)
    if ($object -eq "map")
    {
      $reply = "The list of rooms include:";
      for ($i = 0; $i -le $attic; $i++)
      {
        $m = $map[$i];
        if ($m[8] -eq 0) # room is not locked?
        {
          $check = " ";
          if ($m[$m.Length - 1] -gt 0) { $check = "X"; }
          $reply = "$($reply)`n    [$check] $($m[0])";
        }
      }
      $parsed = $true;
    }
    
    # List non-player characters
    if ($object -eq "npc")
    {
      $reply = "The list of suspects include:";
      foreach ($n in $npc)
      {
        $check = " ";
        if ($n[$n.Length - 1] -gt 0) { $check = "X"; }
        if ($n[3] -gt 0) # npc is active?
        {
          $reply = "$($reply)`n    [$check] $($n[0])";
        }
        else
        {
          $reply = "$($reply)`n    [$check] $($n[0]) (deceased)";
        }
      }
      $parsed = $true;
    }

    # List objects (weapons only)
    if ($object -eq "obj")
    {
      $reply = "The list of weapons include:";
      foreach ($o in $obj)
      {
        if ($o[5] -gt 0)   # object is weapon?
        {
          $check = " ";
          if ($o[$o.Length - 1] -gt 0) { $check = "X"; }
          if ($o[3] -gt 0) # object is active?
          {
            $reply = "$($reply)`n    [$check] $($o[0])";
          }
          else
          {
            $reply = "$($reply)`n    [$check] $($o[0]) (broken)";
          }
        }
        
      }
      $parsed = $true;
    }

    # List commands
    if (($object -eq "") -or ($object -eq "com"))
    {
      $reply = "Enter two-word (verb and noun) commands, such as:";
      $reply = "$reply`n    examine body`n    walk north";
      $reply = "$reply`n  The list of commands include:";
      foreach ($c in $cmd)
      {
        if ($c[3] -gt 0)   # command is visible?
        {
          $reply = "$reply`n    $($c[2])";
        }
      }
      $parsed = $true;
    }

  }

  # Debug command (for debugging a solution)
  if ($command -eq "deb")
  {
    $who    = $npc[$murderer][0];
    $where  = $map[$location][0];
    $what   = $obj[$weapon][0];
    $reply  = "A ghost replies `"$who did it in the $where with the $what.`"";
    $parsed = $true;
  }

  # Drain command (drains an object)
  if ($command -eq "dra")
  {
    $key = $objh[$object];
    if ($key -ne $null)
    {
      $reply = $obj[$key][0];
      if ($obj[$key][2] -eq $room)            # object is in room?
      {
        if ($key -eq $tub)                    # object is tub?
        {
          if ($obj[$ducky][2] -gt $map.Count) # ducky room is invalid?
          {

            # Spontaneously call the rubber ducky into existence by setting
            # the invalid room value to the current location
            $what  = $obj[$ducky][0];
            $reply = "As the $reply drained, you found the $what.";
            $obj[$key][4]   = "It's been drained.";
            $obj[$ducky][2] = $room;

          }
          else
          {
            $reply = "Okay, nothing happened.";
          }
        }
        else
        {
          $reply = "You cannot drain the $reply.";
        }
      }
      else
      {
        $reply = "The $reply is not here.";
      }
      $parsed = $true;
    }
  }

  # Drink command (drinks an object)
  if ($command -eq "dri")
  {
    $key = $objh[$object];
    if ($key -ne $null)
    {
      $reply = $obj[$key][0];
      if (($obj[$key][2] -eq $room) -or `
        ($key -eq $inventory))            # object is in room or carried?
      {
        if ($key -eq $poison)             # object is poison?
        {

          # Instant death (drinking the poison)
          Write-Host `
            "`nYou sip the $reply and your stomach painfully burns.";
          Write-Host "Slowly, your consciousness begins to fade.";
          Write-Host "You are a dead moron.";
          $running = $false;
          continue;

        }
        else
        {
          $reply = "You can't drink from the $reply.";
        }
      }
      else
      {
        $reply = "The $reply is not here.";
      }
      $parsed = $true;
    }
  }

  # Drop command (drops an object from the inventory into the room)
  if ($command -eq "dro")
  {
    if ($inventory -ge 0)        # have inventory?
    {
      $key = $objh[$object];
      if ($key -ne $null)
      {
        $reply = $obj[$key][0];
        if ($key -eq $inventory) # object is carried?
        {
          $obj[$key][2] =  $room;
          $inventory    = -1;
          $reply        =  "Okay, the $reply was dropped.";
        }
        else
        {
          $reply = "You aren't carrying the $reply.";
        }
        $parsed = $true;
      }
    }
    else
    {
      $reply  = "You aren't carrying anything.";
      $parsed = $true;
    }
  }

  # Examine command (examines a non-player character or object)
  if ($command -eq "exa")
  {

    # Examine a non-player character
    $key = $npch[$object];
    if ($key -ne $null)
    {
      if ($npc[$key][2] -eq $room)        # npc is in room?
      {
        $reply = $npc[$key][4];
      }
      else
      {
        $reply = $npc[$key][0];
        $reply = "$reply is not here.";
      }
      $parsed = $true;
    }

    # Examine an object
    $key = $objh[$object];
    if ($key -ne $null)
    {
      if (($obj[$key][2] -eq $room) -or `
        ($key -eq $inventory))            # object is in room or carried?
      {
        $reply = $obj[$key][4];
      }
      else
      {
        $reply = $obj[$key][0];
        $reply = "The $reply is not here.";
      }
      $parsed = $true;
    }

  }

  # Get command (gets an object from the room into the inventory)
  if ($command -eq "get")
  {
    $key = $objh[$object];
    if ($key -ne $null)
    {
      $reply = $obj[$key][0];
      if ($obj[$key][2] -eq $room)   # object is in room?
      {
        if ($inventory -lt 0)        # have no inventory?
        {
          if ($obj[$key][3] -gt 0)   # object is active?
          {
            if ($obj[$key][6] -eq 0) # object is not fixed?
            {
              $inventory    =  $key;
              $obj[$key][2] = -1;
              $reply        =  "Okay, the $reply was taken.";
            }
            else
            {
              $reply = "The $reply is firmly fixed and cannot be freed.";
            }
          }
          else
          {
            $reply = "The broken $reply pieces fall back to the ground.";
          }
        }
        else
        {
          $reply = $obj[$inventory][0];
          $reply = "You are already carrying the $reply.";
          $reply = "$reply`n  Only one item can be carried at a time.";
        }
      }
      else
      {
        $reply = "The $reply is not here.";
      }
      $parsed = $true;
    }
  }

  # Kill command (kills a non-player character with an object)
  if ($command -eq "kil")
  {
    $key = $npch[$object];
    if ($key -ne $null)
    {
      $reply = $npc[$key][0];
      if ($npc[$key][2] -eq $room)          # npc is in room?
      {
        if ($npc[$key][3] -gt 0)            # npc is active?
        {
          if ($inventory -ge 0)             # have inventory?
          {
            if ($obj[$inventory][5] -gt 0)  # object is weapon?
            {
              $chance = (Get-Random -Maximum 100);
              if ($chance -ge $difficulty)
              {

                # Get the body description based on the object id
                $desc = $deadh[$obj[$inventory][1]];
                if ($desc -eq $null) { $desc = $dead; }

                # Non-player character is killed
                $who   = $npc[$key][0];
                $where = $map[$room][0];
                $what  = $obj[$inventory][0];
                $reply = "You murdered $who in the $where with the $what.";
                $npc[$key][3]       =  0;
                $npc[$key][4]       =  $desc;
                $obj[$inventory][2] =  $room;
                $obj[$inventory][3] =  0;
                $inventory          = -1;

              }
              else
              {

                # Non-player character escapes into a different room, which
                # cannot be the crypt, and must be unlocked
                $escape = (Get-Random -Maximum $map.Length);
                while (($escape -eq $room) -or ($escape -eq $crypt) -or `
                  ($map[$escape][8] -gt 0))
                {
                  $escape = (Get-Random -Maximum $map.Length);
                }
                $npc[$key][2] = $escape;
                $reply        = "$reply ran screaming out of the room.";

              }
            }
            else
            {
              $reply = $obj[$inventory][0];
              $reply = "The $reply cannot be used as a weapon.";
            }
          }
          else
          {
            $reply = "You aren't carrying a weapon.";
          }
        }
        else
        {
          $reply = "$reply is already dead.";
        }
      }
      else
      {
        $reply = "$reply is not here.";
      }
      $parsed = $true;
    }
  }

  # Kiss command (kisses a non-player character)
  if ($command -eq "kis")
  {
    $key = $npch[$object];
    if ($key -ne $null)
    {
      $reply = $npc[$key][0];
      if ($npc[$key][2] -eq $room) # npc is in room?
      {
        if ($npc[$key][3] -gt 0)   # npc is active?
        {
          if ($darkness)           # room is dark?
          {

            # Non-player character provides a hint
            $who    = $reply;
            $reply  = "Smooch, smooch ... Oh, $who!";
            $chance = (Get-Random -Maximum 100);
            if ($chance -ge $difficulty)
            {
              $reply = `
                "$reply`n  $who smiles and says `"Read the $docType.`"";
            }

          }
          else
          {

            # Non-player character escapes into a different room, which
            # cannot be the crypt, and must be unlocked
            $escape = (Get-Random -Maximum $map.Length);
            while (($escape -eq $room) -or ($escape -eq $crypt) -or `
              ($map[$escape][8] -gt 0))
            {
              $escape = (Get-Random -Maximum $map.Length);
            }
            $npc[$key][2] = $escape;
            $reply        = "$reply ran screaming out of the room.";
            $reply        = "You started to make your move, but $reply";

          }
        }
        else
        {
          $reply = "Unfortunately, $reply is dead and wouldn't enjoy it.";
        }
      }
      else
      {
        $reply = "Unfortunately, $reply is not here.";
      }
      $parsed = $true;
    } 
  }

  # Quit command (quits the game)
  if ($command -eq "qui")
  {
    $running = $false;
    continue;
  }

  # Read command (reads an object)
  if ($command -eq "rea")
  {
    $key = $objh[$object];
    if ($key -ne $null)
    {
      if (($obj[$key][2] -eq $room) -or `
        ($key -eq $inventory))            # object is in room or carried?
      {
        if ($darkness)                    # room is dark?
        {
          $reply = "It is too dark.";
        }
        else
        {
          if ($key -eq $book)             # object is book?
          {

            # Read the book
            $reply = $obj[$book][4];
            $reply = "$reply`n  Unfortunately, it's written in Russian.";

          }
          elseif ($key -eq $document)     # object is document?
          {

            # Read the document
            $reply = "This document contains a `"$docType`"";
            $reply = "$reply for $($npc[$body][0]).";
            $reply = "$reply`n  The following people are named as the heirs";
            $reply = "$reply of $mapName`:";
            for ($i = 0; $i -lt $npc.Length; $i++)
            {
              if ($i -ne $body)           # not body
              {
                $reply = "$reply`n    $($npc[$i][0])";
              }
            }
            $motive = ($motive -bor 1);   # bitwise flip 0x01 of 0x11
            if ($motive -ge $allbits)
            {
              $who   = $npc[$murderer][0];
              $reply = "$reply`n  You just found the motive for murder.";
              $reply = "$reply`n  $who was cut from the other updated will.";
            }

          }
          elseif ($key -eq $paper)        # object is paper?
          {

            # Read the paper
            $reply = "This paper contains an updated `"$docType`"";
            $reply = "$reply for $($npc[$body][0]).";
            $reply = "$reply`n  The following people are named as the heirs";
            $reply = "$reply of $mapName`:";
            for ($i = 0; $i -lt $npc.Length; $i++)
            {
              if (($i -ne $murderer) -and ($i -ne $body)) # not murderer/body
              {
                $reply = "$reply`n    $($npc[$i][0])";
              }
            }
            $motive = ($motive -bor 2);   # bitwise flip 0x10 of 0x11
            if ($motive -ge $allbits)
            {
              $who   = $npc[$murderer][0];
              $reply = "$reply`n  You just found the motive for murder.";
              $reply = "$reply`n  $who was cut from this updated will.";
            }

          }
          else
          {
            $reply = $obj[$key][0];
            $reply = "You can't read the $reply.";
          }
        }
      }
      else
      {
        $reply = $obj[$key][0];
        $reply = "The $reply is not here.";
      }
      $parsed = $true;
    }
  }

  # Suggest command (suggests the guilt of a non-player character)
  if ($command -eq "sug")
  {
    $key   = -1;
    $hints = @();
    $refs  = @();
    $idxs  = @();
    for ($i = 0; $i -lt $npc.Length; $i++) # find last npc in room
    {
      if (($npc[$i][2] -eq $room) -and ($npc[$i][3] -gt 0)) { $key = $i; }
    }
    if ($key -ge 0)
    {
      $speaker   = $npc[$key][0];
      $speakerId = $key;
      $where     = $map[$room][0];
      $key       = $npch[$object];
      if ($key -ne $null)
      {
        $who   = $npc[$key][0];
        $whoId = $key;
        Write-Host "`nA suggestion has been made:  $who in the $where";
        $object = Read-Host "Which weapon was used in the murder?";
        $object = $object.Trim();
        if ($object.Length -gt 3) { $object = $object.Substring(0, 3); }
        $synonym = $synoh[$object];
        if ($synonym -ne $null)   { $object = $synonym; }
        $key = $objh[$object];
        if ($key -ne $null)
        {
          if ($obj[$key][5] -gt 0)       # object is weapon?
          {
            $what  = $obj[$key][0];
            $reply = `
              "You suggest `"$who did it in the $where with the $what.`"";
            if ($murderer -ne $whoId)    # incorrect murderer?
            {
              if ($speakerId -eq $whoId) # npc speaker suggested?
              {
                $hints += "I am not the correct suspect.";
              }
              else
              {
                $hints += "$who is not the correct suspect.";
              }
              $refs  += "npc";
              $idxs  += $whoId;
            }
            if ($location -ne $room)     # incorrect location?
            {
              $hints += "The $where is not the correct room.";
              $refs  += "map";
              $idxs  += $room;
            }
            if ($weapon -ne $key)        # incorrect weapon?
            {
              $hints += "The $what is not the correct weapon.";
              $refs  += "obj";
              $idxs  += $key;
            }
            if ($hints.Length -gt 0)
            {

              # Display one random hint from the incorrect suggestion
              $rnd  = (Get-Random -Maximum $hints.Length);
              $hint = $hints[$rnd];
              $ref  = $null;
              $tmp  = $null;
              switch ($refs[$rnd])
              {
                "npc" { $ref = $npc; $tmp = "suspects"; break; }
                "map" { $ref = $map; $tmp = "rooms";    break; }
                "obj" { $ref = $obj; $tmp = "weapons";  break; }
              }
              if ($ref -ne $null)
              {
                $idx   = $idxs[$rnd];
                $reply = "$reply`n  $speaker says `"$hint`"";
                $last  = ($ref[$idx].Length - 1);
                if ($ref[$idx][$last] -eq 0)
                {
                  $safe  = $ref[$idx][0];
                  $reply = "$reply`n  The item `"$safe`" has been marked-off";
                  $reply = "$reply in your notebook.";
                  $reply = "$reply`n  Enter `"check $tmp`" for details.";
                  $ref[$idx][$last] = 1;
                }
                $parsed = $true;
              }

            }
            else
            {
              $reply  = "$speaker says `"That's very interesting.`"";
              $parsed = $true;
            }
          }
        }
      }
    }
    else
    {
      $reply = `
        "There are no living suspects in the room with whom to converse.";
      $parsed = $true;
    }
  }

  # Use command (uses an object)
  if ($command -eq "use")
  {
    if ($inventory -ge 0)                     # have inventory?
    {
      $key = $objh[$object];
      if ($key -ne $null)
      {
        $reply = $obj[$key][0];
        if ($key -eq $inventory)              # object is carried?
        {
          if ($key -eq $bomb)                 # object is bomb?
          {
            if ($obj[$mattress][2] -eq $room) # mattress in room
            {

              # Mattress shields (using the bomb)
              $shield = $obj[$mattress][0];
              $reply  = "The $reply explodes";
              $reply  = "$reply but you are shielded by the $shield.";
              $reply  = "$reply`n  The room smells like burned fertilizer.";
              $obj[$key][2] =  $room;
              $obj[$key][3] =  0;
              $inventory    = -1;

            }
            else
            {

              # Instant death (using the bomb)
              Write-Host `
                "`nThe $reply unexpectedly explodes, killing everyone.";
              Write-Host "You are dead.";
              $running = $false;
              continue;

            }
          }
          elseif ((($key -eq $axe) -or ` # object is blunt instrument
            ($key  -eq $pipe)    -or `   #   and room is kitchen
            ($key  -eq $wrench)) -and `  #   and cellar is locked
            ($room -eq $kitchen) -and ($map[$cellar][8] -gt 0))
          {

            # Some objects break locks
            $reply = "Okay, the lock was broken with the $reply.";
            $map[$cellar][8] =  0;
            $map[$crypt][8]  =  $map[$cellar][8];
            $obj[$key][2]    =  $room;
            $obj[$key][3]    =  0;
            $obj[$lock][3]   =  0;
            $inventory       = -1;

          }
          else
          {

            # All other objects
            $reply = "Okay, nothing happened.";

          }
        }
        else
        {
          $reply = "Are aren't carrying the $reply.";
        }
        $parsed = $true;
      }
    }
    else
    {
      $reply  = "You aren't carrying anything usable.";
      $parsed = $true;
    }
  }

  # Walk command (moves the player around the map)
  if ($command -eq "wal") { $command = $object; }
  switch ($command)
  {
    "nor" { $command = "n";  break; }
    "sou" { $command = "s";  break; }
    "wes" { $command = "w";  break; }
    "eas" { $command = "e";  break; }
    "up"  { $command = "u";  break; }
    "dow" { $command = "d";  break; }
    "sec" { $command = "sd"; break; }
    "doo" { $command = "sd"; break; }
  }
  $next = -1;
  switch ($command)
  {
    "n"  { $next = $map[$room][1]; break; }
    "s"  { $next = $map[$room][2]; break; }
    "w"  { $next = $map[$room][3]; break; }
    "e"  { $next = $map[$room][4]; break; }
    "u"  { $next = $map[$room][5]; break; }
    "d"  { $next = $map[$room][6]; break; }
    "sd" { $next = $map[$room][7]; break; }
    "q"  { $running = $false; break; }
    "x"  { $running = $false; break; }
  }
  if ($next -ge 0)            # next room exists for direction?
  {
    if ($map[$next][8] -eq 0) # next room is not locked?
    {
      $room  = $next;
      $reply = "Okay.";
    }
    else
    {
      $reply = $map[$next][0];
      $reply = "The $reply entrance is locked.";
    }
    $parsed = $true;
  }

  # Unknown command
  if (-not $parsed)
  {
    $reply = "Huh?  You can't do that.";
  }
  $count++;

}

<#
 # Hints:
 # All commands utilize the first three characters of each word only.
 # The murderer, room and weapon are randomized at the start of each game.
 # WALK to the Master Bedroom.
 # READ the DOCUMENT to view Mr. Mortem's original "Last Will and Testament".
 # WALK to the Kitchen.
 # GET the AXE, LEAD PIPE or WRENCH (whatever is found).
 # USE either the AXE, LEAD PIPE or WRENCH to BREAK the Cellar LOCK.
 # GET the CANDLESTICK to dispel the darkness in the Cellar.
 # WALK DOWN into the Cellar.
 # READ the PAPER to reveal an updated "Last Will and Testament".
 # One of the suspects has been removed from Mr. Mortem's new will (murderer).
 # The murderer would not want the new will to be discovered (motive).
 # WALK to the room with Mr. Mortem's remains (crime scene room).
 # EXAMINE the BODY to reveal any signs of trauma.
 # The signs of trauma will help to narrow the choice of murder weapon.
 # CALL any other suspect into the room (if necessary) to make a suggestion.
 # SUGGEST the known murderer and a weapon until the correct weapon is found.
 # The other suspect will indicate whether the suggestion was correct.
 # CHECK ROOMS, SUSPECTS and WEAPONS to track the eliminated items.
 # ACCUSE the known murderer and weapon in the crime scene room.  You win.
 #>

# End the game
Write-Host "`nGoodbye.";
Read-Host  "Press the <Enter> Key to Exit ...";