
# -------------------- Final Experiment Script, PiPS Group 8 --------------------

# Key Information:
# This script consists of a Go/No-Go task with customizable parameters and stimuli.
# It allows the researchers to answer research questions where different versions of the Go/No-Go task may be needed.
# Detailed information about this task and its different versions can be found on our GitHub repository:
# https://github.com/anuver314-byte/PIPS_Impulsivity
# For how Go/No-Go task-relevant factors may affect participants' task performances, see Gladwin et al. (2019).
# For people who do not know Python well, extra comments are provided to facilitate understanding of the logical structure.

# Code Structure (script):
# Packages
#     ↓
# Parameter settings -> Stimuli -> Keyboard & User interface
#     ↓
# Trial sequence -> Data output
#     ↓
# Full task

# Workflow Structure (user interface):
# Researcher settings → Stimulus choices → Participant ID
#     ↓
# Instructions for the participant → Practice → Official trials → Appreciation
#     ↓
# Researcher chooses:
#   Next participant with the same settings
#   OR
#   Finish data collection

# -------------------- Packages --------------------

# Python's built-in modules
import csv                          # write results from the task trials into a CSV file
import math                         # provide mathematical functions
import random                       # create a random number generator & shuffle the trial order
from datetime import datetime       # get the current date and time
from pathlib import Path            # build file paths & create the data output folder

# PsychoPy is an open-source package for running experiments in Python
from psychopy import visual, event, core, gui
# the visual module creates the user interface and everything displayed inside it
# the event module controls mouse visibility
# the core module controls the timing and process of the experiment
# gui module creates dialog boxes for researchers to select the task version and enter trial counts
from psychopy.hardware import keyboard
# the keyboard module collects keyboard responses and participants' reaction time

# -------------------- Default Task Version & Parameter Settings --------------------

version_basic = "Go/No-Go Task: Basic"
version_digit = "Go/No-Go Task: Digits"
version_emotional_word = "Go/No-Go Task: Words with Emotional Valence"
version_emotional_face = "Go/No-Go Task: Faces with Emotional Expression"
version_affective_interference = "Go/No-Go Task: Affective Interference"

category_mode = "comparing valence by arousal"
valence_mode = "comparing valence only"
arousal_mode = "comparing arousal only"

default_timeout = 2.0
default_fixation = 0.5
default_practice_feedback = 0.7
default_word_height = 0.10
default_face_duration = 0.300
default_face_folder = Path(__file__).resolve().parent / "Images"
default_interference_timeout = 0.400
default_interference_duration = 0.300
default_interference_fixation = 0.500

default_practice_go = 3
default_practice_nogo = 3
default_official_go = 30
default_official_nogo = 30

default_word_groups = {
    "positive valence / high arousal": ["joyful", "excited", "elated"],
    "positive valence / low arousal": ["calm", "content", "relaxed"],
    "negative valence / high arousal": ["panicked", "outraged", "terrified"],
    "negative valence / low arousal": ["sad", "fatigued", "gloomy"],
    "neutral": ["table", "window", "folder"]
}

word_group_details = {
    "positive valence / high arousal": ("positive", "high"),
    "positive valence / low arousal": ("positive", "low"),
    "negative valence / high arousal": ("negative", "high"),
    "negative valence / low arousal": ("negative", "low"),
    "neutral": ("neutral", "unspecified")
}

# variable names for the output dataset
fieldnames = [
    "participant_ID",                                                    
    "task_version",
    "trial_number",
    "trial_type",
    "grouping_mode",
    "go_group",
    "nogo_group",
    "stimulus_text",
    "word_category",
    "stimulus_image",
    "face_expression",
    "valence",
    "arousal",
    "error",
    "response_time_ms",
    "RealorPractice",
    "HotorColdTrial",
    "Express",
    "block_number",
    "stimulus_colour"
]

# -------------------- Researcher Settings --------------------

# this function shows an error message if an error occurs in the researcher settings without crashing the setup
def settings_error(message):
    researcher_dialog = gui.Dlg(title = "Check Researcher Settings")
    researcher_dialog.addText(message)
    researcher_dialog.show()

# Parse comma-separated stimulus items and reject blanks or duplicates.
# This does not check spelling, whether an item is a real word,
# or whether its emotional category is valid.
def parse_word_list(answer):
    text = str(answer)
    parts = text.split(",")
    words = []
    seen_words = set()

    for part in parts:
        word = part.strip()

        if word == "":
            raise ValueError("Enter at least one word in each list. Separate words with commas, without leaving any blank entries.")
        
        comparison_word = word.casefold()       # .casefold() returns a string where all characters are lower case
        if comparison_word in seen_words:
            raise ValueError("Remove duplicate items within each word list.")

        seen_words.add(comparison_word)
        words.append(word)
    return words

