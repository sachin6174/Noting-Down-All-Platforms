import SwiftUI

struct TemporaryAlertView: View {
    let message: String

    var body: some View {
        Text(message)
            .foregroundColor(.white)
            .padding(AppStyle.padding)
            .background(
                RoundedRectangle(cornerRadius: AppStyle.cornerRadius)
                    .fill(Color.black.opacity(0.8))
            )
            .shadow(radius: 10)
    }
}
