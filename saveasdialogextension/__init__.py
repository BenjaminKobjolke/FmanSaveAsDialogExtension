from fman import DirectoryPaneCommand, ApplicationCommand, show_alert, FMAN_VERSION, DirectoryPaneListener, load_json, save_json, show_prompt
from fman.url import as_human_readable, basename
import subprocess
from subprocess import Popen
import os.path
import os

import atexit

SETTINGS_FILENAME = "Lastdirectories.json"

# Using register() as a decorator 
@atexit.register 
def goodbye(): 
	file_path = os.path.dirname(__file__)
	exe_path = file_path + "\\lastdirectories.exe"
	subprocess.Popen(f'"{exe_path}" exit')

# static class
class Globals():
	# bool 
	first_run_done = False

class OnDirectoryChanged(DirectoryPaneListener):
	
	def on_path_changed(self):
		if Globals.first_run_done != True:
			Globals.first_run_done = True			
			file_path = os.path.dirname(__file__)
			exe_path = file_path + "\\lastdirectories.exe"
			subprocess.Popen(f'"{exe_path}"')			
			
		current_path = self.pane.get_path()

		# happens on start
		if current_path == "null://":
			return

		mylist = load_json(SETTINGS_FILENAME,  default=[])
		mylist.append(as_human_readable(current_path))			
		# trim myList to max 9 items
		if len(mylist) > 9:
			mylist = mylist[len(mylist)-9:]				
					
		mylist = CleanList(mylist)					
		save_json(SETTINGS_FILENAME, mylist)

def CleanList(history_list):
    newList = list(dict.fromkeys(history_list))
    return(newList)