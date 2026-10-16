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
PRG_OW_MAP := $(BLD_DIR)/map_ow.dat
PRG_UW_MAP := $(BLD_DIR)/map_uw.dat
GEN_MAPS   := $(SRC_DIR)/map_overworld.asm $(SRC_DIR)/map_underworld.asm
GEN        := $(SRC_DIR)/sprites.asm $(SRC_DIR)/sprites_enemies.asm $(SRC_DIR)/sprites_extra.asm $(SRC_DIR)/charset.asm $(SRC_DIR)/tiles_data.asm
SRCS       := $(sort $(wildcard $(SRC_DIR)/*.asm $(SRC_DIR)/*.inc) $(GEN))

PRG     := $(BLD_DIR)/$(NAME).prg
PRG_INT := $(BLD_DIR)/intro.prg
D64     := $(BLD_DIR)/$(NAME).d64
LABELS  := $(BLD_DIR)/$(NAME).vs
REPORT  := $(BLD_DIR)/$(NAME).rep

.PHONY: all run run-game debug d64 clean distclean check preview editor

all: $(D64)

# sprites.asm est généré depuis l'ASCII art (assets/link.txt)
$(SRC_DIR)/sprites.asm: assets/link.txt tools/sprgen.py
	$(PYTHON) tools/sprgen.py assets/link.txt -o $@

# sprites_enemies.asm est généré depuis assets/enemies.txt
$(SRC_DIR)/sprites_enemies.asm: assets/enemies.txt tools/sprgen.py
	$(PYTHON) tools/sprgen.py assets/enemies.txt -o $@

# sprites_extra.asm (Old Man, Item Get) est généré depuis assets/extra.txt
$(SRC_DIR)/sprites_extra.asm: assets/extra.txt tools/sprgen.py
	$(PYTHON) tools/sprgen.py assets/extra.txt --prefix link -o $@

# charset.asm, tiles_data.asm, map_overworld.asm et map_underworld.asm sont générés ensemble
$(SRC_DIR)/charset.asm $(SRC_DIR)/tiles_data.asm $(SRC_DIR)/map_overworld.asm $(SRC_DIR)/map_underworld.asm &: assets/tiles.txt assets/world.txt assets/underworld.txt tools/tilegen.py
	$(PYTHON) tools/tilegen.py assets/tiles.txt assets/world.txt \
		--charset $(SRC_DIR)/charset.asm --tiles-out $(SRC_DIR)/tiles_data.asm --map-out $(SRC_DIR)/map_overworld.asm \
		--underworld assets/underworld.txt --underworld-out $(SRC_DIR)/map_underworld.asm

# Cartes Overworld et Donjons compilées sous forme de fichiers binaires séparés à charger à $A000
$(PRG_OW_MAP): $(SRC_DIR)/map_overworld.asm | $(BLD_DIR)
	$(ACME) -f cbm -o $@ $<
	@echo "OK : $@ ($$(stat -c %s $@) octets)"

$(PRG_UW_MAP): $(SRC_DIR)/map_underworld.asm | $(BLD_DIR)
	$(ACME) -f cbm -o $@ $<
	@echo "OK : $@ ($$(stat -c %s $@) octets)"

# Binaire principal du jeu (Moteur de jeu résident en mémoire)
$(PRG): $(SRCS) | $(BLD_DIR)
	$(ACME) -f cbm -o $@ --vicelabels $(LABELS) -r $(REPORT) $(MAIN)
	@echo "OK : $@ ($$(stat -c %s $@) octets)"

# Programme d'introduction autonome (Cascade, Légende, Trésors, Musique SID)
$(PRG_INT): $(SRC_DIR)/intro_main.asm $(SRC_DIR)/intro.asm $(SRC_DIR)/intro_music_data.asm $(SRC_DIR)/charset.asm $(SRC_DIR)/input.asm | $(BLD_DIR)
	$(ACME) -f cbm -o $@ $<
	@echo "OK : $@ ($$(stat -c %s $@) octets)"

# Image disquette D64 : contient INTRO, ZELDA (moteur résident), MAP_OW et MAP_UW
$(D64): $(PRG_INT) $(PRG) $(PRG_OW_MAP) $(PRG_UW_MAP)
	$(C1541) -format "$(NAME),01" d64 $@ \
		-write $(PRG_INT) intro \
		-write $(PRG) zelda \
		-write $(PRG_OW_MAP) map_ow \
		-write $(PRG_UW_MAP) map_uw
	@echo "OK : $@ image disquette D64 prete (INTRO + ZELDA + MAP_OW + MAP_UW) !"


$(BLD_DIR):
	mkdir -p $@

# Aperçus PNG : build/link_preview.png, enemies_preview.png et world_preview.png
preview: | $(BLD_DIR)
	$(PYTHON) tools/sprgen.py assets/link.txt -o $(SRC_DIR)/sprites.asm --preview $(BLD_DIR)/link_preview.png
	$(PYTHON) tools/sprgen.py assets/enemies.txt -o $(SRC_DIR)/sprites_enemies.asm --preview $(BLD_DIR)/enemies_preview.png
	$(PYTHON) tools/tilegen.py assets/tiles.txt assets/world.txt \
		--charset $(SRC_DIR)/charset.asm --tiles-out $(SRC_DIR)/tiles_data.asm --map-out $(SRC_DIR)/map_overworld.asm \
		--preview $(BLD_DIR)/world_preview.png
	@echo "Aperçus : $(BLD_DIR)/link_preview.png $(BLD_DIR)/enemies_preview.png $(BLD_DIR)/world_preview.png"

# Lance la disquette complète (démarre par l'intro puis enchaîne sur le jeu)
run: $(D64)
	$(VICE) +drive8truedrive -trapdevice8 -autostart $(D64)

# Lance directement le jeu sans passer par l'intro (démarrage instantané)
run-game: $(PRG) $(D64)
	$(VICE) -autostart $(PRG) -8 $(D64)

debug: $(D64)
	$(VICE) +drive8truedrive -trapdevice8 -moncommands $(LABELS) -autostart $(D64)

d64: $(D64)

clean:
	rm -rf $(BLD_DIR)

distclean: clean
	rm -f $(GEN) $(GEN_MAPS)

check:
	@./scripts/check-env.sh

editor:
	$(PYTHON) tools/editor.py

