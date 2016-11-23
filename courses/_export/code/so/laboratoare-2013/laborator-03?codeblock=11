    
    

#include <stdlib.h>
#include <stdio.h>

#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

int my_system(const char *command)
{
	pid_t pid;
	int status;
	const char *argv[] = {command, NULL};

	pid = fork();
	switch (pid) {
	case -1:
		/* error forking */
		return EXIT_FAILURE;
	case 0:
		/* child process */
		execvp(command, (char *const *) argv);

		/* only if exec failed */
		exit(EXIT_FAILURE);
	default:
		/* parent process */
		break;
	}

	/* only parent process gets here */
	waitpid(pid, &status, 0);
	if (WIFEXITED(status))
		printf("Child %d terminated normally, with code %d\n",
			pid, WEXITSTATUS(status));

	return status;
}

int main(void) {
	my_system("ls");
	return 0;
}