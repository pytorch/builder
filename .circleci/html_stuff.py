#!/usr/bin/env python3


BODY_STYLESHEET = """
table, th, td {border: 1px solid black; padding: 0.2em; font-size: 80%;}
a:link {
  text-decoration: none;
}

a:visited {
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}

a:active {
  text-decoration: underline;
}
"""


def format_attrs(attrs_dict):
    x = []
    for k, v in sorted(attrs_dict.items()):
        x.append('%s="%s"' % (k, v))

    return " ".join(x)


def link(text, url):
    return html_tag("a", text, {"href": url})


def bracket(stuff):
    return "<" + stuff + ">"


def html_tag(name, content, attrs=None):
    attrs_string = " " + format_attrs(attrs) if attrs else ""
    return bracket(name + attrs_string) + content + bracket("/" + name)


def table_row(items):
    return html_tag("tr", "".join(items))
