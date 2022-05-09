if !(test -f "/home/$USER/.gdbinit") ; \
		then touch "/home/${USER}/.gdbinit" ; \
	fi
echo "add-auto-load-safe-path ${PWD}/.gdbinit" >> /home/${USER}/.gdbinit