# sample_conf4nix

NixOS 25.05 系を前提にした最小サンプル構成です。`UUID` 参照を基本にし、公開しやすいように機種依存の設定や secret 分離は省いています。

## 方針

- `flake` で管理
- `nixpkgs` は `nixos-25.05` を参照
- `fileSystems` は `UUID` を基本にする
- パスワードは説明用に `initialPassword = "Password"` を使う
- SDDM テーマや重い追加パッケージは含めない

## 使い方

`configuration.nix` の以下を自分の環境に置き換えてください。

- `REPLACE_WITH_ROOT_UUID`
- `REPLACE_WITH_EFI_UUID`
- `REPLACE_WITH_SWAP_UUID`

UUID は次で確認できます。

```bash
lsblk -f
blkid
```

インストール例:

```bash
nixos-install --flake .#sample
```

## 注意

この repo はサンプルです。実運用では `initialPassword` の直書きは避け、`hashedPassword` や secret 管理へ移行した方が安全です。
