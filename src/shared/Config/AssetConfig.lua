-- ModuleScript: ReplicatedStorage/Shared/Config/AssetConfig
-- Single source of truth for all game data.
-- All 7 Places share this one module. Edit here, publish once.

local AssetConfig = {}

-- ============================================================
-- ITEMS
-- ============================================================
AssetConfig.Items = {
	NasiBungkus = {
		id          = "NasiBungkus",
		nameKey     = "item.nasibungkus.name",
		descKey     = "item.nasibungkus.desc",
		type        = "Food",
		rarity      = "Biasa",
		imageId     = "rbxassetid://0",
		staminaGain = 30,
		basePrice   = 200,
	},
	EsTeh = {
		id          = "EsTeh",
		nameKey     = "item.esteh.name",
		descKey     = "item.esteh.desc",
		type        = "Drink",
		rarity      = "Biasa",
		imageId     = "rbxassetid://0",
		staminaGain = 15,
		basePrice   = 100,
	},
	RotiBasah = {
		id          = "RotiBasah",
		nameKey     = "item.rotibasah.name",
		descKey     = "item.rotibasah.desc",
		type        = "Food",
		rarity      = "Biasa",
		imageId     = "rbxassetid://0",
		staminaGain = 20,
		basePrice   = 150,
	},
	Kayu = {
		id          = "Kayu",
		nameKey     = "item.kayu.name",
		descKey     = "item.kayu.desc",
		type        = "Material",
		rarity      = "Biasa",
		imageId     = "rbxassetid://0",
		basePrice   = 50,
	},
	Beras = {
		id          = "Beras",
		nameKey     = "item.beras.name",
		descKey     = "item.beras.desc",
		type        = "Material",
		rarity      = "Biasa",
		imageId     = "rbxassetid://0",
		basePrice   = 30,
	},
	DaunPisang = {
		id          = "DaunPisang",
		nameKey     = "item.daunpisang.name",
		descKey     = "item.daunpisang.desc",
		type        = "Material",
		rarity      = "Biasa",
		imageId     = "rbxassetid://0",
		basePrice   = 20,
	},
	KayuBalok = {
		id          = "KayuBalok",
		nameKey     = "item.kayubalok.name",
		descKey     = "item.kayubalok.desc",
		type        = "Material",
		rarity      = "Tidak Biasa",
		imageId     = "rbxassetid://0",
		basePrice   = 200,
	},
	Surat = {
		id          = "Surat",
		nameKey     = "item.surat.name",
		descKey     = "item.surat.desc",
		type        = "Quest",
		rarity      = "Biasa",
		imageId     = "rbxassetid://0",
		basePrice   = 0,
	},
	Cincin = {
		id          = "Cincin",
		nameKey     = "item.cincin.name",
		descKey     = "item.cincin.desc",
		type        = "Material",
		rarity      = "Langka",
		imageId     = "rbxassetid://0",
		basePrice   = 5000,
	},
	TitlePenjelajahNusantara = {
		id          = "TitlePenjelajahNusantara",
		nameKey     = "item.title.penjelajah.name",
		descKey     = "item.title.penjelajah.desc",
		type        = "Kosmetik",
		rarity      = "Legenda",
		imageId     = "rbxassetid://0",
		basePrice   = 0,
	},
	LegendaCosmeticGood = {
		id          = "LegendaCosmeticGood",
		nameKey     = "item.cosmetic.good.name",
		descKey     = "item.cosmetic.good.desc",
		type        = "Kosmetik",
		rarity      = "Legenda",
		imageId     = "rbxassetid://0",
		basePrice   = 0,
	},
	LegendaCosmeticBad = {
		id          = "LegendaCosmeticBad",
		nameKey     = "item.cosmetic.bad.name",
		descKey     = "item.cosmetic.bad.desc",
		type        = "Kosmetik",
		rarity      = "Legenda",
		imageId     = "rbxassetid://0",
		basePrice   = 0,
	},
}

-- ============================================================
-- WEAPONS (equippable — all traditional Indonesian)
-- ============================================================
AssetConfig.Weapons = {
	PencakSilat = {
		id          = "PencakSilat",
		nameKey     = "item.pencaksilat.name",
		origin      = "Jawa / Sumatera",
		damage      = 10,
		cooldown    = 0.45,
		staminaCost = 5,
		range       = 4,
		animationId = "rbxassetid://0",
		unlockQuest = "SQ_SilatMaster",
	},
	Tongkat = {
		id          = "Tongkat",
		nameKey     = "item.tongkat.name",
		origin      = "Nusantara",
		damage      = 14,
		cooldown    = 0.85,
		staminaCost = 10,
		range       = 6,
		animationId = "rbxassetid://0",
		itemRef     = "Tongkat",
	},
	Golok = {
		id          = "Golok",
		nameKey     = "item.golok.name",
		origin      = "Betawi / Sunda",
		damage      = 18,
		cooldown    = 0.8,
		staminaCost = 12,
		range       = 5,
		animationId = "rbxassetid://0",
		itemRef     = "Golok",
	},
	Keris = {
		id          = "Keris",
		nameKey     = "item.keris.name",
		origin      = "Jawa / Bali",
		damage      = 22,
		cooldown    = 0.75,
		staminaCost = 10,
		range       = 4,
		animationId = "rbxassetid://0",
		itemRef     = "Keris",
		moralityBonus = { minMorality = 90, damageMultiplier = 1.25 },
	},
	Mandau = {
		id          = "Mandau",
		nameKey     = "item.mandau.name",
		origin      = "Kalimantan (Dayak)",
		damage      = 28,
		cooldown    = 0.95,
		staminaCost = 15,
		range       = 5,
		animationId = "rbxassetid://0",
		itemRef     = "Mandau",
		zoneRestricted = "PalangkaRaya",
	},
	Ketapel = {
		id             = "Ketapel",
		nameKey        = "item.ketapel.name",
		origin         = "Nusantara",
		damage         = 12,
		cooldown       = 1.2,
		staminaCost    = 8,
		range          = 20,
		projectileSpeed = 80,
		animationId    = "rbxassetid://0",
		itemRef        = "Ketapel",
	},
	Sumpit = {
		id             = "Sumpit",
		nameKey        = "item.sumpit.name",
		origin         = "Kalimantan / Papua",
		damage         = 8,
		cooldown       = 1.5,
		staminaCost    = 6,
		range          = 35,
		projectileSpeed = 120,
		statusEffect   = { type = "Slow", duration = 3, multiplier = 0.5 },
		animationId    = "rbxassetid://0",
		itemRef        = "Sumpit",
	},
}

