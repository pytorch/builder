#!/usr/bin/env python3

import subprocess
import json
from multiprocessing.pool import ThreadPool
import tqdm
from distutils.version import LooseVersion
import argparse

import regenerate
import html_stuff


THREAD_POOL_SIZE = 4


TEST_STEP_PREFIXES = [
    regenerate.STEP_PREFIX_EXAMPLE_TEST,
    regenerate.STEP_PREFIX_EXTERNAL_PROJECT,
]


class JobInfo:
    def __init__(self, job_name, steps, url, status):
        self.job_name = job_name
        self.steps = steps
        self.url = url
        self.status = status

    def is_running(self):
        return self.status == "running"


class StepInfo:
    def __init__(self, step_name, status, url, runtime):
        self.step_name = step_name
        self.status = status
        self.url = url
        self.runtime_millis = runtime


def process_single_build(line):

    cmd2 = "curl -s https://circleci.com/api/v1.1/project/github/%s" % line
    print("About to curl:", cmd2)

    circleci_output = subprocess.check_output(cmd2, shell=True).decode('utf-8')

    job_info = json.loads(circleci_output)
    job_name = job_info.get("build_parameters").get("CIRCLE_JOB")
    build_url = job_info.get("build_url")
    job_status = job_info.get("status")

    job_steps = []
    for x in job_info.get("steps"):
        last_action = x.get("actions", [])[-1]
        runtime = last_action["run_time_millis"]

        step_url = "https://app.circleci.com/jobs/github/%s/parallel-runs/0/steps/%d-%d" % \
                   (line, last_action["index"], last_action["step"])

        job_steps.append(StepInfo(x.get("name"), last_action["status"], step_url, runtime))

    return JobInfo(job_name, job_steps, build_url, job_status)


def generate_table(tests_by_job_name, job_objects_by_job_name, all_test_steps, commit_sha1):

    inner_html = ""

    sorted_test_name_tuples = sorted(all_test_steps.items(), key=lambda x: (x[1], x[0]))
    header_elements = [html_stuff.html_tag("th", "Status"), html_stuff.html_tag("th", "Job name")]
    for test_name, _ in sorted_test_name_tuples:

        cell_color = "#ffd" if all_test_steps.get(test_name) == regenerate.STEP_PREFIX_EXAMPLE_TEST else "#fdf"
        cell_style = "background-color: %s" % cell_color
        header_elements.append(html_stuff.html_tag("th", test_name, {"style": cell_style}))

    inner_html += html_stuff.table_row(header_elements)

    for job_name, job_specific_tests_dict in sorted(tests_by_job_name.items(), key=lambda x: LooseVersion(x[0])):

        job_object = job_objects_by_job_name[job_name]

        job_background = "yellow" if job_object.is_running() else "white"
        test_results_html_list = [
            html_stuff.html_tag("td", job_object.status, {"style": "background-color: %s" % job_background}),
            html_stuff.html_tag("th", html_stuff.link(job_name, job_object.url), {"style": "text-align: right"}),
        ]

        for test_name, _ in sorted_test_name_tuples:
            cell_content = "?"
            cell_link = cell_content
            background_string = "none"
            if test_name in job_specific_tests_dict:
                test_obj = job_specific_tests_dict[test_name]

                if test_obj.status == "success":
                    cell_content = "&#10004;"
                    background_string = "#8f8"

                elif test_obj.status == "timedout":
                    cell_content = "&#9200;"
                    background_string = "#88f"

                elif test_obj.status == "running":
                    cell_content = "&#8987;"
                    background_string = "#ff8"

                else:
                    cell_content = "&#10060;"
                    background_string = "#f88"

                # Can be None if the test hasn't finished
                if test_obj.runtime_millis is not None:
                    cell_content += "<br/>%d sec" % (test_obj.runtime_millis / 1000)

                cell_link = html_stuff.link(cell_content, test_obj.url)

            cell_style = "text-align: center; background: %s" % background_string
            test_results_html_list.append(html_stuff.html_tag("td", cell_link, {"style": cell_style}))

        inner_html += html_stuff.table_row(test_results_html_list)

    tbody = html_stuff.html_tag("tbody", inner_html)
    table_html = html_stuff.html_tag("table", tbody, {"style": "border-collapse: collapse;"})

    html_head = html_stuff.html_tag("head", html_stuff.html_tag("style", html_stuff.BODY_STYLESHEET))

    code_link = html_stuff.link(commit_sha1, "https://github.com/pytorch/builder/commits/" + commit_sha1)
    header_text = " ".join([
        "Test results for",
        html_stuff.html_tag("code", "pytorch/builder"),
        "commit",
        html_stuff.html_tag("code", code_link),
    ])

    body_header = html_stuff.html_tag("p", header_text)
    body_content = body_header + table_html
    html_body = html_stuff.html_tag("body", body_content, {"style": "font-family: sans-serif;"})
    return html_stuff.html_tag("html", html_head + html_body)


