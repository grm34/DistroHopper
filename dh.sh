#!/bin/bash

#
#LANGUAGE=cs_CZ
#LANG=cs_CZ
TEXTDOMAIN=distrohopper
TEXTDOMAINDIR=/usr/share/locale

# bugs notice
function some_bugs() {
	echo $"Done"
	echo $"PS: You saw some bugs?"
	echo $"Could you please provide feedback?"
	echo $"How do you like DistroHopper?"
	echo $"What can be improved, added, changed?"
	echo $" Let me know..."
	echo $"Flawless distro hopping..." && echo "zenobit"
}

function show_help() {
	printf "DistroHopper v. $version\nquickemu v. $("$prefix"quickemu --version)\n"
echo $"Possible arguments:"
echo $"	-h	--help			Show this help and exit"
 echo "---------------------------------------------------------"
echo $"	-d	--dir			Set default directory where VMs are stored"
echo $"	-i	--install		Install DistroHopper"
 echo "---------------------------------------------------------"
echo $"	-m	--mode			Portable mode"
 echo "---------------------------------------------------------"
echo $"	-s	--supported		Update supported VMs"
echo $"	-r	--ready			Update ready to run VMs"
 echo "---------------------------------------------------------"
echo $"	-t	--tui			Run TUI"
echo $"	-g	--gui			Run GUI"
 echo "---------------------------------------------------------"
echo $"	-a	--add			Add new distro to quickget"
echo $"	-f	--functions		Sort functions in quickget"
echo $"	-p	--push			Push changed quickget to quickemu project #todo"
 echo "---------------------------------------------------------"
echo $"	-c	--copy			Copy all ISOs to target dir (for Ventoy)"
 echo "---------------------------------------------------------"
	echo $"Homepage: dh.osowoso.xyz"
	echo $"Project hosted at: https://github.com/oSoWoSo/DistroHopper"
	echo $"Chat group on SimpleX: https://tinyurl.com/7hm4kcjx"
}

function portable() {
	[ -f "$DH_CONFIG" ] && mode_installed || mode_portable
}

function mode_portable() {
	VMS_DIR="$(pwd)"
	DH_CONFIG_DIR="$(pwd)"
	DH_ICON_DIR="$(pwd)/icons"
	prefix=./
	export "VMS_DIR" "DH_CONFIG_DIR" "DH_ICON_DIR" "TERMINAL" "replace" "prefix"
}

function mode_installed() {
	source "$DH_CONFIG"
	prefix=
	export "prefix"
}

# installation
function check_gui_dependencies() {
	[ -f "$PREFIX/yad" ] || echo $"Missing yad!"
}

function check_tui_dependencies() {
	[ -f "$PREFIX/fzf" ] || echo $"Missing fzf!"
}

function set_variables() {
	#progname="${progname:="${0##*/}"}"
	progname="DistroHopper"
	version="0.7"
	#GTK_THEME="alt-dialog"
	DH_CONFIG_DIR="$HOME/.config/distrohopper"
	DH_CONFIG="$DH_CONFIG_DIR/distrohopper.conf"
	DH_ICON_DIR="/usr/share/icons/distrohopper"
	TEXTDOMAIN=distrohopper
	TEXTDOMAINDIR=/usr/share/locale
	PREFIX="/usr/bin/"
	TERMINAL=sakura
	replace='"!"'
	export "DH_CONFIG_DIR" "DH_CONFIG" "TEXTDOMAIN" "TEXTDOMAINDIR" "replace" "DH_ICON_DIR" "PREFIX" "TERMINAL"
	portable
	# Set traps to catch the signals and exit gracefully
	trap "exit" INT
	trap "exit" EXIT
}

function create_structure() {
	source distrohopper.conf
	echo $"creating config dir..."
	mkdir -p "$DH_CONFIG_DIR"
	echo $"creating icons dir as root..."
	mkdir -p "$DH_ICON_DIR"  >/dev/null 2>&1 || sudo mkdir -p "$DH_ICON_DIR"
}

function set_dir() {
	NEWDIR="$(yad --file --directory --title="Where to save VMs?")"
	VMS_DIR="$NEWDIR"
	echo "VMS_DIR=\"$VMS_DIR\"
	export \"VMS_DIR\"" >> "$DH_CONFIG"
	export "VMS_DIR"
}

