#ifndef LAUNCHER_H
#define LAUNCHER_H

/* Forward declarations for main functions */
extern int wm_main(int argc, char *argv[]);
extern int term_main(int argc, char *argv[]);

/* Launcher utilities */
void print_usage(const char *program_name);
void print_version(void);

#endif /* LAUNCHER_H */