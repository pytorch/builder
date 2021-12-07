#!/usr/bin/env python3

from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Dict, Set, List, Iterable

import jinja2
import json
import os
import sys
from typing_extensions import Literal

YamlShellBool = Literal["''", 1]
Arch = Literal["windows", "linux", "macos"]

GITHUB_DIR = Path(__file__).resolve().parent.parent

@dataclass
class BuildConfiguration:
    python_version: str
    gpu_arch_type: str
    gpu_arch_version: str


@dataclass
class CIWorkflow:
    # Required fields
    build_environment: str

    # Optional fields
    build_configs: List[BuildConfiguration]

    def __post_init__(self) -> None:
        self.assert_valid()

    def assert_valid(self) -> None:
        pass

    def generate_workflow_file(self, workflow_template: jinja2.Template) -> None:
        output_file_path = GITHUB_DIR / f"workflows/generated-{self.build_environment}.yml"
        with open(output_file_path, "w") as output_file:
            GENERATED = "generated"  # Note that please keep the variable GENERATED otherwise phabricator will hide the whole file
            output_file.writelines([f"# @{GENERATED} DO NOT EDIT MANUALLY\n"])
            try:
                content = workflow_template.render(asdict(self))
            except Exception as e:
                print(f"Failed on template: {workflow_template}", file=sys.stderr)
                raise e
            output_file.write(content)
            if content[-1] != "\n":
                output_file.write("\n")
        print(output_file_path)

def main() -> None:
    jinja_env = jinja2.Environment(
        variable_start_string="!{{",
        loader=jinja2.FileSystemLoader(str(GITHUB_DIR.joinpath("templates"))),
        undefined=jinja2.StrictUndefined,
    )
    template_and_workflows = [
        (jinja_env.get_template("android_ci_workflow.yml.j2"), ANDROID_WORKFLOWS),
    ]
    # Delete the existing generated files first, this should align with .gitattributes file description.
    existing_workflows = GITHUB_DIR.glob("workflows/generated-*")
    for w in existing_workflows:
        try:
            os.remove(w)
        except Exception as e:
            print(f"Error occurred when deleting file {w}: {e}")

    ciflow_ruleset = CIFlowRuleset()
    for template, workflows in template_and_workflows:
        # added Iterable check to appease the mypy gods
        if not isinstance(workflows, Iterable):
            raise Exception(f"How is workflows not iterable? {workflows}")
        for workflow in workflows:
            workflow.generate_workflow_file(workflow_template=template)
            ciflow_ruleset.add_label_rule(workflow.ciflow_config.labels, workflow.build_environment)
    ciflow_ruleset.generate_json()


if __name__ == "__main__":
    main()
