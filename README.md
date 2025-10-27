# macocr

OCR command line utility for macOS 10.15+. Utilizes the [VNRecognizeTextRequest](https://developer.apple.com/documentation/vision/vnrecognizetextrequest) API.

## Build and Run

```
swift build
swift run
```

If `-c release` is not used, then the executable may be located at: `./.build/debug/macocr`

## Python Build and Run

```
pip install git+https://github.com/ughe/macocr.git
# or locally: cd macocr && pip install -e .
```

usage:

```
from macocr_py import macocr
result_json = macocr("./input.png")
```
