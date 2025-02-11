# audionerd/acid

a tb-303-style sequencer for crow + x0x-heart + grid

influenced by Julian Schmidt’s [“Analysis of the µPD650C-133 CPU timing”](http://sonic-potions.com/Documentation/Analysis_of_the_D650C-133_CPU_timing.pdf)

designed for use with the open source [x0x-heart + pacemaker](http://openmusiclabs.com/projects/x0x-heart)

## connections

crow out 1 → x0x-heart cv  
crow out 2 → x0x-heart gate  
crow out 3 → x0x-heart accent  
crow out 4 → x0x-heart slide  

clock → crow in 1 (optional)  

## sequencing

![monome grid](acid.svg)

`playhead` row shows current step during playback, and a cursor for the currently selected step when editing.

press a step on the `playhead` row to select it. the `keyboard` will display the note assigned to the step, which can be changed by pressing a `keyboard` key.

for each step:
- `gate/accent` can be off, gate on, or accent on
- `slide` can be off or on
- `up`/`down` set the octave of the note

hold `meta` and select a `gate/accent` step to immediately turn it off.

## step values
go to the `acid steps` PARAMETERS sub-menu to change step amount, step start, and step end.

## save/load patterns
go to the `acid data` PARAMETERS sub-menu to save and load patterns.

## future
- range selection
- crow "satellite" mode (allow continued playback disconnected from norns, re-connect to edit pattern)
- random pattern generation
- MIDI out support
