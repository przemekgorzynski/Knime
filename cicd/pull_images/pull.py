import yaml
import docker, docker.errors 
import os
from dotenv import load_dotenv

load_dotenv()

INVENTORY_FILE = "inventory.yml"
client = docker.from_env()

def docker_login():
    registry = os.getenv("DOCKER_REGISTRY")
    username = os.getenv("DOCKER_USERNAME")
    password = os.getenv("DOCKER_PASSWORD")

    if not all([registry, username, password]):
        print("❌ Missing Docker credentials in .env")
        exit(1)

    try:
        print(f"🔐 Logging into {registry} as {username}...")
        client.login(username=username, password=password, registry=registry)
        print("✅ Login successful\n")
    except docker.errors.APIError as e:
        print(f"❌ Login failed: {e.explanation}")
        # exit(1)

def pull_tag_push_cleanup(source_image, source_tag, target_image, target_tag):
    full_source = f"{source_image}:{source_tag}"
    full_target = f"{target_image}:{target_tag}"

    print(f"▶ Pulling: {full_source}")
    image = client.images.pull(full_source)

    print(f"▶ Tagging: {full_source} → {full_target}")
    image.tag(target_image, target_tag)

    print(f"▶ Pushing: {full_target}")
    for line in client.images.push(target_image, tag=target_tag, stream=True, decode=True):
        if 'status' in line:
            print(line['status'])

    # Cleanup: remove both source and tagged image
    print(f"🧹 Removing local images...")
    try:
        client.images.remove(image=f"{target_image}:{target_tag}", force=True)
        client.images.remove(image=f"{source_image}:{source_tag}", force=True)
    except docker.errors.ImageNotFound as e:
        print(f"⚠️  Image not found: {e}")
    except docker.errors.APIError as e:
        print(f"❌ Error during cleanup: {e}")

    print(f"✅ Done: {full_target}\n")

def main():
    docker_login()

    with open(INVENTORY_FILE, "r") as f:
        inventory = yaml.safe_load(f)

    for name, data in inventory.items():
        pull_tag_push_cleanup(
            source_image=data["source"]["image"],
            source_tag=data["source"]["tag"],
            target_image=data["target"]["image"],
            target_tag=data["target"]["tag"],
        )

if __name__ == "__main__":
    main()
