# MujocoExample

SwiftUI + SceneKit で MuJoCo の particle demo を表示する iOS サンプルです。

## 実行方法

1. Xcode で `MujocoExample.xcodeproj` を開きます。

   ```sh
   open examples/MujocoExample/MujocoExample.xcodeproj
   ```

2. scheme は `MujocoExample` を選びます。
3. 実行先を iPhone Simulator または接続した iPhone にします。
4. `Run` を押します。

実機で動かす場合は、Xcode の `Signing & Capabilities` で自分の Team を選んでください。Bundle Identifier が他のアプリと衝突する場合は `com.example.MujocoExample` から変更してください。

## 前提

ルートの `output/mujoco.xcframework` が必要です。無い場合はリポジトリのルートで次を実行します。

```sh
make download
make build
```

## CLI でビルド確認する場合

```sh
xcodebuild \
  -project examples/MujocoExample/MujocoExample.xcodeproj \
  -scheme MujocoExample \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath examples/MujocoExample/.derivedData \
  build
```

`iOS 26.5 is not installed` や destination が無いというエラーが出る場合は、Xcode で `Settings... > Components` を開き、使用する iOS Platform / Simulator runtime をインストールしてください。その後、Xcode を再起動してから再実行します。
