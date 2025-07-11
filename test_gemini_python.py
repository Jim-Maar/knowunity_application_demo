from google import genai
import dotenv
from google.genai import types

dotenv.load_dotenv(".env")
GEMINI_API_KEY = dotenv.get_key(".env", "GEMINI_API_KEY")
client = genai.Client(api_key=GEMINI_API_KEY)

with open('example.mp3', 'rb') as f:
    audio_bytes = f.read()

response = client.models.generate_content(
  model='gemini-2.5-flash',
  contents=[
    'Describe this audio clip',
    types.Part.from_bytes(
      data=audio_bytes,
      mime_type='audio/mp3',
    )
  ]
)

print(response.text)