-- Generated from template

if CAddonTemplateGameMode == nil then
	CAddonTemplateGameMode = class({})
end

local i = 1
local id = -1
local point_team_1
local point_team_2
local point_team_3
local point_team_4
local players_telepoted = false
local players_count = 0
local pre_start_check_completed = false

function Precache( context )
	PrecacheUnitByNameSync("npc_dota_hero_sven", context)
	PrecacheUnitByNameSync("npc_dota_hero_wisp", context)
	PrecacheUnitByNameSync("npc_dota_hero_nevermore", context)
	PrecacheUnitByNameSync("npc_dota_hero_antimage", context)
end

-- Create the game mode when we activate
function Activate()
	GameRules.AddonTemplate = CAddonTemplateGameMode()
	GameRules.AddonTemplate:InitGameMode()
end

function CAddonTemplateGameMode:InitGameMode()
	print( "HORDE is loaded." )
	point_team_1 = Entities:FindByName( nil, "point_teleport_spot_team_1" ):GetAbsOrigin()
	point_team_2 = Entities:FindByName( nil, "point_teleport_spot_team_2" ):GetAbsOrigin()
	point_team_3 = Entities:FindByName( nil, "point_teleport_spot_team_3" ):GetAbsOrigin()
	point_team_4 = Entities:FindByName( nil, "point_teleport_spot_team_4" ):GetAbsOrigin()
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
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(CAddonTemplateGameMode, 'OnPlayerConnectFull'), self)
	ListenToGameEvent( 'game_rules_state_change', Dynamic_Wrap(CAddonTemplateGameMode,'OnGameRulesChange'), self)
end

function CAddonTemplateGameMode:OnPlayerConnectFull(keys)
end

function CAddonTemplateGameMode:OnGameRulesChange(keys)
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_STRATEGY_TIME then
		PlayerResource:ReplaceHeroWith(0,'npc_dota_hero_wisp', 625 , 0)	
		FindClearSpaceForUnit(PlayerResource:GetPlayer(0):GetAssignedHero(), point_team_1, false)
		SendToConsole("dota_camera_center")
	elseif GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
	end	
end	

function CAddonTemplateGameMode:OnNPCSpawned(keys)
  local npc = EntIndexToHScript(keys.entindex)

  if npc:IsRealHero() and npc.bFirstSpawned == nil then
    npc.bFirstSpawned = true
    GameMode:OnHeroInGame(npc)
    print("NpcSpawn")
  end
end

function CAddonTemplateGameMode:OnThink()
	print('Think')
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		-- SOME CODE HERE
		elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
			return nil
	end	
	return 1
end