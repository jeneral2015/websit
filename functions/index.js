const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Firebase function commented out as direct upload is now used from Flutter app
/*
const axios = require("axios");

// Use functions.config().dropbox.token or process.env.DROPBOX_TOKEN
const getDropboxToken = () => {
  return functions.config().dropbox && functions.config().dropbox.token
    ? functions.config().dropbox.token
    : process.env.DROPBOX_TOKEN;
};

const DROPBOX_UPLOAD_PREFIX = '/uploads';

exports.uploadToDropbox = functions.https.onRequest(async (req, res) => {
  try {
    // Allow only POST
    if (req.method !== 'POST') {
      return res.status(405).send('Method Not Allowed');
    }

    const dropboxToken = getDropboxToken();
    if (!dropboxToken) return res.status(500).send('Missing Dropbox token. Set with firebase functions:config:set dropbox.token="..."');

    const { fileName, fileDataBase64, firestoreTargetDoc } = req.body;
    if (!fileName || !fileDataBase64) return res.status(400).send('fileName and fileDataBase64 required');

    const dropboxPath = `${DROPBOX_UPLOAD_PREFIX}/${fileName}`;

    // Upload file to Dropbox
    const uploadResp = await axios.post('https://content.dropboxapi.com/2/files/upload', Buffer.from(fileDataBase64, 'base64'), {
      headers: {
        'Authorization': `Bearer ${dropboxToken}`,
        'Content-Type': 'application/octet-stream',
        'Dropbox-API-Arg': JSON.stringify({
          path: dropboxPath,
          mode: 'add',
          autorename: true,
          mute: false
        }),
      },
      maxBodyLength: Infinity
    });

    // Create shared link
    const linkResp = await axios.post('https://api.dropboxapi.com/2/sharing/create_shared_link_with_settings', { path: dropboxPath }, {
      headers: {
        'Authorization': `Bearer ${dropboxToken}`,
        'Content-Type': 'application/json'
      }
    });

    let sharedUrl = linkResp.data && linkResp.data.url ? linkResp.data.url : null;
    if (sharedUrl) {
      // convert to raw direct link to display image
      sharedUrl = sharedUrl.replace('?dl=0', '?raw=1');
    }

    // If a Firestore target doc path provided, update it
    if (firestoreTargetDoc && sharedUrl) {
      // Expecting firestoreTargetDoc like "site_data/homepage" or "collection/doc"
      const parts = firestoreTargetDoc.split('/');
      if (parts.length === 2) {
        const [collection, doc] = parts;
        await admin.firestore().collection(collection).doc(doc).set({ banner_url: sharedUrl }, { merge: true });
      } else {
        // fallback: try to set as document path
        await admin.firestore().doc(firestoreTargetDoc).set({ banner_url: sharedUrl }, { merge: true });
      }
    }

    // Return the link
    return res.json({ success: true, url: sharedUrl });
  } catch (err) {
    console.error('uploadToDropbox error:', err.response ? err.response.data : err.message || err);
    return res.status(500).json({ success: false, error: err.response ? err.response.data : err.toString() });
  }
});
*/

// init firestore structure (call once manually via HTTP or adapt to onCall)
exports.initFirestoreStructure = functions.https.onRequest(async (req, res) => {
  try {
    const db = admin.firestore();

    const initialDocs = [
      { path: 'site_data/homepage', data: { banner_url: '', welcome_text: 'أهلاً بك', updatedAt: admin.firestore.FieldValue.serverTimestamp() } },
      { path: 'site_data/settings', data: { site_title: 'My Template Site', logo_url: '', theme: 'default', updatedAt: admin.firestore.FieldValue.serverTimestamp() } },
      { path: 'assets/images', data: { createdAt: admin.firestore.FieldValue.serverTimestamp() } }
    ];

    for (const doc of initialDocs) {
      const parts = doc.path.split('/');
      if (parts.length === 2) {
        await db.collection(parts[0]).doc(parts[1]).set(doc.data, { merge: true });
      } else {
        await db.doc(doc.path).set(doc.data, { merge: true });
      }
    }

    return res.json({ success: true, message: 'Initial Firestore structure created/updated.' });
  } catch (err) {
    console.error('initFirestoreStructure error:', err);
    return res.status(500).json({ success: false, error: err.toString() });
  }
});