def build_response_groups(word_groups, mode):
    
    if mode == category_mode:
        groups = {
            category: [] for category in word_groups
        }
    elif mode == valence_mode:
        groups = {
            "Positive": [], "Negative": [], "Neutral": []
        }
    elif mode == arousal_mode:
        groups = {
            "High arousal": [], "Low arousal": []
        }
    else:
        raise ValueError("Unknown grouping mode.")

    for category, words in word_groups.items():
        valence, arousal = word_group_details[category]
        if mode == category_mode:
            group = category
        elif mode == valence_mode:
            group = valence.capitalize()        # capitalize() combines high/low arousal words of the same valence.
        else:
            if arousal == "unspecified":
                continue
            group = arousal.capitalize() + " arousal"

        for word in words:
            groups[group].append({
                "stimulus_text": word, "word_category": category,
                "valence": valence, "arousal": arousal
            })
    return groups

def groups_validation(groups, go_group, nogo_group):
    if go_group == nogo_group:
        raise ValueError("Please choose different Go and No-Go groups.")
    
    if go_group not in groups or nogo_group not in groups:
        raise ValueError("Selected groups are unavailable in this mode.")
    
    selected_sets = []
    
    for group in (go_group, nogo_group):
        seen = set()
        
        for item in groups[group]:
            word = item["stimulus_text"].casefold()
            
            if word in seen:
                raise ValueError(
                    "Remove duplicate words in the selected group: " + group
                )
            seen.add(word)

        if not seen:
            raise ValueError("The selected group is empty: " + group)
        
        selected_sets.append(seen)

    go_words, nogo_words = selected_sets

    for word in go_words:
        if word in nogo_words:
           raise ValueError(
               "Selected Go and No-Go groups must not share items."
               )

def researcher_settings():

    count_labels = [
        "Practice Go trials", "Practice No-Go trials",
        "Official Go trials", "Official No-Go trials"
    ]
    count_values = [str(default_practice_go), str(default_practice_nogo),
                    str(default_official_go), str(default_official_nogo)]

    selected_version = version_basic

# Repeat setup after invalid counts; accept only positive integers.
# Successful validation exits this loop with break.
# Cancel exits the entire function with return None.
    while True:
        researcher_dialog = gui.Dlg(title = "Researcher Settings")     # gui.Dlg() creates a dialog box

        researcher_dialog.addField(                                    # .addField() produces input fields in the dialog box for user input
            "Task version", initial = selected_version,
            choices = [version_basic,
                       version_digit,
                       version_emotional_word,
                       version_emotional_face,
                       version_affective_interference
            ]
        )

        for label, value in zip(count_labels, count_values):
            researcher_dialog.addField(label, initial = value)

        answers = researcher_dialog.show()                             # .show() displays the dialog box for the researchers

        if not researcher_dialog.OK:                                   # dialog.OK returns False if the researcher cancels
            return None                                                # in which case it returns None so that the task does not start

        selected_version = answers["Task version"]
        count_values = []
        for label in count_labels:
            count_values.append(
                str(answers[label]).strip()
                )

        # 'try:' here means "execute this code; if an error occurs, let the 'except:' block handle it"
        try:
            counts = []                                                 

            # the following for-loops check whether researchers input (excluding the task version) consists of positive integers
            
            for value in count_values: 
                number = int(value)                                  
                if number < 1:
                    raise ValueError
                counts.append(number)

        except ValueError:
            settings_error("Please enter positive integers in all four trial-count fields.")
            continue

        settings = {
            "task_version": selected_version,
            "practice_go": counts[0],
            "practice_nogo": counts[1],
            "official_go": counts[2],
            "official_nogo": counts[3]
        }
        break

    if selected_version == version_basic:
        settings["block_builder"] = single_block
        return settings

    if selected_version == version_digit:
            return settings_digit(settings)

    if selected_version == version_emotional_word:
        return settings_emotional_word(settings)

    if selected_version == version_emotional_face:
        return settings_emotional_face(settings)

    if selected_version == version_affective_interference:
        return settings_affective_interference(settings)

def settings_digit(settings):
    go_text = "1, 2, 4, 5, 6, 7, 8, 9"
    nogo_text = "3"

    while True:
        researcher_dialog = gui.Dlg(title = version_digit)
        researcher_dialog.addText(
            "Enter single digits separated by commas.\n"
            "Go and No-Go lists must not share digits."
        )
        researcher_dialog.addField("go digits", initial = go_text)
        researcher_dialog.addField("no-go digits", initial = nogo_text)

        answers = researcher_dialog.show()

        if not researcher_dialog.OK:
            return None

        go_text = str(answers["go digits"])
        nogo_text = str(answers["no-go digits"])

        try:

            go_digits = parse_word_list(go_text)
            nogo_digits = parse_word_list(nogo_text)

            allowed_digits = set("0123456789")

            for digit in go_digits + nogo_digits:
                if digit not in allowed_digits:
                    raise ValueError(
                        "Enter only single digits from 0 to 9."
                    )

            if set(go_digits) & set(nogo_digits):
                raise ValueError(
                    "Go and No-Go lists must not share digits."
                )

        except ValueError as error:
            settings_error(str(error))
            continue

        settings["go_digits"] = go_digits
        settings["nogo_digits"] = nogo_digits
        settings["block_builder"] = single_block
        return settings
    
