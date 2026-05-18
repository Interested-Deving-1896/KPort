#!/usr/bin/env bash
# KPort pacscript — gear/kaddressbook

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kaddressbook"
pkgver="26.04.1"
pkgdesc="address book and contact data manager"
url="http://pim.kde.org/"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/kaddressbook-26.04.1.tar.xz"
)
sha256sums=(
  "1b9f6f78f60a3044164a6b0b7fae5a9608925969d8c71541a61d84ab6d3caa2b"
)

depends=(
  "kpim6-akonadi-search"
  "kf6-kcmutils"
  "kf6-kcolorscheme"
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kcontacts"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-kitemmodels"
  "kf6-kparts"
  "kf6-ktextaddons"
  "kf6-kuserfeedback"
  "kf6-kwidgetsaddons"
  "kf6-kxmlgui"
  "kpim6-akonadi"
  "kpim6-akonadi-contacts"
  "kpim6-grantleetheme"
  "kpim6-kldap"
  "kpim6-kontactinterface"
  "kpim6-libkdepim"
  "kpim6-pimcommon"
  "qt6-base"
)

makedepends=(
  "cmake"
  "kf6-extra-cmake-modules"
  "kf6-karchive"
  "kf6-kauth"
  "kf6-kcalendarcore"
  "kf6-kcmutils"
  "kf6-kcodecs"
  "kf6-kcolorscheme"
  "kf6-kcompletion"
  "kf6-kconfig"
  "kf6-kcontacts"
  "kf6-kcoreaddons"
  "kf6-kdbusaddons"
  "kf6-kdnssd"
  "kf6-kdoctools"
  "kf6-kglobalaccel"
  "kf6-kholidays"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-kitemviews"
  "kf6-knewstuff"
  "kf6-knotifyconfig"
  "kf6-kservice"
  "kf6-ktextaddons"
  "kf6-ktexteditor"
  "kf6-ktexttemplate"
  "kf6-ktextwidgets"
  "kf6-kuserfeedback"
  "kf6-kwallet"
  "kf6-kwidgetsaddons"
  "kf6-kwindowsystem"
  "kf6-kxmlgui"
  "kf6-prison"
  "kf6-sonnet"
  "kf6-syndication"
  "kpim6-akonadi-calendar"
  "kpim6-akonadi-contacts"
  "kpim6-akonadi"
  "kpim6-akonadi-mime"
  "kpim6-akonadi-search"
  "kpim6-calendarsupport"
  "kpim6-eventviews"
  "kpim6-grantleetheme"
  "kpim6-libgravatar"
  "kpim6-incidenceeditor"
  "kpim6-kidentitymanagement"
  "kpim6-kcalendarutils"
  "kpim6-kimap"
  "kpim6-kldap"
  "kpim6-kmailtransport"
  "kpim6-kmbox"
  "kpim6-kmime"
  "kpim6-kontactinterface"
  "kpim6-kpimtextedit"
  "kpim6-ktnef"
  "kpim6-libkdepim"
  "kpim6-libkgapi"
  "kpim6-libkleo"
  "kpim6-libksieve"
  "kpim6-mailcommon"
  "kpim6-mailimporter"
  "kpim6-messagelib"
  "kpim6-pimcommon"
  "~apt:libassuan-dev"
  "~apt:libboost-dev"
  "~apt:libboost-graph-dev"
  "~apt:libgpgme11-dev"
  "~apt:libgpgmepp-dev"
  "~apt:libkgantt-dev"
  "~apt:libx11-dev"
  "~apt:pkgconf"
  "qt6-5compat"
  "qt6-base"
  "qt6-declarative"
  "qt6-phonon"
  "qt6-tools"
  "qt6-webchannel"
  "qt6-webengine"
  "~apt:shared-mime-info"
  "~apt:xsltproc"
  "~apt:zlib1g-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="gear"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

KUSE=(
  "+x11"
  "-test"
)

# ── Build ─────────────────────────────────────────────────────────────────────

build() {
  _kport_lib="${KPORT_LIB_DIR:-/usr/lib/kport}/use-helpers.sh"
  [[ -f "$_kport_lib" ]] && source "$_kport_lib"

  cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DBUILD_TESTING=$(use_flag test ON OFF 2>/dev/null || echo OFF) \
    -DBUILD_QCH=$(use_flag docs ON OFF 2>/dev/null || echo OFF)

  cmake --build build --parallel "$(nproc)"
}

# ── Package ───────────────────────────────────────────────────────────────────

package() {
  DESTDIR="$pkgdir" cmake --install build
}
