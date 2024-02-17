EXE=gammon
SERVICE=gammond
SRC=src/*v
INSTALL_DIR=/usr/local/bin

.PHONY: all install uninstall clean

all: $(EXE)

$(EXE): $(SRC)
	v install --once
	v . -prod

install: $(EXE)
	install $(EXE) $(INSTALL_DIR)
	ln -sf $(INSTALL_DIR)/$(EXE) $(INSTALL_DIR)/$(SERVICE) 

uninstall:
	rm -f $(INSTALL_DIR)/$(EXE) $(INSTALL_DIR)/$(SERVICE)

clean:
	rm $(EXE)
