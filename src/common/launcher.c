/* Unified launcher for guii3 project
 * Detects symlink name and launches appropriate application
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libgen.h>
#include <unistd.h>

#include "launcher.h"

#define VERSION "1.0"

void
print_usage(const char *program_name)
{
	fprintf(stderr, "usage: %s [options]\n", program_name);
	fprintf(stderr, "\nSupported program names:\n");
	fprintf(stderr, "  iiwm - X11 dynamic window manager\n");
	fprintf(stderr, "  iist - X11 simple terminal\n");
	fprintf(stderr, "  guii - this launcher (shows this help)\n");
	fprintf(stderr, "\nTo use, create symlinks:\n");
	fprintf(stderr, "  ln -s guii iiwm\n");
	fprintf(stderr, "  ln -s guii iist\n");
}

void
print_version(void)
{
	printf("guii3 unified launcher %s\n", VERSION);
	printf("Contains: iiwm (dwm 6.2) + iist (st 0.8.2)\n");
}

int
main(int argc, char *argv[])
{
	char *program_name;
	char *argv0_copy;
	
	/* Make a copy of argv[0] since basename() may modify it */
	argv0_copy = strdup(argv[0]);
	if (!argv0_copy) {
		fprintf(stderr, "launcher: memory allocation failed\n");
		return 1;
	}
	
	program_name = basename(argv0_copy);
	
	/* Route to appropriate main function based on program name */
	if (strcmp(program_name, "iiwm") == 0) {
		free(argv0_copy);
		return wm_main(argc, argv);
	} else if (strcmp(program_name, "iist") == 0) {
		free(argv0_copy);
		return term_main(argc, argv);
	} else if (strcmp(program_name, "guii") == 0) {
		/* Default behavior - show help */
		if (argc > 1) {
			if (strcmp(argv[1], "-v") == 0 || strcmp(argv[1], "--version") == 0) {
				print_version();
				free(argv0_copy);
				return 0;
			}
		}
		print_usage(program_name);
		free(argv0_copy);
		return 0;
	} else {
		/* Unknown program name */
		fprintf(stderr, "launcher: unknown program name '%s'\n", program_name);
		fprintf(stderr, "Expected one of: iiwm, iist, guii\n");
		print_usage("guii");
		free(argv0_copy);
		return 1;
	}
}