
# 

from psychopy import visual, event, core

# visual.Window() creates the frame for the user interface
window = visual.Window(
    size = (800, 600),
    fullscr = True,
    color = "black",
)

try:
    # visual.TextStim() creates text stimuli (in this case instructions)
    instructions = visual.TextStim(
        window,
        text = (
            "Go / No-Go Task\n\n"
            "In the following trials, press the SPACE bar only if you seeing the following message:\n"
            "Do nothing if you see the following message:\n\n"
            "Click Start when you are ready.\n"
            "Click Exit if you do not want to proceed."
        ),
        pos = (0, 0.2),     # horizontol position first, vertical second
        height = 0.05,      # text height
        wrapWidth = 1.5,    # width available before long lines wrap
        units = "norm"      # use coordinates relative to the window
    )

    # visual.Rect() creates a rectangle shape (for the start button)
    start_button = visual.Rect(
        window,
        width = 0.4,
        height = 0.18,
        pos = (0, -0.4),
        fillColor = "darkgreen",
        lineColor = "white",
        units = "norm"
    )

    # creates a label for the start button
    start_label = visual.TextStim(
        window,
        text = "Start",
        pos = (0, -0.4),
        height = 0.06,
        color = "white",
        units = "norm"
    )

    # event.Mouse() creates an object that checks mouse position and button presses in the window
    mouse = event.Mouse(win = window)     # "win = " is an argument for event.Mouse() that locates the frame for the mouse object
    mouse.setVisible(True)                # shows the cursor

    # this while loop presents the instructions and the start button 
    # (until the user clicks the start button or exits the task
    while True:
        instructions.draw()       # prepares the instructions off-screen
        start_button.draw()       # prepares the start_button shape off-screen
        start_label.draw()        # prepares the start_button label off-screen
        window.flip()             # presents everything prepared on the window

        if mouse.isPressedIn(start_button, buttons = [0]):
            break                 # checks if the cursor is in the start_button shape
                                  # checks if the left mouse button is currently pressed
                                  # returns True if those two conditions are met
        if "escape" in event.getKeys(keyList = ["escape"]):
            core.quit()           # event.getKeys() returns detected "escape" clicks (on the keyboard)
                                  # core.quit() terminates the experiment

    # the start-screen loop above can detect the press before the participant has released the button,
    # so this while loop tells the program to wait until the participant has released the button
    while mouse.getPressed()[0]:
        core.wait(0.01)           # .getPressed() returns the states of the mouse

    mouse.setVisible(False)                        # hide the cursor so it doesn't distract participants during the task
    event.clearEvents(eventType = "keyboard")      # clear earlier keyboard presses so they don't become trial responses

    confirmation = visual.TextStim(
        window,
        text = "Start clicked successfully!",
        height = 0.06,
        units = "norm"
        )

    confirmation.draw()
    window.flip()
    core.wait(2)     
finally:
    window.close()