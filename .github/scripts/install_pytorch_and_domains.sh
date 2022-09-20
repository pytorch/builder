#!/usr/bin/env python3

def get_os() -> str:
    import sys
    if sys.platform.startswith("darwin"):
        return "macos"
    if sys.platform.startswith("linux"):
        return "linux"
    if sys.platform.startswith("win32") or sys.platform.startswith("cygwin"):
        return "windows"
    raise RuntimeError(f"Unknown platform {sys.platform}")


def get_acc() -> str:
    import os
    return os.getenv("TEST_ACC", "accnone")


def get_ver() -> str:
    import os
    return os.getenv("TEST_VER", "latest_stable")


def get_pkg_type() -> str:
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "--conda":
        return "conda"
    if len(sys.argv) > 1 and sys.argv[1] == "--wheel":
        return "wheel"
    return "pip"

def get_install_command(os: str, pkg: str)
    import sys

def main() -> None:
    import subprocess
    import sys

    os = get_os()
    acc = get_acc()
    pkg_type = get_pkg_type()
    version = get_ver()
    if version in ["latest_lts", "latest_stable"]:
        version = published_versions[version]

    versions = published_versions["versions"][version]
    pkg_vers = versions[os][pkg_type]
    acc_vers = pkg_vers[acc]
    note, cmd = acc_vers["note"], acc_vers["command"]
    if cmd is None:
        print(note)
        sys.exit(0)

    # Check that PyTorch + Domains are installable
    print(f"Installing PyTorch {version} + {acc} using {pkg_type} and Python {sys.version}")
    if pkg_type == "pip":
        cmd_args = [sys.executable] + cmd.split(" ")
        cmd_args[1] = "-mpip"
        subprocess.check_call(cmd_args)
    else:
        assert pkg_type == "conda"
        args = cmd.split(" ")
        # Add `-y` argument
        for idx, arg in enumerate(args):
            if arg == "install":
                args.insert(idx +1, "-y")
        subprocess.check_call(args)


if __name__ == "__main__":
    main()
