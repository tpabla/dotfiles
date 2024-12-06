alias orgsync='echo "Pulling remote orgfiles to local..." && rsync -r ep:~/orgfiles/ ~/orgfiles/
--del'
alias orgpush='echo "Pushing local orgfiles to remote" && rsync -r  ~/orgfiles/ ep:~/orgfiles/ --del'
