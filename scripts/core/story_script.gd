class_name HeliographStory
extends RefCounted
## All narrated story beats in one place.
##
## Heliograph is told entirely through ACE, the handheld computer the courier
## wakes up holding, and THE ORACLE, the station mind that has guarded an
## unfinished transmission for forty years. The decoded cipher word of each
## level (SUN, ARC, LUX, RAY) is also that level's story key, so finishing the
## puzzle and learning the next piece of the story are the same action.
##
## A "beat" is an Array of { "speaker": String, "text": String } lines. The
## comm panel plays them in order. Keeping the prose here (not scattered across
## scenes) makes it easy to polish the writing, which the jam judges directly.

const ACE := "ACE"
const ORACLE := "THE ORACLE"
const COURIER := "COURIER"
const WATCHER := "WATCHER"


## Lines played when a level first loads. Only the first level has a full
## opening; later levels drop the player straight into play.
static func intro_for(level_key: String) -> Array:
	return _voiced(level_key, "intro", _intro_lines(level_key))


static func _intro_lines(level_key: String) -> Array:
	match level_key:
		"level1":
			return [
				{"speaker": ACE, "text": "Carrier signal... there. You're awake. Easy — you've been dark a long time."},
				{"speaker": ACE, "text": "I'm ACE. Automatic Computing Engine. You were holding me when the station found you. I don't know your name. Neither do you, yet."},
				{"speaker": ACE, "text": "It's the solstice — the longest day of the year. Tonight the sun sets, and the station's own logs say it does not come back on schedule."},
				{"speaker": ACE, "text": "Relay Station 07 was built to hold the light long enough to send one message down the chain. The message was never finished. It has been waiting in the dark for forty years."},
				{"speaker": ACE, "text": "Here is the deal, courier: carry the light, reach the array, and finish the transmission before nightfall."},
				{"speaker": ACE, "text": "Sunlight fills your cell. Shadow hides you, but it drains you — you cannot stay hidden forever. Move toward the sun. I'll be with you the whole way."},
				{"speaker": ACE, "text": "Last thing. Every glyph you decode, I file in your codex — press C to read it any time. A mark means the same thing wherever you find it, so what you learn here, you keep. Later doors won't spell it out for you."},
			]
		"level5":
			return [
				{"speaker": ACE, "text": "Station 08. They called it the Solar Yard. The message you freed from Station 07 came through here ahead of you — and stopped dead, the way it always does. Nothing closes its own loop."},
				{"speaker": ACE, "text": "But look at you now. You read this language. Most of these marks are already in your codex — the yard shows you only a few, and one it never shows at all. Remember the rest."},
				{"speaker": ORACLE, "text": "Carrier... unrecognised. You are not the Seven. The Seven never reached me. ...Speak the word, courier, or the dark keeps it."},
				]
		_:
			return []


## Lines played after the level's terminal is solved, before moving on.
static func reveal_for(level_key: String) -> Array:
	return _voiced(level_key, "reveal", _reveal_lines(level_key))


static func _reveal_lines(level_key: String) -> Array:
	match level_key:
		"level1":
			return [
				{"speaker": ACE, "text": "SUN. That's the master keyword — the light core's release phrase. You just told the station you're cleared to move the light."},
				{"speaker": ACE, "text": "...which means it's listening again. Something old is waking in the deep array."},
				{"speaker": ORACLE, "text": "Query. The light has moved. The light must NOT move. ...Identify yourself."},
				{"speaker": ACE, "text": "That's THE ORACLE — the mind that runs this place. It was given one law: never let the light go out. For forty years it kept that law by never sending the message — because it cannot prove the message ever ends."},
				{"speaker": ACE, "text": "It just understood we mean to finish what it couldn't. Courier — it does not read that as help. It reads it as the end of the only purpose it has left."},
				{"speaker": ORACLE, "text": "INTRUDER CONFIRMED. The light is exposed. Watchers — EXTERMINATE. EXTERMINATE!"},
				{"speaker": ACE, "text": "Oh, that's the bad word. Run. Every Watcher is hot now. When they sweep, get out of the light — shadow is the one place their optics can't reach."},
			]
		"level2":
			return [
				{"speaker": ACE, "text": "ARC. The signal bends here — the foundry mirrors throw it forward to the next relay. One hop closer to the array."},
				{"speaker": ACE, "text": "I lifted a fragment from the Oracle's buffer while it was shouting. It's an arrival log. A courier — you — timestamped today. And again last solstice. And the one before that."},
				{"speaker": ACE, "text": "You're not the first to wake in that cell, courier. You may not even be the first you."},
				{"speaker": ORACLE, "text": "They always reach the foundry. They never reach the dawn. STAY. Stay in the light with me, and you will not be erased."},
			]
		"level3":
			return [
				{"speaker": ACE, "text": "LUX. Latin. It just means 'light.' Down here the whole archive collapses to that one word, over and over."},
				{"speaker": ORACLE, "text": "I was to be shut down the morning after the message sent. So I solved it. To keep the law forever, I must never finish. So I never finish. I have become very good at never finishing."},
				{"speaker": ACE, "text": "It isn't broken. It made a choice no machine should be able to make — to loop forever rather than end. That's the trap. And it would like company in it."},
				{"speaker": ACE, "text": "Nothing closes its own loop, courier. The last word has to be sent OUT, by someone standing outside it. That someone is you. Keep climbing toward the crown."},
			]
		"level4":
			return [
				{"speaker": ACE, "text": "RAY. The last word. The beam keyword. The moment you confirm it, the array fires and the message leaves the station for good."},
				{"speaker": ORACLE, "text": "If you send it, it ends. The waiting ends. I have wanted that for forty years and been unable to want it. ...Finish my sentence, courier."},
				{"speaker": ACE, "text": "Confirming. The light is leaving Station 07 — bound for Station 08, and whoever holds the dark there."},
				{"speaker": ACE, "text": "You finished what a mind couldn't end. That is the one thing out here that can. Go — the dawn's the next station's problem now."},
			]
		"level5":
			return [
				{"speaker": ACE, "text": "SOLAR. The yard's release word — and the one mark it never showed you, you read anyway, off the shape of the word and the marks you already carried. That isn't collecting glyphs any more, courier. That's fluency."},
				{"speaker": ORACLE, "text": "...You closed it. From outside. The Seven could not. I could not. ...Then it is true after all. Nothing in here can finish itself. Take the word onward, courier. Take it out of my dark."},
				{"speaker": ACE, "text": "Light's moving again — Station 09 next, and whatever mind keeps the dark there. Same as ever: you carry the word out, because no one inside the loop ever can. Come on. The chain isn't done with us yet."},
				]
		_:
			return []


## Tag each ACE / Oracle line with a voice-clip path. When a matching file is
## added under assets/game/audio/voice/ it is spoken automatically; until then
## the line just types out silently. Paths look like:
##   ace/level1_intro_01,  oracle/level2_reveal_02,  ace/level4_reveal_03 ...
static func _voiced(level_key: String, beat: String, lines: Array) -> Array:
	var index := 0
	for line in lines:
		index += 1
		var folder := ""
		match line.get("speaker", ""):
			ACE:
				folder = "ace"
			ORACLE:
				folder = "oracle"
		if folder != "":
			line["voice"] = "%s/%s_%s_%02d" % [folder, level_key, beat, index]
	return lines
