import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("MyTradeMate")
                    .font(.largeTitle).bold()
                Text("Ready to trade. 🚀")
                    .foregroundStyle(.secondary)

                NavigationLink("Open Dashboard") {
                    Text("Dashboard")
                        .font(.title2)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

// Dacă folosești Xcode 15/16, poți folosi macro-ul #Preview:
#Preview {
    ContentView()
}

/*
 Dacă ai Xcode mai vechi sau dacă #Preview dă eroare,
 comentează blocul de mai sus și decomentează acest PreviewProvider clasic:

 struct ContentView_Previews: PreviewProvider {
     static var previews: some View {
         ContentView()
     }
 }
*/