def settings_emotional_word(settings):
        
    mode_dialog = gui.Dlg(title = "Word grouping")

    mode_dialog.addField(
        "Grouping mode",
        initial = category_mode,
        choices = [category_mode, valence_mode, arousal_mode]
    )

    mode_answers = mode_dialog.show()

    if not mode_dialog.OK:
        return None

    selected_mode = mode_answers["Grouping mode"]
    
    categories = list(default_word_groups.keys())
    word_texts = {}
        
    for category in categories:
        word_texts[category] = ", ".join(default_word_groups[category])

    available_groups = build_response_groups(
        default_word_groups, selected_mode
    )
    group_names = list(available_groups.keys())
    
    go_category = group_names[0]
    nogo_category = group_names[1]

    while True:
        researcher_dialog = gui.Dlg(title = version_emotional_word)
        researcher_dialog.addText(
            "Type your own emotional words, or keep the filled-in lists for defaults.\n"
            "Select one category for Go and one different category for No-Go.\n"
            "Only those two categories will be presented"
        )

        for category in categories:
            researcher_dialog.addField(category, initial = word_texts[category])

        researcher_dialog.addField("go_group", initial = go_category, choices = group_names)
        researcher_dialog.addField("nogo_group", initial = nogo_category, choices = group_names)

        answers = researcher_dialog.show()
        if not researcher_dialog.OK:
            return None

        # Retain the researcher's edits so an input error does not
        # reset every list to its defaults on the next attempt.
        for category in categories:
            word_texts[category] = str(answers[category])
        go_category = answers["go_group"]
        nogo_category = answers["nogo_group"]

        try:
            word_groups = {}
            
            for category in categories:
                word_groups[category] = parse_word_list(word_texts[category])

            groups = build_response_groups(
                word_groups, selected_mode
            )

            groups_validation(
                groups, go_category, nogo_category
            )

        except ValueError as error:
            settings_error(str(error))
            continue

        # Save validated lists and mapping, then exit the function.
        # return also exits while True, so no break is needed here.
        settings["grouping_mode"] = selected_mode
        settings["word_groups"] = word_groups
        settings["response_groups"] = groups
        settings["go_category"] = go_category
        settings["nogo_category"] = nogo_category
        settings["block_builder"] = single_block
        return settings

def face_image_files(folder, expression):

    expression_folder = folder /expression

    if not expression_folder.is_dir():
        raise ValueError(
            f"Cannot find the face folder:\n{expression_folder}"
        )

    allowed_extensions = {".jpg", ".jpeg", ".png", ".bmp"}

    files = []
    for path in expression_folder.iterdir():
        if path.is_file():
            if path.suffix.lower() in allowed_extensions:
                files.append(path)
        
    files = sorted(files)

    if not files:
        raise ValueError(
            f"No supported images found in :\n{expression_folder}"
        )
    return files

def settings_emotional_face(settings):

    folder_text = str(default_face_folder)
    go_expression = "Happy"
    nogo_expression = "Fearful"
    expressions = ["Happy", "Fearful"]

    while True:
        dialog = gui.Dlg(title = version_emotional_face)

        dialog.addText(
            "Respond according to facial expression.\n"
            "Images remain visible for 300 ms.\n"
            "Choose different Go and No-Go expressions."
        )
        dialog.addField("Images folder", initial = folder_text)
        dialog.addField(
            "Go expression",
            initial = go_expression,
            choices = expressions
        )
        dialog.addField(
            "No-Go expression",
            initial = nogo_expression,
            choices = expressions
        )

        answers = dialog.show()

        if not dialog.OK:
            return None

        folder_text = str(answers["Images folder"]).strip().strip('"')
        go_expression = answers["Go expression"]
        nogo_expression = answers["No-Go expression"]

        try:
            if not folder_text:
                raise ValueError("Please enter the Images folder path.")

            if go_expression == nogo_expression:
                raise ValueError(
                    "Choose different Go and No-Go expressions"
                )

            folder = Path(folder_text).expanduser().resolve()

            image_files = {}
            for expression in expressions:
                filenames = []

                for path in face_image_files(folder, expression):
                    filenames.append(str(path))

                image_files[expression] = filenames

        except (ValueError, OSError) as error:
            settings_error(str(error))
            continue

        settings["face_folder"] = str(folder)
        settings["face_image_files"] = image_files
        settings["go_expression"] = go_expression
        settings["nogo_expression"] = nogo_expression
        settings["stimulus_duration"] = default_face_duration
        settings["block_builder"] = single_block

        return settings

def settings_affective_interference(settings):
    folder_text = str(default_face_folder)

    if (
        settings["official_go"] < 6
        or settings["official_nogo"] < 6
    ):
        settings_error(
            "Affective interference requires at least six official "
            "GO trials and six official NO-GO trials.\n"
            "Restart setup and increase the session totals."
        )
        return None
    
    while True:
        dialog = gui.Dlg(title = version_affective_interference)

        dialog.addText(
            "Respond to the frame colour, not the facial expression.\n"
            "Six blocks: two Happy, two Fearful, two scrambled.\n"
            "Official trial counts are session totals, "
            "divided across the six blocks.\n"
            "Response window: 400ms. Image display: 300 ms.\n"
            "Requires Happy, Fearful, Scram1 and Scram2 folders."
        )

        dialog.addField(
            "Images folder",
            initial = folder_text
        )

        answers = dialog.show()

        if not dialog.OK:
            return None

        folder_text = str(answers["Images folder"]).strip().strip('"')

        try:
            if not folder_text:
                raise ValueError(
                    "Please enter the Images folder path."
                )

            folder = Path(folder_text).expanduser().resolve()

            image_files = {}

            expressions = ["Happy", "Fearful", "Scram1", "Scram2"]

            for expression in expressions:
                paths = face_image_files(folder, expression)
                filenames = []

                for path in paths:
                    filename = str(path)
                    filenames.append(filename)

                image_files[expression] = filenames

        except (ValueError, OSError) as error:
            settings_error(str(error))
            continue

        settings["task_version"] = version_affective_interference
        settings["face_folder"] = str(folder.resolve())
        settings["image_files"] = image_files

        settings["response_window"] = default_interference_timeout
        settings["stimulus_duration"] = default_interference_duration
        settings["fixation_duration"] = default_interference_fixation

        settings["block_builder"] = interference_blocks

        return settings

