# Contributing

Thanks for helping. Reports from other watches are the most useful contribution: open a
[watch report](https://github.com/jvitorcosta/garmin-watchfaces/issues/new?template=watch-report.yml)
with your model, firmware and a photo, even when the answer is "it doesn't build".

## Working on it

You need the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) and your own developer key.
Build steps for each face are in the [README](README.md).

- Never commit a developer key (`*.der`) or a built `.prg`.
- Pokéface's sprites and font are downloaded at build time and must stay out of the repository.
  New art must be your own or licensed for reuse, with its licence noted in the README.
- Say in your pull request which watch you tested on, or "simulator only".
- Commits use [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): subject`.
