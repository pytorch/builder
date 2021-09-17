#!/usr/bin/env python3

from datetime import datetime, timedelta
from typing import Any, Dict, List, Iterable, Optional, Union
from urllib.request import urlopen, Request
from urllib.error import HTTPError
import json
import enum
import os


class IssueState(enum.Enum):
    OPEN = "open"
    CLOSED = "closed"
    ALL = "all"

    def __str__(self):
        return self.value


class GitCommit:
    commit_hash: str
    title: str
    body: str
    author: str
    author_date: datetime
    commit_date: Optional[datetime]

    def __init__(self,
                 commit_hash: str,
                 author: str,
                 author_date: datetime,
                 title: str,
                 body: str,
                 commit_date: Optional[datetime] = None) -> None:
        self.commit_hash = commit_hash
        self.author = author
        self.author_date = author_date
        self.commit_date = commit_date
        self.title = title
        self.body = body

    def __contains__(self, item: Any) -> bool:
        return item in self.body or item in self.title


def get_revert_revision(commit: GitCommit) -> Optional[str]:
    import re
    rc = re.match("Revert (D\\d+):", commit.title)
    if rc is None:
        return None
    return rc.group(1)


def get_diff_revision(commit: GitCommit) -> Optional[str]:
    import re
    rc = re.search("\\s*Differential Revision: (D\\d+)", commit.body)
    if rc is None:
        return None
    return rc.group(1)


def is_revert(commit: GitCommit) -> bool:
    return get_revert_revision(commit) is not None


def parse_medium_format(lines: Union[str, List[str]]) -> GitCommit:
    """
    Expect commit message generated using `--format=medium --date=unix` format, i.e.:
        commit <sha1>
        Author: <author>
        Date:   <author date>

        <title line>

        <full commit message>

    """
    if isinstance(lines, str):
        lines = lines.split("\n")
    # TODO: Handle merge commits correctly
    if len(lines) > 1 and lines[1].startswith("Merge:"):
        del lines[1]
    assert len(lines) > 5
    assert lines[0].startswith("commit")
    assert lines[1].startswith("Author: ")
    assert lines[2].startswith("Date: ")
    assert len(lines[3]) == 0
    return GitCommit(commit_hash=lines[0].split()[1].strip(),
                     author=lines[1].split(":", 1)[1].strip(),
                     author_date=datetime.fromtimestamp(int(lines[2].split(":", 1)[1].strip())),
                     title=lines[4].strip(),
                     body="\n".join(lines[5:]),
                     )


def parse_fuller_format(lines: Union[str, List[str]]) -> GitCommit:
    """
    Expect commit message generated using `--format=fuller --date=unix` format, i.e.:
        commit <sha1>
        Author:     <author>
        AuthorDate: <author date>
        Commit:     <committer>
        CommitDate: <committer date>

        <title line>

        <full commit message>

    """
    if isinstance(lines, str):
        lines = lines.split("\n")
    # TODO: Handle merge commits correctly
    if len(lines) > 1 and lines[1].startswith("Merge:"):
        del lines[1]
    assert len(lines) > 7
    assert lines[0].startswith("commit")
    assert lines[1].startswith("Author: ")
    assert lines[2].startswith("AuthorDate: ")
    assert lines[3].startswith("Commit: ")
    assert lines[4].startswith("CommitDate: ")
    assert len(lines[5]) == 0
    return GitCommit(commit_hash=lines[0].split()[1].strip(),
                     author=lines[1].split(":", 1)[1].strip(),
                     author_date=datetime.fromtimestamp(int(lines[2].split(":", 1)[1].strip())),
                     commit_date=datetime.fromtimestamp(int(lines[4].split(":", 1)[1].strip())),
                     title=lines[6].strip(),
                     body="\n".join(lines[7:]),
                     )


def _check_output(items: List[str], encoding='utf-8') -> str:
    from subprocess import check_output
    return check_output(items).decode(encoding)


def get_git_remotes(path: str) -> Dict[str, str]:
    keys = _check_output(["git", "-C", path, "remote"]).strip().split("\n")
    return {key: _check_output(["git", "-C", path, "remote", "get-url", key]).strip() for key in keys}


class GitRepo:
    def __init__(self, path, remote='upstream'):
        self.repo_dir = path
        self.remote = remote

    def _run_git_log(self, revision_range) -> List[GitCommit]:
        log = _check_output(['git', '-C', self.repo_dir, 'log',
                             '--format=fuller', '--date=unix', revision_range, '--', '.']).split("\n")
        rc: List[GitCommit] = []
        cur_msg: List[str] = []
        for line in log:
            if line.startswith("commit"):
                if len(cur_msg) > 0:
                    rc.append(parse_fuller_format(cur_msg))
                    cur_msg = []
            cur_msg.append(line)
        if len(cur_msg) > 0:
            rc.append(parse_fuller_format(cur_msg))
        return rc

    def get_commit_list(self, from_ref, to_ref) -> List[GitCommit]:
        return self._run_git_log(f"{self.remote}/{from_ref}..{self.remote}/{to_ref}")


