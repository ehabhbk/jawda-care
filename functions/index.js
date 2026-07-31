const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();
const db = getFirestore();

async function getFcmToken(userId) {
  if (!userId) return null;
  try {
    const doc = await db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return doc.data().fcmToken || null;
  } catch (e) {
    console.error('getFcmToken failed', e);
    return null;
  }
}

async function getHospitalAdminTokens(hospitalId) {
  if (!hospitalId) return [];
  try {
    const snap = await db
      .collection('users')
      .where('role', '==', 'hospital')
      .where('hospitalId', '==', hospitalId)
      .get();
    const tokens = [];
    snap.forEach((d) => {
      if (d.data().fcmToken) tokens.push(d.data().fcmToken);
    });
    return tokens;
  } catch (e) {
    console.error('getHospitalAdminTokens failed', e);
    return [];
  }
}

async function getDriverTokensForAmbulance(ambulanceId) {
  if (!ambulanceId) return [];
  try {
    const ambDoc = await db.collection('ambulances').doc(ambulanceId).get();
    if (!ambDoc.exists) return [];
    const driverEmail = ambDoc.data().driverEmail;
    if (!driverEmail) return [];

    const userSnap = await db
      .collection('users')
      .where('email', '==', driverEmail)
      .limit(1)
      .get();

    const tokens = [];
    userSnap.forEach((d) => {
      if (d.data().fcmToken) tokens.push(d.data().fcmToken);
    });
    return tokens;
  } catch (e) {
    console.error('getDriverTokensForAmbulance failed', e);
    return [];
  }
}

async function sendPush(tokens, title, body, data) {
  if (!tokens || tokens.length === 0) return;
  try {
    const message = {
      notification: { title, body },
      data: data || {},
      tokens,
    };
    const res = await getMessaging().sendEachForMulticast(message);
    console.log(`Notification sent to ${res.successCount}/${tokens.length} devices`);
  } catch (e) {
    console.error('sendPush failed', e);
  }
}

exports.sendBookingNotifications = onDocumentWritten(
  'bookings/{bookingId}',
  async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    const bookingId = event.params.bookingId;

    if (!afterData) return; // document deleted

    const type = afterData.bookingType || 'icu';
    const userId = afterData.userId;
    const status = afterData.status;

    // CREATED
    if (!beforeData) {
      if (type === 'icu') {
        const tokens = await getHospitalAdminTokens(afterData.hospitalId);
        await sendPush(
          tokens,
          'طلب حجز سرير جديد',
          `${afterData.userName || ''} طلب حجز سرير في ${afterData.hospitalName || 'المستشفى'}`,
          { bookingId, type: 'icu', status }
        );
      }
      return;
    }

    const oldStatus = beforeData.status;
    if (oldStatus === status) return;

    // AMBULANCE
    if (type === 'ambulance') {
      if (status === 'accepted' && afterData.ambulanceId) {
        const driverTokens = await getDriverTokensForAmbulance(afterData.ambulanceId);
        await sendPush(
          driverTokens,
          'طلب إسعاف جديد',
          'تم تعيينك لطلب إسعاف جديد. افتح لوحة التحكم لبدء الرحلة.',
          { bookingId, type: 'ambulance', status }
        );
        const token = await getFcmToken(userId);
        await sendPush(
          token ? [token] : [],
          'تم تعيين سيارة إسعاف',
          `السائق: ${afterData.driverName || ''} - اللوحة: ${afterData.plateNumber || ''}`,
          { bookingId, type: 'ambulance', status }
        );
      } else if (status === 'headingToPatient') {
        const token = await getFcmToken(userId);
        await sendPush(
          token ? [token] : [],
          'السائق في الطريق إليك',
          'سيارة الإسعاف قادمة إليك. تتبع موقعها الآن.',
          { bookingId, type: 'ambulance', status }
        );
      } else if (status === 'pickedUp') {
        const token = await getFcmToken(userId);
        await sendPush(
          token ? [token] : [],
          'تم الاستلام',
          'تم استلامك، نحن في الطريق إلى الوجهة.',
          { bookingId, type: 'ambulance', status }
        );
      } else if (status === 'arrived') {
        const token = await getFcmToken(userId);
        await sendPush(
          token ? [token] : [],
          'وصلنا إلى الوجهة',
          'تم الوصول. نتمنى الشفاء العاجل.',
          { bookingId, type: 'ambulance', status }
        );
      } else if (status === 'rejected') {
        const token = await getFcmToken(userId);
        await sendPush(
          token ? [token] : [],
          'تم رفض الطلب',
          'نعتذر، لم يتمكن السائق من تنفيذ طلبك. حاول مرة أخرى.',
          { bookingId, type: 'ambulance', status }
        );
      } else if (status === 'cancelled') {
        const driverTokens = afterData.ambulanceId
          ? await getDriverTokensForAmbulance(afterData.ambulanceId)
          : [];
        await sendPush(
          driverTokens,
          'تم إلغاء الطلب',
          'ألغى المريض طلب الإسعاف.',
          { bookingId, type: 'ambulance', status }
        );
      }
      return;
    }

    // ICU
    if (type === 'icu') {
      if (status === 'accepted' || status === 'confirmed') {
        const token = await getFcmToken(userId);
        await sendPush(
          token ? [token] : [],
          'تم تأكيد حجز السرير',
          `تم حجز السرير ${afterData.bedName || ''} بنجاح.`,
          { bookingId, type: 'icu', status }
        );
      } else if (status === 'rejected') {
        const token = await getFcmToken(userId);
        await sendPush(
          token ? [token] : [],
          'تم رفض الحجز',
          'نعتذر، لم يتم قبول طلب حجز السرير.',
          { bookingId, type: 'icu', status }
        );
      } else if (status === 'cancelled') {
        const tokens = await getHospitalAdminTokens(afterData.hospitalId);
        await sendPush(
          tokens,
          'تم إلغاء الحجز',
          `ألغى ${afterData.userName || ''} طلب حجز السرير.`,
          { bookingId, type: 'icu', status }
        );
      } else if (status === 'completed') {
        const token = await getFcmToken(userId);
        await sendPush(
          token ? [token] : [],
          'اكتمل الحجز',
          'نتمنى الشفاء العاجل.',
          { bookingId, type: 'icu', status }
        );
      }
    }
  }
);
