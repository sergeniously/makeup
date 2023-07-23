echo "Doing pre-install actions for {PACKAGE_NAME}..."

#if defined deb
echo "Doing DEB package specific actions..."
#elif defined rpm
echo "Doing RPM package specific actions..."
#endif

#if defined x86_64
echo "Doing x86_64 architecture specific actions..."
#elif defined arm64
echo "Doing arm64 architecture specific actions..."
#endif
