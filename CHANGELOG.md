## CHANGELOG

#### 12-00-14:
- Added metasploit support. Will not commit until metasploit accepts changes.
  UPDATE: 12/13/14 - Changes accepted #4142.

#### 2-10-15:
- added rubocop & fixed a bunch of things. Still plenty to go.
- Added Cartero::SinatraHelpers helpers to make webserver code cleaner and smaller.

#### 2-14-15:
- added Cartero::CrawlerBlock Register to block and redirect bots

#### 2-18-15
- Added first version of Cloner --reverse-proxy

#### 2-19-15
- Pushing version 0.4
- Uploaded non-stable changes to Github

#### 2-22-15
- Added _CarteroAutoComplete script for basic Bash AutoComplete.
- Fixed OptsParser language around [non]mandatory arguments.
- Fixed minor issues on install script and added autocomplete logic.
- Added --list-short-options to all commands.
- Added beef logic to AdminWeb & AdminWebServer
- Pushing version 0.4.1

#### 2-28-15
- CryptoBox AES support Implemented. ~/.cartero/config now has new option crypto which allows use to pick encryption methods.

#### 3-1-15
- Several Fixes for rubocop
- Code refactoring.
- Starting Code documentation. I need to remember how things work.

#### 3-3-15
- Commands::information for better understanding of commands.
  + Data for now will be --but not limited to-- name, description, author, type, license & references
  + Added option (--details) to commands that would correctly display information on commands.
  + Although the system supports all type of information fields. We do limit it the types of objects to Arrays of Strings or Strings.
- beef hook generation command
