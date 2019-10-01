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
import argparse


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


BLACKLISTED_TEST_DIRS = {
    # FIXME
    #  Works but too many unit tests (takes too long)
    "pyro",
}


def get_applicable_os_list(btype):
    os_list = ["macos"]
    if btype != "wheel":
        os_list.extend([
            "linux",  # TODO Get linux working with CUDA for wheels
            "win",
        ])

    return os_list


PARMNAME_IS_PYTHON_3 = "is-python3"
PARMNAME_IS_MACOS = "is-macos"
PARMNAME_RUN_EXTERNAL_PROJECTS = "run-external-projects"


STEP_PREFIX_EXAMPLE_TEST = "Example"
STEP_PREFIX_EXTERNAL_PROJECT = "Project"
TEST_NAME_PREFIX_SEPARATOR = ": "


def get_unicode_variants(btype, python_version):
    return [False, True] if btype == "wheel" and python_version == "2.7" else [False]


def generate_workflows(category, prefix='', indentation=6):
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

    if os_type == "macos":
        d[PARMNAME_IS_MACOS] = True

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


def generate_subdirectory_paths(parent_directory, whitelisted_tests=None):
    """
    Generate the tests, one for each repo.

    The whitelist is for local test only (using command-line args).
    The whitelist takes precendence over a blacklist.
    """
    current_directory = os.path.abspath(os.getcwd())
    print("current_directory:", current_directory)

    def predicate_whitelists_and_blacklists(test_name):
        if whitelisted_tests:
            return test_name in whitelisted_tests
        else:
            return test_name not in BLACKLISTED_TEST_DIRS

    return sorted([
        os.path.normpath(os.path.join(parent_directory, o))
        for o in os.listdir(parent_directory)
        if os.path.isdir(os.path.join(parent_directory, o))
        and os.path.exists(os.path.join(parent_directory, o, "run.sh"))
        and predicate_whitelists_and_blacklists(o)
    ])


def wrap_conditional_steps(parameter_name, original_step_dicts, invert_boolean=False):
    keyword = "unless" if invert_boolean else "when"
    return {
        keyword: {
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
            "name": test_name_prefix + TEST_NAME_PREFIX_SEPARATOR + testname,
            "command": " ".join(wrapper_args),
            "no_output_timeout": 600,
            # forces every test to run, even if the previous fails:
            "when": "always",
        }
    }

    conditional_parm = None
    conditional_inversion = False

    # Don't run these tests with Python 2.7
    if testname in ["mnist_hogwild"]:
        conditional_parm = PARMNAME_IS_PYTHON_3

    # Runs out of disk space on MacOS when downloading many-GB file
    if testname in ["fast_neural_style"]:
        conditional_parm = PARMNAME_IS_MACOS
        conditional_inversion = True

    conditional_step = wrap_conditional_steps(conditional_parm, [raw_step], conditional_inversion)
    wrapped_step = conditional_step if conditional_parm else raw_step

    return wrapped_step


def gen_command_steps_for_subdir(whitelisted_tests):
    """
    Whitelist may be empty.
    """

    example_subdirs = generate_subdirectory_paths("test_community_repos/examples", whitelisted_tests)

    external_project_subdirs = generate_subdirectory_paths("test_community_repos/external_projects", whitelisted_tests)

    external_projects_steps = []
    for testdir in external_project_subdirs:
        external_projects_steps.append(render_step(STEP_PREFIX_EXTERNAL_PROJECT, testdir))

    steps_list = []
    for testdir in example_subdirs:
        steps_list.append(render_step(STEP_PREFIX_EXAMPLE_TEST, testdir))

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
            PARMNAME_IS_MACOS: {
                "type": "boolean",
                "default": False,
                "description": "Whether this is operating system is MacOS",
            },
            PARMNAME_RUN_EXTERNAL_PROJECTS: {
                "type": "boolean",
                "default": False,
                "description": "Should external projects be run?",
            },
        },
    }


def gen_commands(whitelisted_tests):
    commands_dict = {
        "run_integration_tests": gen_command_steps_for_subdir(whitelisted_tests),
    }

    return indent(2, commands_dict)


def indent(indentation, data_list):
    return ("\n" + " " * indentation).join(yaml.dump(data_list).splitlines())


def get_cli_args():
    parser = argparse.ArgumentParser(description='Regenerate CircleCI config')
    parser.add_argument('whitelisted_tests', metavar='TESTS', type=str, nargs='*',
                        help='Whitelisted tests for local invocation')
    return parser.parse_args()


if __name__ == "__main__":
    d = os.path.dirname(__file__)
    env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(d),
        lstrip_blocks=True,
        autoescape=False,
    )

    options = get_cli_args()
    generated_commands = gen_commands(options.whitelisted_tests)

    with open(os.path.join(d, 'config.yml'), 'w') as f:
        f.write(env.get_template('config.in.yml').render(
            workflows_standard=generate_workflows("pytorch_test"),
            workflows_nightly=generate_workflows("pytorch_test", prefix="nightly"),
            generated_commands=generated_commands
        ))
