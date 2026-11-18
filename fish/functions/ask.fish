function __ask_structured --argument-names system prompt schema
    # remaining stdin is passed through to claude; prints the schema-validated reply as compact JSON
    claude --model haiku -p --output-format json --json-schema $schema --append-system-prompt $system $prompt \
        | jq -ce '.structured_output // error("no structured output")'
end

function __ask_field --argument-names system prompt name description
    # schema with a single string field; prints that field's raw value
    set -l schema (jq -nc --arg n $name --arg d $description \
        '{type:"object",properties:{($n):{type:"string",description:$d}},required:[$n]}')
    __ask_structured $system $prompt $schema | jq -r --arg n $name '.[$n]'
end

function ask --description 'Ask Claude a shell question, with fish context'
    argparse -x j,x,s h/help j/jq x/exec 's/schema=' -- $argv
    or return

    if set -q _flag_help; or test (count $argv) -eq 0
        echo 'usage: ask [-j | -x | -s SCHEMA] "question" [context...]   (or: cmd | ask ...)' >&2
        echo '  -j, --jq             reply with a jq filter and run it on the input (non-JSON input is converted first)' >&2
        echo '  -x, --exec           reply with a fish command, then confirm before running it' >&2
        echo '  -s, --schema SCHEMA  reply with JSON matching SCHEMA: a JSON Schema, a schema file, or a plain description' >&2
        return 1
    end

    set -l question $argv[1]
    set -l context $argv[2..-1]
    # (cat) in a command substitution hangs on piped stdin in interactive fish; the read builtin doesn't
    if not isatty stdin
        while read -l line
            set -a context $line
        end
    end

    set -l system "The user's shell is fish. Give commands that work in fish, not bash or zsh. Be brief."
    set -l cmdline (status current-commandline)
    if test -n "$cmdline"
        set system "$system The user ran this command line; any stdin is the output of what precedes `ask`: $cmdline"
    end

    if set -q _flag_jq
        __ask_jq $system $question $context
    else if set -q _flag_exec
        __ask_exec $system $question $context
    else if set -q _flag_schema
        __ask_schema $system $question $_flag_schema $context
    else if test (count $context) -gt 0
        printf '%s\n' $context | claude --model haiku -p --append-system-prompt $system $question
    else
        claude --model haiku -p --append-system-prompt $system $question
    end
end

function __ask_schema --argument-names system question spec
    set -l schema
    if test -f $spec
        set schema (jq -c 'del(.["$schema"])' $spec)
        or return 1
    else if printf '%s' $spec | jq -e 'type == "object"' >/dev/null 2>&1
        set schema (printf '%s' $spec | jq -c 'del(.["$schema"])')
    else
        set schema (__ask_field $system "Write a JSON Schema, without a \$schema key, describing this output. Prefer an object at the top level; put lists under a named property. Description: $spec" \
            schema 'The JSON Schema, as a JSON-encoded string')
        or return 1
        set schema (printf '%s' $schema | jq -ce 'select(type == "object") | del(.["$schema"])' 2>/dev/null)
        or begin
            echo 'ask -s: could not generate a valid JSON Schema from the description' >&2
            return 1
        end
    end

    printf '%s\n' $argv[4..-1] | __ask_structured $system $question $schema | jq .
end

function __ask_jq --argument-names system question
    set -l data (string join \n -- $argv[3..-1] | string collect)
    if test -z "$data"
        echo 'ask -j: no input; pipe data in or pass it as arguments' >&2
        return 1
    end

    if not printf '%s\n' $data | jq empty 2>/dev/null
        set data (printf '%s\n' $data | __ask_structured $system \
            "Convert the input to well-structured JSON that preserves all of its information, under the data property." \
            '{"type":"object","properties":{"data":{}},"required":["data"]}' | jq -c .data)
        or return 1
    end

    set -l filter (printf '%s\n' $data | head -c 20000 | __ask_field $system \
        "The input is JSON (possibly truncated). Write a jq filter that does this: $question" \
        filter 'A jq filter program, without a leading jq command or surrounding quotes')
    or return 1
    set_color brblack >&2
    echo "jq '$filter'" >&2
    set_color normal >&2
    printf '%s\n' $data | jq $filter
end

function __ask_exec --argument-names system question
    set -l cmd (printf '%s\n' $argv[3..-1] | __ask_field $system $question \
        command 'One fish command line that does what the user asks')
    or return 1
    if test -z "$cmd"
        echo 'ask -x: no command returned' >&2
        return 1
    end

    set_color green
    echo $cmd
    set_color normal
    read -l -P 'run? [y/N] ' answer </dev/tty
    or return 1
    if string match -qi 'y*' -- $answer
        history append -- $cmd
        eval $cmd
    end
end
