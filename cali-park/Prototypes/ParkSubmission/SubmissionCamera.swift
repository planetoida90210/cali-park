#if DEBUG
// PROTOTYPE — throwaway. A fake in-app camera. The real version uses the camera only (no
// gallery) and strips GPS/EXIF before upload. Sample "photos" are drawn shapes, not images.

import SwiftUI

struct SubmissionCameraView: View {
    @Bindable var model: ParkSubmissionPrototypeModel
    @Environment(\.dismiss) private var dismiss
    @State private var flash = false

    private var nextPhoto: Int { (model.draft.photos.last ?? -1) + 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Gotowe") { dismiss() }
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(SubmissionFormat.photos(model.draft.photos.count))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            SamplePhotoView(index: nextPhoto)
                .overlay {
                    CameraGrid()
                }
                .overlay(alignment: .top) {
                    Text("Złap w kadrze cały drążek albo poręcze")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.55), in: .capsule)
                        .padding(.top, 12)
                }
                .overlay {
                    Color.white.opacity(flash ? 0.85 : 0)
                }
                .clipShape(.rect(cornerRadius: AppRadius.small))

            HStack {
                LastShotThumbnail(photo: model.draft.photos.last)
                Spacer()
                Button {
                    shoot()
                } label: {
                    Circle()
                        .fill(.white)
                        .frame(width: 66, height: 66)
                        .padding(5)
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Zrób zdjęcie")
                .disabled(model.draft.photos.count >= SubmissionDraft.maxPhotos)
                Spacer()
                Color.clear.frame(width: 52, height: 52)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 22)
        }
        .background(.black)
    }

    private func shoot() {
        model.takePhoto()
        flash = true
        withAnimation(.easeOut(duration: 0.35)) { flash = false }
    }
}

private struct LastShotThumbnail: View {
    let photo: Int?

    var body: some View {
        Group {
            if let photo {
                SamplePhotoView(index: photo)
            } else {
                Color.controlFill
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(.rect(cornerRadius: AppRadius.small))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.small).stroke(.white.opacity(0.5), lineWidth: 1))
    }
}

private struct CameraGrid: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            for fraction in [1.0 / 3, 2.0 / 3] {
                path.move(to: CGPoint(x: size.width * fraction, y: 0))
                path.addLine(to: CGPoint(x: size.width * fraction, y: size.height))
                path.move(to: CGPoint(x: 0, y: size.height * fraction))
                path.addLine(to: CGPoint(x: size.width, y: size.height * fraction))
            }
            context.stroke(path, with: .color(.white.opacity(0.25)), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}

/// A drawn stand-in for a photo of a Park: sky, trees, ground and a bar structure.
/// `index` picks one of four scenes so consecutive shots look different.
struct SamplePhotoView: View {
    let index: Int

    private var scene: Int { index % 4 }

    private var sky: [Color] {
        switch scene {
        case 0: [Color(hex: "#6FA8DC"), Color(hex: "#CFE2F3")]
        case 1: [Color(hex: "#F6B26B"), Color(hex: "#FFE599")]
        case 2: [Color(hex: "#8E9AAF"), Color(hex: "#CBC0D3")]
        default: [Color(hex: "#3D85C6"), Color(hex: "#9FC5E8")]
        }
    }

    private var ground: Color {
        switch scene {
        case 0, 3: Color(hex: "#B45F06")
        case 1: Color(hex: "#6AA84F")
        default: Color(hex: "#7F6000")
        }
    }

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let horizon = h * 0.62
            context.fill(
                Path(CGRect(x: 0, y: 0, width: w, height: horizon)),
                with: .linearGradient(Gradient(colors: sky), startPoint: .zero, endPoint: CGPoint(x: 0, y: horizon))
            )
            // Trees.
            for i in 0..<5 {
                let x = w * (0.08 + Double(i) * 0.22) + Double(scene) * 6
                let r = w * (0.11 + 0.03 * Double((i + scene) % 3))
                context.fill(
                    Path(ellipseIn: CGRect(x: x - r, y: horizon - r * 1.7, width: r * 2, height: r * 2)),
                    with: .color(Color(hex: "#38761D").opacity(0.9))
                )
            }
            // Ground (rubber or grass).
            context.fill(Path(CGRect(x: 0, y: horizon, width: w, height: h - horizon)), with: .color(ground))

            let steel = GraphicsContext.Shading.color(Color(hex: "#2B2B2B"))
            let barTop = h * (scene == 1 ? 0.30 : 0.24)
            let post = max(w * 0.025, 2)
            // Pull-up bars: three posts, two bars at different heights.
            let posts = scene == 2 ? [0.2, 0.5] : [0.15, 0.45, 0.75]
            for (i, px) in posts.enumerated() {
                let top = barTop + Double(i % 2) * h * 0.06
                context.fill(Path(CGRect(x: w * px, y: top, width: post, height: h * 0.8 - top)), with: steel)
            }
            for i in 0..<(posts.count - 1) {
                let y = barTop + Double((i + 1) % 2) * h * 0.06 + post
                context.fill(
                    Path(CGRect(x: w * posts[i], y: y, width: w * (posts[i + 1] - posts[i]) + post, height: post * 0.8)), with: steel)
            }
            // Parallel bars in front.
            if scene != 2 {
                let left = w * 0.55
                let right = w * 0.92
                let y = h * 0.66
                for offset in [0.0, h * 0.05] {
                    context.fill(Path(CGRect(x: left, y: y + offset, width: right - left, height: post * 0.8)), with: steel)
                    context.fill(Path(CGRect(x: left + 4, y: y + offset, width: post * 0.8, height: h * 0.14)), with: steel)
                    context.fill(Path(CGRect(x: right - 6, y: y + offset, width: post * 0.8, height: h * 0.14)), with: steel)
                }
            }
        }
        .accessibilityLabel("Przykładowe zdjęcie Parku \(index + 1)")
    }
}
#endif
