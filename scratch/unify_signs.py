import os
from PIL import Image, ImageStat

def get_mean_color(img):
    # Only consider pixels with alpha > 0
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    pixels = img.getdata()
    r_sum, g_sum, b_sum, count = 0, 0, 0, 0
    
    for r, g, b, a in pixels:
        if a > 128: # Significant opacity
            r_sum += r
            g_sum += g
            b_sum += b
            count += 1
            
    if count == 0:
        return (128, 128, 128)
    return (r_sum / count, g_sum / count, b_sum / count)

def unify_colors(ref_path, target_dir):
    ref_img = Image.open(ref_path).convert('RGBA')
    ref_mean = get_mean_color(ref_img)
    print(f"Reference mean: {ref_mean}")
    
    for filename in os.listdir(target_dir):
        if not filename.endswith('.png') or filename == 'backup':
            continue
            
        target_path = os.path.join(target_dir, filename)
        if target_path == ref_path:
            continue
            
        print(f"Processing {filename}...")
        img = Image.open(target_path).convert('RGBA')
        target_mean = get_mean_color(img)
        
        # Calculate ratios
        r_ratio = ref_mean[0] / target_mean[0] if target_mean[0] > 0 else 1
        g_ratio = ref_mean[1] / target_mean[1] if target_mean[1] > 0 else 1
        b_ratio = ref_mean[2] / target_mean[2] if target_mean[2] > 0 else 1
        
        # Limit ratios to stay within reasonable bounds
        r_ratio = max(0.5, min(1.5, r_ratio))
        g_ratio = max(0.5, min(1.5, g_ratio))
        b_ratio = max(0.5, min(1.5, b_ratio))
        
        # Apply scaling
        pixels = img.load()
        for y in range(img.size[1]):
            for x in range(img.size[0]):
                r, g, b, a = pixels[x, y]
                new_r = int(min(255, r * r_ratio))
                new_g = int(min(255, g * g_ratio))
                new_b = int(min(255, b * b_ratio))
                pixels[x, y] = (new_r, new_g, new_b, a)
        
        img.save(target_path)
        print(f"Saved {filename}")

if __name__ == "__main__":
    ref = "assets/images/signs/1_basto_sign.png"
    target = "assets/images/signs"
    unify_colors(ref, target)
