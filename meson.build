project('vala', 'c')
gnome = import('gnome')

resources = gnome.compile_resources(
    'markup', 'data/markup.gresource.xml',
    source_dir: 'data/',
	export: true,
)

executable('markup',
	resources,
	sources: [
		'src/main.vala',
		'src/markup.vala',
	],
	dependencies: [
		dependency('glib-2.0'),
		dependency('gobject-2.0'),
		dependency('gtk+-3.0'),
		dependency('gee-0.8'),
		meson.get_compiler('c').find_library('m'),	# libm; maths library
	],
)
