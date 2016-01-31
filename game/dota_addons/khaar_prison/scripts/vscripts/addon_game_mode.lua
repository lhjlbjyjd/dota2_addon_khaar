-- This is the entry-point to your game mode and should be used primarily to precache models/particles/sounds/etc

require('internal/util')
require('gamemode')
require('creeps_ai')

local i = 1
local id = -1
local team_point = {}
local players_telepoted = false
local players_count = 0
local repeats = 0
local creep_spawn_point = {}
local radiant_players = {}
local dire_players = {}
local players_heave_heroes = {}
local pre_start_check_completed = false
local DOTA_ATTAСKER_UNITS_COUNT_IN_WAVE = 15
local DOTA_ATTAСK_WAVE = 1

function Precache( context )
PrecacheUnitByNameSync("npc_dota_hero_sven", context)
  PrecacheUnitByNameSync("npc_dota_hero_wisp", context)
  PrecacheUnitByNameSync("npc_dota_hero_nevermore", context)
  PrecacheUnitByNameSync("npc_dota_hero_antimage", context)

  DebugPrint("[BAREBONES] Performing pre-load precache")

  -- Particles can be precached individually or by folder
  -- It it likely that precaching a single particle system will precache all of its children, but this may not be guaranteed
  PrecacheResource("particle", "particles/econ/generic/generic_aoe_explosion_sphere_1/generic_aoe_explosion_sphere_1.vpcf", context)
  PrecacheResource("particle_folder", "particles/test_particle", context)

  -- Models can also be precached by folder or individually
  -- PrecacheModel should generally used over PrecacheResource for individual models
  PrecacheResource("model_folder", "particles/heroes/antimage", context)
  PrecacheResource("model", "particles/heroes/viper/viper.vmdl", context)
  PrecacheModel("models/heroes/viper/viper.vmdl", context)

  -- Sounds can precached here like anything else
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_gyrocopter.vsndevts", context)

  -- Entire items can be precached by name
  -- Abilities can also be precached in this way despite the name
  PrecacheItemByNameSync("example_ability", context)
  PrecacheItemByNameSync("item_example_item", context)

  -- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
  -- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way
end

-- Create the game mode when we activate
function Activate()
  GameRules.GameMode = GameMode()
  GameRules.GameMode:InitGameMode()
end

function GameMode:InitGameMode()
  print( "HORDE is loaded." )
  GameRules:SetHeroSelectionTime( 0.0 )
  GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )
  GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )
  GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 8 )
  GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 1 )
  GameRules:SetUseUniversalShopMode( true )
  GameRules:SetTimeOfDay( 0.75 )
  GameRules:SetHeroRespawnEnabled( true )
  GameRules:SetPreGameTime( 10.0 )
  GameRules:SetPostGameTime( 60.0 )
  GameRules:SetTreeRegrowTime( 60.0 )
  GameRules:SetHeroMinimapIconScale( 0.7 )
  GameRules:SetCreepMinimapIconScale( 0.7 )
  GameRules:SetRuneMinimapIconScale( 0.7 )
  GameRules:SetGoldTickTime( 1.0 )
  GameRules:SetGoldPerTick( 1.0 )
  GameRules:GetGameModeEntity():SetCustomGameForceHero( "npc_dota_hero_antimage" )
  GameRules:GetGameModeEntity():SetRemoveIllusionsOnDeath( true )
  GameRules:GetGameModeEntity():SetTopBarTeamValuesOverride( true )
  GameRules:GetGameModeEntity():SetTopBarTeamValuesVisible( false )
  GameRules:GetGameModeEntity():SetCameraDistanceOverride(1600)
  ListenToGameEvent( 'game_rules_state_change', Dynamic_Wrap(GameMode,'OnGameRulesChange'), self)
  ListenToGameEvent('npc_spawned', Dynamic_Wrap(GameMode, 'OnNPCSpawned'), self)
  table.insert(creep_spawn_point, Entities:FindByName( nil, "spawn_point_1" ):GetAbsOrigin())
  table.insert(creep_spawn_point, Entities:FindByName( nil, "spawn_point_2" ):GetAbsOrigin())
  table.insert(creep_spawn_point, Entities:FindByName( nil, "spawn_point_3" ):GetAbsOrigin())
  table.insert(creep_spawn_point, Entities:FindByName( nil, "spawn_point_4" ):GetAbsOrigin())
  table.insert(team_point, Entities:FindByName( nil, "point_teleport_spot_team_1" ):GetAbsOrigin())
  table.insert(team_point, Entities:FindByName( nil, "point_teleport_spot_team_2" ):GetAbsOrigin())
  table.insert(team_point, Entities:FindByName( nil, "point_teleport_spot_team_3" ):GetAbsOrigin())
  table.insert(team_point, Entities:FindByName( nil, "point_teleport_spot_team_4" ):GetAbsOrigin())
