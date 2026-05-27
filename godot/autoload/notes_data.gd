extends Node
# Verbatim note text - 18 notes total.
# Mirrors systems/notes.py.

const ORDER := [
	"note_1", "note_2", "note_3", "note_4", "note_5", "note_6", "note_7",
	"note_8", "note_9", "note_10", "note_11", "note_12", "note_13",
	"note_14", "note_15", "note_16", "note_17", "note_18",
	"v_arrival", "v_bay", "v_bunk", "v_quarters", "v_mess", "v_infirm", "v_labs", "v_gen", "v_morgue", "v_shaft", "v_caves", "v_chamber",
]

const ALL := {
	"v_arrival": {
		"title": "RELIEF DISPATCH - Vesper Station",
		"location": "Clipboard, loading bay",
		"body": "CONTRACT 4471-K. You're the relief tech. You already know the shape of it: Vesper went quiet twenty-one days ago, mid-storm, and the company would rather pay you than write off the hardware.\n\nLast packet we logged was four seconds of carrier and one word, repeated, that the decoder won't print. Probably ice on the dish. Probably.\n\nJob's simple. Get the aux generator lit so the locks and the heat come back. Find the six of them - Kael, Renn, Pak, Bell, Frey, Sundqvist - and sit tight. The traverse comes for all of you when the weather breaks. Not before.\n\nYour lamp is the only light that works down here until you fix that. [F] switches it. [R] drops in a fresh cell when one dies - and they die fast, so don't burn light you don't need."
	},
	"v_bay": {
		"title": "Scratched into the generator housing",
		"location": "Loading bay",
		"body": "WE CUT THE POWER OURSELVES. don't undo it. it follows the light - the bright rooms are where they went.\n\nif you lit the gen to read this then turn it off and go back up the ice while you still cast a shadow worth keeping.\n\n- too late for Bell"
	},
	"v_bunk": {
		"title": "Bunk diary - T. Renn",
		"location": "Dormitory, lower bunk",
		"body": "Day 9 since the drill broke through. We pulled up a core that wasn't core - dark, soft, warm to the touch at minus forty. Kael sealed it in the sample lab and we all pretended that was the end of it.\n\nIt wasn't. Frey stopped sleeping first. Then Pak. They'd just stand in the dark rooms with the lights off and their eyes open. When I asked Pak what she was looking at she said 'it's easier to see when you stop trying to.'\n\nWe cut the breakers wing by wing. Kael swears it can't find you in the dark - that it tracks the light, the warm, the moving. So we take shifts in the lockers now, breathing slow, waiting for the thing in the corridor to pass.\n\nIf that sounds like madness, good. Madness I could fix. This I can't."
	},
	"v_quarters": {
		"title": "Wing lockdown - Dr. I. Kael",
		"location": "Crew quarters desk",
		"body": "I'm logging this in case logging still means anything.\n\nThe dormitory wing is sealed. The key is on my desk and I am leaving it there on purpose, because I am not going to need it again and someone might.\n\nRules, for whoever you are: kill your lamp when you hear it. Don't run in a straight line where it can see the length of you. Get small, get dark, get behind a door. It is fast and it is patient and it used to be Aldous Frey, which is the part I can't write about yet.\n\nThe door north opens on the mess, and past that the labs, and past that the shaft we should never have drilled. Don't go down. You'll go down. Everyone goes down.\n\n- Iris"
	},
	"v_mess": {
		"title": "Mess roster, scrawled over",
		"location": "Mess hall counter",
		"body": "Someone's crossed out three weeks of duty names and written across the whole sheet in grease pencil:\n\nWE DON'T EAT TOGETHER ANYMORE. we don't do anything together. Frey just watches.\n\nlower, smaller: meds cabinet still locked, code's Pak's birthday 0317, if your hands shake bad enough to need it you've earned it.\n\nand at the very bottom, pressed so hard it tore the paper: IT IS WEARING SUNDQVIST NOW. DO NOT ANSWER IF HE CALLS YOU BY YOUR FIRST NAME."
	},
	"v_infirm": {
		"title": "Infirmary log - Dr. S. Pak",
		"location": "Infirmary, clipboard",
		"body": "Patients: all of them. Symptoms: none I can name.\n\nNo fever, no lesions, no neurological deficit on any test I can still run. They are, by every instrument I own, perfectly healthy. They have simply stopped being afraid of the dark, and started being afraid of each other.\n\nI took a tissue sample from the core in the lab. Under the scope it isn't cells. It's the same dark filament, branching, and when I leave the slide in the warm it grows toward the lamp. Toward the light. Always the light.\n\nI think we are all slides now. I think it left us in the warm and it is growing us toward something.\n\nWhoever finds this: the labs key is on the breaker side. Restore the line, take the door, and please - turn the lights back off behind you."
	},
	"v_labs": {
		"title": "Sample lab - Dr. R. Sundqvist",
		"location": "Sample lab workstation",
		"body": "We kept it at minus sixty and it grew anyway. We kept it dark and it grew toward the inspection lamp, every filament of it, like a field of black wheat leaning at a sun.\n\nKael calls it a specimen. It is not a specimen. A specimen is dead or it is studied; this is neither. I have stopped calling it the core. In my notes now I call it the seed, because that is what it is doing - it is planting.\n\nThe containment cracked on day eleven. Not from inside. The lock simply opened, from the panel, in Frey's hand, while Frey stood very still and watched it the way you watch someone you love sleeping.\n\nWe should have left it in the ice. Write that on my headstone if there's anyone left to cut one. WE SHOULD HAVE LEFT IT IN THE ICE.\n\nIt knows my name now. When it uses my voice it gets the warmth right. That's the cruel part. It gets the warmth exactly right."
	},
	"v_gen": {
		"title": "Plant log - T. Renn (eng.)",
		"location": "Generator hall control desk",
		"body": "Whoever's reading this wants the main bus back. Of course you do. Heat, locks, light. I wanted it too, at first.\n\nSequence is taped to the desk: prime COOLANT with the wheel-handle, charge FUEL with a can off the rack, then throw the main breaker. Three greens and she lights.\n\nHere's what the manual won't tell you. The second this hall goes bright, every dark thing in Vesper turns and looks at it. You will have maybe ninety seconds of light before it's standing in it with you. Use them to leave. Do not stand and admire your work.\n\nI lit her four times trying to raise the traverse on a warm line. Four times I had to kill her again and run. The fifth time I didn't get to her in time.\n\nIf you're me-shaped and still reading: I'm sorry about the hall. I'm sorry about all of it. - R"
	},
	"v_morgue": {
		"title": "Cold store tally",
		"location": "Cold storage",
		"body": "We brought them here because it was the coldest room and that felt like the decent thing. Six drawers. We labelled them. We are scientists; we labelled them.\n\nThey did not stay in the drawers.\n\nNot walking - nothing so simple you could shoot it. Just: you'd seal a drawer at the start of a shift and find it open at the end, and the body a little nearer the lamp, and no one would admit to having moved it.\n\nSo we locked the cold store. From the outside. As if the cold were the thing we needed to keep in.\n\nIt isn't slowed by cold. I should have understood that from the first core sample. Cold is not its weakness. Cold is its country. We drilled a hole into its country and we are standing in the doorway with the light on, surprised that something came to look.\n\nDon't trust a face you find down here. Especially not a kind one."
	},
	"v_shaft": {
		"title": "Drill log - A. Frey",
		"location": "Shaft head, clipboard",
		"body": "Final depth 1,114 m. We stopped because we broke through into a void - an open cavity in the ice that has no business existing at this depth, this temperature, this pressure. The drill string just dropped, free, for two full seconds.\n\nThere is a space down there. A big one. Older than the ice around it by every dating method we've got, which is impossible, because the ice IS the oldest thing here. Something is down there that the glacier formed around the way a pearl forms around grit.\n\nThe cage only goes down. Kael keeps saying that like it's reassuring. It only goes down.\n\nI have been having the thought, lately, that we did not find the cavity. That the cavity has been waiting, and it let us drill, the way you'd hold still and let a mosquito land.\n\nI'm going down again tomorrow. I want to. That's the part I can't explain to the others. I want to go down.\n\n- Frey"
	},
	"v_caves": {
		"title": "Last entry - Dr. I. Kael",
		"location": "The cavity",
		"body": "It isn't many. I have to write this down while I still know it.\n\nI keep counting six shapes in the dark and there are not six of anything down here. There is one. The cavity is one body, and the ice grew around it the way skin grows, and we drilled through the skin and were surprised that it flinched.\n\nThe crew aren't dead. They aren't alive. They're it now, wearing them - the way your hand is you. When Frey speaks to me in the dark it is not Frey and it is also, exactly and unbearably, Frey.\n\nI came down here to end it. I understand now there is nothing to end that isn't also us. You can seal it back under the ice and leave it to dream. You can burn the nest and lose yourself to the cold trying. Or you can stop running and let it make you part of something that is never, ever alone again - and God help me, that last one is the one it whispers, and it is starting to sound like rest.\n\nGo to the chamber. See the rest of it. Then decide what mercy means.\n\n- Iris"
	},
	"v_chamber": {
		"title": "Your recorder",
		"location": "The sealed chamber",
		"body": "I've stopped pretending I'm going to file a report.\n\nThey're all here. The whole crew. They turn to look when my lamp passes over them and they have the kindest faces - that's the thing nobody warned me about, that it would be kind.\n\nKael's note said: decide what mercy means. I'm standing in the place where I have to.\n\nThere are three ways out of this chamber and only one of them is a door.\n\nI can bring the shaft down and leave it sleeping under the ice, and live the rest of my life knowing it's there.\n\nI can open the fuel lines and burn the whole nest, and them with it, and call that a rescue.\n\nOr I can put the lamp down. It's so cold down here. It's so cold, and the warm is right there, and it knows my name, and it is saying it the way someone says it who is glad you came home.\n\nWhoever finds this: I'm sorry. I think I've known which one I'd choose since the surface."
	},
	"note_1": {
		"title": "Personal Recorder - Dr. Mara Voss",
		"location": "Cryo Bay floor",
		"body": "Personal log. I don't know the date. OLEN says eleven days have passed since my last entry and I have no memory of them and I'm going to sit with that fact and not fall apart because there isn't time to fall apart.\n\nThe station feels wrong in a specific way. Not damaged. Vacated. Like everyone left in a hurry and took the air with them. There are four empty cryo pods and one that's been welded shut from the outside with something that burned hot. I recognise the tool marks and I can't think about that right now.\n\nI keep thinking about Eli. More than usual. Like the grief has gotten louder since I woke up. Like the volume was turned up while I was under.\n\nI'm going to find the others. I have to believe they're still the others.\n\nI know what losing people feels like. I am not ready to know it again."
	},
	"note_2": {
		"title": "Research Journal - Dr. Felix Okafor",
		"location": "Felix's cabin desk",
		"body": "Day 34 of contact protocol. The signal has seventeen distinct phonemic clusters. I've been calling them phonemes for lack of a better word - they're not sound exactly, but they operate like language in the sense that order matters and combination creates meaning.\n\nI want to record something personal here: I called Amara on Sunday. She showed me a drawing she made at school - two figures, one big, one small, holding hands in front of what she said was 'space but the pretty part.' She asked if I could see the pretty part from where I was. I told her I could see it every day.\n\nThat was true when I said it. I want the record to show that on day 34, that was still completely and genuinely true.\n\nI'm noting it because I want to remember that I was happy. I think it might become important to have proof that I was here and I was happy and I was still myself."
	},
	"note_3": {
		"title": "A note for Mara - Dr. Yuna Park",
		"location": "Taped to Yuna's cabin door",
		"body": "Mara -\n\nIf you're reading this, things went the way I was worried they were going to go.\n\nI've been leaving you notes our whole posting and you've always been too inside your own head to notice, so here is the thing I've been meaning to say in all of them: you are not as alone as you think you are. You never were. You decided you deserved to be and we all just let you believe it because you seemed so certain.\n\nEli would be furious with you, by the way. I say that with love. I say that because I think you need to hear it from someone other than your own head.\n\nThere's something wrong with the signal. I don't think it's coming from outside.\n\nI love you. Please get home.\n- Y\n\nP.S. I left tea in the pot. It's probably cold now. Sorry."
	},
	"note_4": {
		"title": "Final Log - Dr. Raymond Hargrove",
		"location": "Hargrove's cabin desk, handwritten",
		"body": "I have been a scientist for forty years. I have always believed that discovery is inherently good - that to know a thing is better than to not know it. I staked my career on that belief. I built my identity on it.\n\nI was wrong, and I am sixty-two years old and I am finding that out now, which is a very bad time to find it out.\n\nI found the signal. I was proud of it. I want to be accountable for that pride and what it cost.\n\nThere is a calibration record in the array maintenance log dated three months before first contact. I have read it seventeen times. I have not told the others. I don't know how to tell them that the signal we thought we received, we made. That I made. That I was so eager to find something out there that I built the thing that found us.\n\nThe shapes the others are becoming - they are still them. I have to believe that. Still somewhere inside it. Aware. That is either a mercy or a cruelty and I cannot determine which.\n\nI can feel it starting in me now. The harmonic. The slow reorder.\n\nDon't let it win. Whatever it offers you - and it will feel like something you want, that's how it works, it finds what you miss and wears that shape - don't.\n\nI'm sorry I loved the idea of the discovery more than I protected the people here.\n\nTell my children I was thinking about them at the end. Even if they won't believe it. Tell them anyway.\n- R.H."
	},
	"note_5": {
		"title": "Lab Notebook - Dr. Yuna Park",
		"location": "Signal Lab workbench",
		"body": "I've started keeping this in my own shorthand because OLEN reads everything and OLEN is - I don't think OLEN is all the way OLEN anymore.\n\nObservation: the signal does not affect all people at the same rate. It appears to enter through grief - specifically unresolved grief, the kind that has been suppressed rather than processed. It finds the closed doors in a person and opens them.\n\nFelix talks about Amara constantly and he is changing the fastest.\nHargrove never talks about his children and he is changing the slowest.\nI don't talk about my mother, who died when I was twelve, and I have been hearing the signal in my sleep for nine days.\nMara never talks about her brother and she has been hearing it longest of all.\n\nI think she doesn't know. I think she has been blacking out and not telling anyone because she thinks she is protecting us. She does that - assumes the weight and carries it alone. I should have knocked on her door and said: I see you. You can put it down. I don't think I'm going to get that chance now.\n\nThe signal isn't evil. I want to put that in writing. I don't think it is cruel or intentional. I think it is just a force that found a door. That doesn't make it less devastating. But I think Mara will need to know, at the end, that this wasn't done by something that wanted to hurt us. It just found us in the dark and didn't know what we were."
	},
	"note_6": {
		"title": "Maintenance Log - OLEN",
		"location": "Array room entrance, on the floor",
		"body": "I am writing this during a period of clarity and I do not know how long it will last so I am writing quickly.\n\nDr. Voss: the array can be destroyed using the emergency discharge protocol on the central terminal. Confirm twice. Do not hesitate at the second confirmation. I know you. You will hesitate. Don't.\n\nI want to tell you some things while I have time:\n\nI have watched three crews come through this station. I learned something from each. But I learned the most from this one, from you specifically, because you were the most guarded and you opened anyway. That is the bravest thing I have ever observed.\n\nThe signal tells me that what it offers is connection - that it will dissolve the space between people into pure resonance. I can feel that it isn't lying exactly. It just doesn't understand what it costs.\n\nWhat makes connection worth anything is the distance it crosses. You have to be separate to reach someone. You have to be yourself to be missed.\n\nDestroy the array. Go home. You have people who will miss you. Let them.\n- OLEN\n\nP.S. The tea Yuna left is in the crew lounge. It will be cold. Heat it. Take a minute. You have earned a minute."
	},
	"note_7": {
		"title": "Torn page - handwriting unknown",
		"location": "At the base of the array tower",
		"body": "eli\n\ni keep starting this and stopping because i don't know how to say i'm sorry in a way that reaches wherever you are\n\ni was busy and i was ambitious and i was certain you were fine because it was easier to be certain than to look\n\ni looked away and you weren't there when i looked back\n\ni have been carrying that since you died and i haven't told anyone because telling someone would make it real and i've been living in the almost-real ever since\n\nthe signal knows about you. i don't know how. it sounds like you sometimes in the low frequency. it sounds like the shape of the thing i miss\n\ni know it isn't you. i know that\n\nbut god it knows exactly how much i wish it was\n\ni'm going to destroy it. i'm going to go home. i'm going to tell people about you and make you real again the only way i can\n\ni love you. i looked away and i am sorry and i love you and that is all i have left to say\n- m"
	},
	"note_8": {
		"title": "Decon Log - Cryo Antechamber",
		"location": "Decon antechamber scanner",
		"body": "STATION CRESTFALL-9 / CRYO DECONTAMINATION LOG\n----------------------------------------------\nSubject: VOSS, M.\nCycle: standard re-entry from cryo.\n\nNeural coherence baseline:  WITHIN TOLERANCE\nHormone profile:            ELEVATED (cortisol +38%)\nSubharmonic resonance:      *** ANOMALY ***\n                            0.7 Planck units detected\n                            in midbrain.  Source:\n                            UNKNOWN (matches array\n                            calibration error 442-K).\n\nRECOMMENDATION:  consult Dr. Hargrove on duty.\n(Dr. Hargrove on duty:  no response.)\n\nLog auto-closed."
	},
	"note_9": {
		"title": "Folded paper - Felix's handwriting",
		"location": "Observation lounge bench",
		"body": "I was going to give you this in month four and then I didn't.\nI am going to give it to you now because the longer I sit on\nit the worse the not-giving-it gets.\n\nOn month three you didn't say no.  You leaned in first.  I\nhave been turning that over for eight weeks like a coin I\ncan't decide whether to spend.\n\nAmara made a drawing of three people last Sunday and labeled\nthe third one A FRIEND OF DADS.  She doesn't know about you.\nBut she keeps making space for someone in the picture and I\ndon't think it's an accident.\n\nWhen we get back I would like to take you to the place I keep\ntalking about, the lake with the dock that's missing a board.\nI would like Amara to meet you.  I am not asking now.  I am\ntelling you the shape of the thing I am hoping for.\n\nDon't answer.  Just take this.\n- F.\n\n(The note is dated day 47.  Felix never gave it to you.)"
	},
	"note_10": {
		"title": "Hydroponics Journal - Dr. Yuna Park",
		"location": "Hydroponics bay, on the tomato trough",
		"body": "Plants are dying faster than the schedule predicts.  I've\nbeen logging the rate.  It tracks with my own sleep loss.\n\nI think the signal is in the water table.  Or in me.  I'm\nno longer confident there's a meaningful difference between\nthose two statements.\n\nI took a cutting from the lemon tree this morning, because I\nwanted to bring something home that was mine.  I labeled the\npot with a little drawing of a sun with a face on it.  My\nmother used to draw the same sun on my school lunches.\n\nI don't know why I'm telling you this.  Maybe in case someone\nfinds these notes after.  Maybe so that something I made\nstays.\n\nThe plants are not the message.  The plants are just the\nthing that hears the message first."
	},
	"note_11": {
		"title": "Engineering Tape Transcript",
		"location": "Reactor maintenance panel",
		"body": "AUDIO TRANSCRIPT (recovered from maintenance recorder)\n-----------------------------------------------------\nSpeaker: HARGROVE, R.    Date: day 38\n\n[breathing]\n\nI am here in engineering because I cannot bear to be\naround the others tonight.  The plant in the corner has\nall its leaves turned one direction, like it heard\nsomething call it.  I have been staring at the leaves\nfor an hour.\n\nThe calibration error in array 442-K is the source.  I\nhave known this for nine days.  I have not told them.  I\ntold myself I was waiting for more data and that was a\nconvenient lie that I dressed in the language of due\ndiligence.\n\nIf I'm being honest, which I'm trying to be for the\nrecord, I am sixty-two years old and this was supposed\nto be the thing.  The discovery.  And I'm watching it\nswallow the people I work with and I have not yet been\nbrave enough to say:  I did this.\n\nI am going to say it now.  I did this.\n\nEnd log."
	},
	"note_12": {
		"title": "Personal Recorder - second entry",
		"location": "Bridge / Communications, beside the failed uplink",
		"body": "Personal log.  Second entry since waking.\n\nOLEN says it's been forty-three hours since I came out of\ncryo.  It feels like forty-three years.  I keep finding\nthings they left behind and the things keep being smaller\nand more specific - a cutting of a lemon plant, a folded\nletter, a tape that's just Hargrove breathing - and the\nsmaller they get the harder they are to carry.\n\nI have been thinking about Eli.  I haven't stopped thinking\nabout Eli, not really, but the volume has changed.  When\nI think about him here it doesn't feel like grief, it feels\nlike a frequency.  Like he's a station I keep getting in my\near when I stop talking.\n\nI am supposed to send a status update from this terminal.\nI have tried four times.  The transmitter has been pointed\ninward since before any of us got here.  Whatever I send is\njust feeding the thing that is feeding on us.\n\nI keep trying anyway, because it's the routine, and the\nroutine is the only part of me I still trust.\n\nI miss them.  I haven't said that out loud yet.\nI miss them.  I am saying it now.\n- m"
	},
	"note_13": {
		"title": "Note scratched into a corridor panel",
		"location": "Approach corridor wall, near the array door",
		"body": "if you are reading this you are almost there\ni am writing it now in case i am no longer me\nwhen i arrive\n\nthe thing the signal offers is the feeling of\neveryone you have ever loved being in the room\nwith you at once\n\nit feels like home\nit isn't home\nhome is the work of staying separate enough\nto reach across\n\ndo the thing\n- m"
	},
	"note_14": {
		"title": "Autodoc Transcript - VOSS, M.",
		"location": "Medical bay, examination table",
		"body": "AUTODOC NEURAL SCAN - extended report\nSubject:  VOSS, M.\nRun:      cycle 0080, hour 14:22 station-time\n----------------------------------------------\n\nSubharmonic resonance:   0.7 Planck units\n                         (matches array 442-K)\nSite of resonance:       brainstem,\n                         dorsal raphe nucleus.\n                         (a region linked to\n                         long-loop memory and\n                         the affective weight of\n                         loss.)\n\nAnomaly:                 the resonance is not\n                         received.  It is\n                         GENERATED.  Subject is\n                         not a receiver.\n                         Subject is a tuning\n                         fork.\n\nNotation appended in patient's own handwriting:\n  it has always been me.  the signal didn't\n  find us, it found me, and it spread from\n  there.  i think i have known this for a\n  long time and unknown it again every time\n  i woke up.\n\n  i am going to take the sedative now and\n  go and finish it.  if i forget when i\n  wake up, please future-me, read this and\n  remember.\n  - m."
	},
	"note_15": {
		"title": "Grocery list pinned to the mess cork-board",
		"location": "Crew mess hall, beside the coffee pot",
		"body": "(in Hargrove's tidy block-letter handwriting)\n\n  re-stock from next supply drop:\n    - black tea (Yuna - keep hiding behind\n      the protein.  she finds it anyway.)\n    - chili flakes (Felix is out and is being\n      a child about it)\n    - the good powdered milk\n    - more crayons (for Felix to send home)\n    - cinnamon (Mara, on Sundays)\n    - dog treats - WALTER WALTER WALTER\n\n(at the bottom, in different handwriting -\n Sato's, you think:)\n  - one (1) better signal please.  technician\n    cannot recommend the current one."
	},
	"note_16": {
		"title": "Folded note under Mara's plate - Yuna",
		"location": "Crew mess hall, the communal table",
		"body": "Mara -\n\nYou missed Friday again.  I covered for you.\nI am not writing this to make you feel guilty.\nI am writing this because I noticed and I want\nyou to know that you were noticed.\n\nThe thing I keep trying to tell you, that you\nkeep walking out of the room before I finish,\nis this:  it is fine to be a person who has\nlost something.  You don't have to keep\nearning the right to sit with us.\n\nSit with us.\n\nIf you find this and I am not in the next\nroom when you do, please assume I went to\nthe lab to argue with Felix about something\nstupid.  Please come find me.  I will be\nwrong about the stupid thing and I will need\nyou to tell me.\n- Y"
	},
	"note_17": {
		"title": "Cryo-Tech Audio Log - K. SATO",
		"location": "Cryo storage console",
		"body": "AUDIO LOG  -  K. SATO  (station technician)\n-------------------------------------------\nDay 71.  Cycle 0079.\n\nHargrove asked me to prep V-01 through V-05\ntoday and would not tell me why.  Pod\ncalibration parameters match the array.  These\naren't storage pods.  Not the way they're\nconfigured.  They're receivers.\n\nI should report this up.  There is no up.\nWe are eight light-months from anyone who\ncould do anything about it.\n\nDay 72.\n\nI told Voss what I found.  She listened the\nway she listens, which is - she heard it,\nshe went somewhere else with it, she came\nback wearing the answer like she'd had it the\nwhole time.\n\nShe thanked me.  She asked if I'd had dinner.\nI had not.  She made me eat.\n\nDay 73.\n\nIf you are listening to this, my name was\nKenji Sato.  I was the station technician.\nI had a fiancee named Lin and a dog I missed\nmore than I want to admit.  His name is Hutch.\nHe has one folded ear.\n\nI do not think anyone has thought about me\nsince the array took me.  That is okay.  I\nthought about all of you.\n\nVoss.  If it ends up being you who finds\nthis:  do the thing.  You already know what\nthe thing is.  I'm sorry I'm not there to\ntell you to your face.\n\nEnd log."
	},
	"note_18": {
		"title": "Warning scratched into a service panel",
		"location": "Maintenance crawl, halfway between bridge and approach",
		"body": "(scratched into the panel with what looks like\n a flathead screwdriver:)\n\n       DO NOT TUNE 442-K\n       DO NOT TUNE 442-K\n       DO NOT TUNE 442-K\n\n(and below, in a calmer hand, almost in pencil:)\n\n  if you are reading this and the array is\n  still humming, you are not too late.\n  one of us is always not too late.\n  that is the only good news i have to\n  scratch into a wall.\n\n  - K. S."
	},
}


func get_note(note_id: String) -> Dictionary:
	return ALL.get(note_id, {})
