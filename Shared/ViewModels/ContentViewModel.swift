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
    
    private func buffer() -> AVAudioPCMBuffer? {
        guard let audioFileURL = audioFileURL,
              let audioFile = try? AVAudioFile(forReading: audioFileURL) else { return nil }
        let pcmFormat = audioFile.processingFormat
        let frameCapacity = AVAudioFrameCount(12 * audioFile.fileFormat.sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: pcmFormat, frameCapacity: frameCapacity) else { return nil }
        try? audioFile.read(into: buffer)
        return buffer
    }
    
    private func signature() -> SHSignature? {
        guard let buffer = buffer() else { return nil }
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
