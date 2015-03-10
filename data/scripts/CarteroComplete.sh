# file: CarteroAutoComplete
# cartero parameter-completion

_CarteroAutoComplete ()
{
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
	read -a cmd <<<  "$COMP_LINE"


  case "$cur" in
    -*)
    # This is ghetto and I know it does not support all cases. But it will help for now.
    # More complex detailed case statement to follow.

		COMPREPLY=( $( compgen -W '`${cmd[0]} ${cmd[1]} --list-options` `${cmd[0]} ${cmd[1]} --list-short-options`' -- $cur ) );;
   	*)
		COMPREPLY=( $( compgen -W '`cartero --list-commands` `cartero --list-payloads`' -- $cur ) );;
  esac

  return 0
}

complete -F _CarteroAutoComplete -o filenames cartero
