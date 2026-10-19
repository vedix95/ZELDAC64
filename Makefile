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
OW_DATS    := $(foreach n,0 1 2 3,$(BLD_DIR)/ow$(n).dat)
DUNG_DATS  := $(foreach n,1 2 3 4 5 6 7 8 9,$(BLD_DIR)/dung$(n).dat)
GEN_MAPS   := $(SRC_DIR)/map_overworld.asm $(SRC_DIR)/map_underworld.asm $(SRC_DIR)/ow0.asm $(SRC_DIR)/ow1.asm $(SRC_DIR)/ow2.asm $(SRC_DIR)/ow3.asm
GEN        := $(SRC_DIR)/sprites.asm $(SRC_DIR)/sprites_enemies.asm $(SRC_DIR)/sprites_extra.asm $(SRC_DIR)/charset.asm $(SRC_DIR)/tiles_data.asm
SRCS       := $(filter-out $(SRC_DIR)/dung%.asm $(SRC_DIR)/ow%.asm $(SRC_DIR)/map_overworld.asm $(SRC_DIR)/map_underworld.asm, $(sort $(wildcard $(SRC_DIR)/*.asm $(SRC_DIR)/*.inc) $(GEN)))

PRG     := $(BLD_DIR)/$(NAME).prg
PRG_INT := $(BLD_DIR)/intro.prg
D64     := $(BLD_DIR)/$(NAME).d64
LABELS  := $(BLD_DIR)/$(NAME).vs
REPORT  := $(BLD_DIR)/$(NAME).rep

.PHONY: all run run-game debug d64 clean distclean check preview editor extract-music

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

# music_data.inc est généré depuis assets/music_data.json
$(SRC_DIR)/music_data.inc: assets/music_data.json tools/generate_game_audio.py
	$(PYTHON) tools/generate_game_audio.py

# Extraction des partitions authentiques depuis zelda.nes (optionnel pour dev local)
extract-music: tools/extract_music.py
	$(PYTHON) tools/extract_music.py

# charset.asm, tiles_data.asm, ow0..ow3.asm, map_overworld.asm et map_underworld.asm sont générés ensemble
$(SRC_DIR)/charset.asm $(SRC_DIR)/tiles_data.asm $(SRC_DIR)/map_overworld.asm $(SRC_DIR)/map_underworld.asm $(SRC_DIR)/ow0.asm $(SRC_DIR)/ow1.asm $(SRC_DIR)/ow2.asm $(SRC_DIR)/ow3.asm &: assets/tiles.txt assets/world.txt assets/underworld.txt tools/tilegen.py
	$(PYTHON) tools/tilegen.py assets/tiles.txt assets/world.txt \
		--charset $(SRC_DIR)/charset.asm --tiles-out $(SRC_DIR)/tiles_data.asm --map-out $(SRC_DIR)/map_overworld.asm \
		--underworld assets/underworld.txt --underworld-out $(SRC_DIR)/map_underworld.asm

# Chunks Overworld (OW0..OW3) compilés sous forme de fichiers binaires séparés à charger à $C000
$(BLD_DIR)/ow%.dat: $(SRC_DIR)/ow%.asm $(SRC_DIR)/enemy_types.inc | $(BLD_DIR)
	$(ACME) -f cbm -o $@ $<
	@echo "OK : $@ ($$(stat -c %s $@) octets)"

# Donjons 1 à 9 autonomes générés et compilés individuellement à $C000
$(SRC_DIR)/dung1.asm $(SRC_DIR)/dung2.asm $(SRC_DIR)/dung3.asm $(SRC_DIR)/dung4.asm $(SRC_DIR)/dung5.asm $(SRC_DIR)/dung6.asm $(SRC_DIR)/dung7.asm $(SRC_DIR)/dung8.asm $(SRC_DIR)/dung9.asm &: assets/underworld.txt tools/build_dungeons.py
	$(PYTHON) tools/build_dungeons.py

$(BLD_DIR)/dung%.dat: $(SRC_DIR)/dung%.asm $(SRC_DIR)/enemy_types.inc | $(BLD_DIR)
	$(ACME) -f cbm -o $@ $<
	@echo "OK : $@ ($$(stat -c %s $@) octets)"

# Binaire principal du jeu (Moteur de jeu résident en mémoire)
$(PRG): $(SRCS) | $(BLD_DIR)
	$(ACME) -f cbm -o $@ --vicelabels $(LABELS) -r $(REPORT) $(MAIN)
	@echo "OK : $@ ($$(stat -c %s $@) octets)"

$(PRG_INT): $(SRC_DIR)/intro_main.asm $(SRC_DIR)/intro.asm $(SRC_DIR)/intro_music_data.asm $(SRC_DIR)/intro_monsters_data.asm $(SRC_DIR)/charset.asm $(SRC_DIR)/input.asm | $(BLD_DIR)
	$(ACME) -f cbm -o $@ $<
	@echo "OK : $@ ($$(stat -c %s $@) octets)"

# Image disquette D64 : contient INTRO, ZELDA (moteur résident), OW0..OW3 (chunks Overworld) et les 9 Donjons
$(D64): $(PRG_INT) $(PRG) $(OW_DATS) $(DUNG_DATS)
	$(C1541) -format "$(NAME),01" d64 $@ \
		-write $(PRG_INT) intro \
		-write $(PRG) zelda \
		-write $(BLD_DIR)/ow0.dat ow0 \
		-write $(BLD_DIR)/ow1.dat ow1 \
		-write $(BLD_DIR)/ow2.dat ow2 \
		-write $(BLD_DIR)/ow3.dat ow3 \
		-write $(BLD_DIR)/dung1.dat dung1 \
		-write $(BLD_DIR)/dung2.dat dung2 \
		-write $(BLD_DIR)/dung3.dat dung3 \
		-write $(BLD_DIR)/dung4.dat dung4 \
		-write $(BLD_DIR)/dung5.dat dung5 \
		-write $(BLD_DIR)/dung6.dat dung6 \
		-write $(BLD_DIR)/dung7.dat dung7 \
		-write $(BLD_DIR)/dung8.dat dung8 \
		-write $(BLD_DIR)/dung9.dat dung9
	@echo "OK : $@ image disquette D64 prete (INTRO + ZELDA + 4 CHUNKS OVERWORLD + 9 DONJONS) !"


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
	rm -f $(GEN) $(GEN_MAPS) $(SRC_DIR)/dung*.asm

check:
	@./scripts/check-env.sh

editor:
	$(PYTHON) tools/editor.py

