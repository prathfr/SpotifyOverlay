import base64
import os
import requests
import subprocess
import time

spotify_script_directory = "{}/Packages/Microsoft.MinecraftUWP_8wekyb3d8bbwe/RoamingState/OnixClient/Scripts/Data/_spotify_overlay_new".format(os.getenv('LOCALAPPDATA')).replace("\\", "/")

client_id = "0cf442a705504a94acaeed65f98b6417"
client_secret = "8237b2069cd04618bbb12a8c07237538"
refresh_token = "AQBa3gTkuRZXneOZne5bnIXiyG6IHoeLh4wGKgbujF7qFDkJB2VzF0klZP1oOiWAxfYgl5UJWXJsx8ZWrjSJzqgEjetEt7qwRFev9joDHYQqjUPUEQ5qObsdmVdNpD4VBCc"
base_64 = base64.b64encode("{}:{}".format(client_id, client_secret).encode("ascii")).decode("ascii")

#while True:
#	print(open("C:/Users/yadav_xfcy7t5/AppData/Local/Packages/Microsoft.MinecraftUWP_8wekyb3d8bbwe/RoamingState/OnixClient/Scripts/Data/_spotify_overlay_new/_track_data_loop.json", "r").read())
#	time.sleep(0.5)