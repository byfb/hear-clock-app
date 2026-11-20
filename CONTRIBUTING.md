# Contributing to Hear Clock

## Start a branch

Start from the latest `main`. Name the branch `<type>/<short-description>`, using lowercase words separated by hyphens. Use `feat/` for a feature, `fix/` for a bug fix, `hotfix/` for an urgent fix, and `chore/` for documentation or maintenance. [Conventional Branch](https://conventionalbranch.org/)

```sh
git fetch origin main
git switch --no-track -c chore/clarify-widget-setup origin/main
```

## Commit and check your changes

Keep each commit focused on one change. Write the subject as `type: description` or `type(scope): description`. A guide edit might use `docs: clarify how to add the widget`. A clock fix might use `fix(widget): preserve the selected digit size`. [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)

For app changes, run `flutter analyze` and `flutter test`. For widget or speech changes, also try the affected behavior on an Android launcher. For README changes, check the links and preview the affected languages. Check animated images with reduced motion enabled. [Build and test instructions](docs/development.md#test-and-build-an-apk)

## Open and merge a pull request

Push your branch with `git push -u origin HEAD` and open a pull request into `main`. Use a Conventional Commit title that describes the whole change. In the description, say what changed and how you tested it.

If the pull request conflicts with `main`, rebase your contribution branch onto the latest `origin/main`.

```sh
git fetch origin main
git rebase origin/main
```

At each conflict, edit the affected files, stage them with `git add`, and run `git rebase --continue`. Once the rebase finishes, repeat the relevant checks and update your pushed branch with `git push --force-with-lease origin HEAD`.

Choose **Squash and merge** and use the pull request title as the commit subject on `main`. To publish an APK, follow the separate tag workflow on the long-lived `release` branch. [Publish a release](docs/development.md#publish-a-release)
