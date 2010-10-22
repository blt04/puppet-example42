
define apply_patch(
    $source = 'Default',
    $file,
    $patchfile
) {
    exec { "'${source}' patch -N -r - '${file}', '${patchfile}'":
        command => "patch -N -r - '${file}' '${patchfile}'",
        onlyif => "patch -N -r - --dry-run '${file}' '${patchfile}' >/dev/null"
    }
}
