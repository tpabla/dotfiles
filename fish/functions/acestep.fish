function acestep --description 'Launch the ACE-Step Gradio UI and open it in the browser'
    set -l url http://mac-studio:7860
    # Open the browser once the server responds; the first run can take a while because of model downloads
    fish -c "for i in (seq 3600); if curl -s -o /dev/null http://127.0.0.1:7860; echo; echo 'ACE-Step ready: $url'; open $url; exit; end; sleep 1; end" &
    disown
    ~/Repos/ACE-Step-1.5/start_gradio_ui_macos.sh $argv
end
