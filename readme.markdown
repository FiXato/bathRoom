### bathRoom
a Ruby wrapper around [TOIlet](http://caca.zoy.org/wiki/toilet)

Implements most of TOIlets options and has added support for listing all
supported fonts, formats and filters.
Also supports showing formatted sample text in every installed font
available.
Finally, it allows for interactive deleting of each installed font.

## Usage Examples:
```
$ bathroom.rb --usage
A couple of usage examples:
--------------------------------------------------------------------------------
Print 'Hello world!' in rainbow colours with IRC formatting using a random font
  /home/fixato/bin/bathroom.rb --irc --random-font --text 'Hello world!' --rainbow --output

Print the font name in metallic colours with unicode formatting using the calgphy2 font
  /home/fixato/bin/bathroom.rb --unicode --metal --font calgphy2 --output

List all fonts installed in /path/to/your/figlet/fontsdir
  /home/fixato/bin/bathroom.rb --fonts-dir /path/to/your/figlet/fontsdir --fonts

List all installed fonts, supported filters and formats based on default fonts-dir of /usr/share/figlet/
  /home/fixato/bin/bathroom.rb --support

List all supported filters and formats:
  /home/fixato/bin/bathroom.rb --filters --formats

For each installed font, output the toilet command and the font name, along with the alphabet showcasing each font.
  /home/fixato/bin/bathroom.rb --output-all --text-alphabet

Ask for each font if you want to delete the font or keep it.
  /home/fixato/bin/bathroom.rb --interactive-delete
```