random_seed = None


# -------------------- Stimuli --------------------

# define a function that produces an oval shape based on the interface frame, position of the shape on the frame, and the color
def make_oval(window, position, fill_color):
    
    oval_vertices = []                           # Start with an empty list of (x, y) coordinates.
                                                 # The base R equivalent of an empty list is list().

    for i in range(100):                         # create 100 "dots" in total (similar to: 'for i in 1:100' in R)

                                                 # for each individual dot:
        angle = 2 * math.pi * i / 100            # divide a full circle (2 * pi) into 100 steps     

        x = 0.48 * math.cos(angle)               # assign horizontal coordinate 
        y = 0.15 * math.sin(angle)               # assign vertical coordinate              
        oval_vertices.append((x,y))              # append the dot to the oval_vertices list

    return visual.ShapeStim(                     
        window,
        vertices = oval_vertices,
        closeShape = True,                       
        pos = position,
        fillColor = fill_color,
        lineColor = "black",
        lineWidth = 6,
        units = "norm"
    )

# define a function that makes the trial stimuli
def trial_stimuli(window, settings):
    stimuli = {"Go": [], "No-Go": []}

    if settings["task_version"] == version_basic:
        for trial_type, color, label in [
            ("Go", "greenyellow", "GO"),
            ("No-Go", "salmon", "No-Go")
        ]:
            shape = make_oval(window, (0, 0), color)
            text = visual.TextStim(
                window,
                text = label,
                pos = (0, 0),
                height = 0.070,
                color = "black",
                units = "norm"
            )
            stimuli[trial_type].append({
                "objects": [shape, text],
                "stimulus_text": label,
                "word_category": "",
                "valence": "",
                "arousal": ""
            })

    elif settings["task_version"] == version_emotional_word:
        for trial_type, group_name in [
            ("Go",settings["go_category"]),
            ("No-Go", settings["nogo_category"])
        ]:
        
            words = settings["response_groups"][group_name]

            for item in words:
                text = visual.TextStim(
                    window,
                    text = item["stimulus_text"],
                    pos = (0, 0),
                    height = 0.10,
                    wrapWidth = 1.75,
                    color = "white",
                    units = "norm"
                )
                stimuli[trial_type].append({
                    "objects": [text],
                    "stimulus_text": item["stimulus_text"],
                    "word_category": item["word_category"],
                    "valence": item["valence"],
                    "arousal": item["arousal"]
                })

    elif settings["task_version"] == version_digit:

        for trial_type, digits in [
            ("Go", settings["go_digits"]),
            ("No-Go", settings["nogo_digits"])
        ]:
            for digit in digits:
                
                text = visual.TextStim(
                    window,
                    text = digit,
                    pos = (0, 0),
                    height = 0.15,
                    color = "white",
                    units = "norm"
                )

                stimuli[trial_type].append({
                    "objects": [text],
                    "stimulus_text": digit,
                    "word_category": "",
                    "valence": "",
                    "arousal": ""
                })
    elif settings["task_version"] == version_emotional_face:

        for trial_type, expression in [
            ("Go", settings["go_expression"]),
            ("No-Go", settings["nogo_expression"])
        ]:
            for filename in settings["face_image_files"][expression]:

                image = visual.ImageStim(
                    window,
                    image = filename,
                    pos = (0, 0),
                    units = "height"
                )

                aspect_ratio = float(image.size[0] / image.size[1])
                image.size = (0.60 * aspect_ratio, 0.60)

                stimuli[trial_type].append({
                    "objects": [image],
                    "stimulus_text": "",
                    "stimulus_image": Path(filename).name,
                    "face_expression": expression,
                    "word_category": "",
                    "valence": "",
                    "arousal": ""
                })
    elif settings["task_version"] == version_affective_interference:

        stimuli["interference_list"] = {}

        for expression in ["Happy", "Fearful", "Scram1", "Scram2"]:

            colour_list = {
                "blue": [],
                "yellow": []
            }

            if expression == "Happy":
                express_label = "Happy"
                condition_label = "Affective interference"
            elif expression == "Fearful":
                express_label = "Fear"
                condition_label = "Affective interference"
            else:
                express_label = "Neutral"
                condition_label = "Control condition"

            for filename in settings["image_files"][expression]:

                image = visual.ImageStim(
                    window,
                    image = filename,
                    pos = (0, 0),
                    units = "height"
                )

                aspect_ratio = float(image.size[0] / image.size[1])
                image.size = (0.60 * aspect_ratio, 0.60)

                for colour in ["blue", "yellow"]:

                    frame = visual.Rect(
                        window,
                        width = float(image.size[0] + 0.04),
                        height = float(image.size[1] + 0.04),
                        pos = (0, 0),
                        fillColor = colour,
                        lineColor = colour,
                        units = "height"
                    )

                    colour_list[colour].append({
                        "objects": [frame, image],
                        "stimulus_text": "",
                        "stimulus_image": Path(filename).name,
                        "face_expression": expression,
                        "stimulus_colour": colour,
                        "HotorColdTrial": condition_label,
                        "Express": express_label,
                        "word_category": "",
                        "valence": "",
                        "arousal": ""
                    })

            stimuli["interference_list"][expression] = colour_list
    else:
        raise ValueError("Unknown task version.")

    return stimuli

