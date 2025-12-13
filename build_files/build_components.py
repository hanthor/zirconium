#!/usr/bin/env python3
import subprocess
import sys
import concurrent.futures
import os

def get_components():
    components = []
    build_dir = "build_files"
    if not os.path.exists(build_dir):
        print(f"Error: Directory '{build_dir}' not found.")
        sys.exit(1)
        
    for filename in os.listdir(build_dir):
        if filename.endswith(".Containerfile"):
            # "niri.Containerfile" -> "niri"
            component_name = filename[:-len(".Containerfile")]
            components.append(component_name)
    return sorted(components)

COMPONENTS = get_components()

REGISTRY = os.environ.get("REGISTRY", "localhost")

def build_component(component):
    print(f"[{component}] Starting build...")
    dockerfile = f"build_files/{component}.Containerfile"
    image_tag = f"{REGISTRY}/{component}:latest"
    
    cmd = [
        "podman", "build",
        "-f", dockerfile,
        "-t", image_tag,
        "."
    ]
    
    try:
        # Capture output to avoid interleaving, or let it flow if we don't care about mess
        # For better UX, capturing and printing on completion is often nicer, 
        # but for CI/local builds seeing progress is good. 
        # mixing stdout from 9 processes is messy though.
        # Let's capture and print on error or success.
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=True
        )
        print(f"[{component}] Build finished successfully.")
        return True, component, result.stdout
    except subprocess.CalledProcessError as e:
        print(f"[{component}] Build FAILED.")
        return False, component, e.stdout

def main():
    print(f"Building {len(COMPONENTS)} components in parallel to registry '{REGISTRY}'...")
    
    failed = False
    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = {executor.submit(build_component, c): c for c in COMPONENTS}
        
        for future in concurrent.futures.as_completed(futures):
            success, component, output = future.result()
            if not success:
                failed = True
                print(f"\n{'='*40}\nERROR LOG for {component}:\n{output}\n{'='*40}\n")
    
    if failed:
        print("One or more builds failed.")
        sys.exit(1)
    
    print("All builds completed successfully.")

if __name__ == "__main__":
    main()