-- ============================================================
-- CRAFTING RECIPES
-- ============================================================
AssetConfig.Recipes = {
	{
		output       = "NasiBungkus",
		outputAmount = 1,
		ingredients  = {
			{ id = "Beras",      amount = 2 },
			{ id = "DaunPisang", amount = 1 },
		},
		craftTime    = 3,
	},
}

-- ============================================================
-- SHOPS
-- ============================================================
AssetConfig.Shops = {
	WarungParmin = {
		id              = "WarungParmin",
		nameKey         = "shop.warungparmin.name",
		type            = "BuySell",
		acceptedTypes   = { "Food", "Drink" },
		npcName         = "Parmin",
		sellMultiplier  = 0.6,
		moralityDiscount = { threshold = 90, discount = 0.10 },
		stock           = { "NasiBungkus", "EsTeh", "RotiBasah" },
	},
}

-- ============================================================
-- NPCS
-- ============================================================
AssetConfig.NPCs = {
	Parmin = {
		id         = "Parmin",
		nameKey    = "npc.parmin.name",
		modelId    = "rbxassetid://0",
		shopId     = "WarungParmin",
		quests     = { "SQ_CariKayu_01" },
		dialogTree = "Parmin_Main",
		zone       = "KotaJogja",
		schedule   = {
			{ from = 6,  to = 20, location = "WarungParmin_Counter" },
			{ from = 20, to = 6,  location = "Parmin_Home" },
		},
	},
	PakRT = {
		id         = "PakRT",
		nameKey    = "npc.pakrt.name",
		modelId    = "rbxassetid://0",
		quests     = {},
		dialogTree = "PakRT_Main",
		zone       = "KotaJogja",
		schedule   = {
			{ from = 7, to = 22, location = "PakRT_Office" },
		},
	},
	MbokSari = {
		id         = "MbokSari",
		nameKey    = "npc.mboksari.name",
		modelId    = "rbxassetid://0",
		quests     = { "MQ_Ch1_Awal" },
		dialogTree = "MbokSari_Main",
		zone       = "KotaJogja",
		schedule   = {
			{ from = 0, to = 24, location = "MbokSari_House" },
		},
	},
	PakToha = {
		id         = "PakToha",
		nameKey    = "npc.paktoha.name",
		modelId    = "rbxassetid://0",
		quests     = { "MQ_Ch1_Awal" },
		dialogTree = "PakToha_Main",
		zone       = "Suroboyo",
		schedule   = {
			{ from = 0, to = 24, location = "PakToha_Warehouse" },
		},
	},
}

-- ============================================================
-- QUESTS
-- ============================================================
AssetConfig.Quests = {
	MQ_Ch1_Awal = {
		id        = "MQ_Ch1_Awal",
		type      = "Main",
		titleKey  = "quest.main.ch1.title",
		descKey   = "quest.main.ch1.desc",
		giverNPC  = "MbokSari",
		objectives = {
			{ type = "Talk",    target = "Parmin",  count = 1 },
			{ type = "Deliver", item   = "Surat",   target = "PakRT" },
		},
		rewards   = {
			rupiah   = 5000,
			items    = { { id = "KayuBalok", amount = 1 } },
			morality = 10,
		},
		nextQuest = "MQ_Ch1_Konflik",
	},
	MQ_Ch1_Konflik = {
		id        = "MQ_Ch1_Konflik",
		type      = "Main",
		titleKey  = "quest.main.ch1b.title",
		descKey   = "quest.main.ch1b.desc",
		giverNPC  = "PakRT",
		objectives = {
			{ type = "Talk",    target = "PakToha", count = 1 },
			{ type = "Explore", zone   = "Suroboyo" },
		},
		rewards   = {
			rupiah   = 8000,
			morality = 5,
		},
		nextQuest = "MQ_Ch2_Jakarta",
		unlockPlace = "Jawa",
	},
	SQ_CariKayu_01 = {
		id        = "SQ_CariKayu_01",
		type      = "Side",
		titleKey  = "quest.side.carikayu01.title",
		descKey   = "quest.side.carikayu01.desc",
		giverNPC  = "Parmin",
		objectives = {
			{ type = "Gather", item = "Kayu", count = 5 },
		},
		rewards   = {
			rupiah   = 800,
			morality = 5,
		},
	},
}

