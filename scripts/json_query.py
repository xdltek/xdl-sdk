#!/usr/bin/env python3
import json
import sys


def load(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def latest(data):
    print(data["latest"])


def list_versions(data):
    os_order = {
        "ubuntu": 0,
        "debian": 1,
        "kylin": 2,
        "openeuler": 3,
    }

    for version in sorted(data.get("sdk", {}).keys()):
        release = data["sdk"][version]
        packages = release.get("packages", {})
        sorted_os_ids = sorted(packages.keys(), key=lambda name: (os_order.get(name, 99), name))
        for os_id in sorted_os_ids:
            for arch in sorted(packages[os_id].keys()):
                pkg = packages[os_id][arch]
                print(f"{version}\t{os_id}\t{arch}\t{pkg['file']}\t{pkg['md5']}")


def resolve(data, version, os_id, arch):
    if version == "latest":
        version = data["latest"]

    try:
        pkg = data["sdk"][version]["packages"][os_id][arch]
    except KeyError:
        available = []
        for v, release in data.get("sdk", {}).items():
            for os_name, arch_map in release.get("packages", {}).items():
                for arch_name in arch_map.keys():
                    available.append(f"{v}/{os_name}/{arch_name}")
        msg = ", ".join(sorted(available)) if available else "none"
        raise SystemExit(f"No SDK package for version={version}, os={os_id}, arch={arch}. Available: {msg}")

    fields = {
        "version": version,
        "os": os_id,
        "arch": arch,
        "file": pkg["file"],
        "url": pkg["url"],
        "md5": pkg["md5"],
        "size_bytes": str(pkg.get("size_bytes", 0)),
        "release_notes": data["sdk"][version].get("release_notes", ""),
    }
    for key, value in fields.items():
        print(f"{key}\t{value}")


def main(argv):
    if len(argv) < 3:
        raise SystemExit("Usage: json_query.py <latest|list|resolve> <sdk.json> [args...]")

    command = argv[1]
    data = load(argv[2])

    if command == "latest":
        latest(data)
    elif command == "list":
        list_versions(data)
    elif command == "resolve":
        if len(argv) != 6:
            raise SystemExit("Usage: json_query.py resolve <sdk.json> <version|latest> <os> <arch>")
        resolve(data, argv[3], argv[4], argv[5])
    else:
        raise SystemExit(f"Unknown command: {command}")


if __name__ == "__main__":
    main(sys.argv)
