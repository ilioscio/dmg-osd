project('dmg-osd', ['vala', 'c'],
  version: '0.1.0',
  license: 'MIT',
  default_options: [
    'warning_level=2',
    'werror=false',
  ]
)

# Dependencies
gtk_dep = dependency('gtk4')
glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
gio_dep = dependency('gio-2.0')
layer_shell_dep = dependency('gtk4-layer-shell-0')
math_dep = meson.get_compiler('c').find_library('m', required: false)

# Add posix vala package
add_project_arguments(['--pkg', 'posix'], language: 'vala')

# Source files
sources = files(
  'src/main.vala',
  'src/application.vala',
  'src/overlay_window.vala',
  'src/battery_monitor.vala',
  'src/config.vala',
  'src/settings_window.vala'
)

# Executable
dmg_osd_exe = executable(
  'dmg-osd',
  sources,
  dependencies: [
    gtk_dep,
    glib_dep,
    gobject_dep,
    gio_dep,
    layer_shell_dep,
    math_dep
  ],
  install: true
)
