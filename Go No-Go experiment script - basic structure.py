
# This script includes a simple structure that (hopefully) demonstrates how Python is used to create a user interface
# The Go/No-Go task will likely be based on this structure, albeit more complicated

# PsychoPy is a Python package for psychological experiment setups
# visual is a module from PsychoPy that is used for windows and visual stimuli
# core is a module from PsychoPy that is used for timing/waiting

from psychopy import visual, core

# visual.Window() is a function from the visual module that creates a window object, here including:
# size (window size), fullscr (full-screen), and color

window = visual.Window(
    size = (800, 600),
    fullscr = False,
    color = "black",
)

# "try:" attempts to execute the code under try:
# when paired with "finally:", the window will be closed even if an error occurs when executing the code under try:
# visual.TextStim() is a function from the visual module that creates a text stimulation object, here including:
# window (where the text belongs to), text (stimuli content), and color

# message.draw() prepares the text stimuli off-screen
# window.flip() presents the stimuli on screen
# core.wait() asks the stimuli to remain on screen for a certain amount of time (2 seconds in this case)
# window.close() closes the window object

try:
    message = visual.TextStim(
        window,
        text = "PsychoPy is working...",
        color = "white"
    )

    message.draw()
    window.flip()
    core.wait(2)

finally:
    window.close()