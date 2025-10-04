# CONTRIBUTING.md

> プロジェクト: Firefox ブックマーク Web 管理アプリ
> バージョン: v1.0
> 作成日: 2025-10-04 (JST)
> 参照関係: `requirements.md v1` → `design.md v1` → 本書 → `AGENTS.md`

---

## 1. 環境・運用ルール

* **言語/ランタイム**: Python **3.12**
* **フレームワーク**: Django 5.x
* **DB**: PostgreSQL 15+（本番/CI）、開発ローカルは SQLite 可
* **UI**: Bootstrap（Django Template）
* **テスト基盤**: pytest + pytest-django
* **インフラ**: Docker Compose（単一ノード運用）
* **タイムゾーン**: Asia/Tokyo（JST）
* **機密情報管理**: `.env` / GitHub Secrets（リポジトリ直書き禁止）
* **バックアップ**: PostgreSQL を日次ダンプ、Runbook に復旧手順を記録
* **監査**: ログイン/インポート/タグ操作/CRUD/エクスポートを History テーブルに記録

---

## 2. ブランチ運用・PR ルール

### 2.1 ブランチ戦略

* `main`: 保護ブランチ（常にデプロイ可能な状態）
* `feature/<issue#>-<slug>`: 機能開発
* `fix/<issue#>-<slug>`: バグ修正
* `chore/<slug>`: 設定・CI/CD・ドキュメント更新

### 2.2 コミットメッセージ規約

* **Conventional Commits 準拠**

  * `feat:` 機能追加
  * `fix:` バグ修正
  * `docs:` ドキュメント変更
  * `test:` テスト追加/変更
  * `chore:` CI/CD・設定変更

例:

```
feat: タグ結合時の衝突解決UIを追加
fix: URL正規化で末尾スラッシュ除去処理を修正
docs: CONTRIBUTING.md を更新
```

### 2.3 PR ルール

* 1 PR = 1 目的（大規模変更は分割）
* 必須チェック項目（PR テンプレに従う）

  * [ ] pytest 緑
  * [ ] Lint/型チェック通過
  * [ ] マイグレーション差分有無を明記
  * [ ] UI 変更はスクリーンショットを添付
  * [ ] セキュリティ影響を説明
  * [ ] ドキュメント更新（必要に応じて）

---

## 3. コーディング規約

### 3.1 フォーマット & 静的解析

* **Black**: 自動整形（行長 88 文字）
* **Ruff**: Lint（E, F, I, B, UP, D 規則を有効化）
* **mypy**: 型チェック（`django-stubs` 使用）
* **Bandit**: セキュリティ静的解析
* **djLint**: Django テンプレート検査
* **pip-audit**: 依存関係脆弱性チェック
* **detect-secrets**: シークレット検出

### 3.2 設計原則

* **1関数1機能**（単一責任、早期 return、深いネスト禁止）
* 再利用可能な共通処理は `core/utils` に集約

### 3.3 コメントと Docstring

* **Docstring 必須**（関数・クラスに Google スタイルで付与）
* **初心者でも理解できる日本語コメント**を優先
* コメントは「処理の説明」ではなく **「なぜそうするか」** を記載
* 処理単位でコメントを挿入し、前提・制約・副作用を明示
* Issue 番号や参考リンクはコメントに残す

例:

```python
def normalize_url(url: str) -> str:
    """
    URLを正規化して重複判定用のキーを生成する.

    Args:
        url: 入力URL

    Returns:
        正規化されたURL文字列

    Notes:
        なぜ: 重複判定を一貫性ある基準で行うため。
    """
    # スキーム・ホストを小文字化
    # 不要な末尾スラッシュを除去
    # トラッキングクエリを削除
    ...
```

---

## 4. テスト規約

### 4.1 テスト戦略

* **unit**: 純関数（URL 正規化、タグパス生成）
* **service**: importer/dedupe/exporter
* **view**: Django test client（検索/認可/CSRF）
* **admin**: 管理画面基本操作
* **E2E**: JSON インポート実ファイルによる統合テスト

### 4.2 実行方法

```bash
pytest -vv
pytest --cov=./ --cov-report=term-missing
```

### 4.3 基準

* カバレッジ 80%以上
* PR ではテスト同梱必須（既存テストも更新）
* 境界値・不変性テストを重視
* エラーケース（不正JSON、重複URL、タグ結合エラー）もテスト対象

---

## 5. CI/CD ゲート

### 5.1 GitHub Actions（ci.yml）

* **Lint/Format**: Ruff → Black
* **型チェック**: mypy
* **静的解析**: Bandit, djLint, detect-secrets
* **依存脆弱性**: pip-audit
* **Django Checks**: `makemigrations --check`, `check --deploy`
* **テスト**: pytest（Postgres サービス起動）
* 成果物: pytest レポート、カバレッジ（将来 SBOM）

### 5.2 pre-commit

* Black, Ruff, mypy, Bandit, djLint, pip-audit, detect-secrets
* Docstring/行長チェックも強制

---

## 6. リリース・運用

* **ブランチ戦略**: GitHub Flow（`main` 保護）
* **リリース**: タグ `vX.Y.Z` を付与しリリースノート生成
* **ロールバック**: Runbook に復旧手順を記載
* **監視**: `/healthz`・ログ（JSON, request_id）・主要メトリクス（HTTP レイテンシ、エラー率、インポート件数）

---

## 7. PR テンプレート

```
## 概要
- 何を・なぜ（Issue #）

## 変更点
- 主な実装内容
- マイグレーションの有無（あり→差分要約 / なし→理由）

## テスト
- [ ] unit
- [ ] service
- [ ] view/admin
- 実行結果要約（ログ・スクショ）

## セキュリティ影響
- 入力検証 / 権限 / CSRF / CSP など

## リリース・運用
- ロールバック手順
- 監視・メトリクス追加/変更の有無
```

---

## 8. 変更管理