def build_commit_dict(commits: List[GitCommit]) -> Dict[str, GitCommit]:
    rc = {}
    for commit in commits:
        assert commit.commit_hash not in rc
        rc[commit.commit_hash] = commit
    return rc


def fetch_json(url: str, params: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
    headers = {'Accept': 'application/vnd.github.v3+json'}
    token = os.environ.get("GITHUB_TOKEN")
    if token is not None and url.startswith('https://api.github.com/'):
        headers['Authorization'] = f'token {token}'
    if params is not None and len(params) > 0:
        url += '?' + '&'.join(f"{name}={val}" for name, val in params.items())
    try:
        with urlopen(Request(url, headers=headers)) as data:
            return json.load(data)
    except HTTPError as err:
        if err.code == 403 and all(key in err.headers for key in ['X-RateLimit-Limit', 'X-RateLimit-Used']):
            print(f"Rate limit exceeded: {err.headers['X-RateLimit-Used']}/{err.headers['X-RateLimit-Limit']}")
        raise


def fetch_multipage_json(url: str, params: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
    if params is None:
        params = {}
    assert "page" not in params
    page_idx, rc, prev_len, params = 1, [], -1, params.copy()
    while len(rc) > prev_len:
        prev_len = len(rc)
        params["page"] = page_idx
        page_idx += 1
        rc += fetch_json(url, params)
    return rc


def gh_get_milestones(org='pytorch', project='pytorch', state: IssueState = IssueState.OPEN) -> List[Dict[str, Any]]:
    url = f'https://api.github.com/repos/{org}/{project}/milestones'
    return fetch_multipage_json(url, {"state": state})


def gh_get_milestone_issues(org: str, project: str, milestone_idx: int, state: IssueState = IssueState.OPEN):
    url = f'https://api.github.com/repos/{org}/{project}/issues'
    return fetch_multipage_json(url, {"milestone": milestone_idx, "state": state})


def gh_get_ref_statuses(org: str, project: str, ref: str) -> Dict[str, Any]:
    url = f'https://api.github.com/repos/{org}/{project}/commits/{ref}/status'
    params = {"page": 1, "per_page": 100}
    nrc = rc = fetch_json(url, params)
    while "statuses" in nrc and len(nrc["statuses"]) == 100:
        params["page"] += 1
        nrc = fetch_json(url, params)
        if "statuses" in nrc:
            rc["statuses"] += nrc["statuses"]
    return rc


def extract_statuses_map(json: Dict[str, Any]):
    return {s["context"]: s["state"] for s in json["statuses"]}


class PeriodStats:
    commits: int
    reverts: int
    authors: int
    date: datetime

    def __init__(self, date: datetime, commits: int, reverts: int, authors: int) -> None:
        self.date = date
        self.commits = commits
        self.reverts = reverts
        self.authors = authors


def get_monthly_stats(commits: List[GitCommit]) -> Iterable[PeriodStats]:
    y, m, total, reverts, authors = None, None, 0, 0, set()
    for commit in commits:
        commit_date = commit.commit_date if commit.commit_date is not None else commit.author_date
        if y != commit_date.year or m != commit_date.month:
            if y is not None:
                yield PeriodStats(datetime(y, m, 1), total, reverts, len(authors))
            y, m, total, reverts, authors = commit_date.year, commit_date.month, 0, 0, set()
        if is_revert(commit):
            reverts += 1
        total += 1
        authors.add(commit.author)


def print_monthly_stats(commits: List[GitCommit]) -> None:
    stats = list(get_monthly_stats(commits))
    for idx, stat in enumerate(stats):
        y = stat.date.year
        m = stat.date.month
        total, reverts, authors = stat.commits, stat.reverts, stat.authors
        reverts_ratio = 100.0 * reverts / total
        if idx + 1 < len(stats):
            commits_growth = 100.0 * (stat.commits / stats[idx + 1].commits - 1)
        else:
            commits_growth = float('nan')
        print(f"{y}-{m:02d}: commits {total} ({commits_growth:+.1f}%)  reverts {reverts} ({reverts_ratio:.1f}%) authors {authors}")


def analyze_reverts(commits: List[GitCommit]):
    for idx, commit in enumerate(commits):
        revert_id = get_revert_revision(commit)
        if revert_id is None:
            continue
        orig_commit = None
        for i in range(1, 100):
            orig_commit = commits[idx + i]
            if get_diff_revision(orig_commit) == revert_id:
                break
        if orig_commit is None:
            print(f"Failed to find original commit for {commit.title}")
            continue
        print(f"{commit.commit_hash} is a revert of {orig_commit.commit_hash}: {orig_commit.title}")
        revert_statuses = gh_get_ref_statuses("pytorch", "pytorch", commit.commit_hash)
        orig_statuses = gh_get_ref_statuses("pytorch", "pytorch", orig_commit.commit_hash)
        orig_sm = extract_statuses_map(orig_statuses)
        revert_sm = extract_statuses_map(revert_statuses)
        for k in revert_sm.keys():
            if k not in orig_sm:
                continue
            if orig_sm[k] != revert_sm[k]:
                print(f"{k} {orig_sm[k]}->{revert_sm[k]}")


def print_contributor_stats(commits, delta: Optional[timedelta] = None) -> None:
    authors: Dict[str, int] = {}
    now = datetime.now()
    # Default delta is one non-leap year
    if delta is None:
        delta = timedelta(days=365)
    for commit in commits:
        date, author = commit.commit_date, commit.author
        if now - date > delta:
            break
        if author not in authors:
            authors[author] = 0
        authors[author] += 1

    print(f"{len(authors)} contributors made {sum(authors.values())} commits in last {delta.days} days")
    for count, author in sorted(((commit, author) for author, commit in authors.items()), reverse=True):
        print(f"{author}: {count}")


def commits_missing_in_branch(repo: GitRepo, branch: str, orig_branch: str, milestone_idx: int) -> None:
    def get_commits_dict(x, y):
        return build_commit_dict(repo.get_commit_list(x, y))
    master_commits = get_commits_dict(orig_branch, 'master')
    release_commits = get_commits_dict(orig_branch, branch)
    print(f"len(master_commits)={len(master_commits)}")
    print(f"len(release_commits)={len(release_commits)}")
    print("URL;Title;Status")
    for issue in gh_get_milestone_issues('pytorch', 'pytorch', milestone_idx, IssueState.ALL):
        html_url, state = issue["html_url"], issue["state"]
        # Skip closed states if they were landed before merge date
        if state == "closed":
            mentioned_after_cut = any(html_url in commit_message for commit_message in master_commits.values())
            # If issue is not mentioned after cut, that it must be present in release branch
            if not mentioned_after_cut:
                continue
            mentioned_in_release = any(html_url in commit_message for commit_message in release_commits.values())
            # if Issue is mentioned is release branch, than it was picked already
            if mentioned_in_release:
                continue
        print(f'{html_url};{issue["title"]};{state}')


def parse_arguments():
    from argparse import ArgumentParser
    parser = ArgumentParser(description="Print GitHub repo stats")
    parser.add_argument("--repo-path",
                        type=str,
                        help="Path to PyTorch git checkout",
                        default=os.path.expanduser("~/git/pytorch/pytorch"))
    parser.add_argument("--milestone-id", type=str)
    parser.add_argument("--branch", type=str)
    parser.add_argument("--remote",
                        type=str,
                        help="Remote to base off of",
                        default="")
    parser.add_argument("--analyze-reverts", action="store_true")
    parser.add_argument("--contributor-stats", action="store_true")
    parser.add_argument("--missing-in-branch", action="store_true")
    return parser.parse_args()


def main():
    import time
    args = parse_arguments()
    remote = args.remote
    if not remote:
        remotes = get_git_remotes(args.repo_path)
        # Pick best remote
        remote = next(iter(remotes.keys()))
        for key in remotes:
            if remotes[key].endswith('github.com/pytorch/pytorch'):
                remote = key

    repo = GitRepo(args.repo_path, remote)

    if args.missing_in_branch:
        # Use milestone idx or search it along milestone titles
        try:
            milestone_idx = int(args.milestone_id)
        except ValueError:
            milestone_idx = -1
            milestones = gh_get_milestones()
            for milestone in milestones:
                if milestone.get('title', '') == args.milestone_id:
                    milestone_idx = int(milestone.get('number', '-2'))
            if milestone_idx < 0:
                print(f'Could not find milestone {args.milestone_id}')
                return

        commits_missing_in_branch(repo,
                                  args.branch,
                                  f'orig/{args.branch}',
                                  milestone_idx)
        return

    print(f"Parsing git history with remote {remote}...", end='', flush=True)
    start_time = time.time()
    x = repo._run_git_log(f"{remote}/master")
    print(f"done in {time.time()-start_time:.1f} sec")
    if args.analyze_reverts:
        analyze_reverts(x)
    elif args.contributor_stats:
        print_contributor_stats(x)
    else:
        print_monthly_stats(x)


if __name__ == "__main__":
    main()
