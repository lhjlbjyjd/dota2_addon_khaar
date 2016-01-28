-- This is the entry-point to your game mode and should be used primarily to precache models/particles/sounds/etc

require('internal/util')
require('gamemode')

local i = 1
local id = -1
local team_point = {}
local players_telepoted = false
local players_count = 0
local repeats = 0
local radiant_players = {}
local dire_players = {}
local players_heave_heroes = {}
local pre_start_check_completed = false

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
  table.insert(team_point, {Entities:FindByName( nil, "point_teleport_spot_team_1" ):GetAbsOrigin(),
                            Entities:FindByName( nil, "point_teleport_spot_team_2" ):GetAbsOrigin(),
                            Entities:FindByName( nil, "point_teleport_spot_team_3" ):GetAbsOrigin(),
                            Entities:FindByName( nil, "point_teleport_spot_team_4" ):GetAbsOrigin()
              })
  GameRules:SetHeroSelectionTime( 0.0 )
  --GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )
  GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 8 )
  GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 1 )
  GameRules:SetUseUniversalShopMode( true )
  GameRules:SetTimeOfDay( 0.75 )
  GameRules:SetHeroRespawnEnabled( true )
  GameRules:SetPreGameTime( 2.0 )
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
    print(PlayerResource:IsValidPlayer(npc:GetPlayerOwnerID()))
    Timers:CreateTimer(0.5, function()
      GameMode:HeroSpawned(npc)
    end)
end

function GameMode:OnThink()
  print('Think')
  if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    -- SOME CODE HERE
    elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
      return nil
  end 
  return 1
  end
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
  if PlayerResource:GetTeam(npc:GetPlayerID()) == 2 then
    if GameMode:PlayerHaveNoHero(npc:GetPlayerID()) == true then
      if repeats < 4 then
        print(team_point[repeats + 1])
        print("Giving player " .. npc:GetPlayerOwnerID() .. "a new hero")
        for k,v in pairs(team_point) do
          if k == (repeats + 1) then
            point = v
          end  
        end 
        FindClearSpaceForUnit(PlayerResource:ReplaceHeroWith(npc:GetPlayerOwnerID(), "npc_dota_hero_wisp", 625, 0), point, false)
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
    end  
    else 
      PlayerResource:ReplaceHeroWith(npc:GetPlayerOwnerID(), "npc_dota_hero_nevermore", 625, 0)    
    end
end