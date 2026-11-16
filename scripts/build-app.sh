#!/usr/bin/env bash
# 编出 Universal（arm64 + x86_64）release 二进制，组装 dist/六本豆.app 并做本机 ad-hoc 签名。
# Apple 芯片和 Intel 的 Mac 都能用。只在 Mac mini 上跑（需要 Xcode 工具链：多架构 swift build 和 lipo）。
# 环境变量：SAFARIER_VERSION 覆盖版本号（默认 1.5.0），SAFARIER_BUILD 覆盖构建号（默认 git 提交数），
#           SINGBOX_DIR 覆盖自带 sing-box 的目录（默认 .build/sing-box，由 scripts/build-singbox.sh 在编译机上编出来）。
# scripts/build-app.sh --info-plist PATH：只生成 Info.plist 到 PATH（测试用），不编译、不组装。
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
VERSION="${SAFARIER_VERSION:-1.5.0}"
BUILD="${SAFARIER_BUILD:-$(git rev-list --count HEAD 2>/dev/null || echo 1)}"
TARGET_ARCH="${SAFARIER_ARCH:-arm64}"
BUNDLE_ID="com.liubendou.browser"
APP="${SAFARIER_APP_OUT:-$ROOT/dist/六本豆.app}"
SINGBOX_DIR="${SINGBOX_DIR:-$ROOT/.build/sing-box}"
MIERU_DIR="${MIERU_DIR:-$ROOT/.build/mieru}"

# App 声明支持的语言：覆盖 /Applications/Safari.app/Contents/Resources 下的 .lproj，另加 zh-Hans、zh-Hant。
# 只写开发区域时 CFBundle 把本 App 的本地化锁成 zh-Hans，WebKit / WebCore 跟着主 Bundle 走：不管环境语言是什么，
# 网页读到的 navigator.mimeTypes 描述、表单校验提示（validationMessage）都是简体中文，和真 Safari 对不上（检测脚本会读）。
LOCALIZATIONS=(
  ar ca cs da de el en en_AU en_CA en_GB en_IN en_PH es es_419 es_US fi fr fr_CA he hi hr hu id it ja ko ms nl no pl pt pt_PT ro ru sk sl sv th tr uk vi
  zh-Hans zh-Hant zh_CN zh_HK zh_TW
)

# 界面文案是简体中文，开发区域仍是 zh-Hans；CFBundleAllowMixedLocalizations 让系统框架（WebKit、AppKit）
# 按进程语言（Runner 的 -AppleLanguages 就是环境语言）本地化，不再跟着主 Bundle 固定成简体中文。
write_info_plist() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  cat > "$path" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleAllowMixedLocalizations</key>
	<true/>
	<key>CFBundleDevelopmentRegion</key>
	<string>zh-Hans</string>
	<key>CFBundleDisplayName</key>
	<string>六本豆</string>
	<key>CFBundleExecutable</key>
	<string>Liubendou</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>${BUNDLE_ID}</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleLocalizations</key>
	<array>
$(printf '\t\t<string>%s</string>\n' "${LOCALIZATIONS[@]}")
	</array>
	<key>CFBundleName</key>
	<string>六本豆</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>${VERSION}</string>
	<key>CFBundleVersion</key>
	<string>${BUILD}</string>
	<key>LSApplicationCategoryType</key>
	<string>public.app-category.productivity</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>NSCameraUsageDescription</key>
	<string>网页请求使用摄像头时（例如视频会议），六本豆 会先询问你。</string>
	<key>NSMicrophoneUsageDescription</key>
	<string>网页请求使用麦克风时（例如视频会议），六本豆 会先询问你。</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSHumanReadableCopyright</key>
	<string>六本豆</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>NSSupportsAutomaticTermination</key>
	<false/>
	<key>NSSupportsSuddenTermination</key>
	<false/>
</dict>
</plist>
PLIST
  plutil -lint "$path" >/dev/null
}

if [ "${1:-}" = "--info-plist" ]; then
  [ -n "${2:-}" ] || { echo "用法：scripts/build-app.sh --info-plist PATH" >&2; exit 2; }
  write_info_plist "$2"
  exit 0
fi

is_universal() {
  local archs
  archs=" $(lipo -archs "$1" 2>/dev/null || true) "
  [[ "$archs" == *" arm64 "* && "$archs" == *" x86_64 "* ]]
}

case "$TARGET_ARCH" in
  arm64|x86_64) BUILD_ARCHS=(--arch "$TARGET_ARCH") ;;
  universal) BUILD_ARCHS=(--arch arm64 --arch x86_64) ;;
  *) echo "未知架构：$TARGET_ARCH" >&2; exit 1 ;;
esac
for file in sing-box LICENSE COPYING SOURCE; do
  [ -f "$SINGBOX_DIR/$file" ] || { echo "缺少 $SINGBOX_DIR/$file" >&2; exit 1; }
done
for file in mieru LICENSE SOURCE; do
  [ -f "$MIERU_DIR/$file" ] || { echo "缺少 $MIERU_DIR/$file" >&2; exit 1; }