-- ============================================================
-- RELATIONSHIPS
-- ============================================================
AssetConfig.Relationships = {
	Sahabat = { nameKey = "rel.sahabat", icon = "rbxassetid://0", mutual = true },
	Rival   = { nameKey = "rel.rival",   icon = "rbxassetid://0", mutual = true },
	Menikah = {
		nameKey      = "rel.menikah",
		icon         = "rbxassetid://0",
		mutual       = true,
		maxPerPlayer = 1,
		requireItem  = "Cincin",
	},
	Saudara = { nameKey = "rel.saudara", icon = "rbxassetid://0", mutual = true },
	Musuh   = { nameKey = "rel.musuh",   icon = "rbxassetid://0", mutual = true },
}

-- ============================================================
-- MORALITY
-- ============================================================
AssetConfig.Morality = {
	Default = 50,
	Tiers   = {
		{ min = 90, max = 100, labelKey = "morality.pahlawan", color = Color3.fromRGB(255, 215, 0)   },
		{ min = 60, max = 89,  labelKey = "morality.baikhati", color = Color3.fromRGB(0, 200, 80)    },
		{ min = 40, max = 59,  labelKey = "morality.biasa",    color = Color3.fromRGB(180, 180, 180) },
		{ min = 20, max = 39,  labelKey = "morality.nakal",    color = Color3.fromRGB(255, 140, 0)   },
		{ min = 0,  max = 19,  labelKey = "morality.penjahat", color = Color3.fromRGB(200, 0, 0)     },
	},
}

-- ============================================================
-- HOTBAR
-- ============================================================
AssetConfig.Hotbar = {
	DefaultSlots = 4,
	MaxSlots     = 8,
	UpgradeCost  = function(currentSlots)
		return { rupiah = 10000 * (currentSlots - 3) }
	end,
}

-- ============================================================
-- STAMINA
-- ============================================================
AssetConfig.Stamina = {
	Max        = 100,
	RegenRate  = 5,
	SprintCost = 10,
}

-- ============================================================
-- CURRENCY
-- ============================================================
AssetConfig.Currency = {
	Rupiah = { key = "Rupiah", symbol = "Rp", formatLocale = "id-ID" },
	Gold   = { key = "Gold",   symbol = "◆",  formatLocale = nil     },
}

-- ============================================================
-- PLACES (7 islands — fill placeId after publishing each Place)
-- ============================================================
AssetConfig.Places = {
	Jawa = {
		id            = "Jawa",
		nameKey       = "place.jawa",
		placeId       = 0,
		isStarting    = true,
		bandaraZone   = "Suroboyo",
		pelabuhanZone = "Suroboyo",
	},
	Sumatera = {
		id            = "Sumatera",
		nameKey       = "place.sumatera",
		placeId       = 0,
		bandaraZone   = "Medan",
		pelabuhanZone = "Palembang",
	},
	Kalimantan = {
		id            = "Kalimantan",
		nameKey       = "place.kalimantan",
		placeId       = 0,
		bandaraZone   = "Banjarmasin",
		pelabuhanZone = "Pontianak",
	},
	Sulawesi = {
		id            = "Sulawesi",
		nameKey       = "place.sulawesi",
		placeId       = 0,
		bandaraZone   = "Makassar",
		pelabuhanZone = "Makassar",
	},
	Papua = {
		id            = "Papua",
		nameKey       = "place.papua",
		placeId       = 0,
		bandaraZone   = "Jayapura",
		pelabuhanZone = "Sorong",
	},
	NusaTenggara = {
		id            = "NusaTenggara",
		nameKey       = "place.nusatenggara",
		placeId       = 0,
		bandaraZone   = "Denpasar",
		pelabuhanZone = "Denpasar",
	},
	Maluku = {
		id            = "Maluku",
		nameKey       = "place.maluku",
		placeId       = 0,
		bandaraZone   = "Ambon",
		pelabuhanZone = "Ambon",
	},
}

-- ============================================================
-- TRAVEL PRICES (Rupiah)
-- ============================================================
AssetConfig.Travel = {
	airTickets = {
		SameIsland         = 2000,
		JawaToSumatera     = 5000,
		JawaToKalimantan   = 6000,
		JawaToSulawesi     = 8000,
		JawaToNusaTenggara = 5000,
		JawaToMaluku       = 12000,
		JawaToPapua        = 15000,
	},
	ferryTickets = {
		WithinIsland  = 500,
		ShortCrossSea = 1500,
	},
}