function install_prereq() {
	# (Void linux)
	sudo xbps-install -S qemu bash coreutils grep jq procps-ng python3 util-linux sed spice-gtk swtpm usbutils wget xdg-user-dirs xrandr unzip zsync socat gettext
	# Debian: sudo apt install qemu bash coreutils ovmf grep jq lsb procps python3 genisoimage usbutils util-linux sed spice-client-gtk swtpm wget xdg-user-dirs zsync unzip
	# Fedora: sudo dnf install qemu bash coreutils edk2-tools grep jq lsb procps python3 genisoimage usbutils util-linux sed spice-gtk-tools swtpm wget xdg-user-dirs xrandr unzip
}

function install_dh() {
	cp dh quickget quickemu macrecovery windowskey "$PREFIX" >/dev/null 2>&1 || sudo cp dh quickget quickemu macrecovery windowskey "$PREFIX"
	# quickget also to config directory for adding new distros...
	cp quickget "$DH_CONFIG_DIR/"
	echo $"Copying icons..."
	cp icons/* "$DH_ICON_DIR/" >/dev/null 2>&1 || sudo cp icons/* "$DH_ICON_DIR/"
	echo $"Copying to config dir..."
	cp -r ready "$DH_CONFIG_DIR/"
	cp -r supported "$DH_CONFIG_DIR/"

}

function install_process() {
	check_tui_dependencies
	check_gui_dependencies
	#check_quickemu_dependencies
	echo $"Creating directory structure..." \
	 && create_structure \
	 && echo $"Setting up directory..." \
	 && set_dir \
	 && echo $"Installing needed..." \
	 && echo $"For now voidlinux only" \
	 && install_prereq \
	 && echo $"Installing DistroHopper to bin..." \
	 && install_dh
}

# basic
function renew_ready() {
	cd "$VMS_DIR" || exit 1
	rm "$DH_CONFIG_DIR"/ready/*.desktop
#	for files in "$VMS_DIR"/*; do
#	if [ ! -e *.conf ]; then
#		echo $"No .conf files found"
#		return
#	fi
	for vm_conf in *.conf; do
		if [ "$vm_conf" == "distrohopper.conf" ]; then
			continue # skip processing distrohopper.conf
		fi
		vm_desktop=$(basename "$VMS_DIR/$vm_conf" .conf)
		# Use fuzzy matching to find the best matching icon file (ready to run VMs)
		icon_name=$(basename "$VMS_DIR/$vm_conf" .conf | cut -d'-' -f -2)
		icon_file=$(find "$DH_ICON_DIR" -type f -iname "${icon_name// /}.*")
		# If no icon was found, try shorter name (ready to run VMs)
		if [ -z "$icon_file" ]; then
			icon_name=$(basename "$VMS_DIR/$vm_conf" .conf | cut -d'-' -f1)
			icon_file=$(find "$DH_ICON_DIR" -type f -iname "${icon_name// /}.*")
		elif [ -z "$icon_file" ]; then
			icon_file="$DH_ICON_DIR/tux.svg"
		fi
		# content of desktop files (ready to run VMs)
		desktop_file_content="[Desktop Entry]
Type=Application
Name=$vm_desktop
Exec=sh -c 'cd \"$VMS_DIR\" && "$prefix"quickemu -vm $vm_conf'
Icon=$icon_file
Categories=System;Virtualization;"
		# create desktop files (ready to run VMs)
		echo "$desktop_file_content" > "$DH_CONFIG_DIR"/ready/"$vm_desktop".desktop
	done
}

function renew_supported() {
	rm "$DH_CONFIG_DIR"/supported/*.desktop
	# get supported VMs
	"$prefix"quickget | sed 1d | cut -d':' -f2 | grep -o '[^ ]*' > "$DH_CONFIG_DIR/supported.md"
	while read -r get_name; do
		vm_desktop=$(echo "$get_name" | tr ' ' '_')
		releases=$("$prefix"quickget "$vm_desktop" | grep 'Releases' | cut -d':' -f2 | sed 's/^ //')
		editions=$("$prefix"quickget "$vm_desktop" | grep 'Editions' | cut -d':' -f2 | sed 's/^ //')
		icon_name="$DH_ICON_DIR/$get_name"
		if [ -f "$icon_name.svg" ]; then
			icon_file="$icon_name.svg"
		elif [ -f "$icon_name.png" ]; then
			icon_file="$icon_name.png"
		else
			icon_file="$DH_ICON_DIR/tux.svg"
		fi
		# Check if there are editions
		if [ -z "$editions" ]; then
			# Create desktop file for VMs without editions
			desktop_file_content="[Desktop Entry]
Type=Application
Name=$get_name
releases=$releases
replace=$replace
Exec=sh -c 'cd \"$VMS_DIR\" && yad --form --field=\"Release:CB\" \"${releases// /$replace}\" | cut -d\"|\" -f1 | xargs -I{} sh -c \""$prefix"quickget $get_name {}\"'
Icon=$icon_file
Categories=System;Virtualization;"
			echo "$desktop_file_content" > "$DH_CONFIG_DIR"/supported/"$vm_desktop".desktop
		else
			# Create desktop file for VMs with editions
			desktop_file_content="[Desktop Entry]
Type=Application
Name=$get_name
releases=$releases
editions=$editions
replace=$replace
Exec=sh -c 'cd \"$VMS_DIR\" && yad --form --separator=\" \" --field=\"Release:CB\" \"${releases// /$replace}\" --field=\"Edition:CB\" \"${editions// /$replace}\" | xargs -I{} sh -c \"$prefixquickget $get_name {}\"'
Icon=$icon_file
Categories=System;Virtualization;"
			echo "$desktop_file_content" > "$DH_CONFIG_DIR"/supported/"$vm_desktop".desktop
		fi
	done < "$DH_CONFIG_DIR"/supported.md
}

function renew_supported_test() {
	rm "$DH_CONFIG_DIR"/test/ubuntu.desktop
	# get supported VMs
	"$prefix"quickget | sed 1d | cut -d':' -f2 | grep -o '[^ ]*' > "$DH_CONFIG_DIR/ubuntu.md"
	while read -r get_name; do
		vm_desktop=ubuntu
		releases=$("$prefix"quickget "$vm_desktop" | grep 'Releases' | cut -d':' -f2 | sed 's/^ //')
		editions=$("$prefix"quickget "$vm_desktop" | grep 'Editions' | cut -d':' -f2 | sed 's/^ //')
		icon_name="$DH_ICON_DIR/$get_name"
		if [ -f "$icon_name.svg" ]; then
			icon_file="$icon_name.svg"
		elif [ -f "$icon_name.png" ]; then
			icon_file="$icon_name.png"
		else
			icon_file="$DH_ICON_DIR/tux.svg"
		fi
		# Check if there are editions
		if [ -z "$editions" ]; then
			# Create desktop file for VMs without editions
			desktop_file_content="[Desktop Entry]
Type=Application
Name=$get_name
releases=$releases
replace=$replace
Exec=sh -c 'cd \"$VMS_DIR\" && yad --form --field=\"Release:CB\" \"${releases// /$replace}\" | cut -d\"|\" -f1 | xargs -I{} sh -c \""$prefix"quickget $get_name {}\"'
Icon=$icon_file
Categories=System;Virtualization;"
			echo "$desktop_file_content" > "$DH_CONFIG_DIR"/test/ubuntu.desktop
		else
			# Create desktop file for VMs with editions
			desktop_file_content="[Desktop Entry]
Type=Application
Name=$get_name
releases=$releases
editions=$editions
replace=$replace
Exec=sh -c 'cd \"$VMS_DIR\" && yad --form --separator=\" \" --field=\"Release:CB\" \"${releases// /$replace}\" --field=\"Edition:CB\" \"${editions// /$replace}\" | xargs -I{} sh -c \"$prefixquickget $get_name {}\"'
Icon=$icon_file
Categories=System;Virtualization;"
			echo "$desktop_file_content" > "$DH_CONFIG_DIR"/test/ubuntu.desktop
		fi
	done < "$DH_CONFIG_DIR"/test/ubuntu.md
}

function run_gui() {
	check_gui_dependencies
	key=$((RANDOM % 9000 + 1000))
	yad --plug="$key" --tabnum=1 --monitor --icons --listen --read-dir="$DH_CONFIG_DIR"/ready --sort-by-name --no-buttons --borders=0 --icon-size=46 --item-width=76 &
	yad --plug="$key" --tabnum=2 --monitor --icons --listen --read-dir="$DH_CONFIG_DIR"/supported --sort-by-name --no-buttons --borders=0 --icon-size=46 --item-width=76 &
	yad --dynamic --notebook --key="$key" --monitor --listen --window-icon="$DH_ICON_DIR"/hop.svg --width=900 --height=900 --title="DistroHopper" --tab="run VM" --tab="download VM"
}

function run_tui() {
	check_tui_dependencies
	vms=(*.conf)
	printf ' Prepared VMs:\n-------------\n\n'
	# Check if there are any VMs
	if [ ${#vms[@]} -eq 0 ]; then
		echo $"No VMs found."
		exit 1
	fi
	# Print the names of the available VMs
	printf "%s\n" "${vms[@]%.*}"
	echo "-------------"
	# Action prompt
	printf " Do you want to create a new VM? (c)
	 or run an existing one? (press anything)\n"
	read -rn 1 -s start
	case $start in
		c )
			todo="create"
		;;
	esac
	# If the user chose to create a new VM
	if [ "$todo" = "create" ]; then
		os=$("$prefix"quickget | sed 1d | cut -d':' -f2 | grep -o '[^ ]*' | fzf --cycle --header='Choose OS to download
 or CTRL-c or ESC to quit')
		# If the OS is Windows
		if [ "$os" = windows ]; then
			answer=$(echo "Default English
Choose other language" | fzf --cycle)
			# If the user wants another windows language
			if [ "$answer" = "Choose other language" ]; then
				wrelease=$(echo "8
10
11" | fzf --cycle)
				# get window language list
				wlend=$(($(cat "$prefix"quickget | sed '/Arabic/,$!d' | grep -n '}' | cut -d':' -f1 | head -n 1) - 1))
				# get windows language
				wlang=$(cat "$prefix"quickget | sed '/Arabic/,$!d' | head -n $wlend | cut -d'=' -f2 | tail -c +2 | head -c -2 | sed 's/^[ \t]*//' | fzf --cycle --header='Choose Language
 or CTRL-c or ESC to quit')
				# downloading windows
				printf '\n Trying to download Windows %s %s...\n\n' "$wrelease" "$wlang"
				"$prefix"quickget "windows" "$wrelease" "$wlang"
			fi
		fi
		# Get the release and edition to download, if necessary
		choices=$("$prefix"quickget "$os" | sed 1d)
		if [ "$(echo "$choices" | wc -l)" = 1 ]; then
			# get release
			release=$(echo "$choices" | grep 'Releases' | cut -d':' -f2 | grep -o '[^ ]*' | fzf --cycle --header='Choose Release
 or CTRL-c or ESC to quit')
			# downloading
			printf '\n Trying to download %s %s...\n\n' "$os" "$release"
			"$prefix"quickget "$os" "$release"
		else
			# get release
			release=$(echo "$choices" | grep 'Releases' | cut -d':' -f2 | grep -o '[^ ]*' | fzf --cycle --header='Choose Release
 or CTRL-c or ESC to quit')
			# get edition
			edition=$(echo "$choices" | grep 'Editions' | cut -d':' -f2 | grep -o '[^ ]*' | fzf --cycle --header='Choose Edition
 or CTRL-c or ESC to quit')
			# downloading
			printf '\n Trying to download %s %s %s...\n\n' "$os" "$release" "$edition"
			"$prefix"quickget "$os" "$release" "$edition"
		fi
		# choose VM to run
		choosed=$(echo "$(ls ./***.conf 2>/dev/null | sed 's/\.conf$//')" | fzf --cycle --header='Choose VM to run
 or CTRL-c or ESC to quit')
		# Run choosed VM
		printf '\n Starting %s...\n\n' "$choosed"
		"$prefix"quickemu -vm "$choosed.conf"
	fi
}

# more
function isos_to_dir() {
	yad --file --directory > target
	cd "$VMS_DIR" || exit 1
	cp */*.iso "$target"
}

function add_distro() {
	TMP_DIR="/tmp"
	yad --form --field="Pretty name" "" --field="Name" "" --field="Releases" "" --field="Editions" "" --field="URL" "" --field="ISO" "" --field="Checksum file" "" > ${TMP_DIR}/template.tmp
	PRETTY_NAME="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f1)"
	NAME="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f2)"
	RELEASES="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f3)"
	EDITIONS="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f4)"
	URL="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f5)"
	ISO="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f6)"
	CHECKSUM_FILE="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f7)"
	echo "    $NAME)           PRETTY_NAME=$PRETTY_NAME;;
" >  ${TMP_DIR}/${NAME}.tmp
	{ echo "    $NAME \\
"; echo "function releases_$NAME() {
	echo $RELEASES
}
"; echo "function editions_$NAME() {
	echo $EDITIONS
}
"; echo "function get_$NAME() {
	local EDITION="${1:-}"
	local HASH=""
	local ISO="$ISO"
	local URL="$URL"
	HASH=\"$(wget -q -O- "${URL}/${CHECKSUM_FILE}" | grep "(${ISO}" | cut -d' ' -f4)\"
	echo \"${URL}/${ISO} ${HASH}\"
}
"; } >> ${TMP_DIR}/${NAME}.tmp
	meld "${TMP_DIR}/${NAME}.tmp $DH_CONFIG_DIR/quickget"
}

function sort_functions() {
	# Get the name of the script from the command line argument
	script_name=$1
	# Get a list of all the function names in the script
	function_names=$(grep -oP '^[[:space:]]*function \K\w+' "$script_name")
	# Sort the function names alphabetically
	sorted_function_names=$(echo "$function_names" | sort)
	# Loop through the sorted function names and print the function definitions
	for function_name in $sorted_function_names
	do
		# Print the function definition to stdout
		grep -A $(wc -l < "$script_name") -w "function $function_name" "$script_name"
	done
}

function localization() {
	#. gettext.sh
	TEXTDOMAIN=distrohopper
	TEXTDOMAINDIR=/usr/share/locale
	mkdir lang
	mkdir lang/cs
	bash --dump-po-strings dh > lang/source.pot
	cp lang/source.pot lang/cs/distrohopper.pot.tmp
	meld lang/cs/distrohopper.pot.tmp lang/cs/distrohopper.pot && rm lang/cs/distrohopper.pot.tmp
}

create_translation() {
	echo $"Which language you want use [en,cs]?"
	read -rn 1 -s lang
	echo $"Choosed language is: $lang"
	echo $"Dumping language source..."
	bash --dump-po-strings dh.sh > "$DH_CONFIG_DIR"/locale/dh-source.pot
	echo $"Merging changes... (Do it yourself)"
	meld "$DH_CONFIG_DIR"/locale/dh-source.pot "$DH_CONFIG_DIR"/distrohopper-"$lang".pot
	echo $"Generating .mo file..."
	msgfmt -o "$DH_CONFIG_DIR"/locale/distrohopper-"$lang".mo "$DH_CONFIG_DIR"/locale/distrohopper-"$lang".pot
	echo $"Copying translation to '/usr/share/local'..."
	sudo cp "$DH_CONFIG_DIR"/locale/distrohopper-"$lang".mo /usr/share/locale/"$lang"/LC_MESSAGES/distrohopper.mo
}

# run
set_variables

if [[ $# -eq 0 ]]; then
    printf $"No argumet provided!\n\n"
    show_help
    exit 0
fi

while [[ $# -gt 0 ]]
do
	key="$1"
	case $key in
		-h|--help)
			show_help
			shift
			;;
		-d|-dir)
			set_dir
			shift
			;;
		-i|--install)
			echo $"Starting installation..."
			install_process
			shift
			;;
		-m|--mode)
			echo $"Switching to portable mode!"
			mode_portable
			shift
			;;
		-s|--supported)
			echo $"Updating supported VMs..."
			renew_supported
			shift
			;;
		-r|--ready)
			echo $"Updating ready VMs..."
			renew_ready
			shift
			;;
		-t|--tui)
			echo $"Running TUI..."
			run_tui
			shift
			;;
		-g|--gui)
			echo $"Starting DistroHopper GUI..."
			run_gui
			shift
			;;
		-a|--add)
			echo $"Adding new distro started..."
			add_distro
			shift
			;;
		-f|--functions)
			echo $"Sorting functions in template..."
			sort_functions
			shift
			;;
		-p|--push)
			echo $"Pushing changes to... #TODO"
			push_changes
			shift
			;;
		-c|--copy)
			echo $"Copying ISOs to dir. It will take some time..."
			isos_to_dir
			shift
			;;
		-e|--test)
			echo $"Running supported test..."
			renew_supported_test
			shift
			;;
		-l|--language)
			create_translation
			shift
			;;
		*)
			printf $"Invalid option: $1\n\n"
			show_help
			exit 1
			;;
	esac
done

some_bugs

exit 0