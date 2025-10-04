# Xoferif

> Firefox ブックマークの**フォルダ階層をタグのツリー**として取り込み・整理・検索できる Web 管理アプリ
> **Python 3.12 / Django 5 / PostgreSQL 15+ / Bootstrap / pytest**

---

## 目次

* [特徴](#特徴)
* [アーキテクチャ](#アーキテクチャ)
* [要件・設計ドキュメント](#要件設計ドキュメント)
* [クイックスタート](#クイックスタート)

  * [Docker Compose で起動](#docker-compose-で起動)
  * [ローカル環境で起動](#ローカル環境で起動)
* [主要操作](#主要操作)

  * [Firefox JSON のインポート](#firefox-json-のインポート)
  * [タグツリーと検索](#タグツリーと検索)
* [開発](#開発)

  * [ディレクトリ構成](#ディレクトリ構成)
  * [コード規約](#コード規約)
  * [テスト](#テスト)
  * [pre-commit](#pre-commit)
  * [CI/CD](#cicd)
* [環境変数](#環境変数)
* [セキュリティ/監査](#セキュリティ監査)
* [ライセンス](#ライセンス)

---

## 特徴

* **JSONインポート（プレビュー→実行）**：Firefox エクスポートを検証・可視化してから取り込み
* **タグのツリー化**：フォルダ階層をそのままタグ親子関係として登録（`menu/toolbar/unfiled/mobile` 対応）
* **重複検出/マージ**：URL 正規化＋ハッシュで同一候補を提示しマージ
* **高速な検索/フィルタ**：キーワード + タグ AND/OR、子孫タグの包含オプション
* **監査ログ（History）**：認証・インポート・タグ/ブックマーク操作を記録
* **DevSecOps**：Ruff/Black/mypy/Bandit/djLint/pip-audit、pytest、GitHub Actions

---

## アーキテクチャ

```mermaid
flowchart LR
  User[Browser<br/>Bootstrap UI] --> Web[Django App<br/>Views/Services]
  Web --> DB[(PostgreSQL 15+)]
  Web -.-> CI[GitHub Actions / pre-commit]
```

* Django Template + **Bootstrap** でサーバサイド描画
* モデル：Bookmark / Tag（MPTT）/ BookmarkTag（M2M）/ History
* Service 層：importer / tag_resolver / dedupe / exporter

---

## 要件・設計ドキュメント

* `design/requirements.md`（**正規版 v1**）
* `design/design.md`（**正規版 v1**）
* `design/CONTRIBUTING.md`（**正規版 v1**）
* `AGENTS.md`（**正規版 v1**）

> これらに矛盾する実装は受け入れられません。更新は Issue → PR で合意の上行います。

---

## クイックスタート

### Docker Compose で起動

1. `.env` を作成（例）

```env
DJANGO_ENV=development
SECRET_KEY=change-me
DATABASE_URL=postgres://app:app@db:5432/app
ALLOWED_HOSTS=127.0.0.1,localhost
```

2. 起動

```bash
docker compose up -d
docker compose exec web python manage.py migrate
docker compose exec web python manage.py createsuperuser
docker compose exec db psql -U app -d app -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
docker compose exec db psql -U app -d app -c "CREATE EXTENSION IF NOT EXISTS unaccent;"
```

3. アプリ
   `http://localhost:8000`（管理画面：`/admin`）

### ローカル環境で起動

```bash
python -m venv .venv && source .venv/bin/activate
pip install -U pip wheel
pip install -r requirements.txt -r requirements-dev.txt
cp .env.example .env  # なければ作成
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
```

> PostgreSQL をローカル利用する場合は拡張 `pg_trgm`, `unaccent` を作成してください。

---

## 主要操作

### Firefox JSON のインポート

1. 画面の **[インポート]** から Firefox の JSON を選択
2. **プレビュー**で件数/新規タグ/重複候補/エラーを確認
3. 問題なければ **実行** → トランザクションで取り込み
4. 結果は **History** に記録

**取り込みルール（要点）**

* ルート `menu/toolbar/unfiled/mobile` を上位タグとして扱う（表示 ON/OFF 設定可）
* 各ブックマークには**所属パスのすべてのタグ**（親〜子）を付与
* URL 正規化（スキーム/末尾`/`/フラグメント/追跡クエリ）→ `url_norm_hash` で重複検出
* 重複はスキップ/更新/マージを選択可能

### タグツリーと検索

* 左ペイン：ツリー（折り畳み、件数バッジ、改名/移動/結合/削除）
* 右ペイン：一覧・詳細（キーワード + タグ AND/OR、子孫タグ包含）

---

## 開発

### ディレクトリ構成

```
.
├─ design/
│   ├─ requirements.md
│   └─ design.md
├─ bookmarks/
│   ├─ models.py        # Bookmark, Tag(MPTT), BookmarkTag, History
│   ├─ services/
│   │   ├─ importer.py
│   │   ├─ tag_resolver.py
│   │   ├─ dedupe.py
│   │   └─ exporter.py
│   ├─ views.py / urls.py / forms.py / admin.py / templates/
├─ core/                # settings, utils(url_normalize, validators), middleware
├─ tests/               # unit / service / view / admin / e2e
├─ AGENTS.md / CONTRIBUTING.md
└─ manage.py
```

### コード規約

* **Black**（行長 **88**）/**Ruff**/**mypy**/**Bandit**/**djLint**/**pip-audit**/**detect-secrets**
* **1関数1機能**・深いネスト禁止・早期 return 推奨
* **Docstring 必須（Google スタイル）**、**初心者にも分かる日本語コメント**、**「なぜ」重視**
* クエリは `select_related/prefetch_related`、一覧はページング必須

> 詳細は **CONTRIBUTING.md v1** を参照。

### テスト

```bash
pytest -vv
pytest --cov=./ --cov-report=term-missing
```

* レイヤ別：unit（純関数）→ service（import/dedupe）→ view（検索/認可/CSRF）→ admin
* E2E：実サンプル JSON を使った取り込み検証
* 目標カバレッジ：**80%+**

### pre-commit

```bash
pre-commit install
pre-commit run --all-files
```

### CI/CD

* GitHub Actions：Lint → 型 → SAST/依存 → Django Checks → pytest
* 重大脆弱性（High/Critical）/Lint/型/テスト失敗は **PR ブロック**

---

## 環境変数

| 変数              | 例                                       | 説明            |
| --------------- | --------------------------------------- | ------------- |
| `DJANGO_ENV`    | `development` / `production`            | 実行モード         |
| `SECRET_KEY`    | `change-me`                             | Django シークレット |
| `DATABASE_URL`  | `postgres://app:app@localhost:5432/app` | DB 接続         |
| `ALLOWED_HOSTS` | `127.0.0.1,localhost`                   | 許可ホスト         |
| `LOG_LEVEL`     | `INFO`                                  | ログレベル（任意）     |

---

## セキュリティ/監査

* CSRF / XSS（autoescape）/ クリックジャッキング対策 / **CSP**（`script-src 'self'`）
* 依存脆弱性：`pip-audit` をローカル＆CI で実行
* 機密情報：**環境変数/GitHub Secrets**、リポジトリ直書き禁止
* 監査：ログイン/インポート/タグ操作/CRUD/エクスポートを **History** に記録

---

## ライセンス

* OSS ライセンス:Apache-2.0

---

### 補足

* 学習目的で作成しているアプリになります。（作成中）
* 自動生成エージェント運用は **AGENTS.md v1** を参照。
