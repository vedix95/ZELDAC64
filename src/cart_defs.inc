; ===========================================================================
; cart_defs.inc : Définitions et constantes du système Cartouche EasyFlash
; Cartouche 1 Mo (Type 32) - 64 banques x 16 Ko (LoROM $8000 + HiROM $A000)
;   - Banques 00..31 (LoROM) : Code et données ROM non inscriptibles
;   - Banques 56..63 (LoROM) : Secteur Flash 7 (64 Ko) dédié aux sauvegardes
; ===========================================================================

CART_REG                = $de00         ; Registre matériel de sélection de banque (0..63)
CART_CTRL               = $de02         ; Registre de contrôle EasyFlash (Mode + LED)
CART_MODE_8K            = $86           ; LED ON | MEM_CTRL | EXROM=0 ($8000..$9FFF actif)
CART_MODE_16K           = $87           ; LED ON | MEM_CTRL | EXROM=0 | GAME=0
CART_MODE_OFF           = $04           ; MEM_CTRL | EXROM=1 | GAME=1 (Cartouche déconnectée)
CART_DISABLE            = CART_MODE_OFF ; Alias de compatibilité
CART_BANK_SAVE_START    = 56            ; Secteur Flash 7 (banques 56..63 = 64 Ko sauvegardes)

; Tampons de réception en RAM C64
SPRITE_BUF_ADDR         = $2800         ; Tampon des sprites dynamiques ($2800..$3FFF = 6 Ko)
OVERLAY_RAM_ADDR        = $a000         ; Tampon d'exécution des overlays ($A000..$BFFF = 8 Ko sous BASIC)
MAP_DATA_ADDR           = $c000         ; Tampon des cartes actives ($C000..$CCFF = 3.3 Ko)

; Table des banques ROM cartouche (0..63)
CART_BANK_BOOT          = 0             ; Bootloader cartouche (Reset CBM80, déballage intro)
CART_BANK_INTRO_BASE    = 1             ; Banques 1..3 : Intro PRG (RAM $0800..$67FF)
CART_BANK_CORE_BASE     = 4             ; Banques 4..9 : Moteur résident zelda.prg ($0800..$C7FF)

CART_BANK_SPR_OW        = 10            ; Sprites Ennemis Overworld
CART_BANK_SPR_DUNG      = 11            ; Sprites Ennemis Donjon
CART_BANK_SPR_BOSS      = 12            ; Sprites Boss Donjon
CART_BANK_SPR_NPC       = 13            ; Sprites PNJ, Cavernes, Fées & Trésors

CART_BANK_OW0           = 14            ; Chunks Overworld 0..3 (streaming vers $C000)
CART_BANK_OW1           = 15
CART_BANK_OW2           = 16
CART_BANK_OW3           = 17

CART_BANK_DUNG_BASE     = 17            ; Banques 18..26 : Donjons 1 à 9 (1+17=18 .. 9+17=26)

CART_BANK_OVL_INV       = 27            ; Overlay Inventaire & Minimap ($A000)
CART_BANK_OVL_CAVE      = 28            ; Overlay Cavernes & Échoppes ($A000)
CART_BANK_OVL_ITEMS     = 29            ; Overlay Logiques d'Objets Spéciaux ($A000)
CART_BANK_OVL_DEBUG     = 30            ; Overlay Menu Debug ($A000)
CART_BANK_AUDIO         = 31            ; Musiques et sons étendus
CART_BANK_OVL_SAVE      = 32            ; Overlay Sauvegarde EasyFlash & File Select ($A000)
CART_BANK_LINK_SHIELD   = 33            ; Sprites Link Petit Bouclier ($8000) & Bouclier Magique ($8300)
; Banques 34..55 : Libres (ROM non inscriptible)
; Banques 56..63 : Secteur Flash 7 (64 Ko sauvegardes persistantes)
