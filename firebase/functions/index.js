/**
 * Lazim push notifications.
 *
 * Two triggers, both on the family's needs collection:
 *
 *  - onNeedCreated: a new item was added -> notify every other member.
 *  - onNeedUpdated: status or assignment changed -> notify every other member.
 *
 * Design notes:
 *  - The actor is always excluded, so nobody is notified about their own edit.
 *  - Tokens are read from each member document, so a member with two devices
 *    (phone + tablet) gets the notification on both.
 *  - Dead tokens are pruned from the member document after a failed send, which
 *    keeps the token list from rotting over time.
 *  - Notification text is generated in the recipient's language when the member
 *    document records one; otherwise Arabic, since that is the primary language.
 */
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

const STRINGS = {
  ar: {
    newTitle: "صنف جديد",
    newBody: (actor, item) => `${actor} أضاف "${item}"`,
    statusTitle: "تحديث على صنف",
    statusBody: (actor, item, status) => `${actor} غيّر حالة "${item}" إلى ${status}`,
    status: {
      open: "مطلوب",
      claimed: "محجوز",
      purchased: "تم الشراء",
      archived: "مؤرشف",
    },
  },
  en: {
    newTitle: "New item added",
    newBody: (actor, item) => `${actor} added "${item}"`,
    statusTitle: "Item updated",
    statusBody: (actor, item, status) => `${actor} marked "${item}" as ${status}`,
    status: {
      open: "needed",
      claimed: "claimed",
      purchased: "purchased",
      archived: "archived",
    },
  },
};

function strings(locale) {
  return locale === "en" ? STRINGS.en : STRINGS.ar;
}

/** Loads members of a family, excluding the actor. */
async function otherMembers(familyId, actorId) {
  const snap = await db.collection("families").doc(familyId).collection("members").get();
  return snap.docs
    .map((d) => ({ id: d.id, ...d.data() }))
    .filter((m) => m.userId !== actorId);
}

/** Sends one notification per token, pruning tokens that are permanently dead. */
async function sendToMembers(members, familyId, notification, data) {
  const results = [];
  for (const member of members) {
    const tokens = Array.isArray(member.fcmTokens) ? member.fcmTokens : [];
    if (tokens.length === 0) continue;

    const locale = member.locale || "ar";
    const payload = {
      notification: {
        title: notification.title(locale),
        body: notification.body(locale),
      },
      data: Object.fromEntries(
        Object.entries({ ...data, familyId }).map(([k, v]) => [k, String(v ?? "")])
      ),
      android: {
        priority: "high",
        notification: { channelId: "lazim_updates", sound: "default" },
      },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
      tokens,
    };

    try {
      const response = await getMessaging().sendEachForMulticast(payload);
      results.push(response);

      // Prune tokens the service says are gone for good.
      const dead = [];
      response.responses.forEach((r, i) => {
        const code = r.error?.code;
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token" ||
          code === "messaging/invalid-argument"
        ) {
          dead.push(tokens[i]);
        }
      });

      if (dead.length > 0) {
        await db
          .collection("families")
          .doc(familyId)
          .collection("members")
          .doc(member.userId)
          .update({ fcmTokens: FieldValue.arrayRemove(...dead) });
      }
    } catch (err) {
      console.error("send failed for member", member.userId, err);
    }
  }
  return results;
}

exports.onNeedCreated = onDocumentCreated(
  "families/{familyId}/needs/{needId}",
  async (event) => {
    const need = event.data?.data();
    if (!need) return;

    const members = await otherMembers(event.params.familyId, need.createdBy);
    if (members.length === 0) return;

    await sendToMembers(
      members,
      event.params.familyId,
      {
        title: (locale) => strings(locale).newTitle,
        body: (locale) =>
          strings(locale).newBody(need.createdByName || "", need.title || ""),
      },
      {
        type: "need_created",
        needId: event.params.needId,
        title: need.title || "",
      }
    );
  }
);

exports.onNeedUpdated = onDocumentUpdated(
  "families/{familyId}/needs/{needId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const statusChanged = before.status !== after.status;
    const assigneeChanged = before.assignedTo !== after.assignedTo;
    if (!statusChanged && !assigneeChanged) return;

    // Who made the change? The newest activity entry names the actor.
    const activity = Array.isArray(after.activity) ? after.activity : [];
    const latest = activity[activity.length - 1];
    const actorId = latest?.actorId || "";
    const actorName = latest?.actorName || "";

    const members = await otherMembers(event.params.familyId, actorId);
    if (members.length === 0) return;

    const status = after.status || "open";

    await sendToMembers(
      members,
      event.params.familyId,
      {
        title: (locale) => strings(locale).statusTitle,
        body: (locale) =>
          strings(locale).statusBody(
            actorName,
            after.title || "",
            strings(locale).status[status] || status
          ),
      },
      {
        type: "need_updated",
        needId: event.params.needId,
        status,
      }
    );
  }
);
