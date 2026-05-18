#!/usr/bin/env bash
# KPort pacscript — gear/kpim6-messagelib
# Promoted from generated/ — review and test before merging to main
#
# KDE PIM messaging library, data files This package contains the data files

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kpim6-messagelib"
pkgver="26.04.1"
pkgdesc="KDE PIM messaging library, data files"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://pim.kde.org/"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/messagelib-26.04.1.tar.xz"
)
sha256sums=(
  "3b00a06032995097f84cb1b56efb9778fc35bf94fbd6a4ea2f7999e5cc663c6c"
)

depends=(
  "kf6-karchive"
  "kf6-kcalendarcore"
  "kf6-kcodecs"
  "kf6-kcolorscheme"
  "kf6-kcompletion"
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kcontacts"
  "kf6-kcoreaddons"
  "kf6-kguiaddons"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-kio"
  "kf6-kitemmodels"
  "kf6-kitemviews"
  "kf6-kjobwidgets"
  "kf6-kservice"
  "kf6-ktextaddons"
  "kf6-ktexttemplate"
  "kf6-ktextwidgets"
  "kf6-kwidgetsaddons"
  "kf6-kxmlgui"
  "kf6-sonnet"
  "kf6-syntax-highlighting"
  "kpim6-akonadi"
  "kpim6-akonadi-contacts"
  "kpim6-akonadi-mime"
  "kpim6-akonadi-search"
  "kpim6-grantleetheme"
  "kpim6-kidentitymanagement"
  "kpim6-kmailtransport"
  "kpim6-kmbox"
  "kpim6-kmime"
  "kpim6-kpimtextedit"
  "kpim6-libgravatar"
  "kpim6-libkdepim"
  "kpim6-libkleo"
  "kpim6-pimcommon"
  "~apt:libgpgmepp7"
  "~apt:libqgpgmeqt6-15"
  "~apt:libssl3t64"
  "qt6-base"
  "qt6-webengine"
)

makedepends=(
  "cmake"
  "doxygen"
  "git"
  "kf6-kcodecs"
  "kf6-extra-cmake-modules"
  "kf6-karchive"
  "kf6-kcompletion"
  "kf6-kconfig"
  "kf6-kcontacts"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-kitemviews"
  "kf6-knewstuff"
  "kf6-knotifications"
  "kf6-ktextaddons-dev"
  "kf6-ktexttemplate-dev"
  "kf6-kwindowsystem"
  "kf6-kxmlgui"
  "kpim6-akonadi-dev"
  "kpim6-akonadi-mime-dev"
  "kpim6-akonadi-search-dev"
  "kpim6-grantleetheme-dev"
  "kpim6-kidentitymanagement-dev"
  "kpim6-kldap-dev"
  "kpim6-kmailtransport-dev"
  "kpim6-kmbox-dev"
  "kpim6-kmime-dev"
  "kpim6-kpimtextedit-dev"
  "kpim6-libgravatar-dev"
  "kpim6-libkdepim-dev"
  "kpim6-libkleo-dev"
  "kpim6-pimcommon-dev"
  "libcups2-dev"
  "libgpgme-dev"
  "libgpgmepp-dev"
  "libqca-qt6-dev"
  "libqgpgmeqt6-dev"
  "qt6-base-dev"
  "qt6-tools-dev"
  "qt6-webchannel-dev"
  "qt6-webengine-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="gear"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

KUSE=(
  "-docs"
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
