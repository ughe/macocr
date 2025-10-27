import Cocoa
import Vision

// https://developer.apple.com/documentation/vision/vnrecognizetextrequest

var MODE = VNRequestTextRecognitionLevel.accurate
var USE_LANG_CORRECTION = false
var REVISION:Int
if #available(macOS 13, *) {
    REVISION = VNRecognizeTextRequestRevision3
} else if #available(macOS 11, *) {
    REVISION = VNRecognizeTextRequestRevision2
} else {
    REVISION = VNRecognizeTextRequestRevision1
}

func main(args: [String]) -> Int32 {
    var argIndex = 1
    var outputJSON = false
    var minTextHeight: Float?
    var customWords: [String] = []

    // Parse flags
    while argIndex < args.count && args[argIndex].hasPrefix("-") {
        let flag = args[argIndex]

        switch flag {
        case "-j", "--json":
            outputJSON = true
            argIndex += 1
        case "--version":
            print("VNRecognizeTextRequest Revision \(REVISION)")
            return 0
        case "--fast":
            MODE = .fast
            argIndex += 1
        case "--fix":
            USE_LANG_CORRECTION = true
            argIndex += 1
        case "--min-text-height":
            guard argIndex + 1 < args.count else {
                fputs("Error: --min-text-height requires a value\n", stderr)
                return 1
            }
            if let value = Float(args[argIndex + 1]) {
                minTextHeight = value
            } else {
                fputs("Error: invalid --min-text-height value\n", stderr)
                return 1
            }
            argIndex += 2
        case "--custom-word-file":
            guard argIndex + 1 < args.count else {
                fputs("Error: --custom-word-file requires a path\n", stderr)
                return 1
            }
            let wordFile = args[argIndex + 1]
            if let contents = try? String(contentsOfFile: wordFile, encoding: .utf8) {
                customWords = contents.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            } else {
                fputs("Error: failed to read custom word file '\(wordFile)'\n", stderr)
                return 1
            }
            argIndex += 2
        default:
            fputs("Error: unknown flag '\(flag)'\n", stderr)
            return 1
        }
    }

    guard args.count >= argIndex + 1 else {
        fputs(String(format: "usage: %1$@ [flags] image [dst]\n", args[0]), stderr)
        fputs("flags:\n", stderr)
        fputs("  -j, --json              Output in JSON format\n", stderr)
        fputs("  --version               Print revision number\n", stderr)
        fputs("  --fast                  Use fast recognition (default: accurate)\n", stderr)
        fputs("  --fix                   Enable language correction (default: off)\n", stderr)
        fputs("  --min-text-height N     Set minimum text height (0-1)\n", stderr)
        fputs("  --custom-word-file FILE Load custom words from file\n", stderr)
        return 1
    }

    let src = args[argIndex]
    let dst = args.count > argIndex + 1 ? args[argIndex + 1] : nil

    guard let img = NSImage(byReferencingFile: src) else {
        fputs("Error: failed to load image '\(src)'\n", stderr)
        return 1
    }

    guard let imgRef = img.cgImage(forProposedRect: &img.alignmentRect, context: nil, hints: nil) else {
        fputs("Error: failed to convert NSImage to CGImage for '\(src)'\n", stderr)
        return 1
    }

    let imgHeight = CGFloat(imgRef.height)

    let request = VNRecognizeTextRequest { (request, error) in
        let observations = request.results as? [VNRecognizedTextObservation] ?? []

        let output: String

        if outputJSON {
            var jsonLines: [String] = ["["]

            for (index, observation) in observations.enumerated() {
                guard let candidate = observation.topCandidates(1).first else { continue }
                let bbox = observation.boundingBox

                // Convert normalized coordinates (0-1) to pixel coordinates
                // Vision uses bottom-left origin, y needs to be flipped
                let x = Int(bbox.minX * CGFloat(imgRef.width))
                let y = Int((1 - bbox.maxY) * imgHeight) // Flip y-axis
                let w = Int(bbox.width * CGFloat(imgRef.width))
                let h = Int(bbox.height * imgHeight)

                // Manually build JSON with deterministic key order
                let txtEscaped = candidate.string
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                    .replacingOccurrences(of: "\n", with: "\\n")
                    .replacingOccurrences(of: "\r", with: "\\r")
                    .replacingOccurrences(of: "\t", with: "\\t")

                let jsonObj = """
                  { "txt" : "\(txtEscaped)",
                    "x" : \(x), "y" : \(y), "w" : \(w), "h" : \(h), "conf" : \(candidate.confidence) }
                """

                if index < observations.count - 1 {
                    jsonLines.append(jsonObj + ",")
                } else {
                    jsonLines.append(jsonObj)
                }
            }

            jsonLines.append("]")
            output = jsonLines.joined(separator: "\n")
        } else {
            let obs : [String] = observations.map { $0.topCandidates(1).first?.string ?? ""}
            output = obs.joined(separator: "\n")
        }

        if let dst = dst {
            try? output.write(to: URL(fileURLWithPath: dst), atomically: true, encoding: .utf8)
        } else {
            print(output)
        }
    }
    request.recognitionLevel = MODE
    request.usesLanguageCorrection = USE_LANG_CORRECTION
    request.revision = REVISION

    if let minHeight = minTextHeight {
        request.minimumTextHeight = minHeight
    }

    if !customWords.isEmpty {
        request.customWords = customWords
    }

    try? VNImageRequestHandler(cgImage: imgRef, options: [:]).perform([request])

    return 0
}
exit(main(args: CommandLine.arguments))
