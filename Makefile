EXE=gammon
SRC=src/*v

.PHONY: all install clean

all: $(EXE)

$(EXE): $(SRC)
	v . -prod

install: $(EXE)
	install $(EXE) /usr/local/bin
	ln -sf /usr/local/bin/gammond /usr/local/bin/$(EXE) 

clean:
	rm $(EXE)
