#!/bin/bash

echo "Getting SHA-1 keys for your Flutter app..."

echo ""
echo "=== Android Debug SHA-1 ==="
echo "For development environment"
echo ""

if [ -f "$HOME/.android/debug.keystore" ]; then
    keytool -list -v -keystore "$HOME/.android/debug.keystore" -alias androiddebugkey -storepass android -keypass android | grep -E "(SHA1|SHA-1)"
else
    echo "Debug keystore not found at $HOME/.android/debug.keystore"
    echo "You might need to run 'flutter doctor' to set up your Android environment first"
fi

echo ""
echo "=== Android Release SHA-1 ==="
echo "For production environment"
echo ""

echo "To generate release SHA-1, you need to provide your release keystore path."
echo "If you don't have a release keystore yet, create one with:"
echo "keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload"

echo ""
read -p "Enter the path to your release keystore (or press Enter to skip): " keystore_path

if [ -n "$keystore_path" ]; then
    if [ -f "$keystore_path" ]; then
        echo "Enter your keystore password when prompted:"
        keytool -list -v -keystore "$keystore_path" | grep -E "(SHA1|SHA-1)"
    else
        echo "Keystore file not found: $keystore_path"
    fi
else
    echo "Skipping release SHA-1 generation."
fi

echo ""
echo "=== How to add SHA-1 to Firebase Console ==="
echo "1. Go to Firebase Console: https://console.firebase.google.com/"
echo "2. Select your project (mindguard_fr)"
echo "3. Go to Project Settings (gear icon)"
echo "4. Scroll down to 'Your apps' section"
echo "5. Under Android apps, click on your app package name"
echo "6. In 'SHA certificate fingerprints', click 'Add fingerprint'"
echo "7. Paste the SHA-1 value you got above"
echo ""

echo "For iOS, no SHA-1 is needed, but you'll need to configure other settings in your Firebase project."