
# This script demonstrates a basic version of Go/No-Go task, 
# including: instructions, practice trials, official trials.
# including: two non-emotinoal stimuli, one for Go and the other for No-Go

import csv
import math
import random

from datetime import datetime
from pathlib import Path

from psychopy import visual, event, core
from psychopy.hardware import keyboard

# Settings

timeout_seconds = 2.0
fixation_seconds = 0.5
practice_feedback_seconds = 0.7

practice_go = 3
practice_nogo = 3
official_go = 30
official_nogo = 30

random_seed = None

fieldnames = [
    "trial_number",
    "trial_type",
    "error",
    "response_time_ms"
]

# -------------------- Stimuli --------------------

# define a function that produces an oval shape
def make_oval(window, position, fill_color):
    
    oval_vertices = []                           
    for i in range(100):                                                               
        angle = 2 * math.pi * i / 100                                              
        x = 0.48 * math.cos(angle)               
        y = 0.15 * math.sin(angle)                             
        oval_vertices.append((x,y))              

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
def trial_stimuli(window):
    stimuli = {}
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
        stimuli[trial_type] = (shape, text)
    return stimuli

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
def instructions(window, kb):
    
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
def trial(window, kb, stimuli, trial_type, trial_number, timeout):

    # input validation
    if trial_type not in ("Go", "No-Go"):
        raise ValueError("trial_type must be 'Go' or 'No-Go'.")
    if timeout <= 0:
        raise ValueError("timeout must be positive")

    # stimulus setup
    stimulus_shape, stimulus_label = stimuli[trial_type]

    # prepare the stimulus off-screen
    def draw_stimulus():
        stimulus_shape.draw()
        stimulus_label.draw()
    draw_stimulus()

    # present the stimulus and execute the scheduled functions
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
            waitRelease = False,                     
            clear = True                             
        )
        # terminate the task if esc is pressed
        for key in keys:
            if key.name == "escape":
                raise SystemExit("Participant exited with esc")

        # create a list for any space key press
        space_keys = []
        for key in keys:
            if (
                key.name == "space" 
                and key.rt is not None 
                and 0 <= key.rt < timeout
            ):
                space_keys.append(key)

        # register the response and (earliest) response time if there is any space key press in the space_keys list
        if space_keys:
            def press_rt(key):
                return key.rt
            first_press = min(space_keys, 
                              key = press_rt)                             
            response = "space"                                                
            response_time_ms = round(float(first_press.rt) * 1000, 2)    
            break

        # break the loop when time is out
        if kb.clock.getTime() >= timeout:
            break

        draw_stimulus()
        window.flip()

    window.flip()

    # record error
    if trial_type == "Go":
        error = int(response is None)
    else:
        error = int(response is not None)
        if response is None:
            response_time_ms = round(float(timeout) * 1000, 2)

    # collect the results
    return{
        "trial_number": trial_number,
        "trial_type": trial_type,
        "error": error,
        "response_time_ms": response_time_ms,
    }

# -------------------- Data Output --------------------

# define a function that creates a data subfolder
def output_path():
    folder = Path(__file__).resolve().parent / "data"
    folder.mkdir(parents = True, exist_ok = True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    return folder / f"Go_NoGo_task_data_{timestamp}.csv"

# define a function that saves the data into a csv file
def data_output(writer, file, trial_result):
    row = trial_result.copy()
    rt = row["response_time_ms"]
    if rt is None:
        row["response_time_ms"] = ""
    else:
        row["response_time_ms"] = f"{rt:.2f}"
    writer.writerow(row)
    file.flush()

# -------------------- Full Task --------------------
def run_task():

    random_generator = random.Random(random_seed)
    practice_order = trial_order(practice_go, practice_nogo, random_generator)
    official_order = trial_order(official_go, official_nogo, random_generator)
    
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
        stimuli = trial_stimuli(window)
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

        instructions(window, kb)

        # Practice trials
        for number, trial_type in enumerate(practice_order, start = 1):
            intermission(window, kb, fixation, fixation_seconds)
            practice_result = trial(
                window, kb, stimuli, trial_type, number, timeout_seconds
            )
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
                window, kb, feedback, practice_feedback_seconds
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

            for number, trial_type in enumerate(official_order, start = 1):
                intermission(window, kb, fixation, fixation_seconds)
                trial_result = trial(
                    window, kb, stimuli, trial_type, number, timeout_seconds
                )
                data_output(writer, file, trial_result)
                completed += 1

        print(f"Saved the data at: {path}")
        wait_screen(window, kb, "The task is complete. We really appreciate your participation.")
            
    finally:
        window.close()
       
if __name__ == "__main__":
    run_task()