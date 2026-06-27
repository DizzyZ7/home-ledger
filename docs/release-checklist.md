# Release checklist

## Product

- [ ] Confirm the release notes describe user-visible changes.
- [ ] Check RU and EN copy for new screens and error states.
- [ ] Verify mock mode still starts without an API or secrets.
- [ ] Capture and add redacted screenshots in `docs/images/`.

## Quality

- [ ] `make api-lint`
- [ ] `make api-test`
- [ ] `make mobile-analyze`
- [ ] `make mobile-test`
- [ ] Review CI result for the release commit.

## Security and privacy

- [ ] Check `git diff` for `.env`, credentials, private URLs and personal data.
- [ ] Ensure sample accounts and screenshots are synthetic.
- [ ] Review dependency update alerts.
- [ ] Confirm `JWT_SECRET_KEY` is configured outside source control for every deployment.

## Release

- [ ] Update `CHANGELOG.md`.
- [ ] Create annotated Git tag `vX.Y.Z`.
- [ ] Publish GitHub release with concise notes.
- [ ] Add a post-release GitHub Issue for the next milestone.
