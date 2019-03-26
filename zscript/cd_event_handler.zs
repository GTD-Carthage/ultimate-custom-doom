/* Copyright Alexander 'm8f' Kromm (mmaulwurff@gmail.com) 2019
 *
 * This file is a part of Ultimate Custom Doom.
 *
 * Ultimate Custom Doom is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) any
 * later version.
 *
 * Ultimate Custom Doom is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * Ultimate Custom Doom.  If not, see <https://www.gnu.org/licenses/>.
 */

/**
 * This class provides the entry point for all Ultimate Custom Doom features.
 */
class cd_EventHandler : EventHandler
{

  // public: ///////////////////////////////////////////////////////////////////

  override void PlayerEntered  (PlayerEvent event) { init(event); }
  override void PlayerRespawned(PlayerEvent event) { init(event); }

  override
  void WorldTick()
  {
    PlayerInfo player = players[consolePlayer];
    if (player == null) { return; }

    bool isSettingsUpdated = cd_Time.maybeRead();
    if (isSettingsUpdated)
    {
      _settings.read(player);
      updateProperties(player);

      _randomizerLimits.read(player);
    }

    bool isTimeToPulse = ((level.time % Thinker.TICRATE) == 0);
    if (isTimeToPulse) { pulse(player); }
  }

  override
  void WorldThingSpawned(WorldEvent event)
  {
    Actor thing = event.Thing;
    if (thing == null) { return; }

    bool isMonster = thing.bISMONSTER;
    if (!isMonster) { return; }

    cd_Monsters.applyMonsterMultipliersTo(thing, _settings.monster());
  }

  override
  void NetworkProcess(ConsoleEvent event)
  {
    if (event.player != consolePlayer) { return; }

    string name = event.name;

    if      (name == "cd_reset_monster_settings" ) { resetMonsterSettings(); }
    else if (name == "cd_reset_cvars_to_defaults") { resetCvarsToDefaults(); }
    else if (name == "cd_reset_randomizer_cvars" ) { resetRandomizerCvars(); }
  }

  override
  void RenderOverlay(RenderEvent event)
  {
    if (event.camera != players[consolePlayer].mo) { return; }

    _randomizer.show(players[consolePlayer], _settings.randomizer());
  }

  // private: //////////////////////////////////////////////////////////////////

  private
  void resetMonsterSettings()
  {
    cd_Monsters.applyMonsterMultipliersToAll(_settings.monster());
  }

  private
  void resetCvarsToDefaults()
  {
    _settings.resetCvarsToDefaults(players[consolePlayer]);
  }

  private
  void resetRandomizerCvars()
  {
    _randomizerLimits.resetCvarsToDefaults(players[consolePlayer]);
  }

  private
  void init(PlayerEvent event)
  {
    if (event == null) { return; }
    if (event.playerNumber != consolePlayer) { return; }

    PlayerInfo player = players[consolePlayer];

    _settings         = new("cd_Settings"        ).init();
    _playerProperties = new("cd_PlayerProperties").init(_settings.player(), player);
    _miscProperties   = new("cd_MiscProperties"  ).init(_settings.misc  (), player);
    _randomizer       = new("cd_Randomizer"      ).init();
    _randomizerLimits = new("cd_RandomizerLimits").init();

    _settings.read(player);
    _randomizerLimits.read(player);

    player.mo.GiveInventoryType("cd_StartGiverCheck");
  }

  private
  void updateProperties(PlayerInfo player)
  {
    _playerProperties.update(_settings.player(), player);
    _miscProperties  .update(_settings.misc(),   player);
  }

  private
  void pulse(PlayerInfo player)
  {
    cd_PlayerHealth.regenerate(player, _settings.healthRegeneration());
    cd_PlayerArmor .regenerate(player, _settings.armorRegeneration ());
    cd_PlayerAmmo  .regenerate(player, _settings.ammoRegeneration  ());

    cd_PlayerHealth.degenerate(player, _settings.healthDegeneration());
    cd_PlayerArmor .degenerate(player, _settings.armorDegeneration ());

    cd_PermanentPowerupProperties.adjustTimes(player, _settings.permanentPowerup());

    cd_Randomizer.randomize(player, _settings, _randomizerLimits);
  }

  // private: //////////////////////////////////////////////////////////////////

  private cd_Settings         _settings;
  private cd_PlayerProperties _playerProperties;
  private cd_MiscProperties   _miscProperties;
  private cd_Randomizer       _randomizer;
  private cd_RandomizerLimits _randomizerLimits;

} // class cd_EventHandler
