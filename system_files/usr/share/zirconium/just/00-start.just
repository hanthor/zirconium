default:
    @zjust --choose

zdots-update:
    #!/usr/bin/env bash
    yes s | chezmoi apply --no-tty --keep-going -S "/usr/share/zirconium/zdots" --verbose --config "$HOME/.config/zirconium/chezmoi/chezmoi.toml"

zdots-reset FILE:
    #!/usr/bin/env bash
    chezmoi apply --force -S "/usr/share/zirconium/zdots" --verbose --config "$HOME/.config/zirconium/chezmoi/chezmoi.toml" {{FILE}}

zdots-override-all:
    #!/usr/bin/env bash
    chezmoi apply --force -S "/usr/share/zirconium/zdots" --verbose --config "$HOME/.config/zirconium/chezmoi/chezmoi.toml" 

toggle-user-motd:
    #!/usr/bin/env bash

    TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/zirconium/no-show-user-motd"

    if [ -e "$TARGET" ] ; then
         rm -r "${TARGET}"
         echo "Enabled the MOTD"
         exit 0
    fi
    mkdir -p "$(dirname "$(realpath ${TARGET})")"
    touch "${TARGET}"
    echo "Disabled the MOTD"


restart-shell:
    #!/usr/bin/env bash
    if systemctl is-active --quiet --user dms ; then
        systemctl restart --user dms
    fi


reset-niri:
    #!/usr/bin/env bash
    zjust zdots-reset "${HOME}/.config/niri"

update-greeter:
    dms greeter sync
