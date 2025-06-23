import argv
import clip
import clip/help
import clip/opt.{type Opt}
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

type Cli {
  Arg(pattern: String, path: String)
}

fn pattern_opt() -> Opt(String) {
  opt.new("pattern") |> opt.help("A pattern to search for")
}

fn path_opt() -> Opt(String) {
  opt.new("path") |> opt.help("A path to a file to search in")
}

pub fn main() -> Nil {
  let cmd =
    clip.command({
      use pattern <- clip.parameter
      use path <- clip.parameter
      Arg(pattern, path)
    })
    |> clip.opt(pattern_opt())
    |> clip.opt(path_opt())
  let result =
    cmd
    |> clip.help(help.simple("grleam", "Example"))
    |> clip.run(argv.load().arguments)

  case result {
    Error(e) -> io.println_error(e)
    Ok(cmd) -> {
      let Arg(pattern, path) = cmd
      let lines =
        simplifile.read(path)
        |> result.map(fn(content) { string.split(content, "\n") })
      case lines {
        Error(e) ->
          e
          |> string.inspect
          |> string.append(": File Not Found")
          |> io.println_error
        Ok(lines) ->
          lines
          |> list.filter(fn(line) { string.contains(line, pattern) })
          |> list.each(fn(line) { io.println(line) })
      }
    }
  }
}
