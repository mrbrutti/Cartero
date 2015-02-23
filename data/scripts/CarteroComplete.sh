# file: CarteroAutoComplete
# cartero parameter-completion

_CarteroAutoComplete ()
{
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
	local line=${COMP_LINE%$cur}

  case "$cur" in
    -*)
		COMPREPLY=( $( compgen -W '`$line --list-options` `$line --list-short-options`' -- $cur ) );;
   	*)
		COMPREPLY=( $( compgen -W '`cartero --list-commands` `bin/cartero --list-payloads`' -- $cur ) );;
  esac

  return 0
}

complete -F _CarteroAutoComplete -o filenames cartero
