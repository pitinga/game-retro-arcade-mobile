extends RefCounted
# The sole catalogue authority. Gameplay is intentionally unavailable in M1.
const ITEMS = [
	{"id":"G01","slug":"river-shooter","name":"Canyon Wings","free":true,"landscape":false,"pt":"Voo e navegação","en":"Flight and navigation"},
	{"id":"G02","slug":"endurance-racing","name":"Horizon Rally","free":true,"landscape":false,"pt":"Corrida de resistência","en":"Endurance racing"},
	{"id":"G03","slug":"brick-breaker","name":"Prism Break","free":true,"landscape":false,"pt":"Quebra de prismas","en":"Prism breaking"},
	{"id":"G04","slug":"submarine-rescue","name":"Abyss Rescue","free":false,"landscape":true,"pt":"Resgate subaquático","en":"Underwater rescue"},
	{"id":"G05","slug":"ice-platformer","name":"Polar Workshop","free":false,"landscape":true,"pt":"Reparo polar","en":"Polar repairs"},
	{"id":"G06","slug":"cave-rescue","name":"Deep Signal","free":false,"landscape":true,"pt":"Resgate subterrâneo","en":"Underground rescue"},
	{"id":"G07","slug":"mall-chase","name":"Skyport Chase","free":false,"landscape":true,"pt":"Interceptação","en":"Interception"},
	{"id":"G08","slug":"jungle-adventure","name":"Emerald Expedition","free":false,"landscape":true,"pt":"Exploração","en":"Exploration"},
	{"id":"G09","slug":"asteroid-shooter","name":"Orbit Shards","free":false,"landscape":true,"pt":"Mineração orbital","en":"Orbital mining"},
	{"id":"G10","slug":"missile-defense","name":"Aurora Shield","free":false,"landscape":true,"pt":"Defesa de habitats","en":"Habitat defense"}
]
static func find(id: String) -> Dictionary:
	for item: Dictionary in ITEMS:
		if item.id == id:
			return item.duplicate(true)
	return {}

static func can_access(id: String, verified_pro: bool) -> bool:
	var item := find(id)
	return not item.is_empty() and (item.free or verified_pro)
