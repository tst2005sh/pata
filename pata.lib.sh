pata_builtin() {
		local self='pata builtin'
		case "$1" in
			(CmdExists)
				shift; command >/dev/null 2>&1 -v "$1"
			;;
			(In)
				shift
				local new="$1"
				case "$1" in
				(':'*) new="$NAMESPACE/${1#:}";;
				esac
				if [ -n "$new" ] && [ ! -e "$new" ]; then
					echo >&2 "$self: No such namespace $new"
					return 1
				fi
				NAMESPACE="$new";
			;;
			(Load) shift; . ./${NAMESPACE:+$NAMESPACE/}$1.cmd.sh;;
			(Cmd)
				shift;
				local hand="${PATA_COMMAND_HANDLER:-Aliaser}"
				local cmd ret
				if ! command >/dev/null 2>&1 -v "$PATA_COMMAND_HANDLER"; then
					cmd="$1";shift
				else
					if ! cmd="$("$hand" "$1")"; then
						echo >&2 "ERROR: PATA_COMMAND_HANDLER=$hand fail"
						return 1
					fi
					case "$cmd" in
						('') cmd="$1";shift
					esac
				fi
				"$cmd" "$@";
			;;
			(Chain)
				shift
				while [ $# -gt 0 ]; do
					case "$1" in
						('#'*) shift;;
						(*) break ;;
					esac
				done
				if [ $# -gt 1 ]; then
					local a1="$1";shift
					$self Chain "$a1" | $self Chain "$@";
					return $?
				fi
				if [ $# -gt 0 ]; then
					if [ "$1" != : ]; then
						$self Cmd "$1";
						#"$1";
					fi
				elif [ ! -t 0 ]; then
					cat
				fi
			;;
			(ChainOrDefault)
				shift
				while [ $# -gt 0 ]; do
					case "$1" in
						('#'*) shift;;
						(*) break ;;
					esac
				done
#				if [ $# -eq 0 ]; then
#					$self Chain default
#				else
#					$self Chain "$@"
#				fi
				$self Chain "${@:-default}"
			;;
			(ChainOrDefaultInput)
				shift
				{
					if [ -t 0 ]; then # currently no input data
						if $self CmdExists "default"; then
							defaultInput
						else
							echo >&2 "ERROR: no data and no defaultInput available"
							return 1
						fi
					else
						cat
					fi
				} | $self ChainOrDefault "$@"
			;;
			(DefaultOrChain) echo >&2 "FIXME: rename DefaultOrChain to ChainOrDefault"; return 12;;
			(DefaultInputOrChain) echo >&2 "FIXME: rename DefaultInputOrChain to ChainOrDefaultInput"; return 13;;
			(*)
#				local cmd="PATABUILTIN_$1"
#				if command >/dev/null 2>&1 -v "$cmd"; then
					echo >&2 "pata: builtin $1 not found"
					return 1
#				fi
#				shift
#				"$cmd" "$@"
			;;
		esac
}

pata_command() {
	local self='pata command'
	local cmd="$1";shift;
	case "$cmd" in
		(CmdExists|In|Load|Chain|ChainOrDefault|ChainOrDefaultInput|DefaultOrChain|DefaultInputOrChain)
			cmd="PATABUILTIN_$cmd"
		;;
		(GET|FILTER|CONVERT|COLUMN|OUTPUT)
			cmd="PATA_$cmd"
		;;
		(*)
			echo >&2 "$self: unsupported command $cmd";return 12
		;;
	esac

	case "$cmd" in
	(PATA_PATA_*)
		echo >&2 "$self: ERROR: loop detected? $cmd"
		return 123
	;;
	esac

	if command >/dev/null 2>&1 -v "$cmd"; then
		"$cmd" "$@"
	else
		case "$cmd" in
			(PATABUILTIN_*) pata builtin "$cmd";return $?;;
		esac
		echo >&2 "$self: command $cmd not found"
		return 1
	fi
}
pata() {
	local self=pata
	case "$1" in
		(builtin) local a1="$1";shift;"pata_$a1" "$@";;
		(command) local a1="$1";shift;"pata_$a1" "$@";;
		(buildin) echo >&2 "$self: typo? buildin instead of builtin ?"; return 124 ;;
		(-*) echo "Usage: pata builtin|command ...";return 0;;
		(*) echo >&2 "WARNING: FIX usage from 'pata ...' to 'pata command ...' for pata $*"
			pata command "$@"
		;;
	esac
}
