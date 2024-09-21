#pragma semicolon 1
#pragma newdecls required

#include <sdktools>

ConVar
    cvDistMax,
    cvEnable;

public Plugin myinfo = 
{
	name = "[Any] Block Drop Plant",
	author = "Nek.'a 2x2 | ggwp.site ",
	description = "Блокировка выборса плента",
	version = "1.0.0 101",
	url = "https://ggwp.site/"
};

public void OnPluginStart()
{
    cvEnable = CreateConVar("sm_drop_plant_enable", "1", "Включить плагин?");
    cvDistMax = CreateConVar("sm_drop_plant_dist_max", "200.0", "Максимальная дистанция?");

    AddCommandListener(Event_DropPlant, "drop");

    AutoExecConfig(true, "block_drop_plant");
}

public int TraceToPlayer(int client)
{
	float vecClientEyePos[3], vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);
	GetClientEyeAngles(client, vecClientEyeAng);

	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayPlayer, client);

	if (TR_DidHit(INVALID_HANDLE))
	{
		int ent = TR_GetEntityIndex(INVALID_HANDLE);
		if(ent != 0)
		{
            float vecTargetEyePos[3], fDist;
            GetClientEyePosition(ent, vecTargetEyePos);
            fDist = GetVectorDistance(vecClientEyePos, vecTargetEyePos);

            if(cvDistMax.FloatValue >= fDist)
            {
                PrintToChatAll("Дистанция между [%N] и [%N] => [%.2f]", client, ent, fDist);
                return ent;
            }
			    
            else return 0;
		}
	}

	return 0;
}

public bool TraceRayPlayer(int entityhit, int mask, any self)
{
	return entityhit > 0 && entityhit != self;
}

stock bool IsValidClient(int client)
{
    return 0 < client <= MaxClients && IsClientInGame(client);
}

public Action Event_DropPlant(int client, const char[] command, any args)
{
	if(!cvEnable.BoolValue || !IsValidClient(client) || !IsPlayerAlive(client) || IsFakeClient(client) || b_dropbomp(client) <= -1)
        return Plugin_Continue;

    TransferPlant(client);

    return Plugin_Handled;
}

int b_dropbomp(int client)
{
	char s_weapon[16];
	int i_weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (i_weapon > -1 && GetEdictClassname(i_weapon, s_weapon, sizeof(s_weapon)))
	{
		if (StrEqual(s_weapon, "weapon_c4", true))
		{
			return i_weapon;
		}
	}
	return -1;
}

void TransferPlant(int client)
{
    int target = TraceToPlayer(client);

    if(!IsValidClient(target) || GetClientTeam(client) != GetClientTeam(target))
    {
        PrintToChat(client, "Передать можно только союзнику!");
        return;
    }

    RemoveWeaponBySlot(client, 4);
    FakeClientCommand(client,"use weapon_knife");
        
    GivePlayerItem(target, "weapon_c4");
}

void RemoveWeaponBySlot(int client, int slot)
{
	int entity = GetPlayerWeaponSlot(client, slot);

	if(IsValidEntity(entity))
	{
		RemovePlayerItem(client, entity);
		AcceptEntityInput(entity, "KillHierarchy");
	}
	return;
}