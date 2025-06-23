import argv
import clip
import clip/help
import clip/opt.{type Opt}
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

/// The command-line interface data type for grleam
type Cli {
  Arg(pattern: String, path: String)
}

/// Creates an option for the pattern parameter
fn pattern_opt() -> Opt(String) {
  opt.new("pattern") |> opt.help("A pattern to search for")
}

/// Creates an option for the file path parameter
fn path_opt() -> Opt(String) {
  opt.new("path") |> opt.help("A path to a file to search in")
}

/// Reads a file and returns its contents as a list of lines
/// Returns an error message if the file cannot be read
fn read_file(path: String) -> Result(List(String), String) {
  simplifile.read(path)
  |> result.map(fn(content) { string.split(content, "\n") })
  |> result.map_error(fn(e) {
    string.inspect(e)
    |> string.append(": File Not Found")
  })
}

/// Filters lines containing the specified pattern
fn filter_lines(lines: List(String), pattern: String) -> List(String) {
  list.filter(lines, fn(line) { string.contains(line, pattern) })
}

/// Sets up the command-line interface for grleam
fn setup_command() -> clip.Command(Cli) {
  clip.command({
    use pattern <- clip.parameter
    use path <- clip.parameter
    Arg(pattern, path)
  })
  |> clip.opt(pattern_opt())
  |> clip.opt(path_opt())
  |> clip.help(help.simple("grleam", "Grep-like tool in Gleam"))
}

/// Main entry point for the grleam application
/// Parses command-line arguments, reads the specified file,
/// filters lines containing the pattern, and prints the results
pub fn main() -> Nil {
  let result =
    setup_command()
    |> clip.run(argv.load().arguments)
    |> result.map(fn(cmd) {
      let Arg(pattern, path) = cmd
      read_file(path)
      |> result.map(fn(lines) { filter_lines(lines, pattern) })
    })
    |> result.flatten()

  case result {
    Ok(detected_lines) ->
      detected_lines
      |> list.each(fn(line) { io.println(line) })
    Error(msg) -> io.println_error(msg)
  }
}
