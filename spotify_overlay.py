import requests
import json
import time
import os
import base64
import shutil
import keyboard
import subprocess

from colorthief import ColorThief

from data import refresh_token, base_64, spotify_script_directory
#from refresh import Refresh
import text_loop


def refresh():
    response = requests.post(
        "https://accounts.spotify.com/api/token",
        data = {
            "grant_type": "refresh_token",
            "refresh_token": refresh_token
        },
        headers = {
            "Authorization": "Basic {}".format(base_64)
        }
    )

    response_json = response.json()

    with open(spotify_script_directory + "/_cache.json", "w") as outfile:
        json.dump(response_json, outfile, indent = 4)

    return response_json


def convertDuration(milliseconds):
	milliseconds = int(milliseconds)
	seconds = (milliseconds / 1000) % 60
	minutes = (milliseconds / ( 1000 * 60 )) % 60

	seconds = str(int(seconds))
	minutes = str(int(minutes))

	if len(seconds) == 1:
		seconds = "0" + seconds

	return "{}:{}".format(minutes, seconds)


def get_token():
	if os.path.exists(spotify_script_directory) == False:
		print("Spotify overlay script directory doesn't exist!")
		print("Creating it now...")
		os.mkdir(spotify_script_directory)
		print("Spotify overlay script directory created")
	else:
		pass
	if os.path.exists(spotify_script_directory + "/_cache.json") == True:
	    if time.ctime(os.path.getmtime(spotify_script_directory + "/_cache.json") + 3600) > time.ctime():
	        return "not_expired"
	    elif time.ctime(os.path.getmtime(spotify_script_directory + "/_cache.json") + 3600) < time.ctime():
	        print("Token expired!")
	        print("Refreshing now...")
	        refresh()
	        print("Refreshed token!")
	        return "expired"
	elif os.path.exists(spotify_script_directory + "/_cache.json") == False:
	    print("No cache file!")
	    print("Creating it now...")
	    refresh()
	    print("Cache file created")


def get_current_track():
	last_track_name = None

	get_token()

	with open(spotify_script_directory + "/_cache.json", "r") as openfile:
		token_info = json.load(openfile)
		spotify_access_token = token_info['access_token']

	response = requests.get(
		"https://api.spotify.com/v1/me/player/currently-playing",
		headers = {
			"Content-Type": "application/json",
			"Authorization": "Bearer {}".format(spotify_access_token)
		}
	)

	if response.status_code != None or "":
		if response.status_code == 200 or response.status_code == 201 or response.status_code == 202:
			json_response = response.json()

			track_name = json_response['item']['name']
			track_artists = [artist for artist in json_response['item']['artists']]
			track_artist_names = ', '.join([artist['name'] for artist in track_artists])
			album_name = json_response['item']['album']['name']
			track_progress = json_response['progress_ms']
			track_duration = json_response['item']['duration_ms']
			track_album_art = json_response['item']['album']['images'][0]['url']

			result = {
				"error": "No error",
				"error_code": response.status_code,
				"track_name": track_name,
				"track_artists": track_artist_names,
				"track_album": album_name,
				"track_progress": track_progress,
				"track_duration": track_duration,
				"track_album_art": track_album_art
			}

			if result['track_name'] != last_track_name:
				last_track_name = result['track_name']

			return result

		elif response.status_code == 204:

			result = {
				"error" : "No song playing",
				"error_code": response.status_code
			}

			return result
		else:

			result = {
				"error" : "Error",
				"error_code": response.status_code
			}

			return result


def main():
	print("[!] Skipping a song may or may not break the script / may add a temporary delay")
	print()
	print("Press Ctrl + / to exit.")
	print()

	if keyboard.is_pressed('ctrl + /'):
		print("alt f4'ed the existence of this script")
		exit()

	track_info = get_current_track()

	with open(spotify_script_directory + "/_track_data.json", "w") as track_data_file:
			json.dump(track_info, track_data_file, indent = 4)

	if track_info['error'] == "No error":

		i = 1

		print()
		print("0       Track: {}".format(track_info['track_name']))
		print("		Artist(s): {}".format(track_info['track_artists']))
		print("		Album: {}".format(track_info['track_album']))
		print("		Track duration: {}".format(convertDuration(track_info['track_duration'])))

		current_time = time.time()

		track_pending_time = int((track_info['track_duration'] - track_info['track_progress']) / 1000) + 2
		refreshtime = time.ctime(current_time + track_pending_time)

		print("		Refreshed at: {}".format(time.ctime()))
		print("		Next API refresh time: {} (in {})".format(refreshtime, convertDuration(track_pending_time * 1000)))
		print()

		response = requests.get(track_info['track_album_art'], stream = True)
		response.raw.decode_content = True
		with open(spotify_script_directory + "/track_album_art.png", 'wb') as track_album_art_image_file:
			shutil.copyfileobj(response.raw, track_album_art_image_file)

		with open(spotify_script_directory + "/_track_album_art_data.json", "w") as track_album_art_data_file:
			track_album_art_data_file.write(str(ColorThief(spotify_script_directory + "/track_album_art.png").get_color(quality = 1)))

		last_track_name = track_info['track_name']

		while True:
			if keyboard.is_pressed('ctrl + /'):
				print("alt f4'ed the existence of this script")
				exit()
			if time.ctime() == refreshtime:
				track_info_loop = get_current_track()

				with open(spotify_script_directory + "/_track_data.json", "w") as track_data_file:
					json.dump(track_info_loop, track_data_file, indent = 4)

				if track_info_loop['error'] == "No error":

					current_time = time.time()
					track_pending_time = (track_info_loop['track_duration'] - track_info_loop['track_progress']) + 1000
					refreshtime = time.ctime(current_time + int(track_pending_time / 1000))

					numberOfSpaces = 5 - len(str(i))

					if last_track_name != track_info_loop['track_name']:
						print(str(i) + (" " * (numberOfSpaces)) + "   Track: " + track_info_loop['track_name'])
						print("		Artist(s): {}".format(track_info_loop['track_artists']))
						print("		Album: {}".format(track_info_loop['track_album']))
						print("		Track duration: {}".format(convertDuration(track_info_loop['track_duration'])))
						print("		Refreshed at: {}".format(time.ctime()))
						print("		Next API refresh time: {} (in {})".format(refreshtime, convertDuration(track_pending_time)))
						print()

						response = requests.get(track_info['track_album_art'], stream = True)
						response.raw.decode_content = True
						with open(spotify_script_directory + "/track_album_art.png", 'wb') as track_album_art_image_file:
							shutil.copyfileobj(response.raw, track_album_art_image_file)

						with open(spotify_script_directory + "/_track_album_art_data.json", "w") as track_album_art_data_file:
							track_album_art_data_file.write(str(ColorThief(spotify_script_directory + "/track_album_art.png").get_color(quality = 1)))

					elif last_track_name == track_info_loop['track_name']:
						print("{}{}   Refreshed at: {}".format(str(i), " " * numberOfSpaces, time.ctime()))
						print("		Next API refresh time: {} (in {})".format(refreshtime, convertDuration(track_pending_time)))
						print()

					last_track_name = track_info_loop['track_name']

					i = i + 1

				elif track_info_loop['error'] == "No song playing":
					print(track_info_loop['error'])
				elif track_info_loop['error'] == "Error":
					print(track_info_loop['error'])
					break

	elif track_info['error'] == "No song playing":
		print("{} {}".format(track_info['error_code'], track_info['error']))
	elif track_info['error'] == "Error":
		print("{} {}".format(track_info['error_code'], track_info['error']))

main()
#text_loop.loop_text(15)