done
if ! "$SINGBOX_DIR/sing-box" version | grep -q 'with_quic'; then
  echo "sing-box 缺少 with_quic" >&2; exit 1
fi
swift build -c release "${BUILD_ARCHS[@]}" --product Safarier
BIN="$(swift build -c release "${BUILD_ARCHS[@]}" --show-bin-path)/Safarier"
copy_slice() {
  local source="$1" destination="$2"
  if [ "$TARGET_ARCH" = universal ] || [ "$(lipo -archs "$source")" = "$TARGET_ARCH" ]; then
    cp "$source" "$destination"
  else
    lipo "$source" -thin "$TARGET_ARCH" -output "$destination"
  fi
}

echo "==> 组装 $APP ($TARGET_ARCH)"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
mkdir -p "$APP/Contents/Helpers" "$APP/Contents/Resources/ThirdParty/sing-box"
mkdir -p "$APP/Contents/Resources/ThirdParty/mieru"
copy_slice "$BIN" "$APP/Contents/MacOS/Liubendou"
copy_slice "$SINGBOX_DIR/sing-box" "$APP/Contents/Helpers/sing-box"
copy_slice "$MIERU_DIR/mieru" "$APP/Contents/Helpers/mieru"
chmod 755 "$APP/Contents/MacOS/Liubendou" "$APP/Contents/Helpers/sing-box" "$APP/Contents/Helpers/mieru"
printf 'APPL????' > "$APP/Contents/PkgInfo"
cp "$SINGBOX_DIR/LICENSE" "$SINGBOX_DIR/COPYING" "$SINGBOX_DIR/SOURCE" "$APP/Contents/Resources/ThirdParty/sing-box/"
cp "$MIERU_DIR/LICENSE" "$MIERU_DIR/SOURCE" "$APP/Contents/Resources/ThirdParty/mieru/"
cp "$ROOT/NOTICE.md" "$APP/Contents/Resources/ThirdParty/NOTICE.md"
cp "$ROOT/LICENSE" "$APP/Contents/Resources/ThirdParty/LICENSE.txt"
mkdir -p "$APP/Contents/Resources/ThirdParty/Yams"
cp "$ROOT/.build/checkouts/Yams/LICENSE" "$APP/Contents/Resources/ThirdParty/Yams/"

# 界面翻译：主 Bundle 的 Resources 下按语言放 .lproj，没写的语言回落到开发区域 zh-Hans。
for lproj in "$ROOT"/Resources/*.lproj; do
  [ -d "$lproj" ] || continue
  cp -R "$lproj" "$APP/Contents/Resources/"
done
# 开发区域是简体中文：从英文表的键生成中文表（键就是中文原文），不往仓库里放副本。
mkdir -p "$APP/Contents/Resources/zh-Hans.lproj"
swift "$ROOT/scripts/make-zh-strings.swift" "$ROOT/Resources/en.lproj/Localizable.strings" "$APP/Contents/Resources/zh-Hans.lproj/Localizable.strings"

echo "==> 生成图标"
ICON_WORK="$(mktemp -d)"
trap 'rm -rf "$ICON_WORK"' EXIT
swift "$ROOT/scripts/make-icon.swift" "$ICON_WORK/icon.png"
ICONSET="$ICON_WORK/AppIcon.iconset"
mkdir -p "$ICONSET"
for spec in 16:16x16 32:16x16@2x 32:32x32 64:32x32@2x 128:128x128 256:128x128@2x 256:256x256 512:256x256@2x 512:512x512 1024:512x512@2x; do
  sips -z "${spec%%:*}" "${spec%%:*}" "$ICON_WORK/icon.png" --out "$ICONSET/icon_${spec#*:}.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

write_info_plist "$APP/Contents/Info.plist"

# Older updaters remove quarantine recursively before installing the bundle.
chmod -R u+w "$APP"

echo "==> ad-hoc 签名"
# 由内向外签：先签里面的 sing-box，再签整个 App（App 的签名把它封进去）。不用 --deep，否则会把 sing-box 重签掉。
codesign -s - --force --identifier com.liubendou.browser.sing-box "$APP/Contents/Helpers/sing-box"
codesign -s - --force --identifier com.liubendou.browser.mieru "$APP/Contents/Helpers/mieru"
codesign -s - --force "$APP"
codesign --verify --deep --strict "$APP"
for binary in "$APP/Contents/MacOS/Liubendou" "$APP/Contents/Helpers/sing-box" "$APP/Contents/Helpers/mieru"; do
  if [ "$TARGET_ARCH" = "universal" ]; then
    is_universal "$binary" || { echo "$binary 不是 Universal：$(lipo -archs "$binary")" >&2; exit 1; }
  else
    [ "$(lipo -archs "$binary")" = "$TARGET_ARCH" ] || { echo "$binary 架构不是 $TARGET_ARCH：$(lipo -archs "$binary")" >&2; exit 1; }
  fi
  echo "    ${binary#"$APP/"}：$(lipo -archs "$binary")"
done

echo "==> 完成：${APP}（${VERSION} build ${BUILD}，arch：${TARGET_ARCH}）"
codesign -dv "$APP" 2>&1 | grep -E '^(Identifier|Format|Signature)=' || true
