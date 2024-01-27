EXE=gammon
SRC=src/*v

.PHONY: all install clean

all: $(EXE)

$(EXE): $(SRC)
	v . -prod

install: $(EXE)
	cp $(EXE) /usr/local/bin

clean:
	rm $(EXE)