def single_block(settings, stimuli):
    return [{
        "block_number": 1,
        "stimuli": stimuli,
        "instruction_text": "",
        "metadata": {
            "grouping_mode": settings.get("grouping_mode", ""),
            "go_group": settings.get("go_category", ""),
            "nogo_group": settings.get("nogo_category", "")
        }
    }]

def interference_blocks(settings, stimuli):
    lists = stimuli["interference_list"]

    conditions = settings.get(
        "interference_conditions",
        ["Happy", "Fearful", "Neutral"]
    )

    colour_rules = settings.get(
        "interference_colour_rules",
        [
            ("blue", "yellow"),
            ("yellow", "blue")
        ]
    )

    blocks = []

    for condition in conditions:

        if condition == "Neutral":
            expressions = ["Scram1", "Scram2"]
            condition_label = "Control condition"
            express_label = "Neutral"
        elif condition in ("Happy", "Fearful"):
            expressions = [condition]
            condition_label = "Affective interference"
            express_label = "Happy" if condition == "Happy" else "Fear"
        else:
            raise ValueError(
                f"Unknown interference condition: {condition}"
            )

        for go_colour, nogo_colour in colour_rules:

            if(
                go_colour not in ("blue", "yellow")
                or nogo_colour not in ("blue", "yellow")
                or go_colour == nogo_colour
            ):
                raise ValueError(
                    "Go and No-Go must use different colours: "
                    "blue and yellow."
                )

            block_stimuli = {
                "Go": [],
                "No-Go": []
            }

            for expression in expressions:
                block_stimuli["Go"].extend(
                    lists[expression][go_colour]
                )

                block_stimuli["No-Go"].extend(
                    lists[expression][nogo_colour]
                )

            if not block_stimuli["Go"] or not block_stimuli["No-Go"]:
                raise ValueError(
                    f"No usable images for condition: {condition}"
                )

            blocks.append({
                "block_number": len(blocks) + 1,
                "HotorColdTrial": condition_label,
                "Express": express_label,
                "go_group": go_colour,
                "nogo_group": nogo_colour,
                "stimuli": block_stimuli,
                "instruction_text": (
                    f"Block {len(blocks) + 1}\n\n"
                    f"GO colour: {go_colour}.\n"
                    f"NO-GO colour: {nogo_colour}.\n\n"
                    "Respond to the frame colour, not the image.\n"
                    "Press SPACE for GO. Do not press for NO-GO."
                ),
                "metadata": {
                    "go_group": go_colour,
                    "nogo_group": nogo_colour,
                    "HotorColdTrial": condition_label,
                    "Express": express_label
                }
            })

    return blocks

def prepare_blocks(settings, stimuli):
    blocks = settings["block_builder"](settings, stimuli)
    number_of_blocks = len(blocks)

    if number_of_blocks == 0:
        raise ValueError("At least one block is required.")

    if (
        settings["official_go"] < number_of_blocks
        or settings["official_nogo"] < number_of_blocks
    ):
        settings_error(
            f"This plan has {number_of_blocks} blocks.\n"
            f"Enter at least {number_of_blocks} official GO trials "
            f"and {number_of_blocks} official NO-GO trials.\n"
            "The entered counts are session totals."
        )
        return None

    go_base, go_extra = divmod(
        settings["official_go"], number_of_blocks
    )
    nogo_base, nogo_extra = divmod(
        settings["official_nogo"], number_of_blocks
    )

    for index, block in enumerate(blocks):
        block["official_go"] = go_base + int(index < go_extra)
        block["official_nogo"] = nogo_base + int(index < nogo_extra)

    return blocks

# -------------------- Keyboard and User Interface --------------------

# define a function that checks whether the participant exits the task
def check_exit(kb):
    if kb.getKeys(
        keyList = ["escape"],
        waitRelease = False,
        clear = True):
        raise SystemExit("Participant exited with esc.")

