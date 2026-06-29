export SCRIPT_DIR=$(realpath $(dirname $0))

replace() {
    export org=$2 new=$3
    find $1 -type f -exec sed -i 's@'$org'@'$new'@g' {} \;
}

set_keys() {
    mkdir -p $SCRIPT_DIR/keys
    if [ -z "$LOCAL_TEST_JKS" ] || [ -z "$STORE_TEST_JKS" ]; then
        echo "No signing keys provided, generating a temporary test keystore..."
        keytool -genkeypair -v -keystore $SCRIPT_DIR/keys/test.jks -keyalg RSA -keysize 2048 -validity 10000 -alias testkey -keypass testpassword -storepass testpassword -dname "CN=Test, O=Test, C=US" -storetype PKCS12
        echo "keyAlias=testkey" > $SCRIPT_DIR/keys/local.properties
        echo "keyPassword=testpassword" >> $SCRIPT_DIR/keys/local.properties
        echo "storePassword=testpassword" >> $SCRIPT_DIR/keys/local.properties
    else
        echo $LOCAL_TEST_JKS | base64 -d > $SCRIPT_DIR/keys/local.properties
        echo $STORE_TEST_JKS | base64 -d > $SCRIPT_DIR/keys/test.jks
    fi
    unset LOCAL_TEST_JKS
    unset STORE_TEST_JKS
}

sign_apk() {
    export apksigner=$(find $ANDROID_HOME/build-tools -name apksigner | sort | tail -n 1)
    source $SCRIPT_DIR/keys/local.properties
    $apksigner sign -verbose -ks $SCRIPT_DIR/keys/test.jks --ks-pass pass:$storePassword --key-pass pass:$keyPassword --ks-key-alias $keyAlias --out $2 $1 || exit 1
}

sign_aab() {
    source $SCRIPT_DIR/keys/local.properties
    jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore $SCRIPT_DIR/keys/test.jks -storepass $storePassword -keypass $keyPassword -signedjar $2 $1 $keyAlias || exit 1
}
