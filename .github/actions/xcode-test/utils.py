"""Small helpers shared by the test runner and simulator selector."""

import shlex
import subprocess


def command(*args, capture=False):
    """Log and run a command, returning stdout only when the caller requests it."""
    print("+ " + shlex.join(args), flush=True)
    result = subprocess.run(args, check=True, stdout=subprocess.PIPE if capture else None)
    return result.stdout if capture else None


def version(value):
    """Turn up to three numeric components into a tuple for numeric ordering."""
    parts = tuple(int(n) for n in value.split("."))
    return (parts + (0, 0, 0))[:3]
