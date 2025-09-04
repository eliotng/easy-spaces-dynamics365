# GitHub Actions Power Platform Integration Setup

This guide sets up **official Microsoft Power Platform GitHub Actions** for automated deployment from GitHub to your Dynamics 365 environment.

## 🎯 What This Enables

- ✅ **Automated deployment** from GitHub to Power Platform
- ✅ **Bidirectional sync** between repository and Dynamics 365
- ✅ **Official Microsoft solution** (not custom scripts)
- ✅ **Triggered on push** or manual dispatch
- ✅ **Proper source control integration**

## 📋 Setup Steps

### Step 1: Add GitHub Repository Secrets

Go to your GitHub repository: https://github.com/eliotng/easy-spaces-dynamics365

1. Click **Settings** → **Secrets and variables** → **Actions**
2. Add these repository secrets:

**Required Secrets:**
```
POWERPLATFORM_USERNAME: EliotNg@quix24.onmicrosoft.com
POWERPLATFORM_PASSWORD: [your Microsoft account password]
```

### Step 2: Workflow Configuration

The workflow file is already created at:
```
.github/workflows/deploy-to-powerplatform.yml
```

**Environment:** `https://org7cfbe420.crm.dynamics.com`  
**Solution:** `EasySpacesSolution`  
**Source:** `out/EasySpaces_Working_Update.zip`

### Step 3: Trigger Deployment

**Manual Trigger:**
1. Go to **Actions** tab in GitHub
2. Select **"Deploy Easy Spaces to Power Platform"**
3. Click **"Run workflow"**
4. Click **"Run workflow"** button

**Automatic Trigger:**
- Any push to `main` branch with changes in `solution/` or `out/` folders

## 🔄 Workflow Process

1. **Checkout** repository code
2. **Install** Power Platform tools  
3. **Authenticate** to your Dynamics 365 environment
4. **Import** solution from `out/EasySpaces_Working_Update.zip`
5. **Export** current solution state
6. **Unpack** and sync back to repository
7. **Commit** any changes back to GitHub

## 🎉 Benefits

- **Official Microsoft Integration** - Uses Microsoft's own GitHub Actions
- **Automated Deployment** - Push to deploy your entities
- **Bidirectional Sync** - Changes sync both ways
- **No CLI Issues** - Bypasses local authentication problems
- **Enterprise Ready** - Scalable for team development

## 🚀 Usage

After setup, simply:
```bash
git add .
git commit -m "Update entities"
git push origin main
```

The GitHub Action will automatically deploy to your Power Platform environment!

## 🔗 References

- [Microsoft Power Platform Actions](https://github.com/microsoft/powerplatform-actions)
- [Official Documentation](https://aka.ms/poweractionsdocs)
- [Sample Workflows](https://github.com/microsoft/powerplatform-actions-lab)