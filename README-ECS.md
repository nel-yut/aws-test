# AWS ECS Blue-Green Deployment with CodeDeploy

このプロジェクトは、QiitaのBlue/Greenデプロイメント構成を参考にしたAWS ECSとCodeDeployを使用したCI/CDパイプラインです。

参考記事: [ECSをBlue/Greenデプロイするイメージをterraformで掴んでみる](https://qiita.com/suiwave/items/e37338031c07e4dee52a)

## 🏗️ アーキテクチャ

- **ECS Fargate**: コンテナオーケストレーション（CODE_DEPLOYコントローラー使用）
- **Application Load Balancer (ALB)**: プロダクション（80番）とテスト（8080番）リスナー
- **CodeDeploy**: Blue/Greenデプロイメント管理
- **CodeBuild**: Dockerイメージビルド・ECRプッシュ
- **CodePipeline**: CI/CDパイプライン統合
- **CodeCommit**: ソースコードリポジトリ
- **ECR**: コンテナイメージレジストリ
- **VPC**: ネットワーク分離（コスト削減のためNAT Gateway 1台構成）

## 📁 プロジェクト構造

```
├── app/                          # コンテナアプリケーション
│   ├── app.py                   # Flask アプリケーション
│   ├── requirements.txt         # Python依存関係
│   ├── Dockerfile              # コンテナイメージ定義
│   ├── buildspec.yml           # CodeBuildビルド仕様
│   ├── appspec_template.yaml   # CodeDeployアプリケーション仕様
│   └── taskdef_template.json   # ECSタスク定義テンプレート
├── infra-ecs/                   # ECSインフラ用Terraform
│   ├── main.tf                 # プロバイダー設定
│   ├── variables.tf            # 変数定義
│   ├── vpc.tf                  # VPCリソース（NAT Gateway 1台）
│   ├── alb.tf                  # ロードバランサー（prod/test listeners）
│   ├── ecs.tf                  # ECSクラスター・サービス
│   ├── ecr.tf                  # ECRリポジトリ
│   ├── codebuild.tf           # CodeBuildプロジェクト
│   ├── codedeploy.tf          # CodeDeployアプリケーション
│   ├── codepipeline.tf        # CodePipelineパイプライン
│   ├── outputs.tf             # 出力値
│   ├── modules/               # 再利用可能モジュール
│   │   ├── iam_role/
│   │   └── security_group/
│   └── json/
│       └── container_definitions.json
└── README-ECS.md               # このファイル
```

## 🚀 セットアップ手順

### 1. 前提条件

- AWS アカウント
- AWS CLI 設定済み
- Terraform >= 1.5
- Docker
- `my_ip_cidr_block` 変数を自分のIPアドレスに設定（セキュリティ）

### 2. インフラストラクチャのデプロイ

```bash
cd infra-ecs
terraform init
terraform plan
terraform apply
```

### 3. アプリケーションコードの準備

CodeCommitリポジトリにアプリケーションコードをプッシュします：

```bash
# CodeCommitリポジトリの情報を取得
terraform output codecommit_repository_clone_url_http

# Git設定とプッシュ
cd ../app
git init
git add .
git commit -m "Initial commit"
git remote add origin <CODECOMMIT_CLONE_URL>
git push -u origin main
```

## 🔄 Blue-Green デプロイメントフロー

### 1. 自動デプロイメント

1. **ソースコミット**: CodeCommitにコードをプッシュ
2. **ビルド**: CodeBuildがDockerイメージをビルド・ECRにプッシュ
3. **デプロイ**: CodeDeployがBlue/Greenデプロイメントを実行

### 2. デプロイメントプロセス

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ CodeCommit  │───▶│ CodeBuild   │───▶│ CodeDeploy  │
│ (Source)    │    │ (Build)     │    │ (Deploy)    │
└─────────────┘    └─────────────┘    └─────────────┘
                           │
                           ▼
                   ┌─────────────┐
                   │     ECR     │
                   │  (Images)   │
                   └─────────────┘
```

### 3. トラフィックフロー

- **本番環境**: `http://<ALB_DNS>` (80番ポート) → Blue環境
- **テスト環境**: `http://<ALB_DNS>:8080` (8080番ポート) → Green環境

## 📊 アプリケーションエンドポイント

- `GET /`: メインページ（現在の環境情報を表示）
- `GET /health`: ヘルスチェック（ALBヘルスチェック用）
- `GET /info`: 詳細な環境情報

## 🔧 環境変数

アプリケーションは以下の環境変数で動作制御：

- `ENVIRONMENT`: `BLUE` または `GREEN`
- `VERSION`: アプリケーションバージョン（コミットハッシュ）
- `PORT`: リスニングポート（8080）

## 📈 モニタリング

- **CloudWatch Logs**: `/ecs-task/bg-deploy-test` ログループ
- **ALB Access Logs**: S3バケット
- **Container Insights**: ECSクラスターメトリクス
- **CodePipeline**: パイプライン実行履歴

## 🔒 セキュリティ

- VPC内プライベートサブネットでのコンテナ実行
- セキュリティグループによる最小権限アクセス
- ECRイメージスキャン自動実行
- IAMロールベースの権限管理

## 🚨 トラブルシューティング

### よくある問題

1. **CodePipeline失敗**
   ```bash
   aws codepipeline get-pipeline-execution --pipeline-name bg-deploy-test-pipeline --pipeline-execution-id <ID>
   ```

2. **ECSタスク起動失敗**
   ```bash
   aws ecs describe-services --cluster bg-deploy-test-ecs-cluster --services bg-deploy-test-ecs-service
   ```

3. **ALBヘルスチェック失敗**
   ```bash
   aws elbv2 describe-target-health --target-group-arn <TARGET_GROUP_ARN>
   ```

4. **CodeBuildビルド失敗**
   ```bash
   aws codebuild batch-get-builds --ids <BUILD_ID>
   ```

## 🛠️ カスタマイズ

### 設定可能な項目

- `variables.tf` でインフラパラメータを調整
- `my_ip_cidr_block` でアクセス許可IPを制限
- `buildspec.yml` でビルドプロセスをカスタマイズ
- `appspec_template.yaml` でデプロイ動作を制御

### デプロイ設定の変更

```bash
# 手動でデプロイ実行
aws codedeploy create-deployment \
  --application-name bg-deploy-test-codedeploy-app \
  --deployment-group-name bg-deploy-test-deployment-group
```

## 💰 コスト最適化

- NAT Gateway 1台構成（az-1a のみ）
- ECS Fargateタスク最小構成（256 CPU, 512 Memory）
- ALBアクセスログは必要に応じて無効化可能

## 📝 重要な設定

### Blue/Green切り替えタイミング

- **自動切り替え**: 180分のタイムアウト設定
- **テスト期間**: 8080番ポートでテスト可能
- **ロールバック**: デプロイ失敗時自動ロールバック
- **ターミネート**: 成功時に5分後に旧環境削除

### ignore_changes設定

以下のリソースはCodeDeployによって動的変更されるため、Terraformから除外：

- ALBリスナールールのターゲットグループ
- ECSサービスのロードバランサー設定
- ECSサービスのタスク定義

## 📞 サポート

問題や質問がある場合は、以下を確認してください：

1. CloudWatchログでエラー詳細を確認
2. CodePipelineの実行状況を確認
3. ECSサービスのイベントログを確認
4. ALBターゲットグループのヘルス状況を確認

## 📚 参考資料

- [Qiita記事: ECSをBlue/Greenデプロイするイメージをterraformで掴んでみる](https://qiita.com/suiwave/items/e37338031c07e4dee52a)
- [AWS CodeDeploy Blue/Green Deployments](https://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html)
- [AWS ECS Blue/Green Deployments](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-type-bluegreen.html)