-- ============================================================
-- ZONES (37 total — all 7 islands)
-- ============================================================
AssetConfig.Zones = {

	-- JAWA (6 zones)
	Suroboyo = {
		id = "Suroboyo", place = "Jawa", nameKey = "zone.suroboyo",
		region = "Jawa Timur", unlockQuest = nil,
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Betawi-Jawa port city, rujak cingur, Jembatan Merah",
	},
	KotaJogja = {
		id = "KotaJogja", place = "Jawa", nameKey = "zone.kotajogja",
		region = "DIY Yogyakarta", unlockQuest = nil,
		hasBandara = false, hasPelabuhan = false,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Kraton, Malioboro, batik parang/kawung, gudeg, keris",
	},
	Semarang = {
		id = "Semarang", place = "Jawa", nameKey = "zone.semarang",
		region = "Jawa Tengah", unlockQuest = "MQ_Ch1_Awal",
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Lawang Sewu, lumpia, pecinan, Jawa-Tionghoa mix",
	},
	Bandung = {
		id = "Bandung", place = "Jawa", nameKey = "zone.bandung",
		region = "Jawa Barat", unlockQuest = "MQ_Ch1_Awal",
		hasBandara = true, hasPelabuhan = false,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Sunda — angklung, mie kocok, kujang, Gedung Sate",
	},
	Jakarta = {
		id = "Jakarta", place = "Jawa", nameKey = "zone.jakarta",
		region = "DKI Jakarta", unlockQuest = "MQ_Ch2_Jakarta",
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Betawi — Monas, kerak telor, ondel-ondel, kota tua",
	},
	Serang = {
		id = "Serang", place = "Jawa", nameKey = "zone.serang",
		region = "Banten", unlockQuest = "MQ_Ch2_Jakarta",
		hasBandara = false, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Baduy enclave, debus tradition, golok Banten",
	},

	-- SUMATERA (10 zones)
	BandaAceh = {
		id = "BandaAceh", place = "Sumatera", nameKey = "zone.bandaaceh",
		region = "Aceh", unlockQuest = nil,
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Islamic architecture, tari saman, mie aceh, rencong dagger",
	},
	Medan = {
		id = "Medan", place = "Sumatera", nameKey = "zone.medan",
		region = "Sumatera Utara", unlockQuest = nil,
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Batak — ulos, bika ambon, Danau Toba, tor-tor dance",
	},
	Padang = {
		id = "Padang", place = "Sumatera", nameKey = "zone.padang",
		region = "Sumatera Barat", unlockQuest = "MQ_Ch1_Awal",
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Minangkabau — rumah gadang, rendang, randai, saluang",
	},
	Pekanbaru = {
		id = "Pekanbaru", place = "Sumatera", nameKey = "zone.pekanbaru",
		region = "Riau", unlockQuest = "MQ_Ch1_Awal",
		hasBandara = true, hasPelabuhan = false,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Melayu Riau — lancang kuning, sagu, tepak sirih",
	},
	Palembang = {
		id = "Palembang", place = "Sumatera", nameKey = "zone.palembang",
		region = "Sumatera Selatan", unlockQuest = "MQ_Ch1_Awal",
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Ampera Bridge, pempek, songket, Sungai Musi, Sriwijaya legacy",
	},
	BandarLampung = {
		id = "BandarLampung", place = "Sumatera", nameKey = "zone.bandarlampung",
		region = "Lampung", unlockQuest = "MQ_Ch2_Sumatera",
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Tapis cloth, gajah Sumatera, Way Kambas, tari sigeh pengunten",
	},
	PangkalPinang = {
		id = "PangkalPinang", place = "Sumatera", nameKey = "zone.pangkalpinang",
		region = "Bangka Belitung", unlockQuest = "MQ_Ch2_Sumatera",
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Timah (tin) mining heritage, mie belitung, pantai pasir putih",
	},
	Jambi = {
		id = "Jambi", place = "Sumatera", nameKey = "zone.jambi",
		region = "Jambi", unlockQuest = "MQ_Ch2_Sumatera",
		hasBandara = true, hasPelabuhan = false,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Batik Jambi, Candi Muaro Jambi ruins, sungai Batanghari",
	},
	Bengkulu = {
		id = "Bengkulu", place = "Sumatera", nameKey = "zone.bengkulu",
		region = "Bengkulu", unlockQuest = "MQ_Ch3_Sumatera",
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Rafflesia arnoldii, kain besurek, benteng Inggris (Fort Marlborough)",
	},
	TanjungPinang = {
		id = "TanjungPinang", place = "Sumatera", nameKey = "zone.tanjungpinang",
		region = "Kepulauan Riau", unlockQuest = "MQ_Ch3_Sumatera",
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Melayu pesisir, seafood, Pulau Penyengat royal ruins",
	},

	-- KALIMANTAN (5 zones)
	Pontianak = {
		id = "Pontianak", place = "Kalimantan", nameKey = "zone.pontianak",
		region = "Kalimantan Barat", unlockQuest = nil,
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Equator monument, Melayu-Tionghoa mix, soto banjar",
	},
	Banjarmasin = {
		id = "Banjarmasin", place = "Kalimantan", nameKey = "zone.banjarmasin",
		region = "Kalimantan Selatan", unlockQuest = nil,
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Pasar terapung (floating market), sasirangan cloth, Banjar culture",
	},
	PalangkaRaya = {
		id = "PalangkaRaya", place = "Kalimantan", nameKey = "zone.palangkaraya",
		region = "Kalimantan Tengah", unlockQuest = "MQ_Ch1_Kalimantan",
		hasBandara = true, hasPelabuhan = false,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Dayak Ngaju — betang longhouse, manik-manik, mandau, sungai Kahayan",
	},
	Samarinda = {
		id = "Samarinda", place = "Kalimantan", nameKey = "zone.samarinda",
		region = "Kalimantan Timur", unlockQuest = "MQ_Ch2_Kalimantan",
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Sarung samarinda weaving, sungai Mahakam, Kutai kingdom legacy",
	},
	TanjungSelor = {
		id = "TanjungSelor", place = "Kalimantan", nameKey = "zone.tanjungselor",
		region = "Kalimantan Utara", unlockQuest = "MQ_Ch3_Kalimantan",
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Tidung culture, frontier remote feel, rare forest drops",
	},

	-- SULAWESI (7 zones)
	Makassar = {
		id = "Makassar", place = "Sulawesi", nameKey = "zone.makassar",
		region = "Sulawesi Selatan", unlockQuest = nil,
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Bugis — Fort Rotterdam, coto makassar, pinisi boat, andi nobility",
	},
	TanahToraja = {
		id = "TanahToraja", place = "Sulawesi", nameKey = "zone.tanahtoraja",
		region = "Sulawesi Selatan", unlockQuest = nil,
		hasBandara = false, hasPelabuhan = false,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Tongkonan, tau-tau, kopi Toraja, Rambu Solo' procession",
	},
	Manado = {
		id = "Manado", place = "Sulawesi", nameKey = "zone.manado",
		region = "Sulawesi Utara", unlockQuest = "MQ_Ch1_Sulawesi",
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Minahasa — tinutuan bubur, Bunaken sea, woku spice, cakalang",
	},
	Gorontalo = {
		id = "Gorontalo", place = "Sulawesi", nameKey = "zone.gorontalo",
		region = "Gorontalo", unlockQuest = "MQ_Ch2_Sulawesi",
		hasBandara = true, hasPelabuhan = false,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Karawo embroidery, nasi bihu, binde biluhuta soup",
	},
	Palu = {
		id = "Palu", place = "Sulawesi", nameKey = "zone.palu",
		region = "Sulawesi Tengah", unlockQuest = "MQ_Ch2_Sulawesi",
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Kaili culture, bawang goreng Palu, ikan kaledo, teluk Palu",
	},
	Kendari = {
		id = "Kendari", place = "Sulawesi", nameKey = "zone.kendari",
		region = "Sulawesi Tenggara", unlockQuest = "MQ_Ch3_Sulawesi",
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Tolaki — tenun Kendari silver filigree, sinonggi sagu",
	},
	Mamuju = {
		id = "Mamuju", place = "Sulawesi", nameKey = "zone.mamuju",
		region = "Sulawesi Barat", unlockQuest = "MQ_Ch3_Sulawesi",
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Mandar — perahu Mandar, ikan bakar, remote frontier vibe",
	},

	-- PAPUA (4 zones)
	Jayapura = {
		id = "Jayapura", place = "Papua", nameKey = "zone.jayapura",
		region = "Papua", unlockQuest = nil,
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Sentani — tifa drum, ukiran Sentani, danau Sentani, noken bag",
	},
	Sorong = {
		id = "Sorong", place = "Papua", nameKey = "zone.sorong",
		region = "Papua Barat Daya", unlockQuest = "MQ_Ch1_Papua",
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Raja Ampat gateway, cenderawasih bird, diving, bahari culture",
	},
	Manokwari = {
		id = "Manokwari", place = "Papua", nameKey = "zone.manokwari",
		region = "Papua Barat", unlockQuest = "MQ_Ch2_Papua",
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Arfak mountains, cenderawasih display, hutan hujan Papua",
	},
	Merauke = {
		id = "Merauke", place = "Papua", nameKey = "zone.merauke",
		region = "Papua Selatan", unlockQuest = "MQ_Ch3_Papua",
		hasBandara = true, hasPelabuhan = false,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Marind-Anim — savanna, kangguru Papua, sagu, tari wutukala",
	},

	-- NUSA TENGGARA (3 zones)
	Denpasar = {
		id = "Denpasar", place = "NusaTenggara", nameKey = "zone.denpasar",
		region = "Bali", unlockQuest = nil,
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Pura Besakih, kecak dance, gamelan Bali, lawar, ogoh-ogoh",
	},
	Mataram = {
		id = "Mataram", place = "NusaTenggara", nameKey = "zone.mataram",
		region = "NTB (Lombok)", unlockQuest = nil,
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Sasak — tenun Lombok, ayam taliwang, Rinjani, gendang beleq",
	},
	Kupang = {
		id = "Kupang", place = "NusaTenggara", nameKey = "zone.kupang",
		region = "NTT (Timor)", unlockQuest = "MQ_Ch1_NusaTenggara",
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Timor — tenun ikat NTT, se'i babi, savanna, flobamora culture",
	},

	-- MALUKU (2 zones)
	Ambon = {
		id = "Ambon", place = "Maluku", nameKey = "zone.ambon",
		region = "Maluku", unlockQuest = nil,
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Rempah-rempah (spice islands), tari cakalele, ikan kuah pala, sagu",
	},
	Ternate = {
		id = "Ternate", place = "Maluku", nameKey = "zone.ternate",
		region = "Maluku Utara", unlockQuest = "MQ_Ch1_Maluku",
		hasBandara = true, hasPelabuhan = true,
		bgmId = "rbxassetid://0", ambientSound = "rbxassetid://0",
		culturalNote = "Kesultanan Ternate, cengkeh, pala, Benteng Oranje, kie raha",
	},
}

