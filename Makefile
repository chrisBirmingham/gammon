EXE=gammon
SRC=src/*v

.PHONY: all install clean

all: $(EXE)

$(EXE): $(SRC)
	v . -prod

install: $(EXE)
	cp $(EXE) /usr/local/bin
	cp config/$(EXE).json /etc

clean:
	rm $(EXE)
