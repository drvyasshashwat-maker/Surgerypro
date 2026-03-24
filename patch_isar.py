import sys

gradle_path = sys.argv[1]
namespace = sys.argv[2]

with open(gradle_path, 'r') as f:
    content = f.read()

if 'namespace' not in content:
    content = content.replace('android {', 'android {\n    namespace "' + namespace + '"', 1)
    with open(gradle_path, 'w') as f:
        f.write(content)
    print("Namespace injected successfully.")
else:
    print("Namespace already exists.")
