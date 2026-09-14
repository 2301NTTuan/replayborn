extends Node

# Small synthesized mono samples: no external audio assets or runtime generators.
const RATE: int = 22050
var samples: Dictionary = {}
var voices: Dictionary = {}
var muted: bool = false
var music_voice: AudioStreamPlayer

func _ready() -> void:
	for key in ["shot", "hit", "hurt", "echo", "level_up", "upgrade", "win", "lose", "secondary_boomerang", "secondary_orbit", "secondary_drone", "secondary_mine", "secondary_beam"]:
		var params: Array = {
			"shot": [850.0, 300.0, 0.055], "hit": [220.0, 90.0, 0.06],
			"hurt": [170.0, 45.0, 0.22], "echo": [330.0, 880.0, 0.3],
			"level_up": [520.0, 1560.0, 0.42], "upgrade": [440.0, 1100.0, 0.22], "win": [440.0, 1320.0, 0.6],
			"lose": [220.0, 55.0, 0.5],
			"secondary_boomerang": [980.0, 420.0, 0.10], "secondary_orbit": [260.0, 760.0, 0.14],
			"secondary_drone": [1250.0, 680.0, 0.08], "secondary_mine": [180.0, 680.0, 0.20],
			"secondary_beam": [720.0, 1320.0, 0.16]
		}[key]
		samples[key] = make_tone(params[0], params[1], params[2])
		var voice := AudioStreamPlayer.new()
		voice.stream = samples[key]
		voice.volume_db = -15.0 if key == "shot" or key == "hit" else -7.0
		add_child(voice)
		voices[key] = voice
	music_voice = AudioStreamPlayer.new()
	var licensed_loop := load("res://assets/audio/replayborn_tense_future_loop.ogg") as AudioStreamOggVorbis
	if licensed_loop != null:
		licensed_loop.loop = true
		music_voice.stream = licensed_loop
	else:
		music_voice.stream = make_music()
	music_voice.volume_db = -24
	add_child(music_voice)
	music_voice.play()

func make_music() -> AudioStreamWAV:
	var sample := AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = RATE
	var count: int = RATE * 8
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var notes: Array = [110.0, 130.8128, 164.8138, 146.8324]
	for index in range(count):
		var time: float = float(index) / RATE
		var local: float = fmod(time, 2.0)
		var frequency: float = notes[mini(3, int(time / 2))]
		var envelope: float = sin(PI * local / 2.0)
		var value: float = sin(TAU * frequency * local) * 0.65 + sin(TAU * frequency * 2 * local) * 0.2
		bytes.encode_s16(index * 2, int(value * envelope * 9000))
	sample.data = bytes
	sample.loop_mode = AudioStreamWAV.LOOP_FORWARD
	sample.loop_begin = 0
	sample.loop_end = count
	return sample

func set_levels(effects: float, music: float) -> void:
	set_muted(effects <= 0)
	for key in voices:
		voices[key].volume_db = (-15.0 if key in ["shot", "hit"] else -7.0) + linear_to_db(maxf(0.0001, effects))
	if music_voice != null:
		music_voice.volume_db = -16.0 + linear_to_db(maxf(0.0001, music))
		if music <= 0:
			music_voice.stop()
		elif not music_voice.playing:
			music_voice.play()

func make_tone(start: float, finish: float, duration: float) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	var count: int = int(RATE * duration)
	bytes.resize(count * 2)
	var phase: float = 0.0
	for index in range(count):
		var progress: float = float(index) / count
		phase += TAU * lerpf(start, finish, progress) / RATE
		var envelope: float = minf(progress * 30.0, 1.0) * pow(1.0 - progress, 2.0)
		bytes.encode_s16(index * 2, int(sin(phase) * envelope * 12000.0))
	var sample := AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = RATE
	sample.data = bytes
	return sample

func play(cue: String) -> void:
	if muted or not voices.has(cue):
		return
	var voice: AudioStreamPlayer = voices[cue]
	# A separate voice per cue prevents rapid shots from cutting off feedback.
	if not voice.playing:
		voice.play()

func set_muted(value: bool) -> void:
	muted = value
	if muted:
		for voice in voices.values():
			voice.stop()

func _exit_tree() -> void:
	if music_voice != null:
		music_voice.stop()
		music_voice.stream = null
	for voice in voices.values():
		voice.stop()
		voice.stream = null
	voices.clear()
	samples.clear()
