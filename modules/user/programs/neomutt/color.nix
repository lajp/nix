{ ... }:
{
  programs.neomutt.extraConfig = ''
    color index yellow default '.*'
    color index_author red default '.*'
    color index_number blue default
    color index_subject cyan default '.*'

    color index brightyellow black "~N"
    color index_author brightred black "~N"
    color index_subject brightcyan black "~N"

    color index brightyellow blue "~T"
    color index_author brightred blue "~T"
    color index_subject brightcyan blue "~T"

    mono bold bold
    mono underline underline
    mono indicator reverse
    mono error bold
    color normal default default
    color indicator brightblack white
    color sidebar_highlight red default
    color sidebar_divider brightblack black
    color sidebar_flagged red black
    color sidebar_new green black
    color normal brightyellow default
    color error red default
    color tilde black default
    color message cyan default
    color markers red white
    color attachment white default
    color search brightmagenta default
    color status brightyellow black
    color hdrdefault brightgreen default
    color quoted green default
    color quoted1 blue default
    color quoted2 cyan default
    color quoted3 yellow default
    color quoted4 red default
    color quoted5 brightred default
    color signature brightgreen default
    color bold black default
    color underline black default
    color normal default default

    color header brightmagenta default "^From"
    color header brightcyan default "^Subject"
    color header brightwhite default "^(CC|BCC)"
    color header blue default ".*"
    color body brightred default "[\-\.+_a-zA-Z0-9]+@[\-\.a-zA-Z0-9]+"
    color body brightblue default "(https?|ftp)://[\-\.,/%~_:?&=\#a-zA-Z0-9]+"
    color body green default "\`[^\`]*\`"
    color body brightblue default "^# \.*"
    color body brightcyan default "^## \.*"
    color body brightgreen default "^### \.*"
    color body yellow default "^(\t| )*(-|\\*) \.*"
    color body brightcyan default "[;:][-o][)/(|]"
    color body brightcyan default "[;:][)(|]"
    color body brightcyan default "[ ][*][^*]*[*][ ]?"
    color body brightcyan default "[ ]?[*][^*]*[*][ ]"
    color body red default "(BAD signature)"
    color body cyan default "(Good signature)"
    color body brightblack default "^gpg: Good signature .*"
    color body brightyellow default "^gpg: "
    color body brightyellow red "^gpg: BAD signature from.*"
    mono body bold "^gpg: Good signature"
    mono body bold "^gpg: BAD signature from.*"
    color body red default "([a-z][a-z0-9+-]*://(((([a-z0-9_.!~*'();:&=+$,-]|%[0-9a-f][0-9a-f])*@)?((([a-z0-9]([a-z0-9-]*[a-z0-9])?)\\.)*([a-z]([a-z0-9-]*[a-z0-9])?)\\.?|[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)(:[0-9]+)?)|([a-z0-9_.!~*'()$,;:@&=+-]|%[0-9a-f][0-9a-f])+)(/([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*(;([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*)*(/([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*(;([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*)*)*)?(\\?([a-z0-9_.!~*'();/?:@&=+$,-]|%[0-9a-f][0-9a-f])*)?(#([a-z0-9_.!~*'();/?:@&=+$,-]|%[0-9a-f][0-9a-f])*)?|(www|ftp)\\.(([a-z0-9]([a-z0-9-]*[a-z0-9])?)\\.)*([a-z]([a-z0-9-]*[a-z0-9])?)\\.?(:[0-9]+)?(/([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*(;([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*)*(/([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*(;([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*)*)*)?(\\?([-a-z0-9_.!~*'();/?:@&=+$,]|%[0-9a-f][0-9a-f])*)?(#([-a-z0-9_.!~*'();/?:@&=+$,]|%[0-9a-f][0-9a-f])*)?)[^].,:;!)? \t\r\n<>\"]"
  '';
}
