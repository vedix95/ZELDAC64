# ---------------------------------------------------------------------------
# Projet C64 : Zelda
#   make          -> assemble build/zelda.prg
#   make run      -> assemble puis lance dans VICE (x64sc)
#   make debug    -> idem, avec les labels chargés dans le moniteur VICE
#   make d64      -> crée une image disque build/zelda.d64
#   make clean    -> supprime build/
#   make check    -> vérifie que les outils sont installés
# ---------------------------------------------------------------------------

NAME    := zelda
ACME    ?= acme
VICE    ?= x64sc
C1541   ?= c1541
PYTHON  ?= python3

SRC_DIR := src
BLD_DIR := build
MAIN    := $(SRC_DIR)/main.asm
GEN     := $(SRC_DIR)/sprites.asm $(SRC_DIR)/charset.asm $(SRC_DIR)/map_data.asm
SRCS    := $(sort $(wildcard $(SRC_DIR)/*.asm $(SRC_DIR)/*.inc) $(GEN))

PRG     := $(BLD_DIR)/$(NAME).prg
D64     := $(BLD_DIR)/$(NAME).d64
LABELS  := $(BLD_DIR)/$(NAME).vs
REPORT  := $(BLD_DIR)/$(NAME).rep

.PHONY: all run debug d64 clean check preview

all: $(PRG)

# sprites.asm est généré depuis l'ASCII art (assets/link.txt)
$(SRC_DIR)/sprites.asm: assets/link.txt tools/sprgen.py
	$(PYTHON) tools/sprgen.py assets/link.txt -o $@

# charset.asm et map_data.asm sont générés ensemble (cible groupée : make >= 4.3)
$(SRC_DIR)/charset.asm $(SRC_DIR)/map_data.asm &: assets/tiles.txt assets/map.txt tools/tilegen.py
	$(PYTHON) tools/tilegen.py assets/tiles.txt assets/map.txt \
		--charset $(SRC_DIR)/charset.asm --map-out $(SRC_DIR)/map_data.asm

$(PRG): $(SRCS) | $(BLD_DIR)
	$(ACME) -f cbm -o $@ --vicelabels $(LABELS) -r $(REPORT) $(MAIN)
	@echo "OK : $@ ($$(stat -c %s $@) octets)"

$(BLD_DIR):
	mkdir -p $@

# Aperçus PNG : build/link_preview.png et build/map_preview.png
preview: | $(BLD_DIR)
	$(PYTHON) tools/sprgen.py assets/link.txt -o $(SRC_DIR)/sprites.asm --preview $(BLD_DIR)/link_preview.png
	$(PYTHON) tools/tilegen.py assets/tiles.txt assets/map.txt \
		--charset $(SRC_DIR)/charset.asm --map-out $(SRC_DIR)/map_data.asm \
		--preview $(BLD_DIR)/map_preview.png
	@echo "Aperçus : $(BLD_DIR)/link_preview.png $(BLD_DIR)/map_preview.png"

run: $(PRG)
	$(VICE) -autostart $(PRG)

debug: $(PRG)
	$(VICE) -moncommands $(LABELS) -autostart $(PRG)

d64: $(PRG)
	$(C1541) -format "$(NAME),01" d64 $(D64) -write $(PRG) $(NAME)

clean:
	rm -rf $(BLD_DIR)

check:
	@./scripts/check-env.sh
