#!/usr/bin/env python3
"""
Example demonstrating how to use ONNX Runtime GenAI with MIGraphX backend.

This example shows:
1. Loading a model with MIGraphX backend
2. Encoding input text
3. Generating output text with streaming
"""

import onnxruntime_genai as og

def main():
    # Path to your ONNX model directory
    # The model should contain:
    # - ONNX model files (encoder, decoder, etc.)
    # - genai_config.json with MIGraphX provider configuration
    model_path = "path/to/your/model"
    
    # Load the model with MIGraphX backend
    # The backend will be automatically selected based on genai_config.json
    print("Loading model with MIGraphX backend...")
    model = og.Model(model_path)
    
    # Create tokenizer
    tokenizer = og.Tokenizer(model)
    
    # Create stream for token-by-token output
    stream = tokenizer.create_stream()
    
    # Set up generation parameters
    search_options = {
        'max_length': 2048,
        'batch_size': 1,
        'top_p': 0.9,
        'top_k': 50,
        'temperature': 1.0,
    }
    
    # Define chat template
    chat_template = '<|user|>\n{input} <|end|>\n<|assistant|>'
    
    # Get user input
    user_input = input("Input: ")
    if not user_input:
        print("Error: Input cannot be empty")
        return
    
    # Format the prompt
    prompt = chat_template.format(input=user_input)
    
    # Encode the prompt
    input_tokens = tokenizer.encode(prompt)
    
    # Create generator parameters
    params = og.GeneratorParams(model)
    params.set_search_options(**search_options)
    
    # Create the generator
    generator = og.Generator(model, params)
    
    # Generate output
    print("Output: ", end='', flush=True)
    
    try:
        generator.append_tokens(input_tokens)
        while not generator.is_done():
            generator.generate_next_token()
            new_token = generator.get_next_tokens()[0]
            print(stream.decode(new_token), end='', flush=True)
    except KeyboardInterrupt:
        print("\n  --control+c pressed, aborting generation--")
    
    print()
    
    # Cleanup
    del generator

if __name__ == "__main__":
    main()
