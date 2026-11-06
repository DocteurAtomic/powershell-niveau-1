# Module 1, clip 1.2: verb and noun.
# Run from the root of the clone, one command at a time at the console.

# A command, its type and the module it comes from.
Get-Command -Name Get-ChildItem

# The approved verbs: three of them, with their group and alias prefix.
Get-Verb -Verb Get, Remove, Copy

# Every command whose noun is Item, then the Get commands whose noun contains Item.
Get-Command -Noun Item
Get-Command -Verb Get -Noun *Item*

# Four kinds of commands: alias, cmdlet, function, application (a program of the system).
Get-Command -Name dir, gci, ls, Get-ChildItem, prompt