def go(commit_sha1, maybe_authtoken):
    curl_auth_args = ["-H", '"Authorization: token %s"' % maybe_authtoken] if maybe_authtoken else []

    curl_command = " ".join([
        "curl",
        "-s",
    ] + curl_auth_args + [
        "https://api.github.com/repos/pytorch/builder/commits/%s/status" % commit_sha1,
    ])

    curl_pipeline = [
        curl_command,
        "jq -r .statuses[].target_url",
        "cut -d'?' -f1",
        "cut -d/ -f5-",
        "grep pytorch",
    ]

    cmd = " | ".join(curl_pipeline)
    github_output = subprocess.check_output(cmd, shell=True).decode('utf-8')

    build_specs = github_output.splitlines()

    pool = ThreadPool(THREAD_POOL_SIZE)

    # Forces to a list to get the progress bar to print right away
    all_job_infos = list(tqdm.tqdm(pool.imap_unordered(process_single_build, build_specs), total=len(build_specs)))

    all_test_steps = {}
    tests_by_job_name = {}
    job_objects_by_job_name = {}
    for job_info in all_job_infos:

        job_objects_by_job_name[job_info.job_name] = job_info

        tests_for_job = tests_by_job_name.setdefault(job_info.job_name, {})
        for step_obj in job_info.steps:
            for test_step_prefix in TEST_STEP_PREFIXES:
                full_prefix = test_step_prefix + regenerate.TEST_NAME_PREFIX_SEPARATOR
                if step_obj.step_name.startswith(full_prefix):
                    stripped_test_name = step_obj.step_name[len(full_prefix):]
                    all_test_steps[stripped_test_name] = test_step_prefix
                    tests_for_job[stripped_test_name] = step_obj

    filtered_job_results_dict = {k: v for k, v in tests_by_job_name.items() if v}
    html = generate_table(filtered_job_results_dict, job_objects_by_job_name, all_test_steps, commit_sha1)
    with open("test-results.html", "w") as output_fh:
        output_fh.write(html)


def get_cli_args():
    parser = argparse.ArgumentParser(
        description='Regenerate CircleCI config',
        epilog='Suggested usage: .circleci/get_build_results.py $(git rev-parse HEAD)')
    parser.add_argument('builder_repo_revision', metavar='BUILDER_SHA1', type=str, nargs='?',
                        help='Commit SHA1 of pytorch/builder repo')
    parser.add_argument('--github-auth-token', type=str,
                        help="GitHub auth token in case API is rate-limited. If you don't have one, visit "
                             "https://github.com/settings/tokens and grant it the \"repo:status\" scope.")

    return parser.parse_args()


if __name__ == "__main__":
    options = get_cli_args()

    sha1 = options.builder_repo_revision
    if not sha1:
        sha1 = subprocess.check_output("git rev-parse HEAD", shell=True).decode('utf-8').strip()

    print("Fetching build results for commit \"%s\" of pytorch/builder repo..." % sha1)
    go(sha1, options.github_auth_token)
