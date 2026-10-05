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

SRC_DIR := src
BLD_DIR := build
MAIN    := $(SRC_DIR)/main.asm
SRCS    := $(wildcard $(SRC_DIR)/*.asm $(SRC_DIR)/*.inc)

PRG     := $(BLD_DIR)/$(NAME).prg
D64     := $(BLD_DIR)/$(NAME).d64
LABELS  := $(BLD_DIR)/$(NAME).vs
REPORT  := $(BLD_DIR)/$(NAME).rep

.PHONY: all run debug d64 clean check

all: $(PRG)

$(PRG): $(SRCS) | $(BLD_DIR)
	$(ACME) -f cbm -o $@ --vicelabels $(LABELS) -r $(REPORT) $(MAIN)
	@echo "OK : $@ ($$(stat -c %s $@) octets)"

$(BLD_DIR):
	mkdir -p $@

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
