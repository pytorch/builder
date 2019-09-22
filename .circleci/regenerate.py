#!/usr/bin/env python3

"""
This script should use a very simple, functional programming style.
Avoid Jinja macros in favor of native Python functions.

Don't go overboard on code generation; use Python only to generate
content that can't be easily declared statically using CircleCI's YAML API;
i.e. make use of CircleCI mechanisms for parameterization and conditional execution.

Data declarations (e.g. the nested loops for defining the configuration matrix)
should be at the top of the file for easy updating.

See this comment for design rationale:
https://github.com/pytorch/vision/pull/1321#issuecomment-531033978
"""

import jinja2
import yaml
import os.path
from packaging.version import Version, parse


ALL_PYTHON_VERSIONS = [
    "2.7",
    "3.5",
    "3.6",
    "3.7",
]


ALL_CUDA_VERSIONS = [
    "cu92",
    "cu100",
]


def get_applicable_os_list(btype):
    os_list = ["macos"]
    if btype != "wheel":
        os_list.extend([
            "linux",  # TODO Get linux working with CUDA for wheels
            "win",
        ])

    return os_list


PARMNAME_IS_PYTHON_3 = "is-python3"
PARMNAME_RUN_EXTERNAL_PROJECTS = "run-external-projects"


def get_unicode_variants(btype, python_version):
    return [False, True] if btype == "wheel" and python_version == "2.7" else [False]


def workflows(category, prefix='', indentation=6):
    w = []

    for btype in ["wheel", "conda"]:
        for os_type in get_applicable_os_list(btype):

            # PyTorch for Python 2.7 builds are not supported on Windows.
            python_versions = [p for p in ALL_PYTHON_VERSIONS if not (os_type == "win" and p == "2.7")]

            for python_version in python_versions:

                # TODO allow Windows to run CUDA
                cuda_list = ALL_CUDA_VERSIONS if os_type == "linux" else []

                for cu_version in (["cpu"] + cuda_list):
                    for unicode in get_unicode_variants(btype, python_version):

                        should_run_external_projects = python_version == ALL_PYTHON_VERSIONS[-1] and \
                            cu_version in ("cpu", ALL_CUDA_VERSIONS[-1])

                        w += workflow_item(
                            should_run_external_projects,
                            category,
                            btype,
                            os_type,
                            python_version,
                            cu_version,
                            unicode,
                            prefix,
                        )

    return indent(indentation, w)


def workflow_item(
        should_run_external_projects,
        category,
        btype,
        os_type,
        python_version,
        cu_version,
        unicode,
        prefix=''):

    unicode_suffix = "u" if unicode else ""
    python_descriptor = f"py{python_version}{unicode_suffix}"

    name_components = [prefix] if prefix else [] + [
        category,
        os_type,
        btype,
        python_descriptor,
        cu_version,
    ]

    base_workflow_name = "_".join(name_components)

    w = generate_base_workflow(
        should_run_external_projects,
        base_workflow_name,
        python_version,
        cu_version,
        unicode,
        os_type,
        btype,
    )

    return [w]


def generate_base_workflow(
        should_run_external_projects,
        base_workflow_name,
        python_version,
        cu_version,
        unicode,
        os_type,
        btype):

    d = {
        "name": base_workflow_name,
        "python_version": python_version,
        "cu_version": cu_version,
    }

    if parse(python_version) >= Version("3"):
        d[PARMNAME_IS_PYTHON_3] = True

    if should_run_external_projects:
        d[PARMNAME_RUN_EXTERNAL_PROJECTS] = True

    if unicode:
        d["unicode_abi"] = '1'

    if cu_version == "cu92":
        d["wheel_docker_image"] = "soumith/manylinux-cuda92"

    job_name_pieces = [
        "binary",
        os_type,
        btype,
    ]

    if cu_version != "cpu" and btype == "conda":
        job_name_pieces.append("cuda")

    job_name = "_".join(job_name_pieces)

    return {job_name: d}


