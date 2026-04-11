import os
from PIL import Image

def slice_cards(image_path, output_dir):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    img = Image.open(image_path)
    width, height = img.size
    
    # Grid is 12 columns x 5 rows
    # The image has 12 columns and 5 rows visible.
    cols = 12
    rows = 5
    
    card_width = width / cols
    card_height = height / rows
    
    suits = ['oro', 'copa', 'espada', 'basto']
    
    for row in range(rows):
        for col in range(cols):
            # Calculate coordinates
            left = col * card_width
            top = row * card_height
            right = (col + 1) * card_width
            bottom = (row + 1) * card_height
            
            # Crop card
            card = img.crop((left, top, right, bottom))
            
            # Define name
            if row < 4:
                card_num = col + 1
                name = f"{suits[row]}_{card_num}.png"
            else:
                if col == 0:
                    name = "blanca.png"
                elif col == 1:
                    name = "dorso.png"
                else:
                    continue # Skip empty slots in last row
            
            # Save
            card.save(os.path.join(output_dir, name))
            print(f"Saved {name}")

if __name__ == "__main__":
    image_path = "/Users/martinregas/.gemini/antigravity/brain/a6f7d387-b272-4b3b-9d96-a23105cfca26/media__1775861480719.png"
    output_dir = "assets/images/cards"
    slice_cards(image_path, output_dir)
