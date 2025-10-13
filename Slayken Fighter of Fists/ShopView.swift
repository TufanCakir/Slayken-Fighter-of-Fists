import SwiftUI
struct ShopView: View {
    var body: some View {
        VStack {
            Image(systemName: "cart.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
                .padding(.bottom, 8)
            Text("Shop Coming Soon")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
    }
}

struct ComingSoonView: View {
    var body: some View {
        VStack {
            Image(systemName: "hourglass.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
                .padding(.bottom, 8)
            Text("Feature Coming Soon")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
    }
}