# define a function that displays a message and pauses the task until the participant presses SPACE
def wait_screen(window, kb, text):
    message = visual.TextStim(
        window,
        text = text + "\n\nPress SPACE to continue.",
        height = 0.065,
        wrapWidth = 1.75,
        color = "white",
        units = "norm"
    )
    message.draw()
    window.callOnFlip(kb.clearEvents)
    window.flip()

    while True:
        keys = kb.getKeys(
                keyList = ["space", "escape"],
                waitRelease = False,
                clear = True
            )

        space_pressed = False
            
        for key in keys:
            if key.name == "escape":
                raise SystemExit("Participant exited with esc")
            if key.name == "space":
                space_pressed = True
        if space_pressed:
            break
    
        message.draw()
        window.flip()
            
    window.flip()

# define a function that shows the instruction
def instructions_basic(window, kb):
    
    # the panel on which the instruction as a whole will be presented
    panel = visual.Rect(
        window,
        width = 1.85,
        height = 1.85,
        fillColor = "white",
        lineColor = "white",
        units = "norm"
    )

    # go instruction (message, go button label & shape)
    go_instruction = visual.TextStim(
        window,
        text = "In the following trials, press only the SPACE bar if you see the following message:",
        pos = (0, 0.65),
        height = 0.065,
        wrapWidth = 1.70,
        color = "black",
        units = "norm"
    )
    go_shape = make_oval(window, (0, 0.34), "greenyellow")
    go_label = visual.TextStim(
        window,
        text = "GO",
        pos = (0, 0.34),
        height = 0.070,
        color = "black",
        units = "norm"
    )
    
    # nogo instruction (message, go button label & shape)
    nogo_instruction = visual.TextStim(
        window,
        text = "Do nothing if you see the following message:",
        pos = (0, 0.04),
        height = 0.065,
        wrapWidth = 1.70,
        color = "black",
        units = "norm"
        )
    nogo_shape = make_oval(window, (0, -0.23), "salmon")
    nogo_label = visual.TextStim(
        window,
        text = "NO-GO",
        pos = (0, -0.23),
        height = 0.070,
        color = "black",
        units = "norm"
        )

    # footer (message)
    footer = visual.TextStim(
        window,
        text = "Press SPACE to continue. \nYou may stop at any time by pressing esc.",
        pos = (0, -0.65),
        height = 0.055,
        wrapWidth = 1.75,
        color = "black",
        units = "norm"
    )

    # put everything together in order in a list
    screen_objects = [
        panel, 
        go_instruction, go_shape, go_label,
        nogo_instruction, nogo_shape, nogo_label,
        footer 
    ]
    for object in screen_objects:
        object.draw()
    window.callOnFlip(kb.clearEvents)
    window.flip()

    while True:
        keys = kb.getKeys(
            keyList = ["space", "escape"],
            waitRelease = False,
            clear = True
        )
    
        space_pressed = False
                
        for key in keys:
            if key.name == "escape":
                raise SystemExit("Participant exited with esc")
            if key.name == "space":
                space_pressed = True
        if space_pressed:
            break

        for object in screen_objects:
            object.draw()
        window.flip()         
    window.flip()

    wait_screen(
        window,
        kb,
        "You will first complete some practice trials.\n"
    )

def instructions_digit(window, kb, settings):

    go_digits = ", ".join(settings["go_digits"])
    nogo_digits = ", ".join(settings["nogo_digits"])

    wait_screen(
        window,
        kb,
        "Go/No-Go Task: Single-Digit Numbers\n\n"
        "Press SPACE as quickly and accurately as possible for:\n"
        + go_digits
        + "\n\nDo NOT press SPACE for:\n"
        + nogo_digits
        + "\n\nYou may stop at any time by pressing esc."
    )

    wait_screen(
        window,
        kb,
        "You will first complete some practice trials."
    )

def instructions_emotional_word(window, kb, settings):

    go_category = settings["go_category"]
    nogo_category = settings["nogo_category"]

    go_word_list = [
        item["stimulus_text"]
        for item in settings["response_groups"][go_category]
    ]
    nogo_word_list = [
        item["stimulus_text"]
        for item in settings["response_groups"][nogo_category]
    ]

    go_words = ", ".join(go_word_list)
    nogo_words = ", ".join(nogo_word_list)

    wait_screen(
        window,
        kb,
        "Go/No-Go Task: Emotional Words\n\n"
        "Press SPACE as quickly and accurately as possible for:\n"
        + go_category
        + "\n"
        + go_words
        + "\n\nDo NOT press Space for:\n"
        + nogo_category
        + "\n"
        + nogo_words
        + "\n\nYou may stop at any time by pressing esc."
    )

    wait_screen(
        window,
        kb,
        "You will first complete some practice trials."
    )

def instructions_emotional_face(window, kb, settings):

    wait_screen(
        window,
        kb,
        f"Press SPACE for {settings['go_expression'].lower()} faces.\n\n"
        f"Do NOT press SPACE for "
        f"{settings['nogo_expression'].lower()} faces.\n\n"
        "Respond as quickly and accurately as possible.\n"
        "Each face appears briefly. You can still respond "
        "after it disappears, before the next trial.\n\n"
        "You may stop at any time by pressing esc."
    )

    wait_screen(
        window,
        kb,
        "You will first complete some practice trials."
    )

