from transformers import pipeline
from PIL import Image

# Load the model pipeline
pipe = pipeline(
    "image-text-to-text",
    model="openbmb/MiniCPM-V-2_6",
    trust_remote_code=True,
    device_map="auto",         # Automatically use your GPU (4070)
    torch_dtype="auto"
)

# Open the local image
image = Image.open("IMG_5106.JPG")  # Make sure this file is in the same folder

# Create the messages input
messages = [
    {
        "role": "user",
        "content": [
            {"type": "image", "image": image},
            {"type": "text", "text": "Describe this image simply."}
        ]
    }
]

# Run the model
result = pipe(messages)

# Show the result
print(result)
