-- ModuleScript: ReplicatedStorage/Shared/Config/DialogTrees
-- All NPC dialog trees as nested data tables.
-- onEnter entries use { service, method, args } dispatch (no loadstring).
-- Morality gates: minMorality / maxMorality on choice entries.

local DialogTrees = {}

-- ── Parmin (Warung operator, Jogja) ───────────────────────────────
DialogTrees.Parmin_Main = {
	root  = "greet",
	nodes = {
		greet = {
			speaker = "Parmin",
			textKey = "npc.parmin.greet",
			choices = {
				{ labelKey = "dialog.choice.ask_shop",   next = "about_shop"   },
				{ labelKey = "dialog.choice.ask_arjuna", next = "about_arjuna" },
				{ labelKey = "dialog.choice.bye",        next = nil            },
			},
		},
		about_shop = {
			speaker = "Parmin",
			textKey = "npc.parmin.about_shop",
			choices = {
				{ labelKey = "dialog.choice.thanks", next = nil },
			},
		},
		about_arjuna = {
			speaker = "Parmin",
			textKey = "npc.parmin.arjuna_story",
			onEnter = {
				service = "QuestService",
				method  = "triggerCheck",
				args    = { "MQ_Ch1_Awal", "Talk", "Parmin" },
			},
			choices = {
				{ labelKey = "dialog.choice.thanks", next = nil },
			},
		},
	},
}

-- ── PakRT (Village head, Jogja) ───────────────────────────────────
DialogTrees.PakRT_Main = {
	root  = "greet",
	nodes = {
		greet = {
			speaker = "PakRT",
			textKey = "npc.pakrt.greet",
			choices = {
				{ labelKey = "dialog.choice.ask_village", next = "about_village" },
				{ labelKey = "dialog.choice.bye",         next = nil             },
			},
		},
		about_village = {
			speaker = "PakRT",
			textKey = "npc.pakrt.about_village",
			choices = {
				{ labelKey = "dialog.choice.thanks", next = nil },
			},
		},
	},
}

-- ── MbokSari (Quest giver, Jogja) ────────────────────────────────
DialogTrees.MbokSari_Main = {
	root  = "greet",
	nodes = {
		greet = {
			speaker = "MbokSari",
			textKey = "npc.mboksari.greet",
			choices = {
				{ labelKey = "dialog.choice.ask_quest", next = "offer_quest" },
				{ labelKey = "dialog.choice.bye",       next = nil           },
			},
		},
		offer_quest = {
			speaker = "MbokSari",
			textKey = "npc.mboksari.offer_quest",
			onEnter = {
				service = "QuestService",
				method  = "offerQuest",
				args    = { "MQ_Ch1_Awal" },
			},
			choices = {
				{ labelKey = "dialog.choice.accept", next = nil },
				{ labelKey = "dialog.choice.later",  next = nil },
			},
		},
	},
}

-- ── PakToha (Conflict arc NPC, Suroboyo) ─────────────────────────
-- Morality-gated: threaten choice only available for low-morality players.
DialogTrees.PakToha_Main = {
	root  = "greet",
	nodes = {
		greet = {
			speaker = "PakToha",
			textKey = "npc.paktoha.greet",
			choices = {
				{ labelKey = "dialog.choice.ask_situation", next = "about_situation", minMorality = 20 },
				{ labelKey = "dialog.choice.threaten",      next = "threaten",        maxMorality = 39 },
				{ labelKey = "dialog.choice.bye",           next = nil               },
			},
		},
		about_situation = {
			speaker = "PakToha",
			textKey = "npc.paktoha.about_situation",
			onEnter = {
				service = "QuestService",
				method  = "triggerCheck",
				args    = { "MQ_Ch1_Konflik", "Talk", "PakToha" },
			},
			choices = {
				{ labelKey = "dialog.choice.thanks", next = nil },
			},
		},
		threaten = {
			speaker = "PakToha",
			textKey = "npc.paktoha.threaten_response",
			choices = {
				{ labelKey = "dialog.choice.leave", next = nil },
			},
		},
	},
}

return DialogTrees