def instructions_affective_interference(window, kb, settings):
    colour_rules = settings.get(
        "interference_colour_rules",
        [
            ("blue", "yellow"),
            ("yellow", "blue")
        ]
    )

    practice_go_colour, practice_nogo_colour = colour_rules[0]

    wait_screen(
        window,
        kb,
        "Please respond to the frame colour as quickly and accurately as you can.\n\n"
        f"Practice GO colour: {practice_go_colour}.\n"
        f"Practice NO-GO colour: {practice_nogo_colour}.\n\n"
        "Press SPACE for GO.\n"
        "Do not press for NO-GO.\n\n"
        "The colour rule can change between official blocks.\n"
        "Read the instructions before each block."
    )


def instructions(window, kb, settings):
    if settings["task_version"] == version_basic:
        instructions_basic(window, kb)
    elif settings["task_version"] == version_emotional_word:
        instructions_emotional_word(window, kb, settings)
    elif settings["task_version"] == version_digit:
        instructions_digit(window, kb, settings)
    elif settings["task_version"] == version_emotional_face:
        instructions_emotional_face(window, kb, settings)
    elif settings["task_version"] == version_affective_interference:
        instructions_affective_interference(window, kb, settings)


def intermission(window, kb, stimulus, duration):
    clock = core.Clock()
    stimulus.draw()
    window.callOnFlip(clock.reset)
    window.flip()

    while clock.getTime() < duration:
        check_exit(kb)
        stimulus.draw()
        window.flip()
    window.flip()

# -------------------- Trial Sequence --------------------

# define a function that randomizes the trial orders
def trial_order(n_go, n_nogo, random_generator):
    order = ["Go"] * n_go + ["No-Go"] * n_nogo
    random_generator.shuffle(order)
    return order

# define a function that runs the trial
def trial(window, kb, stimuli, trial_type, trial_number, timeout, 
          random_generator, task_version, stimulus_duration = None):

    # input validation
    if trial_type not in ("Go", "No-Go"):
        raise ValueError("trial_type must be 'Go' or 'No-Go'.")
    if timeout <= 0:
        raise ValueError("timeout must be positive")
    if stimulus_duration is not None:
        if not 0 < stimulus_duration <= timeout:
            raise ValueError(
                "Stimulus duration must be positive and no longer "
                "than the response window."
            )

    # stimulus setup
    # Retrieve the prebuilt pool for this trial's response type.
    # Each entry contains drawable objects plus descriptive metadata.
    # Random selection is with replacement; per-word totals are not fixed.
    stimulus_list = stimuli[trial_type]
    if len(stimulus_list) == 1:
        selected_stimulus = stimulus_list[0]
    else:
        selected_stimulus = random_generator.choice(stimulus_list)

    # prepare the stimulus off-screen
    def draw_stimulus():
        for stimulus_object in selected_stimulus["objects"]:
            stimulus_object.draw()
    # Basic stimuli contain a shape and label; word stimuli contain text.
    # Draw every object belonging to the selected stimulus.
    draw_stimulus()

    # Clear old key events and reset the RT clock on the stimulus-onset flip.
    # Responses are therefore timed relative to this trial's presentation.
    window.callOnFlip(kb.clearEvents)                
    window.callOnFlip(kb.clock.reset)                
    window.flip()                                    

    # set up response collection
    response = None
    response_time_ms = None

    # this loop checks the participant's response
    while True:
        # retrieve selected key presses from the keyboard object (defined later in run_task())
        keys = kb.getKeys(                           
            keyList = ["space", "escape"],           
            waitRelease = False,                     # return a detected press without waiting for release
            clear = True                             # remove returned events so they are not counted again
        )
        # terminate the task if esc is pressed
        for key in keys:
            if key.name == "escape":
                raise SystemExit("Participant exited with esc")

        # Accept presses timestamped from onset up to, but not including,
        # the response deadline. Ignore pre-onset and late presses.
        space_keys = []
        for key in keys:
            if (
                key.name == "space" 
                and key.rt is not None 
                and 0 <= key.rt < timeout
            ):
                space_keys.append(key)

        # register the response and (earliest) response time if there is any space key press in the space_keys list
        if response is None and space_keys:
            def press_rt(key):
                return key.rt
            
            # Several presses can arrive in one polling batch.
            # Record the earliest valid SPACE press, not an arbitrary list entry.
            first_press = min(space_keys, 
                              key = press_rt)                             
            response = "space"                                                
            response_time_ms = round(float(first_press.rt) * 1000, 2)    
            if stimulus_duration is None:
                break

        # break the loop when time is out
        if kb.clock.getTime() >= timeout:
            break

        if(
            stimulus_duration is None
            or kb.clock.getTime() < stimulus_duration
        ): 
            draw_stimulus()
        
        window.flip()

    window.flip()

    # record error
    if trial_type == "Go":
        error = int(response is None)
    else:
        error = int(response is not None)

    # collect the results
    return{
        "task_version": task_version,
        "trial_number": trial_number,
        "trial_type": trial_type,
        "stimulus_text": selected_stimulus["stimulus_text"],
        "word_category": selected_stimulus["word_category"],
        "stimulus_image": selected_stimulus.get("stimulus_image", ""),
        "valence": selected_stimulus["valence"],
        "arousal": selected_stimulus["arousal"],
        "face_expression": selected_stimulus.get("face_expression", ""),
        "stimulus_colour": selected_stimulus.get("stimulus_colour", ""),
        "HotorColdTrial": selected_stimulus.get("HotorColdTrial", ""),
        "Express": selected_stimulus.get("Express", ""),
        "error": error,
        "response_time_ms": response_time_ms,
    }

