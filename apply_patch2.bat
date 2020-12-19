SET ROM_DIR=H:\ffight3p\gittest\mame0206\roms

del build\megaman_hack.bin
copy build\megaman.bin build\megaman_hack.bin

Asm68k.exe /p megaman_hack.asm, build\megaman_hack.bin

del build\out\rcmu_23b.8f
del build\out\rcmu_22b.7f
del build\out\rcmu_21a.6f

java -jar RomMangler.jar split megaman_out_split.cfg build\megaman_hack.bin

del %ROM_DIR%\megaman.zip

java -jar RomMangler.jar zipdir build\out %ROM_DIR%\megaman.zip

pause