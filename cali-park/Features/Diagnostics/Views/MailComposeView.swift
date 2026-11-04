import MessageUI
import SwiftUI

// MARK: - MailMessage
/// A support e-mail with one attachment, for `MailComposeView`.
struct MailMessage: Identifiable {
    let id = UUID()
    let recipient: String
    let subject: String
    let body: String
    let attachment: Data
    let attachmentName: String
    let mimeType: String
}

// MARK: - MailComposeView
/// The system mail composer. The user reviews and sends the message there
/// (or cancels); the app never sends anything on its own. Use it only when
/// `MailComposeView.canSendMail` is true, i.e. Mail has an account.
struct MailComposeView: UIViewControllerRepresentable {
    let message: MailMessage
    @Environment(\.dismiss) private var dismiss

    static var canSendMail: Bool { MFMailComposeViewController.canSendMail() }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([message.recipient])
        controller.setSubject(message.subject)
        controller.setMessageBody(message.body, isHTML: false)
        controller.addAttachmentData(message.attachment, mimeType: message.mimeType, fileName: message.attachmentName)
        return controller
    }

    func updateUIViewController(_ controller: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        private let dismiss: DismissAction
        private let logger = AppLog.logger(category: "MailCompose")

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: (any Error)?
        ) {
            if let error {
                logger.error("Mail composer failed: \(String(describing: error), privacy: .public)")
            }
            dismiss()
        }
    }
}

// MARK: - DiagnosticSendButton
/// "Wyślij raport": opens the mail composer to the support address when Mail
/// has an account (`compose` presents it), otherwise the share sheet, from
/// which the user picks any app (Gmail, Files, AirDrop). Disabled without
/// an attachment.
struct DiagnosticSendButton: View {
    let title: LocalizedStringKey
    let attachment: DiagnosticAttachment?
    let compose: (DiagnosticAttachment) -> Void

    var body: some View {
        if let attachment {
            if MailComposeView.canSendMail {
                Button(title, systemImage: "envelope") { compose(attachment) }
            } else {
                ShareLink(item: attachment, preview: SharePreview(attachment.fileName)) {
                    Label(title, systemImage: "square.and.arrow.up")
                }
            }
        } else {
            Button(title, systemImage: "square.and.arrow.up") {}
                .disabled(true)
        }
    }
}

// MARK: - Mail message
extension DiagnosticAttachment {
    /// The support e-mail carrying this attachment.
    func mailMessage(subject: String) throws -> MailMessage {
        MailMessage(
            recipient: SupportContact.email,
            subject: subject,
            body: DiagnosticExport.mailBody,
            attachment: try data(),
            attachmentName: fileName,
            mimeType: "application/json"
        )
    }
}