-- ============================================================
-- TASK SYSTEM
-- ============================================================
AssetConfig.Tasks = {
	dailyQuota    = { easy = 3, medium = 2 },
	weeklyQuota   = { medium = 2, hard = 1 },
	rerollCost    = { rupiah = 500 },
	rerollsPerDay = 1,
	resetHourUTC  = 17, -- 00:00 WIB = 17:00 UTC

	allDailyBonus = {
		rupiah   = { min = 2000, max = 5000 },
		itemDrop = { chance = 0.4, rarityMin = "TidakBiasa" },
		morality = 3,
	},
	allWeeklyBonus = {
		gold     = 2,
		itemDrop = { chance = 1.0, rarityMin = "Epik" },
	},

	Templates = {
		{
			id         = "T_Explore",
			difficulty = "Easy",
			type       = "Explore",
			titleKey   = "task.explore.title",
			descKey    = "task.explore.desc",
			target     = "any",
			count      = 1,
			reward     = { rupiah = 400 },
		},
		{
			id         = "T_Gather_Kayu",
			difficulty = "Easy",
			type       = "Gather",
			titleKey   = "task.gather.kayu.title",
			descKey    = "task.gather.kayu.desc",
			item       = "Kayu",
			count      = 3,
			reward     = { rupiah = 350 },
		},
		{
			id         = "T_Talk_NPCs",
			difficulty = "Easy",
			type       = "Talk",
			titleKey   = "task.talk.title",
			descKey    = "task.talk.desc",
			count      = 2,
			reward     = { rupiah = 300 },
		},
		{
			id         = "T_Craft_Any",
			difficulty = "Easy",
			type       = "Craft",
			titleKey   = "task.craft.title",
			descKey    = "task.craft.desc",
			count      = 1,
			reward     = { rupiah = 350 },
		},
		{
			id           = "T_Sell_Value",
			difficulty   = "Easy",
			type         = "SellValue",
			titleKey     = "task.sell.title",
			descKey      = "task.sell.desc",
			targetRupiah = 1000,
			reward       = { rupiah = 500 },
		},
		{
			id         = "T_Combat",
			difficulty = "Medium",
			type       = "Combat",
			titleKey   = "task.combat.title",
			descKey    = "task.combat.desc",
			count      = 3,
			reward     = { rupiah = 1000 },
		},
		{
			id         = "T_SideQuest",
			difficulty = "Medium",
			type       = "CompleteQuest",
			titleKey   = "task.sidequest.title",
			descKey    = "task.sidequest.desc",
			questType  = "Side",
			count      = 1,
			reward     = { rupiah = 1200 },
		},
		{
			id         = "T_Collect",
			difficulty = "Medium",
			type       = "Collect",
			titleKey   = "task.collect.title",
			descKey    = "task.collect.desc",
			itemType   = "Koleksi",
			count      = 1,
			reward     = { rupiah = 900 },
		},
		{
			id         = "T_W_Combat_Hard",
			difficulty = "Hard",
			type       = "Combat",
			titleKey   = "task.weekly.combat.title",
			descKey    = "task.weekly.combat.desc",
			count      = 15,
			reward     = { rupiah = 5000 },
		},
		{
			id         = "T_W_Craft_Variety",
			difficulty = "Hard",
			type       = "CraftVariety",
			titleKey   = "task.weekly.craft.title",
			descKey    = "task.weekly.craft.desc",
			count      = 5,
			reward     = { rupiah = 4000 },
		},
	},
}

