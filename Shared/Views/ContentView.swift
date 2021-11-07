//
//  ContentView.swift
//  Shared
//
//  Created by Peter Yaacoub on 08/07/2021.
//

import SwiftUI



//MARK:- View

struct ContentView: View {
    
    
    
    //MARK:- Private Properties
    
    @StateObject private var viewModel = ContentViewModel()
    
    
    
    //MARK:- Body
    
    var body: some View {
        VStack {
            Spacer()
            Group {
                AsyncImage(url: viewModel.songMatch?.artworkURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .cornerRadius(20)
                } placeholder: {
                    Image(systemName: "square")
                        .font(.system(size: 200))
                        .frame(width: 200, height: 200)
                        .cornerRadius(20)
                }
                Text(viewModel.songMatch?.title ?? "Song Title")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(viewModel.songMatch?.artist ?? "Song Artist")
                    .font(.title)
            }
            .redacted(reason: viewModel.songMatch == nil ? .placeholder : [])
            if let appleMusicURL = viewModel.songMatch?.appleMusicURL {
                Link("View on Apple Music", destination: appleMusicURL)
                    .tint(.pink)
            }
            Spacer()
            Toggle("Saves to Shazam Library", isOn: $viewModel.savesToLibrary)
                .padding(.horizontal, 60)
                .padding(.vertical)
            Button(viewModel.isMatching ? "Matching…" : "Match preexisting audio", action: viewModel.startMatching)
                .disabled(viewModel.isMatching)
                .padding(.vertical)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.blue)
    }
    
}



//MARK:- Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
