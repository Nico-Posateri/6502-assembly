# 6502 Assembly Game for the Atari 2600
A collection of micro-projects developed while studying 6502 Assembly for the Atari 2600, culminating in a simple yet complete bomber game.

![0-bomber](https://github.com/Nico-Posateri/6502-assembly-game/assets/141705409/425c29c7-d118-4841-a713-c0e0aa15c00e)

## Assembling and Running the Source Code
**On Windows 10, in order to easily assemble the source code using [DASM](https://dasm-assembler.github.io/), add a new environment variable pathed to \dasm**. In the CLI, navigate your directory to the folder containing the source code you wish to assemble and type `dasm "name1".asm -f3 -v0 -o"name2".bin`, where "name1" is simply the name of the .asm, and "name2" is the desired name of the assembled .bin.

Launch the [Stella Atari 2600 emulator](https://stella-emu.github.io/), navigate once again to the folder containing the project and select the .bin to begin playing.

## Additional Information
These projects make use of [companion header files](https://github.com/munsie/dasm/tree/master/machines/atari2600) provided by [munsie](https://github.com/munsie). The [Gopher2600 emulator](https://github.com/JetSetIlly/Gopher2600) was also used for its debugging tools, and [6502.org](http://www.6502.org/tutorials/6502opcodes.html) proved a useful tool for understanding clockcycles and opcodes.

[6502 Assembly course](https://www.udemy.com/course/programming-games-for-the-atari-2600/) taught by [Gustavo Pezzi](https://github.com/gustavopezzi).