-- ============================================================
-- FESTIVAL EVENTS
-- ============================================================
AssetConfig.Events = {
	Lebaran = {
		id           = "Lebaran",
		nameKey      = "event.lebaran.name",
		currency     = { id = "KoinLebaran", symbol = "🪙", nameKey = "event.lebaran.currency" },
		durationDays = 14,
		taskBonus    = true,
		shopItems    = { "BajuKoko", "KetupatDisplay" },
		eventTasks   = {
			{ type = "Talk",  count = 5, reward = { eventCurrency = 2 } },
			{ type = "Craft", item = "Ketupat", count = 3, reward = { eventCurrency = 5 } },
		},
	},
}

-- ============================================================
-- LOGIN STREAK REWARDS
-- ============================================================
AssetConfig.LoginStreak = {
	{ day = 1,  reward = { rupiah = 500 } },
	{ day = 2,  reward = { rupiah = 800 } },
	{ day = 3,  reward = { rupiah = 1000, items = { { id = "NasiBungkus", amount = 2 } } } },
	{ day = 5,  reward = { rupiah = 2000, items = { { id = "RandomTidakBiasa", amount = 1 } } } },
	{ day = 7,  reward = { rupiah = 3000, gold = 1 } },
	{ day = 14, reward = { rupiah = 5000, gold = 2, items = { { id = "RandomEpik", amount = 1 } } } },
	{ day = 30, reward = { rupiah = 10000, gold = 5, items = { { id = "RandomLegenda", amount = 1 } } } },
}

-- ============================================================
-- ACHIEVEMENTS
-- ============================================================
AssetConfig.Achievements = {
	{
		id      = "ACH_FirstMarriage",
		nameKey = "ach.firstmarriage.name",
		descKey = "ach.firstmarriage.desc",
		type    = "Relationship",
		target  = "Menikah",
		count   = 1,
		reward  = { gold = 1 },
	},
	{
		id      = "ACH_Defeat100",
		nameKey = "ach.defeat100.name",
		descKey = "ach.defeat100.desc",
		type    = "Combat",
		count   = 100,
		reward  = { rupiah = 5000 },
	},
	{
		id      = "ACH_AllPlaces",
		nameKey = "ach.allplaces.name",
		descKey = "ach.allplaces.desc",
		type    = "ExplorePlace",
		count   = 7,
		reward  = { gold = 5, items = { { id = "TitlePenjelajahNusantara", amount = 1 } } },
	},
	{
		id      = "ACH_AllZonesJawa",
		nameKey = "ach.allzonesjawa.name",
		descKey = "ach.allzonesjawa.desc",
		type    = "ExploreZone",
		place   = "Jawa",
		count   = 6,
		reward  = { gold = 1 },
	},
	{
		id      = "ACH_Pahlawan",
		nameKey = "ach.pahlawan.name",
		descKey = "ach.pahlawan.desc",
		type    = "Morality",
		target  = "Pahlawan",
		reward  = { items = { { id = "LegendaCosmeticGood", amount = 1 } } },
	},
	{
		id      = "ACH_Penjahat",
		nameKey = "ach.penjahat.name",
		descKey = "ach.penjahat.desc",
		type    = "Morality",
		target  = "Penjahat",
		reward  = { items = { { id = "LegendaCosmeticBad", amount = 1 } } },
	},
}

