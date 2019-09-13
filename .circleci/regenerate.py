#!/usr/bin/env python3

"""
This script should use a very simple, functional programming style.
Avoid Jinja macros in favor of native Python functions.

Don't go overboard on code generation; use Python only to generate
content that can't be easily declared statically using CircleCI's YAML API.

Data declarations (e.g. the nested loops for defining the configuration matrix)
should be at the top of the file for easy updating.

See this comment for design rationale:
https://github.com/pytorch/vision/pull/1321#issuecomment-531033978
"""

import jinja2
import yaml
import os.path


def workflows(prefix='', upload=False, indentation=6):
    w = []
    for btype in ["wheel", "conda"]:
        os_list = ["linux", "macos"]
        if btype != "wheel":
            os_list.append("win")
        for os_type in os_list:
            for python_version in ["2.7", "3.5", "3.6", "3.7"]:
                for cu_version in (["cpu", "cu92", "cu100"] if os_type == "linux" else ["cpu"]):
                    for unicode in ([False, True] if btype == "wheel" and python_version == "2.7" else [False]):
                        w += workflow_pair(btype, os_type, python_version, cu_version, unicode, prefix, upload)

    return indent(indentation, w)


def workflow_pair(btype, os_type, python_version, cu_version, unicode, prefix='', upload=False):

    w = []
    unicode_suffix = "u" if unicode else ""
    base_workflow_name = f"{prefix}binary_{os_type}_{btype}_py{python_version}{unicode_suffix}_{cu_version}"

    w.append(generate_base_workflow(base_workflow_name, python_version, cu_version, unicode, os_type, btype))

    return w


def generate_base_workflow(base_workflow_name, python_version, cu_version, unicode, os_type, btype):

    d = {
        "name": base_workflow_name,
        "python_version": python_version,
        "cu_version": cu_version,
    }

    if unicode:
        d["unicode_abi"] = '1'

    if cu_version == "cu92":
        d["wheel_docker_image"] = "soumith/manylinux-cuda92"

    return {f"binary_{os_type}_{btype}": d}


def indent(indentation, data_list):
    return ("\n" + " " * indentation).join(yaml.dump(data_list).splitlines())


if __name__ == "__main__":
    d = os.path.dirname(__file__)
    env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(d),
        lstrip_blocks=True,
        autoescape=False,
    )

    with open(os.path.join(d, 'config.yml'), 'w') as f:
        f.write(env.get_template('config.in.yml').render(workflows=workflows))
