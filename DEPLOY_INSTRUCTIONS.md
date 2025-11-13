# Deploy instructions (manual steps)

1. Ensure firebase-tools installed:
   npm install -g firebase-tools

2. Login to Firebase:
   firebase login

3. Select project:
   firebase use <YOUR_FIREBASE_PROJECT_ID>

4. Set Dropbox credentials securely (do NOT commit them):
   firebase functions:config:set dropbox.token="<DROPBOX_ACCESS_TOKEN>" dropbox.app_key="<DROPBOX_APP_KEY>"

   Alternatively you can set env vars before deploying:
   export DROPBOX_TOKEN="<DROPBOX_ACCESS_TOKEN>"
   export DROPBOX_APP_KEY="<DROPBOX_APP_KEY>"

5. Install functions deps:
   cd functions && npm install && cd ..

6. Deploy functions:
   firebase deploy --only functions

7. Build Flutter web:
   flutter build web

8. Deploy hosting:
   firebase deploy --only hosting

9. (Optional) Initialize Firestore structure:
   Call the initFirestoreStructure function endpoint:
   curl -X POST https://<REGION>-<PROJECT>.cloudfunctions.net/initFirestoreStructure
   or open the function URL in browser.

10. Test upload from Dashboard using the example in lib/services/dropbox_uploader.dart:
    - Configure functionUrl in that service to point to deployed uploadToDropbox function.
    - Use targetFirestoreDoc e.g. "site_data/homepage" to auto update banner_url.
