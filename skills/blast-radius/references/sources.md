# Sources

How to read each kind of input, and how to write the report back.
Write every comment body to a temp file first. Pass the file, not an inline string. This keeps quotes and newlines safe.

## Text or file

- Text: use it as the ticket body. The ID rule is in SKILL.md step 2.
- File: read it. The ID is the file name without extension. If the file has many tasks, ask which one, or measure the whole file and say so.

## GitHub issue

Input: `#42`, `42`, `owner/repo#42`, or `https://github.com/<owner>/<repo>/issues/42`.
If only a number: the repo is the current repo (`gh repo view --json nameWithOwner -q .nameWithOwner`).

```bash
gh issue view 42 --repo OWNER/REPO --json number,title,body,labels,comments,url,state
```

Find an older report comment (the marker is in report.md):

```bash
gh api repos/OWNER/REPO/issues/42/comments --paginate \
  --jq '.[] | select(.body | contains("<!-- blast-radius:before")) | .id'
```

Post a new comment:

```bash
gh issue comment 42 --repo OWNER/REPO --body-file /tmp/blast-radius-42.md
```

Edit a comment in place (COMMENT_ID from the search above):

```bash
gh api repos/OWNER/REPO/issues/comments/COMMENT_ID -X PATCH -F body=@/tmp/blast-radius-42.md
```

## GitHub PR

Input: a number, `owner/repo#12`, or `https://github.com/<owner>/<repo>/pull/12`.

```bash
gh pr view 12 --repo OWNER/REPO --json number,title,body,url,headRefName,baseRefName,files,additions,deletions,closingIssuesReferences
gh pr diff 12 --repo OWNER/REPO
```

`closingIssuesReferences` gives the linked issues. Use it first to find the ticket ID.
A PR comment is an issue comment. Use the same commands as above, with the PR number, and the marker `blast-radius:after`.

## Azure DevOps work item

Input: `AB#1234`, `1234` with `--org` and `--project`, or `https://dev.azure.com/<org>/<project>/_workitems/edit/1234`.
Get org and project from the URL. Else from `az devops configure --list`. Else from the git remote (`dev.azure.com/<org>/<project>/_git/<repo>`). Else ask.

```bash
az boards work-item show --id 1234 --org https://dev.azure.com/ORG --output json
```

Use `fields."System.Title"`, `fields."System.Description"` (HTML: strip the tags), and `fields."Microsoft.VSTS.Common.AcceptanceCriteria"`.

Read comments, and find an older report:

```bash
az devops invoke --area wit --resource comments --org https://dev.azure.com/ORG \
  --route-parameters project=PROJECT workItemId=1234 \
  --api-version 7.1-preview --http-method GET --output json
```

Search `.comments[].text` for `blast-radius:before`.

Post a new comment. The body file is JSON: `{"text": "<report>"}`. Add `--query-parameters format=markdown` so the text shows as Markdown. If the server rejects it, post HTML instead.

```bash
az devops invoke --area wit --resource comments --org https://dev.azure.com/ORG \
  --route-parameters project=PROJECT workItemId=1234 \
  --query-parameters format=markdown \
  --api-version 7.1-preview --http-method POST --in-file /tmp/blast-radius-1234.json
```

Edit in place: the same command with `commentId=ID` in `--route-parameters` and `--http-method PATCH`.

Diagrams: use ASCII here, not Mermaid.

## Azure Repos PR

```bash
az repos pr show --id 12 --org https://dev.azure.com/ORG --output json
```

For the diff, fetch both branches and use git:

```bash
git fetch origin SOURCE_BRANCH TARGET_BRANCH
git diff --stat origin/TARGET_BRANCH...origin/SOURCE_BRANCH
```

Linked work items: `az repos pr work-item list --id 12 --org https://dev.azure.com/ORG`.

Post a comment as a new thread. The body file is JSON:
`{"comments":[{"parentCommentId":0,"content":"<report>","commentType":1}],"status":1}`.

```bash
az devops invoke --area git --resource pullRequestThreads --org https://dev.azure.com/ORG \
  --route-parameters project=PROJECT repositoryId=REPO pullRequestId=12 \
  --api-version 7.1 --http-method POST --in-file /tmp/blast-radius-pr-12.json
```

Diagrams: use ASCII here, not Mermaid.

## When a command fails

- `gh` or `az` missing, or not logged in: tell the user the exact login command (`gh auth login` or `az login`), write the report as a file, and stop there.
- 403 or 404: say which repo or project, and ask the user to check access.
- Never retry a post more than once. A double post spams people.
