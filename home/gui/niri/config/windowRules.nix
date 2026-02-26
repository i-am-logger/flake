''
window-rule {
    match app-id=r#"^1Password$"#
    open-floating true
    default-column-width { fixed 1200; }
    default-window-height { fixed 900; }
}

window-rule {
    match app-id=r#"^org\.pulseaudio\.pavucontrol$"#
    open-floating true
}

window-rule {
    match app-id=r#"^\.blueman-manager-wrapped$"#
    open-floating true
}

window-rule {
    match app-id=r#"^nm-connection-editor$"#
    open-floating true
}

window-rule {
    match app-id=r#"^xdg-desktop-portal-gtk$"#
    open-floating true
}

window-rule {
    match app-id=r#"^brave$"#
    match title=r#"^Save File$"#
    open-floating true
}
''
