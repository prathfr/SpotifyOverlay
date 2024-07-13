import requests
import webbrowser
import json
import os
from datetime import datetime
from urllib.parse import urlencode

st = datetime.now().timestamp()

CLIENT_ID = "0cf442a705504a94acaeed65f98b6417"
CLIENT_SECRET = "8237b2069cd04618bbb12a8c07237538"
REDIRECT_URI = "https://localhost:7777/callback"
CACHE_FILE_PATH = "./spotifyoverlaycache.json"

def spotify_auth(CLIENT_ID: str, REDIRECT_URI: str):
    webbrowser.open("https://accounts.spotify.com/authorize?" + urlencode({
        "client_id": CLIENT_ID,
        "response_type":"code",
        "redirect_uri": REDIRECT_URI,
        "scope": "user-read-currently-playing"
    }))

def get_tokens(CLIENT_ID: str, CLIENT_SECRET: str, REDIRECT_URI: str):
    data = {"client_id": CLIENT_ID, "client_secret": CLIENT_SECRET}
    try:
        with open(CACHE_FILE_PATH, 'r') as f:
            fdata = json.load(f)
            if datetime.now().timestamp() - os.path.getmtime(CACHE_FILE_PATH) < fdata['expires_in']:
                return fdata
            else:
                data = {
                    **data,
                    "grant_type": "refresh_token",
                    "refresh_token": fdata['refresh_token']
                }
    except FileNotFoundError:
        spotify_auth(CLIENT_ID, REDIRECT_URI)
        auth_code = input('Enter the code: ')
        data = {
            **data,
            "grant_type": "authorization_code",
            "code": auth_code,
            "redirect_uri": REDIRECT_URI
        }
    r = requests.post("https://accounts.spotify.com/api/token", data = data)
    with open(CACHE_FILE_PATH, 'w') as f2:
        f2.write(json.dumps(r.json(), indent = 4))
    return r.json()

t = get_tokens(CLIENT_ID, CLIENT_SECRET, REDIRECT_URI)
access_token = t['access_token']

def get_currently_playing(ACCESS_TOKEN):
    r = requests.get("https://api.spotify.com/v1/me/player/currently-playing", headers={"Authorization": "Bearer " + ACCESS_TOKEN})
    return r

player_info = get_currently_playing(access_token)

def parse_output(RESP):
    output = {}
    if RESP.status_code == 200:
        player = RESP.json()['item']
        output = {
            "track_name": player['name'],
            "artists": player['artists'][0]['name'],
        }
    else:
        output = {
            "track_name": "No track playing",
            "artists": "No artist"
        }
    return output

print(parse_output(player_info))
print(round(datetime.now().timestamp()-st,3),'ms')
