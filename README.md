# MarketCap Game

Anlage.App Market Cap Game: https://anlage.app/game

## Download Links

- [Android: Play Store](https://play.google.com/store/apps/details?id=app.anlage.game.marketcap)
- [iOS: App Store](https://itunes.apple.com/us/app/marketcap-game-by-anlage-app/id1446255350?mt=8)


## CI

Currently I have configured https://app.bitrise.io/dashboard/builds for creating iOS builds.

## Development

Some pseudo-secret files (firebase tokens, itunes affiliate tokens, etc.) are encrypted using 
blackbox. These are required for successful building, but can be faked during development.

For production to decrypt install [blackbox](https://github.com/StackExchange/blackbox) and run
`blackbox_postdeploy`.