end

function GameMode:OnGameRulesChange(keys)
  if GameRules:State_Get() == DOTA_GAMERULES_STATE_STRATEGY_TIME then 
    SendToConsole("dota_camera_center")
  elseif GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
  end 
end 

function GameMode:OnNPCSpawned(keys)
  local npc = EntIndexToHScript(keys.entindex)
  if npc:IsRealHero() and npc.bFirstSpawned == nil then
    npc.bFirstSpawned = true
    print("HERO SPAWNED")
    Timers:CreateTimer(0.5, function()
      GameMode:HeroSpawned(npc)
    end)
  else 
  end  
end

function GameMode:OnThink()
  print('Think')
  if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    GameMode:SpawnAttakers()
  return 30
  elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
    return nil
  end 
  return 0.1
end

function GameMode:PlayerHaveNoHero(keys)
  local playerID = keys
    for _,v in pairs(players_heave_heroes) do
      if v == playerID then
        return false
      end
    end
    table.insert(players_heave_heroes, playerID)
    return true      
end

function GameMode:HeroSpawned(keys)
  local npc = keys
  local sven_team_point = 0
  local point
  local hero
  if GameMode:PlayerHaveNoHero(npc:GetPlayerID()) == true then
    if PlayerResource:GetTeam(npc:GetPlayerID()) == DOTA_TEAM_GOODGUYS then
      if repeats < 4 then
        print("Giving player " .. npc:GetPlayerOwnerID() .. "a new hero")
        for k,v in pairs(team_point) do
          if k == (repeats + 1) then
            point = v
          end  
        end 
        hero =  PlayerResource:ReplaceHeroWith(npc:GetPlayerOwnerID(), "npc_dota_hero_wisp", 625, 0)
        FindClearSpaceForUnit(hero, point, false)
        repeats = repeats + 1
      else  
        for k,v in pairs(team_point) do
          if k == (sven_team_point + 1) then
            point = v
          end  
        end
        PlayerResource:ReplaceHeroWith(npc:GetPlayerOwnerID(), "npc_dota_hero_sven", 625, 0)
        FindClearSpaceForUnit(PlayerResource:ReplaceHeroWith(npc:GetPlayerOwnerID(), "npc_dota_hero_wisp", 625, 0), point, false)
        sven_team_point= sven_team_point + 1  
      end  
    else 
      PlayerResource:ReplaceHeroWith(npc:GetPlayerOwnerID(), "npc_dota_hero_nevermore", 625, 0)    
    end
  end  
end

function GameMode:SpawnAttakers()

local attack_units = {
  "npc_dota_creature_kobold_tunneler",
  "npc_dota_creature_gnoll_assassin",
  "npc_dota_creature_troll_healer",
  "npc_dota_creature_basic_zombie",
  "npc_dota_creature_basic_zombie_exploding",
  "npc_dota_creature_corpselord",
  "npc_dota_creature_lesser_nightcrawler",
  "npc_dota_creature_berserk_zombie"
}

for i=1, DOTA_ATTAСKER_UNITS_COUNT_IN_WAVE do
  for q=1, 4 do
    CreateUnitByName( attack_units[ DOTA_ATTAСK_WAVE ], creep_spawn_point[q] , true, nil, nil, DOTA_TEAM_BADGUYS )
  end  
end 

for _,v in pairs( Entities:FindAllByClassname( attack_units[ DOTA_ATTAСK_WAVE ] ) ) do
  CreepsAI:MakeInstance(v,{spawnPos = v:GetAbsOrigin(), aggroRange = 0, leashRange = 0})
end 

DOTA_ATTAСK_WAVE = DOTA_ATTAСK_WAVE + 1

end