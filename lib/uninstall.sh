#!/bin/bash

uninstall_junest() {
	display_header "JuNest uninstallation"

	local targets=(
        "$HOME/.junest"
        "$JUNEST_ROOT"
    )
	local found=()
	for dir in "${targets[@]}"; do
        if [ -d "$dir" ]; then
            found+=("$dir")
        fi
    done
	
	if [ ${#found[@]} -ne 0 ]; then
		echo "The following directories will be permanently removed:"
		for dir in "${found[@]}"; do
			if [ -d "$dir" ]; then
				echo "  - $dir"
			fi
		done

		echo ""
		if [ "${FORCE:-false}" = true ] || confirm "Uninstall JuNest ?"; then
			echo -e "\n--> Removing JuNest environments..."
			for dir in "${targets[@]}"; do
				if [ -d "$dir" ]; then
					echo "  - Deleting: $dir"
					rm -rf "$dir"
				fi
			done
			
			echo -e "\nJuNest uninstalled successfully."
		else
			echo -e "[Aborted] skip.."
		fi
	else
			echo -e "JuNest not installed."
	fi
}

uninstall() {
	if [ -d "$HOME/.junest" ]; then
		uninstall_junest
		
		echo -e "\n[SUCCESS] Uninstallation complete."
	else
		echo -e "\nNothing to uninstall."
	fi
}
