extends SceneTree
const Shield=preload("res://games/missile-defense/model.gd")
# A bounded greedy reference player; actual simulation, no injected kills.
# Assign at most one successful shot per threat, prioritising imminent impact.
func intercept(model: RefCounted,threat: Dictionary) -> Vector2:
	var pos: Vector2=threat.pos
	var destination: Vector2=model.positions[threat.target]
	var velocity: Vector2=(destination-pos).normalized()*float(threat.speed)
	var impact:=pos.distance_to(destination)/maxf(1,float(threat.speed))
	for sample in range(1,121):
		var time:=float(sample)*0.025
		if time>=impact:
			break
		var aim:=pos+velocity*time
		if aim.y>Shield.H-34:
			break
		var distance: float=INF
		for i in range(2):
			if model.launchers[i] and model.ammo[i]>0:
				distance=minf(distance,Vector2(model.positions[i]).distance_to(aim))
		if distance/(1.15*Shield.H)+0.15<=time:
			return aim
	return Vector2(-1,-1)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var attempted: int=0
	var cleared: int=0
	var uncovered: int=0
	var rng:=RandomNumberGenerator.new()
	for seed in range(12):
		for wave: int in [1,5,20]:
			rng.seed=seed
			var m:=Shield.new()
			m.create(rng,["easy","normal","hard"][seed%3])
			m.wave=wave
			m.begin_wave()
			var assigned: Dictionary={}
			for tick in range(12000):
				if tick%3==0 and m.cooldown<=0:
					var threats: Array=m.threats.duplicate()
					threats.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return Vector2(a.pos).distance_to(m.positions[a.target])/float(a.speed)<Vector2(b.pos).distance_to(m.positions[b.target])/float(b.speed))
					for threat: Dictionary in threats:
						var key:=str(threat.start)+":"+str(threat.target)
						if assigned.has(key):
							continue
						var aim:=intercept(m,threat)
						if aim.x>=0 and m.fire(aim):
							assigned[key]=true
							break
				var result:=m.step({},1.0/60,rng)
				if not result.is_empty() or m.wave_wait>=0:
					break
			attempted+=1
			if m.wave_wait>=0:
				cleared+=1
			if m.habitats.count(true)<5 or m.launchers.count(true)<2:
				uncovered+=7-m.habitats.count(true)-m.launchers.count(true)
			print("AGENT seed=",seed," wave=",wave," cleared=",m.wave_wait>=0," intact=",m.habitats.count(true),"/",m.launchers.count(true))
	print("AGENT SUMMARY attempted=",attempted," cleared=",cleared," structures_lost=",uncovered)
	# Report empirical coverage rather than claim a mathematical solver. All representative scenarios must clear with every structure intact.
	quit(0 if attempted==36 and cleared==attempted and uncovered==0 else 1)
