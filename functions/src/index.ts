import { initializeApp } from "firebase-admin/app";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/logger";
import sgMail from "@sendgrid/mail";

initializeApp();

const SUPPORT_EMAIL = "unispace.0.1.0@gmail.com";
const EMAIL_SUBJECT = "[UniSpace] New Contact Message";

type SupportMessage = {
  name?: string;
  email?: string;
  message?: string;
  createdAt?: { toDate?: () => Date } | string | number | null;
  deviceInfo?: Record<string, unknown> | null;
};

const getCreatedAt = (createdAt: SupportMessage["createdAt"]): string => {
  if (createdAt && typeof createdAt === "object" && "toDate" in createdAt) {
    const date = createdAt.toDate?.();
    if (date) {
      return date.toISOString();
    }
  }
  if (typeof createdAt === "number") {
    return new Date(createdAt).toISOString();
  }
  if (typeof createdAt === "string" && createdAt.trim().length > 0) {
    return createdAt;
  }
  return "unknown";
};

const buildEmailBody = (data: SupportMessage, docId: string): string => {
  const deviceInfo = data.deviceInfo ?? {};
  return [
    `Document ID: ${docId}`,
    `Name: ${data.name ?? "-"}`,
    `Email: ${data.email ?? "-"}`,
    `Created At: ${getCreatedAt(data.createdAt ?? null)}`,
    "",
    "Message:",
    data.message ?? "-",
    "",
    "Device Info:",
    JSON.stringify(deviceInfo, null, 2),
  ].join("\n");
};

export const onSupportMessageCreate = onDocumentCreated(
  {
    document: "supportMessages/{docId}",
    secrets: ["SENDGRID_API_KEY"],
  },
  async (event) => {
    const data = event.data?.data() as SupportMessage | undefined;
    if (!data) {
      logger.warn("Support message missing data payload.", {
        document: event.params.docId,
      });
      return;
    }

    const messageText = data.message?.trim();
    if (!messageText) {
      logger.warn("Support message missing required message field.", {
        document: event.params.docId,
      });
      return;
    }

    const apiKey = process.env.SENDGRID_API_KEY;
    if (!apiKey) {
      logger.error("SENDGRID_API_KEY is not configured.");
      return;
    }

    sgMail.setApiKey(apiKey);

    const emailBody = buildEmailBody({ ...data, message: messageText }, event.params.docId);

    try {
      await sgMail.send({
        to: SUPPORT_EMAIL,
        from: SUPPORT_EMAIL,
        subject: EMAIL_SUBJECT,
        text: emailBody,
        replyTo: data.email ?? undefined,
      });
      logger.info("Support email sent.", { document: event.params.docId });
    } catch (error) {
      logger.error("Failed to send support email.", {
        document: event.params.docId,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  },
);
