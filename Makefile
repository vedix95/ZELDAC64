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
PYTHON  ?= python3

SRC_DIR := src
BLD_DIR := build
MAIN    := $(SRC_DIR)/main.asm
OW_DATS    := $(foreach n,0 1 2 3,$(BLD_DIR)/ow$(n).dat)
DUNG_DATS  := $(foreach n,1 2 3 4 5 6 7 8 9,$(BLD_DIR)/dung$(n).dat)
GEN_MAPS   := $(SRC_DIR)/map_overworld.asm $(SRC_DIR)/map_underworld.asm $(SRC_DIR)/ow0.asm $(SRC_DIR)/ow1.asm $(SRC_DIR)/ow2.asm $(SRC_DIR)/ow3.asm
GEN        := $(SRC_DIR)/sprites.asm $(SRC_DIR)/sprites_enemies.asm $(SRC_DIR)/sprites_extra.asm $(SRC_DIR)/charset.asm $(SRC_DIR)/tiles_data.asm
DUNG_ASMS  := $(foreach n,1 2 3 4 5 6 7 8 9,$(SRC_DIR)/dung$(n).asm)
SRCS       := $(filter-out $(DUNG_ASMS) $(SRC_DIR)/ow%.asm $(SRC_DIR)/map_overworld.asm $(SRC_DIR)/map_underworld.asm, $(sort $(wildcard $(SRC_DIR)/*.asm $(SRC_DIR)/*.inc) $(GEN)))

PRG     := $(BLD_DIR)/$(NAME).prg
PRG_INT := $(BLD_DIR)/intro.prg
CRT     := $(BLD_DIR)/$(NAME).crt
LABELS  := $(BLD_DIR)/$(NAME).vs
REPORT  := $(BLD_DIR)/$(NAME).rep

.PHONY: all run run-game run-crt debug crt clean distclean check preview maps extract-music atlas assets-sheet

all: $(CRT)

# sprites.asm est généré depuis l'ASCII art (assets/link.txt)
$(SRC_DIR)/sprites.asm: assets/link.txt tools/sprgen.py
	$(PYTHON) tools/sprgen.py assets/link.txt -o $@

# sprites_enemies.asm est généré depuis assets/enemies.txt
$(SRC_DIR)/sprites_enemies.asm: assets/enemies.txt tools/sprgen.py
	$(PYTHON) tools/sprgen.py assets/enemies.txt -o $@

# sprites_extra.asm (Old Man, Item Get) est généré depuis assets/extra.txt
$(SRC_DIR)/sprites_extra.asm: assets/extra.txt tools/sprgen.py
	$(PYTHON) tools/sprgen.py assets/extra.txt --prefix link -o $@

# music_data.inc, music_data_low.inc et cart_audio.bin sont générés depuis assets/music_data.json
$(SRC_DIR)/music_data.inc $(SRC_DIR)/music_data_low.inc $(BUILD_DIR)/cart_audio.bin &: assets/music_data.json tools/generate_game_audio.py
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
$(PRG): $(SRCS) $(BLD_DIR)/sprite_ptrs.inc | $(BLD_DIR)
	$(ACME) -f cbm -o $@ --vicelabels $(LABELS) -r $(REPORT) $(MAIN)
	@echo "OK : $@ ($$(stat -c %s $@) octets)"

$(PRG_INT): $(SRC_DIR)/intro_main.asm $(SRC_DIR)/intro.asm $(SRC_DIR)/intro_music_data.asm $(SRC_DIR)/intro_monsters_data.asm $(SRC_DIR)/intro_charset.asm $(SRC_DIR)/input.asm | $(BLD_DIR)
	$(ACME) -f cbm -o $@ --vicelabels $(BLD_DIR)/intro.vs $<
	@echo "OK : $@ ($$(stat -c %s $@) octets)"

SPR_BINS   := $(BLD_DIR)/sprites_ow.bin $(BLD_DIR)/sprites_dung.bin $(BLD_DIR)/sprites_boss.bin $(BLD_DIR)/sprites_npc.bin
OVL_DATS   := $(BLD_DIR)/ovl_inv.dat $(BLD_DIR)/ovl_cave.dat $(BLD_DIR)/ovl_items.dat $(BLD_DIR)/ovl_debug.dat

$(BLD_DIR)/sprite_ptrs.inc $(SPR_BINS) &: assets/enemies.txt assets/extra.txt tools/build_sprite_banks.py | $(BLD_DIR)
	$(PYTHON) tools/build_sprite_banks.py

$(BLD_DIR)/resident_symbols.inc: $(PRG) tools/vs2inc.py | $(BLD_DIR)
	$(PYTHON) tools/vs2inc.py $(LABELS) $@

$(BLD_DIR)/ovl_inv.dat: $(SRC_DIR)/overlay_inventory.asm $(SRC_DIR)/inventory.asm $(SRC_DIR)/inventory_draw.asm $(BLD_DIR)/resident_symbols.inc | $(BLD_DIR)
	$(ACME) -f plain -o $@ $<

$(BLD_DIR)/ovl_cave.dat: $(SRC_DIR)/overlay_cave.asm $(SRC_DIR)/cave.asm $(BLD_DIR)/resident_symbols.inc | $(BLD_DIR)
	$(ACME) -f plain -o $@ $<

$(BLD_DIR)/ovl_items.dat: $(SRC_DIR)/overlay_items.asm $(BLD_DIR)/resident_symbols.inc | $(BLD_DIR)
	$(ACME) -f plain -o $@ $<

$(BLD_DIR)/ovl_debug.dat: $(SRC_DIR)/overlay_debug.asm $(SRC_DIR)/debug.asm $(BLD_DIR)/resident_symbols.inc | $(BLD_DIR)
	$(ACME) -f plain -o $@ $<

# Image cartouche Magic Desk CRT (512 Ko) avec 64 banques mémoires et streaming instantané
$(CRT): $(PRG) $(OW_DATS) $(DUNG_DATS) $(SPR_BINS) $(OVL_DATS) $(PRG_INT) tools/cartgen.py src/cart_boot.asm
	$(PYTHON) tools/cartgen.py

crt: $(CRT)

# Lance le jeu directement depuis la cartouche (0 délai de chargement, streaming instantané)
run: $(CRT)
	$(VICE) -cartcrt $(CRT)

run-game: $(CRT)
	$(VICE) -cartcrt $(CRT)

run-crt: $(CRT)
	$(VICE) -cartcrt $(CRT)

debug: $(CRT)
	$(VICE) -moncommands $(LABELS) -cartcrt $(CRT)

$(BLD_DIR):
	mkdir -p $@

# Aperçus PNG des sprites et tuiles
preview: | $(BLD_DIR)
	$(PYTHON) tools/sprgen.py assets/link.txt -o $(SRC_DIR)/sprites.asm --preview $(BLD_DIR)/link_preview.png
	$(PYTHON) tools/sprgen.py assets/enemies.txt -o $(SRC_DIR)/sprites_enemies.asm --preview $(BLD_DIR)/enemies_preview.png
	$(PYTHON) tools/tilegen.py assets/tiles.txt assets/world.txt \
		--charset $(SRC_DIR)/charset.asm --tiles-out $(SRC_DIR)/tiles_data.asm --map-out $(SRC_DIR)/map_overworld.asm \
		--preview $(BLD_DIR)/world_preview.png
	@echo "Aperçus : $(BLD_DIR)/link_preview.png $(BLD_DIR)/enemies_preview.png $(BLD_DIR)/world_preview.png"

# Génération des cartes complètes PNG de l'Overworld et des 9 Donjons
maps: | $(BLD_DIR)
	$(PYTHON) tools/render_maps.py

# Extraction et génération de l'atlas graphique complet et des planches de contact PNG
atlas: | $(BLD_DIR)
	$(PYTHON) tools/export_assets_sheet.py --all
	@echo "Atlas graphique généré dans $(BLD_DIR)/atlas_all_assets.png"

assets-sheet: atlas

clean:
	rm -rf $(BLD_DIR)

distclean: clean
	rm -f $(GEN) $(GEN_MAPS) $(SRC_DIR)/dung*.asm

check:
	@./scripts/check-env.sh


