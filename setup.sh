#!/bin/bash

mypath=$(readlink -f "${BASH_SOURCE:-$0}")
mydir=$(dirname "${mypath}")
# shellcheck source=src/functions.sh
source "${mydir}/src/functions.sh"

# COLORS #
GREEN=$(tput setaf 2)
ORANGE=$(tput setaf 3)
# RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
# CYAN=$(tput setaf 6)
# BLACK=$(tput setaf 0)
RESET=$(tput setaf 7)

# FUNCTIONS
info_text() {
	echo "${GREEN}$1${RESET}"
}

h1_text() {
	echo "${BLUE}$1${RESET}"
}

warn_text() {
	echo "${ORANGE}$1${RESET}"
}

setup_alias() {
	envfile=$(envfile)
	cdir=$(pwd)
	{ echo ""; echo "# WIX CLI"; echo "alias wix=\"source ${cdir}/wix-cli.sh\""; } >> "${envfile}"
	# shellcheck source=$HOME/.bashrc
	source "${envfile}"
}

setup_completion() {
	cdir=$(pwd)
	{ echo ""; echo "# WIX CLI"; echo "source ${cdir}/src/completion.sh"; } >> "${HOME}/.bash_completion"
	# shellcheck source=$HOME/.bash_completion
	source "${HOME}/.bash_completion"
}

# INITIAL SETUP
if ! using_zsh; then
	info_text "Installing dependencies..."
	sudo apt-get install xclip
	curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
	sudo apt-get install speedtest
fi

if mac; then
	info_text "Installing dependencies..."
	brew install xclip jq
	brew tap teamookla/speedtest
	brew install speedtest --force
fi

info_text "Installing python dependencies..."
pip3 install -r requirements.txt

info_text "Setting up wix-cli..."
chmod +x wix-cli.sh


# SETUP METADATA FILES
md_dir=.wix-cli
mkdir "${md_dir}"
declare -a files=("git-user.txt" "git-orgs.txt" "dir-aliases.txt" "run-configs.txt" "todo.txt" ".env")
for i in "${files[@]}"; do
	if ! [[ -f "${md_dir}/${i}" ]]; then
		touch "${md_dir}/${i}"
		chmod +rwx "${md_dir}/${i}"
	else
		warn_text "File ${i} already exists. Would you like to overwrite it? [[ y / n ]"
		read -r overwrite_file
		if [[ "${overwrite_file}" = "y" ]]; then
			rm "${md_dir}/${i}"
			touch "${md_dir}/${i}"
			chmod +rwx "${md_dir}/${i}"
		fi
	fi
done
if ! [[ -d "${md_dir}/run-configs" ]]; then
	mkdir "${md_dir}/run-configs"
fi


# GET USER SPECIFIC DETAILS
echo ""
h1_text "Please enter your github username:"
read -r gituser
echo "username=${gituser}" >> ${md_dir}/git-user.txt

echo ""
h1_text "Please enter your full name (this will be used for copyright clauses on GitHub software licenses):"
read -r fullname
echo "name=${fullname}" >> ${md_dir}/git-user.txt

echo ""
h1_text "Please enter the default github organization you want to setup with this cli: (enter it's github username) ***leave empty if none***"
read -r gitorg
if [[ "${gitorg}" != "" ]]; then
	echo "default=${gitorg}" >> ${md_dir}/git-orgs.txt
fi

echo ""
echo "The default directory aliases setup are as follows:"
echo "1) docs = ~/Documents"
echo "2) down = ~/Downloads"
h1_text "Would you like to include these? [[ y / n ]"
read -r keep_default_diraliases
if [[ "${keep_default_diraliases}" = "y" ]]; then
	{ echo "docs=~/Documents"; echo "down=~/Downloads"; } >> ${md_dir}/dir-aliases.txt
fi

# FINAL SETUP
echo ""
info_text "Okay we should be good to go!"

# ADD ALIAS TO ENV FILE
envfile=$(envfile)
alias_check=$(alias wix)
if [[ "${alias_check}" != "" ]]; then
	warn_text "It looks like you already have a wix alias setup. Would you like to overwrite it? [[ y / n ]"
	read -r overwrite_alias
    if [[ "${overwrite_alias}" = "y" ]]; then
		echo "${ORANGE}Please edit the ${envfile} file manually to remove your old alias${RESET}"
        setup_alias
    fi
else
	setup_alias
fi

# ADD COMPLETION TO COMPLETION FILE
completionfile="${HOME}/.bash_completion"
if [[ -f "${completionfile}" ]]; then
	completion_search=$(cat "${completionfile}" | grep -c "$(pwd)/src/completion.sh")
	if [[ "${completion_search}" != "" ]]; then
		warn_text "It looks like you already have wix completion setup. Would you like to overwrite it? [[ y / n ]"
		read -r overwrite_completion
		if [[ "${overwrite_completion}" = "y" ]]; then
			echo "${ORANGE}Please edit the ${HOME}/.bashrc file manually to remove your old completion${RESET}"
			setup_completion
		fi
	else
		setup_completion
	fi
else
	warn_text "It looks like you don't have a ${HOME}/.bash_completion file (allowing you to use the wix command with tab-completion)."
	warn_text "Would you like to create one? [[ y / n ]"
	read -r create_completion
	if [[ "${create_completion}" = "y" ]]; then
		touch "${HOME}/.bash_completion"
		setup_completion
	else
		error_text "You need to have a ${HOME}/.bash_completion file to use wix completion, rerun this setup script if you would like to create one."
	fi
fi

echo ""
info_text "WIX CLI successfully added to ${envfile} !"
info_text "Use 'wix' to get going :)"
echo ""