# -------------------- Data Output --------------------

# define a function that creates a data subfolder
def output_path():
    folder = Path(__file__).resolve().parent / "data"
    folder.mkdir(parents = True, exist_ok = True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    return folder / f"Go_NoGo_task_data_{timestamp}.csv"

# define a function that saves the data into a csv file
def data_output(writer, file, trial_result):
    row = trial_result.copy()
    rt = row["response_time_ms"]

    # Write missing RTs as blank cells and measured RTs to two decimal places.
    if rt is None:
        row["response_time_ms"] = ""
    else:
        row["response_time_ms"] = f"{rt:.2f}"

    writer.writerow(row)
    file.flush()     # Flush each row to reduce buffering-related loss after an interruption.

# -------------------- Full Task --------------------
def run_task(settings):

    response_window = settings.get(
        "response_window",
        default_timeout
    )

    fixation_duration = settings.get(
        "fixation_duration",
        default_fixation
    )

    # create a random number generator to shuffle trial order
    random_generator = random.Random(random_seed)

    # retrieve the trial counts from the dictionary in researcher_settings()
    practice_order = trial_order(settings["practice_go"],
                                 settings["practice_nogo"], 
                                 random_generator)
    
    window = visual.Window(
        fullscr = False,
        size = (1000, 700),
        screen = 0,
        color = "black",
        units = "norm",
        allowGUI = False
    )

    try:
        
        kb = keyboard.Keyboard()                    
        event.Mouse(win = window).setVisible(False)
        stimuli = trial_stimuli(window, settings)
    
        blocks = prepare_blocks(settings, stimuli)

        if blocks is None:
            return
            
        practice_block = blocks[0]

        fixation = visual.TextStim(
            window,
            text = "+",
            height = 0.08,
            color = "white"
        )
        feedback = visual.TextStim(
            window,
            height = 0.07,
            wrapWidth = 1.75,
            color = "black"
        )

        instructions(window, kb, settings)

        # Practice trials
        for number, trial_type in enumerate(practice_order, start = 1):
            intermission(window, kb, fixation, fixation_duration)
            practice_result = trial(
                window, kb, practice_block["stimuli"],
                trial_type, number, response_window,
                random_generator, settings["task_version"],
                stimulus_duration = settings.get("stimulus_duration")
            )
            practice_result["RealorPractice"] = "Practice"
            if practice_result["error"] == 0:
                feedback.text = "Correct"
                feedback.color = "greenyellow"
            else:
                if trial_type == "Go":
                    feedback.text = "Go - press the SPACE bar"
                else:
                    feedback.text = "No-Go: do not do anything"
                feedback.color = "salmon"
            intermission(
                window, kb, feedback, default_practice_feedback
            )

        wait_screen(
            window,
            kb,
            "Practice trials are now completed.\n\n"
            "You are now ready for the official trials."
        )

        # Official trials
        path = output_path()
        print("data output location:", path)
        completed = 0

        with path.open("x",
                       newline = "",
                       encoding = "utf-8") as file:
            writer = csv.DictWriter(file, fieldnames = fieldnames)
            writer.writeheader()
            file.flush()

            for block in blocks:
                if block["instruction_text"]:
                    wait_screen(window, kb, block["instruction_text"])

                official_order = trial_order(
                    block["official_go"],
                    block["official_nogo"],
                    random_generator
                )

                for trial_type in official_order:
                    intermission(
                        window, kb, fixation, fixation_duration
                    )

                    trial_result = trial(
                        window, kb, block["stimuli"], trial_type,
                        completed + 1, response_window,
                        random_generator, settings["task_version"],
                        stimulus_duration = settings.get("stimulus_duration")
                    )

                    trial_result["participant_ID"] = settings["participant_ID"]
                    trial_result["RealorPractice"] = "RealTask"
                    trial_result["block_number"] = block["block_number"]
                    trial_result.update(block["metadata"])

                    data_output(writer, file, trial_result)
                    completed += 1

        print(f"Saved the data at: {path}")
        wait_screen(window, kb, "The task is complete. We really appreciate your participation.")
            
    finally:
        window.close()

def continue_collection():
    researcher_dialog_2 = gui.Dlg(title = "Data Collection")
    researcher_dialog_2.addText("The participant's session has ended.")
    researcher_dialog_2.addText(
        "Click OK for the next participant.\n"
        "Click Cancel to finish data collection."
    )
    researcher_dialog_2.show()

    return researcher_dialog_2.OK

if __name__ == "__main__":
    settings = researcher_settings()

    if settings is not None:
        while True:
            dialog = gui.Dlg(title = "Participant")
            dialog.addField("Participant ID", initial = "")
            answers = dialog.show()

            if not dialog.OK:
                break

            participant_id = str(answers["Participant ID"]).strip()

            if not participant_id:
                print("Participant ID cannot be blank.")
                continue

            settings["participant_ID"] = participant_id
            run_task(settings)

            if not continue_collection():
                break