-- ============================================================
-- AUDIO (global/situational — zone BGM lives in Zones table)
-- ============================================================
AssetConfig.Audio = {
	BGM = {
		Combat        = "rbxassetid://0",
		MainMenu      = "rbxassetid://0",
		QuestComplete = "rbxassetid://0",
		TravelScreen  = "rbxassetid://0",
		Night         = "rbxassetid://0", -- shared night theme for all islands
	},
	SFX = {
		Punch         = "rbxassetid://0",
		KayuHit       = "rbxassetid://0",
		PisauHit      = "rbxassetid://0",
		KetapelShoot  = "rbxassetid://0",
		ItemPickup    = "rbxassetid://0",
		QuestComplete = "rbxassetid://0",
		ShopBuy       = "rbxassetid://0",
		ShopSell      = "rbxassetid://0",
		DialogOpen    = "rbxassetid://0",
		ZoneEnter     = "rbxassetid://0",
		MoralityRise  = "rbxassetid://0",
		MoralityFall  = "rbxassetid://0",
	},
	VFX = {
		HitSpark      = "HitSpark",
		MoralityRise  = "MoralityRise",
		MoralityFall  = "MoralityFall",
		AchRadiance   = "AchRadiance",
	},
}

-- ============================================================
-- ZONE BOUNDS (center + size for ZoneBoundary Part creation)
-- Positions are placeholders — replace with actual terrain positions after Studio work.
-- Each Place's zones share a coordinate space; zones in other Places have no conflict
-- because each Place is a separate server.
-- ============================================================
AssetConfig.ZoneBounds = {
	-- JAWA (6 zones)
	KotaJogja = { center = Vector3.new(    0, 50,    0), size = Vector3.new(2048, 500, 2048) },
	Suroboyo  = { center = Vector3.new( 3000, 50,    0), size = Vector3.new(2048, 500, 2048) },
	Semarang  = { center = Vector3.new( 6000, 50,    0), size = Vector3.new(2048, 500, 2048) },
	Bandung   = { center = Vector3.new(    0, 50, 3000), size = Vector3.new(2048, 500, 2048) },
	Jakarta   = { center = Vector3.new( 3000, 50, 3000), size = Vector3.new(2048, 500, 2048) },
	Serang    = { center = Vector3.new( 6000, 50, 3000), size = Vector3.new(2048, 500, 2048) },
	-- SUMATERA (10 zones)
	BandaAceh     = { center = Vector3.new(    0, 50,    0), size = Vector3.new(2048, 500, 2048) },
	Medan         = { center = Vector3.new( 3000, 50,    0), size = Vector3.new(2048, 500, 2048) },
	Padang        = { center = Vector3.new( 6000, 50,    0), size = Vector3.new(2048, 500, 2048) },
	Pekanbaru     = { center = Vector3.new(    0, 50, 3000), size = Vector3.new(2048, 500, 2048) },
	Palembang     = { center = Vector3.new( 3000, 50, 3000), size = Vector3.new(2048, 500, 2048) },
	BandarLampung = { center = Vector3.new( 6000, 50, 3000), size = Vector3.new(2048, 500, 2048) },
	PangkalPinang = { center = Vector3.new(    0, 50, 6000), size = Vector3.new(2048, 500, 2048) },
	Jambi         = { center = Vector3.new( 3000, 50, 6000), size = Vector3.new(2048, 500, 2048) },
	Bengkulu      = { center = Vector3.new( 6000, 50, 6000), size = Vector3.new(2048, 500, 2048) },
	TanjungPinang = { center = Vector3.new(    0, 50, 9000), size = Vector3.new(2048, 500, 2048) },
	-- KALIMANTAN (5 zones)
	Pontianak    = { center = Vector3.new(    0, 50,    0), size = Vector3.new(2048, 500, 2048) },
	Banjarmasin  = { center = Vector3.new( 3000, 50,    0), size = Vector3.new(2048, 500, 2048) },
	PalangkaRaya = { center = Vector3.new( 6000, 50,    0), size = Vector3.new(2048, 500, 2048) },
	Samarinda    = { center = Vector3.new(    0, 50, 3000), size = Vector3.new(2048, 500, 2048) },
	TanjungSelor = { center = Vector3.new( 3000, 50, 3000), size = Vector3.new(2048, 500, 2048) },
	-- SULAWESI (7 zones)
	Makassar   = { center = Vector3.new(    0, 50,    0), size = Vector3.new(2048, 500, 2048) },
	TanahToraja = { center = Vector3.new( 3000, 50,    0), size = Vector3.new(2048, 500, 2048) },
	Manado     = { center = Vector3.new( 6000, 50,    0), size = Vector3.new(2048, 500, 2048) },
	Gorontalo  = { center = Vector3.new(    0, 50, 3000), size = Vector3.new(2048, 500, 2048) },
	Palu       = { center = Vector3.new( 3000, 50, 3000), size = Vector3.new(2048, 500, 2048) },
	Kendari    = { center = Vector3.new( 6000, 50, 3000), size = Vector3.new(2048, 500, 2048) },
	Mamuju     = { center = Vector3.new(    0, 50, 6000), size = Vector3.new(2048, 500, 2048) },
	-- PAPUA (4 zones)
	Jayapura  = { center = Vector3.new(    0, 50,    0), size = Vector3.new(2048, 500, 2048) },
	Sorong    = { center = Vector3.new( 3000, 50,    0), size = Vector3.new(2048, 500, 2048) },
	Manokwari = { center = Vector3.new(    0, 50, 3000), size = Vector3.new(2048, 500, 2048) },
	Merauke   = { center = Vector3.new( 3000, 50, 3000), size = Vector3.new(2048, 500, 2048) },
	-- NUSA TENGGARA (3 zones)
	Denpasar = { center = Vector3.new(    0, 50,    0), size = Vector3.new(2048, 500, 2048) },
	Mataram  = { center = Vector3.new( 3000, 50,    0), size = Vector3.new(2048, 500, 2048) },
	Kupang   = { center = Vector3.new(    0, 50, 3000), size = Vector3.new(2048, 500, 2048) },
	-- MALUKU (2 zones)
	Ambon   = { center = Vector3.new(    0, 50,    0), size = Vector3.new(2048, 500, 2048) },
	Ternate = { center = Vector3.new( 3000, 50,    0), size = Vector3.new(2048, 500, 2048) },
}

