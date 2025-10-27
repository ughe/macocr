import json
import pathlib
import subprocess
import sys
import typing as t

def macocr(image_path: str, accurate: bool = True, fix: bool = False) -> t.List[t.Dict]:
    """Run macocr on input image and return JSON results.
Utilizes the VNRecognizeTextRequest API on macOS only.
https://developer.apple.com/documentation/vision/vnrecognizetextrequest"""
    binary = pathlib.Path(__file__).parent / "bin" / "macocr"
    cmd = [str(binary)]
    if not accurate:
        cmd.append("--fast")
    if fix:
        cmd.append("--fix")

    cmd.append("--json")
    cmd.append(image_path)

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return json.loads(result.stdout.strip())
    except:
        print(f"Unexpected failure in macocr binary command: {' '.join(cmd)}", file=sys.stderr)
        return None
