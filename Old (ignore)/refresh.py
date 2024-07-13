from data import refresh_token, base_64, spotify_script_directory
import requests
import json
import os
import time


class Refresh:

    def __init__(self):
        self.refresh_token = refresh_token
        self.base_64 = base_64

    def refresh(self):
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

    def check_for_directory(self):
        if (os.path.exists(spotify_script_directory)) == False:
            print("Spotify overlay script directory doesn't exist!")
            print("Creating it now...")
            os.mkdir(spotify_script_directory)
            print("Spotify overlay script directory created")

    def check_for_token(self):
        if (os.path.exists(spotify_script_directory)) == False:
            print("Spotify overlay script directory doesn't exist!")
            print("Creating it now...")
            os.mkdir(spotify_script_directory)
            print("Spotify overlay script directory created")
        if os.path.exists(spotify_script_directory + "/_cache.json") == True:
            if time.ctime(os.path.getmtime(spotify_script_directory + "/_cache.json") + 3600) > time.ctime():
                return "not_expired"
            elif time.ctime(os.path.getmtime(spotify_script_directory + "/_cache.json") + 3600) < time.ctime():
                print("Token expired!")
                print("Refreshing now...")
                Refresh().refresh()
                print("Refreshed token!")
                return "expired"
        elif os.path.exists(spotify_script_directory + "/_cache.json") == False:
            print("No cache file!")
            print("Creating it now...")
            Refresh().refresh()
            print("Cache file created")