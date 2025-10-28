// BORR Serves as a simple build tool for this projects examples
//
// To use it just run odin build borr.odin -file -out:borr
// and after that just run ./borr
//
// The build tool will rebuild itself when the source files changes

package borr

import "core:fmt"
import "core:hash"
import "core:os"
import "core:strings"
import "core:sys/posix"

SOURCE_HASH :: #load_hash("borr.odin", "crc32")

file_crc32 :: proc(path: string) -> u32 {
	data, ok := os.read_entire_file_from_filename(path)
	if !ok {
		panic("Failed to read file")
	}
	return hash.crc32(data)
}

main :: proc() {
	original_args := os.args
	if file_crc32("borr.odin") != SOURCE_HASH {
		fmt.println("Source file has changed, rebuilding...")
		child_pid := posix.fork(); switch child_pid {
		case -1:
			panic("fork failed")

		case 0:
			posix.execlp("odin", "odin", "build", "borr.odin", "-file", "-out:borr", cstring(nil))
			fmt.eprintln("Failed to exec odin for self-rebuild")
			os.exit(1)

		case:
			for {
				status: i32
				wpid := posix.waitpid(child_pid, &status, {.UNTRACED, .CONTINUED})
				if wpid == -1 {
					panic("waitpid failure")
				}

				switch {
				case posix.WIFEXITED(status):
				// fmt.printfln("child exited, status=%v", posix.WEXITSTATUS(status))
				case posix.WIFSIGNALED(status):
					fmt.printfln("child killed (signal %v)", posix.WTERMSIG(status))
				case posix.WIFSTOPPED(status):
					fmt.printfln("child stopped (signal %v", posix.WSTOPSIG(status))
				case posix.WIFCONTINUED(status):
					fmt.println("child continued")
				case:
					fmt.println("unexpected status (%x)", status)
				}

				if posix.WIFEXITED(status) || posix.WIFSIGNALED(status) {
					break
				}
			}

			posix.execlp("./borr", "borr", cstring(nil))
			fmt.eprintln("Failed to exec borr after rebuild")
			os.exit(1)
		}
	}

	fmt.println("TODO: Actually add the logic")
}