BLACKLISTED_TEST_DIRS = set([
    # Internal examples

    # FIXME this test times out with 20 minutes of no output
    "fast_neural_style",

    # FIXME current error: "IMAGENET_ROOT not set"
    #  Need to somehow pre-load 200GB data onto CI
    "imagenet",

    # FIXME
    #   File "main.py", line 57, in <module>
    #     mp.set_start_method('spawn')
    #  AttributeError: 'module' object has no attribute 'set_start_method'
    "mnist_hogwild",

    # FIXME
    #   IOError: [E050] Can't find model 'en'.
    #   It doesn't seem to be a shortcut link, a Python package or a valid path to a data directory.
    "snli",

    # FIXME
    #  test_community_repos/external_projects/gpytorch/run.sh: line 12:   896 Segmentation fault
    #  (core dumped) python -m unittest
    "gpytorch",

    # ========================
    # External projects

    # FIXME fails with no specific error message:
    # https://circleci.com/gh/pytorch/builder/1992?utm_campaign=vcs-integration-link&utm_medium=referral&utm_source=github-build-link
    "OpenNMT",

    # FIXME fails with flaky tests:
    "allennlp",

    # FIXME Too long with no output (exceeded 10m0s)
    "cyclegan",

    # FIXME
    #  E   ImportError: /lib64/libstdc++.so.6: version `GLIBCXX_3.4.20' not found (required by
    #  /opt/conda/envs/env3.7/lib/python3.7/site-packages/torch_scatter/scatter_cpu.cpython-37m-x86_64-linux-gnu.so)
    "geometric",

    # FIXME (on pytorch_test_linux_conda_py3.7_cu100)
    #    File "/tmp/20188/block/block.py", line 100
    #     if (i==j):   tup = (*tup, main[i])
    #                         ^
    #   SyntaxError: invalid syntax
    "block",

    # FIXME
    #  Works but too many unit tests (takes too long)
    "pyro",

    # FIXME
    #  TypeError: likelihood_i() got an unexpected keyword argument 'noise'
    "botorch",

    # FIXME
    #  Failed test "test_purge" (for CPU build)
    #  AssertionError: should have failed with non-writable path
    "fastai",
])


def generate_subdirectory_paths(parent_directory):
    """
    Generate the tests, one for each repo
    """
    current_directory = os.path.abspath(os.getcwd())
    print("current_directory:", current_directory)
    return sorted([
        os.path.normpath(os.path.join(parent_directory, o))
        for o in os.listdir(parent_directory)
        if os.path.isdir(os.path.join(parent_directory, o))
        and os.path.exists(os.path.join(parent_directory, o, "run.sh"))
        and o not in BLACKLISTED_TEST_DIRS
    ])


def wrap_conditional_steps(parameter_name, original_step_dicts):
    return {
        "when": {
            "condition": "<< parameters.%s >>" % parameter_name,
            "steps": original_step_dicts,
        }
    }


def render_step(test_name_prefix, testdir):

    runner_cmd = os.path.join(testdir, "run.sh")

    wrapper_args = [
        "<< parameters.script-wrapper >>",
        runner_cmd,
    ]

    testname = os.path.basename(testdir)

    raw_step = {
        "run": {
            "name": test_name_prefix + ": " + testname,
            "command": " ".join(wrapper_args),
            "no_output_timeout": 600,
        }
    }

    conditional_parm = None

    # Don't run these tests with Python 2.7
    if testname in ["mnist_hogwild"]:
        conditional_parm = PARMNAME_IS_PYTHON_3

    wrapped_step = wrap_conditional_steps(conditional_parm, [raw_step]) if conditional_parm else raw_step

    return wrapped_step


def gen_command_steps_for_subdir():

    example_subdirs = generate_subdirectory_paths("test_community_repos/examples")

    external_project_subdirs = generate_subdirectory_paths("test_community_repos/external_projects")

    external_projects_steps = []
    for testdir in external_project_subdirs:
        external_projects_steps.append(render_step("External project", testdir))

    steps_list = []

    if False:  # TODO restore this!
        for testdir in example_subdirs:
            steps_list.append(render_step("Example test", testdir))

    steps_list.append(wrap_conditional_steps(PARMNAME_RUN_EXTERNAL_PROJECTS, external_projects_steps))

    return {
        "description": "PyTorch examples",
        "steps": steps_list,
        "parameters": {
            "script-wrapper": {
                "type": "string",
                "default": "",
                "description": "A command to which the script will be passed as an argument",
            },
            PARMNAME_IS_PYTHON_3: {
                "type": "boolean",
                "default": False,
                "description": "Whether this is Python 3",
            },
            PARMNAME_RUN_EXTERNAL_PROJECTS: {
                "type": "boolean",
                "default": False,
                "description": "Should external projects be run?",
            },
        },
    }


def gen_commands():
    commands_dict = {
        "run_integration_tests": gen_command_steps_for_subdir(),
    }

    return indent(2, commands_dict)


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
        f.write(env.get_template('config.in.yml').render(
            workflows=workflows,
            gen_commands=gen_commands
        ))
