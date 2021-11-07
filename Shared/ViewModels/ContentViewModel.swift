//
//  ContentViewModel.swift
//  Demo-ShazamKit
//
//  Created by Peter Yaacoub on 08/07/2021.
//

import ShazamKit



//MARK:- ViewModel

class ContentViewModel: NSObject, ObservableObject {
    
    
    
    //MARK:- Private Properties
    
    private let audioFileURL = Bundle.main.url(forResource: "Audio", withExtension: "mp3")
    private let session = SHSession()
    
    
    
    //MARK:- Properties
    
    @Published private(set) var isMatching = false
    @Published private(set) var songMatch: SongMatch? = nil
    
    var savesToLibrary = false
    
    
    
    //MARK:- Init
    
    override init() {
        super.init()
        session.delegate = self
    }
    
    
    
    //MARK:- Private Methods
    
    private func buffer(audioFile: AVAudioFile, outputFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount((1024 * 64) / (audioFile.processingFormat.streamDescription.pointee.mBytesPerFrame))
        let outputFrameCapacity = AVAudioFrameCount(12 * audioFile.fileFormat.sampleRate)
        guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: frameCount),
              let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCapacity),
              let converter = AVAudioConverter(from: audioFile.processingFormat, to: outputFormat) else { return nil }
        while true {
            let status = converter.convert(to: outputBuffer, error: nil) { inNumPackets, outStatus in
                do {
                    try audioFile.read(into: inputBuffer)
                    outStatus.pointee = .haveData
                    return inputBuffer
                } catch {
                    if audioFile.framePosition >= audioFile.length {
                        outStatus.pointee = .endOfStream
                        return nil
                    } else {
                        outStatus.pointee = .noDataNow
                        return nil
                    }
                }
            }
            switch status {
            case .endOfStream, .error: return nil
            default: return outputBuffer
            }
        }
    }
    
    private func signature() -> SHSignature? {
        guard let audioFileURL = audioFileURL,
              let audioFile = try? AVAudioFile(forReading: audioFileURL),
              let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let buffer = buffer(audioFile: audioFile, outputFormat: audioFormat) else { return nil }
        let signatureGenerator = SHSignatureGenerator()
        try? signatureGenerator.append(buffer, at: nil)
        return signatureGenerator.signature()
    }
    
    
    
    //MARK:- Methods
    
    func startMatching() {
        guard let signature = signature(), isMatching == false else { return }
        isMatching = true
        session.match(signature)
    }
    
}



//MARK:- Extensions

extension ContentViewModel: SHSessionDelegate {
    
    func session(_ session: SHSession, didFind match: SHMatch) {
        guard let matchedMediaItem = match.mediaItems.first else { return }
        DispatchQueue.main.async { [weak self] in
            self?.isMatching = false
            self?.songMatch = SongMatch(appleMusicURL: matchedMediaItem.appleMusicURL,
                                        artist: matchedMediaItem.artist,
                                        artworkURL: matchedMediaItem.artworkURL,
                                        title: matchedMediaItem.title)
        }
        guard savesToLibrary == true else { return }
        SHMediaLibrary.default.add([matchedMediaItem]) { error in return }
    }
    
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        print(String(describing: error))
        DispatchQueue.main.async { [weak self] in
            self?.isMatching = false
        }
    }
    
}
