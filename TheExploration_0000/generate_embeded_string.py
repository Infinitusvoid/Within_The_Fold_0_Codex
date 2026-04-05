import os

def generate_cpp_function_from_txt(txt_file_path):
    # Extract filename without extension for function name
    base_name = os.path.splitext(os.path.basename(txt_file_path))[0]

    # Read contents of the text file
    with open(txt_file_path, 'r', encoding='utf-8') as file:
        content = file.read()

    # Escape special characters for C++ string literals
    escaped_content = content.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n"\n"')

    # Create the C++ function code as a string
    cpp_code = f'''#include <string>

std::string {base_name}()
{{
    return "{escaped_content}";
}}
'''

    # Define output path
    output_cpp_file = f"{base_name}.cpp"

    # Write the generated code to the disk
    with open(output_cpp_file, 'w', encoding='utf-8') as file:
        file.write(cpp_code)

    print(f"C++ function generated in file: {output_cpp_file}")

# Example usage:
if __name__ == "__main__":
    txt_file = "vertex_shader_exploring_0000.glsl"  # replace with your txt file
    generate_cpp_function_from_txt(txt_file)
