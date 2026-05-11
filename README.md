# Kennie

Kennie 是一款以 Flutter 製作的 2D 像素風 RPG 專案，整合了 Flame / Bonfire 遊戲框架、地圖場景切換、NPC 對話、寶箱獎勵、裝備與背包系統、等級成長、技能解鎖、BGM / SFX 音效，以及本機存檔流程。

目前專案已具備可遊玩的主流程：

- 標題選單與設定頁
- 村莊與遺跡兩張主要地圖
- NPC 對話與故事旗標推進
- 近戰 / 火球戰鬥
- 裝備、藥水、寶箱與掉落
- 首領戰與條件式場景解鎖
- `SharedPreferences` 本地存檔

## 專案特色

- **Flutter 遊戲化實作**：使用 `Flame` 與 `Bonfire` 建立 2D RPG 遊戲體驗。
- **資料驅動場景設計**：地圖、傳送點、NPC、敵人、寶箱集中定義於地圖設定檔中。
- **狀態集中管理**：以 `GameStateController` 統一管理玩家數值、背包、任務旗標、對話與存檔。
- **多平台支援**：專案包含 `web`、`android`、`ios`、`macos` 目標平台。
- **觸控與鍵盤並存**：桌面 / Web 可用鍵盤操作，行動裝置提供虛擬搖桿與觸控按鈕。
- **音效與 BGM 管理**：標題、一般地圖、Boss 場景使用不同背景音樂，並支援主選單 BGM 音量調整。

## 技術棧

- **Framework**：Flutter
- **Game Engine**：Flame、Bonfire
- **State Management**：Provider
- **Storage**：SharedPreferences
- **Audio**：audioplayers、just_audio
- **UI**：Material 3、NES UI、Auto Size Text
- **Map / Tile**：tiled、flame_tiled

主要相依套件定義於 [pubspec.yaml](pubspec.yaml)。

## 執行需求

- Flutter SDK：建議使用與 Dart `3.9.x` 相容的 Flutter 版本
- Dart SDK：`^3.9.2`
- Xcode / Android Studio：若需建置 iOS / Android
- Chrome 或其他瀏覽器：若需執行 Web 版本

## 快速開始

### 1. 安裝相依套件

```bash
flutter pub get
```

### 2. 啟動專案

#### Web

```bash
flutter run -d chrome
```

#### macOS

```bash
flutter run -d macos
```

#### Android / iOS

```bash
flutter run
```

> 在行動裝置上，遊戲會優先鎖定橫向畫面；在 Web 標題選單進入遊戲時，會嘗試切換為橫向全螢幕。

## 測試

目前專案包含基本 Widget 測試，可使用：

```bash
flutter test
```

測試檔位於 [test/widget_test.dart](test/widget_test.dart)。

## 建置

### 建置 Web

```bash
flutter build web
```

### 建置 macOS

```bash
flutter build macos
```

### 建置 Android APK

```bash
flutter build apk
```

## 遊戲操作

### 鍵盤操作

- `方向鍵`：移動
- `J` / `Enter`：近戰攻擊
- `K` / `2`：施放火球
- `H` / `1`：快速使用藥水
- `Space`：互動 / 對話 / 開啟物件
- `Esc`：開啟或關閉暫停選單

### 觸控操作

- 左下虛擬搖桿：角色移動
- 右下施法搖桿：瞄準並放開施法
- 右側按鈕：互動 / 攻擊
- 右上按鈕：暫停選單

## 遊戲內容概覽

### 場景

- **Village**：初始村莊，包含長老、商人、斥候與教學型敵人。
- **Ruins**：迷霧遺跡區域，包含多種可重生怪物、Boss 與條件式出口機制。

### 系統

- **角色成長**：等級、經驗值、HP / MP、攻擊 / 防禦。
- **技能解鎖**：火球會隨等級提升進化為更高階技能。
- **裝備系統**：武器、防具與附加屬性會影響最終能力值。
- **背包系統**：支援藥水、裝備、任務道具與寶箱獎勵。
- **劇情旗標**：以 `storyFlags` 推進對話、場景開關與 Boss 條件。
- **存檔機制**：使用本地儲存保留地圖、座標、等級、背包與旗標狀態。

## 專案結構

以下為主要目錄與責任分工：

```text
lib/
├─ main.dart                    # 入口，初始化 Flutter 與畫面方向
├─ app.dart                     # MaterialApp 與遊戲 Overlay 組裝
├─ audio_manager.dart           # BGM / SFX 管理
├─ game/
│  ├─ rpg_game.dart             # 遊戲主體、地圖切換、輸入與 Overlay 同步
│  └─ overlay_ids.dart          # Overlay ID 常數
├─ map/
│  ├─ world_map_manager.dart    # 地圖載入、碰撞、互動、敵人與事件處理
│  ├─ map_definition.dart       # 場景、傳送點、NPC、敵人、寶箱定義
│  └─ ...
├─ state/
│  ├─ game_state_controller.dart # 玩家狀態、背包、任務旗標、對話、戰鬥、存檔
│  ├─ models/                    # 遊戲資料模型
│  └─ services/save_repository.dart
├─ components/                  # 角色、敵人、特效、可互動物件元件
├─ ui/overlays/                 # HUD、標題、對話、暫停、寶箱等 UI
└─ platform/                    # Web 顯示 / 全螢幕輔助
```

### 資源目錄

- [assets/audio](assets/audio)
- [assets/bgm](assets/bgm)
- [assets/images](assets/images)

地圖素材與角色圖像均由 `pubspec.yaml` 中的 `assets` 設定載入。

## 核心程式入口

- 應用入口： [lib/main.dart](lib/main.dart)
- App 組裝： [lib/app.dart](lib/app.dart)
- 遊戲主循環： [lib/game/rpg_game.dart](lib/game/rpg_game.dart)
- 地圖管理： [lib/map/world_map_manager.dart](lib/map/world_map_manager.dart)
- 遊戲狀態： [lib/state/game_state_controller.dart](lib/state/game_state_controller.dart)

## 存檔機制

存檔由 [lib/state/services/save_repository.dart](lib/state/services/save_repository.dart) 負責，底層使用 `SharedPreferences`，目前的主要特性如下：

- 使用單一主存檔鍵值 `kennie.save.primary`
- 儲存玩家位置、地圖、等級、裝備、背包與劇情旗標
- 可從標題選單直接接續遊戲

若要重置本機進度，可清除 App / 瀏覽器儲存資料。

## 開發建議

### 新增地圖

1. 將地圖資源加入 `assets/images/...`
2. 在 [pubspec.yaml](pubspec.yaml) 確認資源路徑已註冊
3. 於 [lib/map/map_definition.dart](lib/map/map_definition.dart) 新增 `MapDefinition`
4. 若有特殊互動或敵人邏輯，再補到 [lib/map/world_map_manager.dart](lib/map/world_map_manager.dart)

### 新增敵人 / NPC / 寶箱

- 敵人、NPC、寶箱基本配置可優先放在 [lib/map/map_definition.dart](lib/map/map_definition.dart)
- 若需要額外戰鬥或事件邏輯，再延伸 `components/` 與狀態控制層

### 新增 UI Overlay

- Overlay 設計集中在 [lib/ui/overlays](lib/ui/overlays)
- 新增後記得同步更新 [lib/game/overlay_ids.dart](lib/game/overlay_ids.dart) 與 [lib/app.dart](lib/app.dart)

