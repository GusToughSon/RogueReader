What is it? <BR>
Its a thing<BR>
how does it work?<BR>
I dont know...<BR>
RogueReader<BR>

Key Components:<BR>

Memory Reading: You are using NomadMemory.au3 to read from specific<BR>
memory addresses like Type, HP, MaxHP, and Pos X/Y, which are handled<BR>
correctly using the base address and offsets.

GUI: The GUI includes all labels and controls for displaying relevant<BR>
information, along with buttons for terminating the process and exiting<BR>
the script.<BR>
 
Healer Logic: You have correctly implemented the logic to check if the <BR>
HealerStatus is ON and compare HP2 with the healing threshold from the <BR>
slider. It sends the "2" key if the conditions are met, followed by the <BR>
defined sleep interval (pottimer).

Hotkey Handling: The use of backtick (~) to toggle HealerStatus` is working <BR>
as expected with a sleep buffer to avoid rapid toggling.<BR>

Target Logic: The attack mode and target logic for sending {TAB} and waiting <BR>
are also well implemented.