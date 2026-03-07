# GitHub 推送指南

## 当前状态
- 本地 Git 仓库：✅ 已配置
- 远程仓库：✅ 已配置 (https://github.com/hhr346/audio_book_reader.git)
- 推送认证：⏳ 需要配置

## 推送方法

### 方法 1: HTTPS + Personal Access Token (推荐)

#### 1. 创建 Token
1. 访问 https://github.com/settings/tokens
2. 点击 "Generate new token"
3. 选择 scopes: repo, workflow
4. 生成并保存 token

#### 2. 配置凭证
```bash
cd /Users/hhr/Desktop/audio_book_reader
git remote set-url origin https://<USERNAME>:<TOKEN>@github.com/hhr346/audio_book_reader.git
git push -u origin main
```

### 方法 2: SSH Key

#### 1. 生成 SSH Key
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

#### 2. 添加 Key 到 GitHub
1. 复制公钥：`cat ~/.ssh/id_ed25519.pub | pbcopy`
2. 访问 https://github.com/settings/keys
3. 点击 "New SSH key"
4. 粘贴并保存

#### 3. 切换远程 URL
```bash
git remote set-url origin git@github.com:hhr346/audio_book_reader.git
git push -u origin main
```

## 推送命令
```bash
cd /Users/hhr/Desktop/audio_book_reader
git push origin main
```

## 验证推送
访问 https://github.com/hhr346/audio_book_reader 查看最新提交

---

*待用户配置认证信息后执行推送*
