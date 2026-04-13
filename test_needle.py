import argparse
import json
import random
import time
import requests

def generate_dummy_text(length_in_tokens):
    # Rough estimate: 1 token ~= 4 characters or 0.75 words
    # We'll use a repeating story to fill space
    story = "Once upon a time in a galaxy far, far away, there was a small planet inhabited by curious creatures. They spent their days studying the stars and wondering about the universe. "
    words = story.split()
    
    # Estimate words needed
    target_words = int(length_in_tokens * 0.75)
    
    repeated_words = words * (target_words // len(words) + 1)
    return " ".join(repeated_words[:target_words])

def insert_needle(context, needle, position_percent):
    words = context.split()
    insert_idx = int(len(words) * (position_percent / 100.0))
    new_words = words[:insert_idx] + needle.split() + words[insert_idx:]
    return " ".join(new_words)

def test_single_needle(model_url, context_len, needle_pos):
    print(f"\n--- Testing Single Needle at {needle_pos}% depth, Context Len: {context_len} ---")
    
    dummy_context = generate_dummy_text(context_len)
    
    secret_fact = "The secret color of the Blackwell GPU is neon green."
    context_with_needle = insert_needle(dummy_context, secret_fact, needle_pos)
    
    prompt = f"{context_with_needle}\n\nQuestion: What is the secret color of the Blackwell GPU?\nAnswer:"
    
    payload = {
        "prompt": prompt,
        "max_tokens": 20,
        "temperature": 0.0, # Greedy for precision
    }
    
    try:
        response = requests.post(f"{model_url}/generate", json=payload)
        response.raise_for_status()
        result = response.json()
        generated_text = result['text'][0]
        
        print(f"Model response: {generated_text}")
        
        success = "neon green" in generated_text.lower()
        print(f"Result: {'SUCCESS' if success else 'FAILED'}")
        return success
    except Exception as e:
        print(f"Error during request: {e}")
        return False

def test_multi_needle(model_url, context_len):
    print(f"\n--- Testing Multi-Needle Correlation, Context Len: {context_len} ---")
    
    dummy_context = generate_dummy_text(context_len)
    
    # Clues
    clue1 = "The first part of the password is 'Black'."
    clue2 = "The second part of the password is 'well'."
    clue3 = "The third part of the password is '6000'."
    
    # Insert at 10%, 50%, 90%
    context = insert_needle(dummy_context, clue1, 10)
    context = insert_needle(context, clue2, 50)
    context = insert_needle(context, clue3, 90)
    
    prompt = f"{context}\n\nQuestion: What is the full password combined from the three clues in the text?\nAnswer:"
    
    payload = {
        "prompt": prompt,
        "max_tokens": 20,
        "temperature": 0.0,
    }
    
    try:
        response = requests.post(f"{model_url}/generate", json=payload)
        response.raise_for_status()
        result = response.json()
        generated_text = result['text'][0]
        
        print(f"Model response: {generated_text}")
        
        success = "blackwell6000" in generated_text.lower().replace(" ", "").replace("'", "")
        print(f"Result: {'SUCCESS' if success else 'FAILED'}")
        return success
    except Exception as e:
        print(f"Error during request: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Needle In A Haystack Test Client")
    parser.add_argument("--model_url", type=str, default="http://localhost:8000", help="vLLM server URL")
    parser.add_argument("--context_len", type=int, default=100000, help="Context length in tokens")
    parser.add_argument("--test_type", type=str, default="single", choices=["single", "multi", "all"], help="Test type")
    
    args = parser.parse_args()
    
    if args.test_type == "single" or args.test_type == "all":
        # Test at different depths
        test_single_needle(args.model_url, args.context_len, 10)
        test_single_needle(args.model_url, args.context_len, 50)
        test_single_needle(args.model_url, args.context_len, 90)
        
    if args.test_type == "multi" or args.test_type == "all":
        test_multi_needle(args.model_url, args.context_len)

if __name__ == "__main__":
    main()
