import time
import json

from data import spotify_script_directory

def loop_text(textLength):
	i = 0
	track_name_loop = "No song playing"
	while True:
		with open(spotify_script_directory + "/_track_data.json") as track_data_file:
			track_info = json.load(track_data_file)
		if track_info['error'] == "No error":
			if i <= len(track_info['track_name']):
				track_name_loop = track_info['track_name'][i:i + textLength]
				i = i + 1
			elif i > len(track_info['track_name']):
				i = 0
			print(track_name_loop)
			with open(spotify_script_directory + "/_track_data_loop.json", "w") as track_data_loop_file:
				track_data_loop_file.write(track_name_loop)
			time.sleep(0.5)
		else:
			pass