# $ brew install openjdk
#
# openjdk is keg-only, which means it was not symlinked into /opt/homebrew,
# because macOS provides similar software (which can break things...)
#
# Adding this to your PATH overrides the macOS dummy java program:
# export PATH="/usr/local/opt/openjdk/bin:$PATH"
