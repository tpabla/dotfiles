function jqui --description 'Interactive jq explorer: pipe JSON in or pass a file'
    set -l tmp (mktemp -t ijq.XXXXXX.json)

    # Source the JSON from a file argument or from stdin.
    if test (count $argv) -gt 0
        if not test -f "$argv[1]"
            echo "jqui: file not found: $argv[1]" >&2
            rm -f $tmp
            return 1
        end
        cp "$argv[1]" $tmp
    else if not isatty stdin
        cat >$tmp
    else
        echo "jqui: pipe JSON to stdin or pass a file" >&2
        echo "usage: jqui [file.json]   |   command | jqui" >&2
        rm -f $tmp
        return 1
    end

    if not jq -e . $tmp >/dev/null 2>&1
        echo "jqui: input is not valid JSON" >&2
        rm -f $tmp
        return 1
    end

    # fzf drives the UI: the query box is the live jq filter, the preview
    # shows its result. ctrl-y copies the result, ctrl-f copies the filter.
    set -l out (echo "" | fzf \
        --print-query \
        --disabled \
        --ansi \
        --query="." \
        --preview "jq --color-output {q} $tmp 2>&1" \
        --preview-window="top:90%:wrap" \
        --header=(printf '%s' 'enter: print result   ctrl-y: copy result   ctrl-f: copy filter   esc: quit') \
        --bind="ctrl-y:execute-silent(jq {q} $tmp | pbcopy)" \
        --bind="ctrl-f:execute-silent(printf %s {q} | pbcopy)")
    set -l fzf_status $status

    # esc / abort exits 130; nothing to print.
    if test $fzf_status -ne 0
        rm -f $tmp
        return 0
    end

    # With --print-query the query (our filter) is the first output line.
    set -l filter $out[1]
    jq "$filter" $tmp
    set -l rc $status
    rm -f $tmp
    return $rc
end
