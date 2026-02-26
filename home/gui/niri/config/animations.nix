''
animations {
    workspace-switch { spring damping-ratio=1.0 stiffness=1000 epsilon=0.0001; }
    window-open { duration-ms 200; curve "ease-out-expo"; }
    window-close { duration-ms 200; curve "ease-out-expo"; }
    horizontal-view-movement { spring damping-ratio=1.0 stiffness=800 epsilon=0.0001; }
    window-movement { spring damping-ratio=1.0 stiffness=800 epsilon=0.0001; }
    window-resize { duration-ms 200; curve "ease-out-expo"; }
}
''
