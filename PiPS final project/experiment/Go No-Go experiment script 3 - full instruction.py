
# This script includes the instruction part of the Go/No-Go task

import math
from psychopy import visual, event, core

# define a function that produces an oval shape
def make_oval(window, position, fill_color):
    
    oval_vertices = []                           # start from an empty list
    for i in range(100):                         # create 100 "dots" in total
                                                 # for each unique dot:
        angle = 2 * math.pi * i / 100            # divide a full circle (2 * pi) into 100 steps
                                                 # & assign:
        x = 0.48 * math.cos(angle)               # Horizontal coordinate
        y = 0.15 * math.sin(angle)               # Vertical coordinate
                            
        oval_vertices.append((x,y))              # append the dot to the oval_vertices list

    return visual.ShapeStim(                     # form a shape based on the oval_vertices list
        window,
        vertices = oval_vertices,
        closeShape = True,                       # connect the last dot to the first dot
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
        text = "In the following trials, press only the SPACE bar if you seeing the following message:",
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
        text = "Do nothing if you seeing the following message:",
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

def testing(window):

    message = visual.TextStim(
        window,
        text = "Start clicked successfully...\n\nPress esc to exit.",
        height = 0.075,
        wrapWidth = 1.70,
        color = "white",
        units = "norm"
    )

    clock = core.Clock()
    while clock.getTime() < 2.0:
        message.draw()
        window.flip()
        if "escape" in event.getKeys(keyList = ["escape"]):
            core.quit()

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
        event.globalKeys.add(
            key = "escape", 
            func = core.quit
        )
        instructions(window)
        testing(window)
    finally:
        window.close()
        event.globalKeys.remove(key = "escape")

if __name__ == "__main__":
    run_task()