-- ============================================================
-- DAY / NIGHT CYCLE
-- ============================================================
AssetConfig.DayNight = {
	RealMinutesPerDay    = 30,
	DawnHour             = 5,
	DuskHour             = 19,
	BrightnessDay        = 1.0,
	BrightnessNight      = 0.15,
	AmbientDay           = Color3.fromRGB(115, 115, 115),
	AmbientNight         = Color3.fromRGB(12, 12, 35),
	OutdoorAmbientDay    = Color3.fromRGB(115, 115, 115),
	OutdoorAmbientNight  = Color3.fromRGB(12, 12, 35),
	BroadcastIntervalSec = 60, -- how often GameTimeUpdate fires to clients
}

-- ============================================================
-- WORLD EVENTS (array for weighted-random selection)
-- ============================================================
AssetConfig.WorldEvents = {
	{
		id             = "MerchantAttacked",
		nameKey        = "event.world.merchant.name",
		weight         = 30,
		duration       = 60,
		banditCount    = 2,
		moralityReward = 8,
		rupiahReward   = 2000,
	},
	{
		id       = "RareIngredientSpawn",
		nameKey  = "event.world.ingredient.name",
		weight   = 20,
		duration = 120,
		itemId   = "Cincin",
	},
	{
		id             = "NPCDistress",
		nameKey        = "event.world.distress.name",
		weight         = 35,
		duration       = 90,
		moralityReward = 5,
		rupiahReward   = 500,
	},
	{
		id             = "PoacherCamp",
		nameKey        = "event.world.poacher.name",
		weight         = 15,
		duration       = 120,
		poacherCount   = 3,
		moralityReward = 10,
		rupiahReward   = 1500,
	},
}

-- ============================================================
-- RARITY (glow colors for collectible pedestals)
-- ============================================================
AssetConfig.Rarity = {
	Biasa            = { color = Color3.fromRGB(180, 180, 180), glowRange = 8  },
	["Tidak Biasa"]  = { color = Color3.fromRGB(30,  220,  80), glowRange = 12 },
	Langka           = { color = Color3.fromRGB(60,  100, 255), glowRange = 16 },
	Legenda          = { color = Color3.fromRGB(255, 170,   0), glowRange = 24 },
}

-- ============================================================
-- HELPER FUNCTIONS (nil-safe — callers must check return value)
-- ============================================================
function AssetConfig.getItem(id)
	return AssetConfig.Items[id]
end
function AssetConfig.getWeapon(id)
	return AssetConfig.Weapons[id]
end
function AssetConfig.getZone(id)
	return AssetConfig.Zones[id]
end
function AssetConfig.getQuest(id)
	return AssetConfig.Quests[id]
end
function AssetConfig.getPlace(id)
	return AssetConfig.Places[id]
end
function AssetConfig.getNPC(id)
	return AssetConfig.NPCs[id]
end
function AssetConfig.getShop(id)
	return AssetConfig.Shops[id]
end

-- Returns the morality tier table for a given morality value (0-100)
function AssetConfig.getMoralityTier(value)
	for _, tier in AssetConfig.Morality.Tiers do
		if value >= tier.min and value <= tier.max then
			return tier
		end
	end
	return AssetConfig.Morality.Tiers[#AssetConfig.Morality.Tiers]
end

-- Returns all zones belonging to a specific Place id
function AssetConfig.getZonesByPlace(placeId)
	local result = {}
	for _, zone in AssetConfig.Zones do
		if zone.place == placeId then
			result[#result + 1] = zone
		end
	end
	return result
end

return AssetConfig
