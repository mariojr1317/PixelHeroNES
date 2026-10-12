TARGET := pixel-hero
CA65 := ca65
LD65 := ld65
SRC := src/main.asm
OBJ := build/main.o

.PHONY: all clean

all: $(TARGET).nes

build:
	mkdir -p build

$(OBJ): $(SRC) | build
	$(CA65) $(SRC) -o $(OBJ)

$(TARGET).nes: $(OBJ) cfg/nes.cfg
	$(LD65) -C cfg/nes.cfg $(OBJ) -o $@

clean:
	rm -rf build $(TARGET).nes
