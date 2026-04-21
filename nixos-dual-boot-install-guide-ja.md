# NixOS デュアルブート導入手順

この手順は、既存の Windows などを残したまま NixOS を追加する前提でまとめています。`fdisk` でパーティションを作成した後から、`flake` を使って `nixos-install` するところまでを対象にしています。

## 前提

- 既存 OS と NixOS の両方を UEFI モードで使う
- 既存の EFI System Partition はできるだけ流用する
- インストール先ディスクを誤認しないよう、作業前に `lsblk -f` を必ず確認する
- 例では `/dev/nvme0n1` を使うが、実際のデバイス名は自分の環境に合わせる

## 1. パーティションを確認する

まず現在の構成を確認します。

```bash
lsblk -f
blkid
```

典型例:

- 既存 EFI パーティション: `/dev/nvme0n1p1`
- Windows パーティション: `/dev/nvme0n1p3`
- 新しく切った NixOS ルート: `/dev/nvme0n1p5`
- 必要なら swap: `/dev/nvme0n1p6`

## 2. ファイルシステムを作成する

既存の EFI パーティションは通常フォーマットしません。新規に作った NixOS 用だけ作成します。

### ルートを ext4 にする例

```bash
mkfs.ext4 -L nixos /dev/nvme0n1p5
```

### swap を作る例

```bash
mkswap -L swap /dev/nvme0n1p6
swapon /dev/nvme0n1p6
```

ラベルを付けておくと、`/dev/disk/by-label/...` でも参照できます。ただし基本は `UUID` 参照で進める方が無難です。ラベル参照は、設定を人間が読みやすくしたいときの補助的な方法として使います。

## 3. マウントする

既存の EFI を流用する例です。

```bash
mount /dev/nvme0n1p5 /mnt
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
```

EFI の実体が分からない場合は `lsblk -f` で `vfat` かつ `EFI` 系ラベルのものを確認します。

## 4. flake 管理の設定を配置する

HTTPS で clone する例:

```bash
git clone https://github.com/Lrnz3318/nixos.git /mnt/etc/nixos
```

SSH 鍵を Live 環境に入れているなら:

```bash
git clone git@github.com:Lrnz3318/nixos.git /mnt/etc/nixos
```

## 5. hardware-configuration.nix を生成する

インストール先の実機に合わせて再生成します。

```bash
nixos-generate-config --root /mnt
```

これで `/mnt/etc/nixos/hardware-configuration.nix` がそのマシン向けに更新されます。

## 6. パスワード用ファイルを置く

今の設定は `hashedPasswordFile` を使う前提なので、Live 環境で hash ファイルを置きます。

```bash
mkdir -p /mnt/etc/nixos/secrets
mkpasswd -m yescrypt > /mnt/etc/nixos/secrets/root-password-hash
mkpasswd -m yescrypt > /mnt/etc/nixos/secrets/nix-password-hash
```

`mkpasswd` が無い場合は `nix-shell -p whois --run 'mkpasswd -m yescrypt'` でも作れます。

## 7. 参照方式を確認する

NixOS の `fileSystems` では、次のような参照方法が使えます。

- `UUID`
- `PARTUUID`
- `/dev/disk/by-label/<LABEL>`
- `/dev/disk/by-partlabel/<PARTLABEL>`

基本方針:

1. まずは `hardware-configuration.nix` に生成された `UUID` をそのまま使う
2. UUID ではなくパーティション単位で厳密に識別したいなら `PARTUUID`
3. ラベル参照は読みやすさを優先したいときの補助策として使う

最初のインストールでは、特別な理由がなければ `UUID` のままで進めるのが安全です。

### `UUID` を使う例

`blkid` で UUID を確認します。

```bash
blkid /dev/nvme0n1p5
blkid /dev/nvme0n1p1
```

設定例:

```nix
fileSystems."/" = {
  device = "/dev/disk/by-uuid/7e78331e-9abc-46d0-8fe8-c455e7fd3610";
  fsType = "ext4";
};

fileSystems."/boot" = {
  device = "/dev/disk/by-uuid/9271-524F";
  fsType = "vfat";
};
```

### `by-label` を使う例

これは基本手順ではなく、読みやすさを上げたいときの補助的な方法です。

```nix
fileSystems."/" = {
  device = "/dev/disk/by-label/nixos";
  fsType = "ext4";
};
```

### `PARTUUID` を使う例

`blkid` で `PARTUUID` を確認します。

```bash
blkid /dev/nvme0n1p5
```

出力例:

```text
/dev/nvme0n1p5: LABEL="nixos" UUID="..." BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="12345678-05"
```

設定例:

```nix
fileSystems."/" = {
  device = "/dev/disk/by-partuuid/12345678-05";
  fsType = "ext4";
};
```

### `by-label` に切り替えたいケース

- UUID を毎回見比べるのが面倒
- ルートパーティションが 1 個だけで名前を付けた方が明快
- 自分の `configuration.nix` で人間が読みやすい参照にしたい

### `PARTUUID` に切り替えたいケース

- 同じラベル名を複数ボリュームで使う可能性がある
- パーティション単位で厳密に識別したい
- ファイルシステムを作り直してもパーティション識別を維持したい

注意:

- `UUID` はファイルシステムを再作成すると変わる
- `PARTUUID` はパーティションを切り直すと変わる
- `LABEL` は重複させると危険

## 8. 実際の参照先を検証する

マウント前後でリンク先を確認できます。

```bash
ls -l /dev/disk/by-label
ls -l /dev/disk/by-uuid
ls -l /dev/disk/by-partuuid
```

設定と実体が一致しているかを確認します。

## 9. インストールする

flake 名が `nixos` の場合:

```bash
nixos-install --flake /mnt/etc/nixos#nixos
```

別ホスト構成を使うなら:

```bash
nixos-install --flake /mnt/etc/nixos#nixos-dev
```

## 10. よくあるハマりどころ

### EFI を新規フォーマットしてしまう

既存 Windows があるなら、既存 EFI を使う方が安全です。誤って EFI を消すと既存ブートローダも飛びます。

### `configuration.nix` 側の参照と実ディスクが一致していない

`UUID` や `PARTUUID` を書き間違えた、あるいは `by-label` を書いたのに実際にはそのラベルを付けていないケースです。

確認:

```bash
ls -l /dev/disk/by-label
e2label /dev/nvme0n1p5
```

必要ならラベルを付け直します。

```bash
e2label /dev/nvme0n1p5 nixos
```

### `hardware-configuration.nix` が古い

別マシンの `hardware-configuration.nix` をそのまま使うと失敗しやすいです。Live 環境では毎回 `nixos-generate-config --root /mnt` を実行した方がよいです。

### `boot.loader.efi.canTouchEfiVariables = true;` が効かない

Live USB を Legacy BIOS で起動していると、UEFI 用の設定が正しく動かないことがあります。Live USB 自体を UEFI で起動し直してください。

## 11. 最小チェックリスト

- `lsblk -f` で対象ディスクを確認した
- NixOS 用ルートにファイルシステムを作成した
- 既存 EFI を `/mnt/boot` にマウントした
- repo を `/mnt/etc/nixos` に clone した
- `nixos-generate-config --root /mnt` を実行した
- `secrets/` に password hash を置いた
- `fileSystems` の参照先が実体と一致している
- `nixos-install --flake /mnt/etc/nixos#nixos` を実行した

## 12. インストール後

```bash
reboot
```

再起動後に NixOS が立ち上がれば完了です。必要なら NixOS 側で `git pull` し、`sudo nixos-rebuild switch --flake /etc/nixos#nixos` で更新できます。
