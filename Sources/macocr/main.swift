import Cocoa
import Vision

func main(args: [String]) -> Int32 {
    guard CommandLine.arguments.count == 3 else {
        fputs("Usage: vn [image] [dst]\n", stderr)
        return 1
    }

    let (src, dst) = (args[1], args[2])

    guard let img = NSImage(byReferencingFile: src) else {
        fputs("Error: failed to load image '\(src)'\n", stderr)
        return 1
    }

    guard let imgRef = img.cgImage(forProposedRect: &img.alignmentRect, context: nil, hints: nil) else {
        fputs("Error: failed to convert NSImage to CGImage for '\(src)'\n", stderr)
        return 1
    }

    let request = VNRecognizeTextRequest { (request, error) in
        let observations = request.results as? [VNRecognizedTextObservation] ?? []
        let obs : [String] = observations.map { $0.topCandidates(1).first?.string ?? ""}
        try? obs.joined(separator: "\n").write(to: URL(fileURLWithPath: dst), atomically: true, encoding: String.Encoding.utf8)
    }

    try? VNImageRequestHandler(cgImage: imgRef, options: [:]).perform([request])

    return 0
}
exit(main(args: CommandLine.arguments))
