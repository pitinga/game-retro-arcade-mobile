extends RefCounted
# Pure shared fixed-step lifecycle; no wall clock, render or SDK.
enum State { BOOT, READY, RUNNING, PAUSED, RESULT, DISPOSED }
const STEP: float = 1.0 / 60.0
const MAX_STEPS: int = 5
var state: State = State.BOOT
var tick: int = 0
var accumulator: float = 0.0
var rng := RandomNumberGenerator.new()
var cosmetic_rng := RandomNumberGenerator.new()
var difficulty: String = "normal"
var model: RefCounted
var _result: Dictionary = {}
var _input: Dictionary = {}

func configure(module: RefCounted, seed_value: int, level: String) -> bool:
	if state != State.BOOT or not level in ["easy","normal","hard"] or module == null:
		return false
	if not module.has_method("create") or not module.has_method("step"):
		return false
	model = module
	rng.seed = seed_value
	cosmetic_rng.seed = seed_value ^ 0x5a5a5a5a
	difficulty = level
	model.call("create", rng, difficulty)
	state = State.READY
	return true

func start() -> bool:
	if state != State.READY:
		return false
	state = State.RUNNING
	return true

func set_input(snapshot: Dictionary) -> void:
	if state == State.RUNNING:
		_input = snapshot.duplicate(true)

func advance(delta: float) -> int:
	if state != State.RUNNING or not is_finite(delta) or delta <= 0.0:
		return 0
	accumulator += minf(delta, 0.1)
	var steps := 0
	while accumulator + 0.000000001 >= STEP and steps < MAX_STEPS and state == State.RUNNING:
		accumulator = maxf(0.0, accumulator - STEP)
		tick += 1
		steps += 1
		var terminal: Variant = model.call("step", _input.duplicate(true), STEP, rng)
		if terminal is Dictionary and not terminal.is_empty():
			finish(terminal)
	if steps == MAX_STEPS:
		accumulator = fmod(accumulator, STEP)
	return steps

func pause() -> void:
	if state == State.RUNNING:
		state = State.PAUSED
		_input.clear()
		accumulator = 0.0

func resume() -> bool:
	if state != State.PAUSED:
		return false
	state = State.RUNNING
	return true

func finish(result_data: Dictionary) -> bool:
	if state != State.RUNNING:
		return false
	_result = result_data.duplicate(true)
	state = State.RESULT
	_input.clear()
	accumulator = 0.0
	return true

func get_result() -> Dictionary:
	return _result.duplicate(true)

func dispose() -> void:
	_input.clear()
	accumulator = 0.0
	model = null
	state = State.DISPOSED
