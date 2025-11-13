#!/usr/bin/env bash
set -e

# Usage: ./scripts/init-firebase.sh <FIREBASE_PROJECT_ID>
PROJECT_ID=$1
if [ -z "$PROJECT_ID" ]; then
  echo "Usage: ./scripts/init-firebase.sh <FIREBASE_PROJECT_ID>"
  exit 1
fi

echo "Setting firebase project to $PROJECT_ID"
firebase use $PROJECT_ID

echo "Initializing Firestore/Functions/Hosting (interactive step may appear)"
firebase init firestore functions hosting --project $PROJECT_ID

echo "Installing functions dependencies..."
cd functions
npm install
cd ..

echo "Done. Next steps: set dropbox config with:"
echo "firebase functions:config:set dropbox.token=\"<DROPBOX_ACCESS_TOKEN>\" dropbox.app_key=\"<DROPBOX_APP_KEY>\""
echo "Then deploy functions: firebase deploy --only functions"
echo "Build flutter web: flutter build web"
echo "Deploy hosting: firebase deploy --only hosting"
