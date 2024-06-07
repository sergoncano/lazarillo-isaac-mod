LazarilloMod = RegisterMod("El Lazarillo De Tormes", 1)

----------------------------------------------------------------------------- Player setup
include("scripts/lazarillo_player_setup")

----------------------------------------------------------------------------- Beggar mechanics
include("scripts/normal_beggar")
include("scripts/rotten_beggar")
include("scripts/key_master")
include("scripts/bomb_bum")
include("scripts/battery_bum")

----------------------------------------------------------------------------- Shop mechanics
include("scripts/steal_from_shops")

----------------------------------------------------------------------------- Chest mechanics
include("scripts/mega_chest")