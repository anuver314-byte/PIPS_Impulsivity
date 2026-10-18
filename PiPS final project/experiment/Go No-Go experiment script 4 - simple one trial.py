
# This script includes both instruction and a single Go/No-Go trial for testing. 

import csv
import math
import random

from pathlib import Path
from psychopy import visual, event, core
from psychopy.hardware import keyboard

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

# define a function that shows the instruction
def instructions(window):
    
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

    # start button (shape, label)
    start_button = visual.Rect(
        window,
        width = 0.65,
        height = 0.19,
        pos = (0, -0.58),
        fillColor = "darkgreen",
        lineColor = "black",
        units = "norm"
        )
    start_label = visual.TextStim(
        window,
        text = "Start",
        pos = (0, -0.58),
        height = 0.075,
        color = "white",
        units = "norm"
        )

    # exit message
    exit_message = visual.TextStim(
        window,
        text = "You may stop at any time by pressing esc.",
        pos = (0, -0.81),
        height = 0.050,
        wrapWidth = 1.70,
        color = "black",
        units = "norm"
    )

    # put everything together in order in a list
    screen_objects = [
        panel, 
        go_instruction, go_shape, go_label,
        nogo_instruction, nogo_shape, nogo_label,
        start_button, start_label, exit_message 
    ]

    # track participants' cursor movement
    mouse = event.Mouse(win = window)                     # create a mouse object 
    mouse.setVisible(True)                                # make the cursor visible for the participant
    event.clearEvents(eventType = "keyboard")             # clear all keyboard presses before the trial begins
    
    previous_left_press = bool(                           # return True if left button of the mouse gets pressed *accidentally
        mouse.getPressed()[0]                              
        )

    # this loop shows the instruction until the participant clicks "Start" or exits the task
    while True:
        for screen_object in screen_objects:
            screen_object.draw()                          # prepare all objects in the list off-screen
        window.flip()                                     # present all objects in order on-screen

        if "escape" in event.getKeys(keyList = ["escape"]):
            core.quit()                                   # quit the task if "esc" is cilcked

        left_press = bool(                                # return True if left button of the mouse gets pressed
            mouse.getPressed()[0]
            )
                                                          # break the loop only when the left mouse is clicked and the cursor is in the start button
        new_left_press = left_press and not previous_left_press
        if new_left_press and mouse.isPressedIn(start_button, buttons = [0]):
            break
        previous_left_press = left_press

    # this loop continues while the left button of the mouse is down and stops when it is no longer down
    while mouse.getPressed()[0]:
        for screen_object in screen_objects:
            screen_object.draw()
        window.flip()
        if "escape" in event.getKeys(keyList = ["escape"]):
            core.quit()

    mouse.setVisible(False)                         # make the cursor invisible
    event.clearEvents(eventType = "keyboard")       # clear all keyboard presses

# define a function that runs the first trial
def trial(window, kb, trial_type = "Go", timeout = 2.0, trial_number = 1):

    # input validation
    if trial_type not in ("Go", "No-Go"):
        raise ValueError("trial_type must be 'Go' or 'No-Go'.")
    if timeout <= 0:
        raise ValueError("timeout must be positive")

    # stimulus setup
    go = trial_type == "Go"
    stimulus_shape = make_oval(window, (0, 0), 
                      "greenyellow" if go else "salmon")
    stimulus_label = visual.TextStim(
        window,
        text = "GO" if go else "NO-GO",
        pos = (0, 0),
        height = 0.070,
        color = "black",
        units = "norm"
    )

    # prepare the stimulus off-screen
    def draw_stimulus():
        stimulus_shape.draw()
        stimulus_label.draw()
    draw_stimulus()

    # present the stimulus and execute the scheduled functions
    window.callOnFlip(kb.clearEvents)                # schedule to clear old keyboard presses
    window.callOnFlip(kb.clock.reset)                # schedule to reset the response clock
    window.flip()                                    

    # set up response collection
    response = None
    response_time_ms = None

    # this loop checks the participant's response
    while True:
        # retrieve selected key presses from the keyboard object (defined later in run_task())
        keys = kb.getKeys(                           
            keyList = ["space", "escape"],           # retrieve specifically "space" and "escape"
            waitRelease = False,                     # detect a key as soon as it is pressed without waiting for release
            clear = True                             # removes the retrieved event so that it is handled only once
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
                              key = press_rt)                            # select the earliest space key press 
            response = "space"                                                
            response_time_ms = round(float(first_press.rt) * 1000, 2)    # converts a value into a number
            break

        # break the loop when time is out
        if kb.clock.getTime() >= timeout:
            break

        draw_stimulus()
        window.flip()

    window.flip()

    # record error
    if go:
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

# define a function that saves the results into a csv file
def save_result(result, filename = "practice_trial.csv"):
    
    # create an object representing the file’s location & converts it into an absolute path
    path = Path(filename).resolve()                                    
    
    with path.open("w",                                                # create the file or overwrites it if it already exists  
                   newline = "",                                       # let the CSV module handle line endings correctly, avoiding extra blank lines on Windows
                   encoding = "utf-8") as file:                        # UTF-8 is a widely supported text encoding that handles ordinary letters and other symbols.
                                                                       # "as file" call the opened file object file
        # create a dictionary-based CSV writer                                                               
        writer = csv.DictWriter(file,                                  
                                fieldnames = list(result.keys())       # extract the dictionary’s keys as a list to set the column names and their order
                                )
        writer.writeheader()                                           # write the column names
        writer.writerow(result)                                        # write the dictionary’s values into the corresponding columns
                                                                       # "with" automatically close the file when this indented block ends
    return path

def run_task():
    
    window = visual.Window(
        fullscr = False,
        size = (1000, 700),
        screen = 0,
        color = "black",
        units = "norm",
        allowGUI = False
    )

    try:
        instructions(window)

        kb = keyboard.Keyboard()                    # creates a keyboard object to check key presses
        clock = core.Clock()
        while clock.getTime() < 0.5:
            if kb.getKeys(keyList = ["escape"],
                          waitRelease = False):
                raise SystemExit("Participant exited with esc,")
            window.flip()

        trial_type = random.choice(["Go", "No-Go"])
        trial_result = trial(
            window, 
            kb, 
            trial_type = trial_type, 
            timeout = 2.0,
            trial_number = 1
            )
        saved_path = save_result(trial_result)
        print("Trial result:", trial_result)
        print("Saved to:", saved_path)
    finally:
        window.close()
       
if __name__ == "__main__":
    run_task()