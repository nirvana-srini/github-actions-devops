# github-actions-devops

Github actions is a CI/CD tool offered by Github.

Github actions provide image as environment ubuntu.

Github actions connect to AWS using OpenID Connect(OIDC) open standard for authentication.

Configuration supports using YAML

Pipeline starts with name ex. CICD Pipeline or workflow

`on:` is trigger `push:` push code on branch(ex.main) triggers pipeline and runs automatically.
    `pull_request` and `workflow_branch`

`jobs` `runs_on` ubuntu latest environmet.

`steps` 

inside project need to create a .github/workflows/test.yaml

For keys: `setting-> secrets and variables -> create secret `

# Deployment protection rules
Add reviewers for production manual approvals otherwise automatically run the workflow job.
![1793554441247](image/README/1793554441247.png)


