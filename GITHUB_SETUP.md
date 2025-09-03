# GitHub Repository Setup Instructions

Your Easy Spaces Dynamics 365 project is ready to be pushed to GitHub!

## Steps to Create and Push to GitHub

### Option 1: Using GitHub Web Interface (Recommended)

1. **Create a new repository on GitHub:**
   - Go to https://github.com/new
   - Repository name: `easy-spaces-dynamics365`
   - Description: `Microsoft Dynamics 365 conversion of Salesforce Easy Spaces LWC sample app - Event management solution using Power Platform`
   - Set to **Public** (or Private if you prefer)
   - **DO NOT** initialize with README, .gitignore, or license (we already have these)
   - Click "Create repository"

2. **Push your local code to GitHub:**
   
   After creating the empty repository, GitHub will show you commands. Run these in your terminal:

   ```bash
   cd /home/e/projects/easy-spaces-dynamics365
   
   # Add the remote repository (replace YOUR_USERNAME with your GitHub username)
   git remote add origin https://github.com/YOUR_USERNAME/easy-spaces-dynamics365.git
   
   # Push the code
   git branch -M main
   git push -u origin main
   ```

### Option 2: Using GitHub CLI

If you have GitHub CLI installed:

```bash
# Install GitHub CLI if needed
# Windows: winget install --id GitHub.cli
# Mac: brew install gh
# Linux: See https://github.com/cli/cli#installation

# Authenticate with GitHub
gh auth login

# Create repository and push
cd /home/e/projects/easy-spaces-dynamics365
gh repo create easy-spaces-dynamics365 --public \
  --description "Microsoft Dynamics 365 conversion of Salesforce Easy Spaces LWC sample app" \
  --source=. --remote=origin --push
```

### Option 3: Using Git with Personal Access Token

1. **Create a Personal Access Token on GitHub:**
   - Go to https://github.com/settings/tokens
   - Click "Generate new token" → "Generate new token (classic)"
   - Give it a name like "easy-spaces-deploy"
   - Select scopes: `repo` (full control)
   - Generate and copy the token

2. **Push using the token:**
   ```bash
   cd /home/e/projects/easy-spaces-dynamics365
   
   # Add remote with token (replace TOKEN and USERNAME)
   git remote add origin https://TOKEN@github.com/USERNAME/easy-spaces-dynamics365.git
   
   # Push
   git push -u origin master:main
   ```

## After Pushing to GitHub

Once your repository is on GitHub, you can:

1. **Add topics** to make it discoverable:
   - `dynamics365`
   - `power-platform`
   - `power-apps`
   - `dataverse`
   - `canvas-app`
   - `model-driven-app`
   - `power-automate`

2. **Enable GitHub Pages** (optional) for documentation:
   - Go to Settings → Pages
   - Source: Deploy from branch
   - Branch: main, folder: / (root)

3. **Add a license** if desired:
   - Recommended: MIT or Apache 2.0 for open source

4. **Create releases** for version management:
   - Go to Releases → Create a new release
   - Tag version: v1.0.0
   - Release title: Initial Release
   - Describe the features

## Repository Structure on GitHub

Your repository will contain:
```
easy-spaces-dynamics365/
├── solution/               # Dynamics 365 solution files
├── model-driven-app/      # Model-driven app configuration
├── canvas-app/            # Canvas app JSON
├── power-automate/        # Flow definitions
├── data/                  # Sample data
├── scripts/               # Deployment automation
├── .gitignore            # Git ignore rules
├── README.md             # Main documentation
├── DEPLOYMENT_GUIDE.md   # Deployment instructions
└── GITHUB_SETUP.md       # This file
```

## Sharing Your Repository

Once published, share your repository URL:
```
https://github.com/YOUR_USERNAME/easy-spaces-dynamics365
```

This URL can be shared with:
- Your team members
- The Power Platform community
- In documentation or presentations
- On social media with #PowerPlatform #Dynamics365

## Need Help?

- GitHub Documentation: https://docs.github.com/
- Git Basics: https://git-scm.com/book/en/v2/Getting-Started-Git-Basics
- Power Platform Community: https://powerusers.microsoft.com/