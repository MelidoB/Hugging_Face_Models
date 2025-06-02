#!/bin/bash

MODEL="minicpm-v:8b"
FOLDER="images"
OUTPUT_DIR="graduation_jsons"
TIMESTAMP="May 30, 2025"

# Check if folder exists
if [ ! -d "$FOLDER" ]; then
    echo "Error: Folder '$FOLDER' does not exist"
    exit 1
fi

# Create output directory for JSON files
mkdir -p "$OUTPUT_DIR"

# Initialize JSON files for each goal
echo '{"images": [], "notes": "Start with a solo shot in your gown for maximum impact. Follow with family (parents, sister, grandpa) for emotional connection, then friends for celebration vibe. Limit to 10 images."}' > "$OUTPUT_DIR/instagram_post.json"
echo '{"images": [], "notes": "Use solo, family, and friend shots for quick, engaging stories. Order: solo to set context, then mix family and friends for variety. Add stickers and music like Good Days by SZA or On Top of the World by Imagine Dragons."}' > "$OUTPUT_DIR/instagram_stories.json"
echo '{"images": [], "notes": "Start with a before shot (getting ready), transition to after (in gown, celebrating with family). Prioritize dynamic shots for trending song sync."}' > "$OUTPUT_DIR/instagram_reel.json"
echo '{"images": [], "notes": "Focus on professional solo shot in gown first, then add family (parents, grandpa) for support story. Keep it polished and gratitude-focused."}' > "$OUTPUT_DIR/linkedin_post.json"
echo '{"images": [], "notes": "For Vlog: Order by timeline—getting ready, ceremony, family reactions, solo reflection. For Short: Quick solo and celebration shots. For Sit-Down: Use solo and family as cutaways during challenges and proud moments."}' > "$OUTPUT_DIR/youtube.json"

# Loop over all images in the folder
for img in "$FOLDER"/*.{jpg,jpeg,png,JPG,JPEG,PNG}; do
    [ -e "$img" ] || continue  # Skip if no images

    echo "Found image: $img"
    echo "Describing: $img"

    # Run ollama with a strong English prompt, capture errors
    DESC=$(ollama run "$MODEL" "Provide a detailed description of this image in English only: $img. Identify people (e.g., solo person in graduation gown, with sister, mom, dad, both parents, friend, friends, grandpa) and context (e.g., getting ready, ceremony, celebration). Include date if visible." 2> error.log)
    if [ $? -ne 0 ]; then
        echo "Error running ollama for $img, check error.log"
        cat error.log
        continue
    fi
    echo "Description: $DESC"

    # If description is empty, set a default
    if [ -z "$DESC" ]; then
        echo "Warning: No description for $img"
        DESC="No description generated for $img"
    fi

    # Categorize image for each goal based on description
    # Instagram Post: Solo, family, friends
    if echo "$DESC" | grep -qi "solo.*graduation gown"; then
        jq --arg img "$img" --arg desc "$DESC" --arg category "Solo" '.images += [{"file": $img, "description": $desc, "category": $category}]' "$OUTPUT_DIR/instagram_post.json" > "$OUTPUT_DIR/instagram_post.tmp" && mv "$OUTPUT_DIR/instagram_post.tmp" "$OUTPUT_DIR/instagram_post.json"
    elif echo "$DESC" | grep -qi "sister\|mom\|dad\|both parents\|grandpa"; then
        jq --arg img "$img" --arg desc "$DESC" --arg category "Family" '.images += [{"file": $img, "description": $desc, "category": $category}]' "$OUTPUT_DIR/instagram_post.json" > "$OUTPUT_DIR/instagram_post.tmp" && mv "$OUTPUT_DIR/instagram_post.tmp" "$OUTPUT_DIR/instagram_post.json"
    elif echo "$DESC" | grep -qi "friend\|friends"; then
        jq --arg img "$img" --arg desc "$DESC" --arg category "Friends" '.images += [{"file": $img, "description": $desc, "category": $category}]' "$OUTPUT_DIR/instagram_post.json" > "$OUTPUT_DIR/instagram_post.tmp" && mv "$OUTPUT_DIR/instagram_post.tmp" "$OUTPUT_DIR/instagram_post.json"
    fi

    # Instagram Stories: Solo, family, friends
    if echo "$DESC" | grep -qi "solo\|sister\|mom\|dad\|both parents\|grandpa\|friend\|friends"; then
        jq --arg img "$img" --arg desc "$DESC" --arg category "Story" '.images += [{"file": $img, "description": $desc, "category": $category}]' "$OUTPUT_DIR/instagram_stories.json" > "$OUTPUT_DIR/instagram_stories.tmp" && mv "$OUTPUT_DIR/instagram_stories.tmp" "$OUTPUT_DIR/instagram_stories.json"
    fi

    # Instagram Reel: Before (getting ready), after (gown, celebration)
    if echo "$DESC" | grep -qi "getting ready"; then
        jq --arg img "$img" --arg desc "$DESC" --arg category "Before" '.images += [{"file": $img, "description": $desc, "category": $category}]' "$OUTPUT_DIR/instagram_reel.json" > "$OUTPUT_DIR/instagram_reel.tmp" && mv "$OUTPUT_DIR/instagram_reel.tmp" "$OUTPUT_DIR/instagram_reel.json"
    elif echo "$DESC" | grep -qi "graduation gown\|celebration"; then
        jq --arg img "$img" --arg desc "$DESC" --arg category "After" '.images += [{"file": $img, "description": $desc, "category": $category}]' "$OUTPUT_DIR/instagram_reel.json" > "$OUTPUT_DIR/instagram_reel.tmp" && mv "$OUTPUT_DIR/instagram_reel.tmp" "$OUTPUT_DIR/instagram_reel.json"
    fi

    # LinkedIn Post: Solo, family
    if echo "$DESC" | grep -qi "solo.*graduation gown"; then
        jq --arg img "$img" --arg desc "$DESC" --arg category "Solo" '.images += [{"file": $img, "description": $desc, "category": $category}]' "$OUTPUT_DIR/linkedin_post.json" > "$OUTPUT_DIR/linkedin_post.tmp" && mv "$OUTPUT_DIR/linkedin_post.tmp" "$OUTPUT_DIR/linkedin_post.json"
    elif echo "$DESC" | grep -qi "sister\|mom\|dad\|both parents\|grandpa"; then
        jq --arg img "$img" --arg desc "$DESC" --arg category "Family" '.images += [{"file": $img, "description": $desc, "category": $category}]' "$OUTPUT_DIR/linkedin_post.json" > "$OUTPUT_DIR/linkedin_post.tmp" && mv "$OUTPUT_DIR/linkedin_post.tmp" "$OUTPUT_DIR/linkedin_post.json"
    fi

    # YouTube: Getting ready, ceremony, family, solo
    if echo "$DESC" | grep -qi "getting ready\|ceremony\|sister\|mom\|dad\|both parents\|grandpa\|solo"; then
        jq --arg img "$img" --arg desc "$DESC" --arg category "Vlog" '.images += [{"file": $img, "description": $desc, "category": $category}]' "$OUTPUT_DIR/youtube.json" > "$OUTPUT_DIR/youtube.tmp" && mv "$OUTPUT_DIR/youtube.tmp" "$OUTPUT_DIR/youtube.json"
    fi
done

echo "All descriptions saved in $OUTPUT_DIR:"
ls -l "$OUTPUT_DIR"
echo "Contents of each JSON file:"
for json in "$OUTPUT_DIR"/*.json; do
    echo "File: $json"
    cat "$json"
    echo "----------------"
done
