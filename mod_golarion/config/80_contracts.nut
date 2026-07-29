// ---- Hand-authored contracts (Phase 4) -------------------------------------
// One category-key + Settlement-action push per contract. Each contract also sets
// m.Category directly in its own create() (the category-hook loop already ran).

// Contract 1 - the Abandoned Watchtower (haunted frontier ruin).
::Const.Contracts.ContractCategoryMap.legend_watchtower_contract <- ::Const.Contracts.Categories.Battle;
::Const.FactionTrait.Actions[::Const.FactionTrait.Settlement].push("scripts/factions/contracts/legend_watchtower_action");

// Contract 2 - Skull's Crossing (Economy mechanism-gamble; Thassilonian dam, draught-gated).
::Const.Contracts.ContractCategoryMap.legend_skulls_crossing_contract <- ::Const.Contracts.Categories.Economy;
::Const.FactionTrait.Actions[::Const.FactionTrait.Settlement].push("scripts/factions/contracts/legend_skulls_crossing_action");

// Contract 3 - Black Forks (Battle; forest village, cult in a ruined monastery; day/night branch).
::Const.Contracts.ContractCategoryMap.skv_black_forks_contract <- ::Const.Contracts.Categories.Battle;
::Const.FactionTrait.Actions[::Const.FactionTrait.Settlement].push("scripts/factions/contracts/skv_black_forks_action");

::Const.Contracts.ContractCategoryMap.skv_metringer_contract <- ::Const.Contracts.Categories.Battle;
::Const.FactionTrait.Actions[::Const.FactionTrait.Settlement].push("scripts/factions/contracts/skv_metringer_action");

// Contract 4 - The Den Hunt (Legendary; bounty on the permanent skv_den location).
// Noble-only: no ContractCategoryMap entry (nobles don't use category slots); m.Category set in create().
::Const.FactionTrait.Actions[::Const.FactionTrait.NobleHouse].push("scripts/factions/contracts/skv_den_hunt_action");

// Contract 5 - The Choking Tower (Economy; non-combat tower-ascent; spawns/owns its own site).
::Const.Contracts.ContractCategoryMap.skv_choking_tower_contract <- ::Const.Contracts.Categories.Economy;
::Const.FactionTrait.Actions[::Const.FactionTrait.Settlement].push("scripts/factions/contracts/skv_choking_tower_action");

// Contract 6 - The Azari Palace (Economy; heist). Offered NORTH + SOUTH (Settlement + OrientalCityState).
::Const.Contracts.ContractCategoryMap.skv_azari_contract <- ::Const.Contracts.Categories.Economy;
::Const.FactionTrait.Actions[::Const.FactionTrait.Settlement].push("scripts/factions/contracts/skv_azari_action");
::Const.FactionTrait.Actions[::Const.FactionTrait.OrientalCityState].push("scripts/factions/contracts/skv_azari_action");

// Contract 8 - Ambush in <City> (Battle; courier-rescue, two-city delivery).
// Offered NORTH + SOUTH (Settlement + OrientalCityState).
::Const.Contracts.ContractCategoryMap.skv_ambush_contract <- ::Const.Contracts.Categories.Battle;
::Const.FactionTrait.Actions[::Const.FactionTrait.Settlement].push("scripts/factions/contracts/skv_ambush_action");
::Const.FactionTrait.Actions[::Const.FactionTrait.OrientalCityState].push("scripts/factions/contracts/skv_ambush_action");

// Contract 9 - Carthica's Pride in <City> (Hunt). NOBLE-ONLY.
// Gate is the noble lane's ~1050 "Professional" unlock (verified vs Legends 19.4.14 + wiki); no per-contract renown line.
// ContractCategoryMap entry now unread (nobles don't use category slots); m.Category set in create().
::Const.Contracts.ContractCategoryMap.skv_carthica_contract <- ::Const.Contracts.Categories.Hunt;
::Const.FactionTrait.Actions[::Const.FactionTrait.NobleHouse].push("scripts/factions/contracts/skv_carthica_action");
// DEV knob: uncomment to also offer at size-2+ towns:
// ::Const.FactionTrait.Actions[::Const.FactionTrait.Settlement].push("scripts/factions/contracts/skv_carthica_action");

// Contract 10 - Hollow's Last Hope (Hunt; plague clock, Darkmoon Vale expedition).
// Gate is situation.sickness on a forest-adjacent village of size <=2 -- NO rarity roll.
::Const.Contracts.ContractCategoryMap.skv_hollows_contract <- ::Const.Contracts.Categories.Hunt;
::Const.FactionTrait.Actions[::Const.FactionTrait.Settlement].push("scripts/factions/contracts/skv_hollows_action");

// ---- Legendary category icon ----
// Legends ships Legendary = "" (deliberately blank). This fills it; GLOBAL, cosmetic, save-safe.
// Two files needed: JS appends "_sw.png" (disabled) or ".png" -- value here has NO extension.
::Const.Contracts.ContractCategoryIconMap.Legendary = "ui/icons/contract_type_legendary";
