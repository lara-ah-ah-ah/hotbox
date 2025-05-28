import gleam/list
import gleam/string
import simplifile.{type FileError}

pub type HotboxError {
  FileError(error: FileError, at: String)
  ShelloutError(code: Int, text: String)
  OSError
  UnknownOSError
  UnsupportedError
  MissingFileError(String)
}

pub fn error_as_string(error: HotboxError) {
  case error {
    FileError(error, path) -> simplifile.describe_error(error) <> " at " <> path
    ShelloutError(code, text) ->
      "OS Error: " <> string.inspect(code) <> " " <> text
    OSError -> "Couldn't determine Operating System"
    UnknownOSError -> "Unknown OS"
    UnsupportedError -> "This functionality isn't supported yet"
    MissingFileError(path) -> "Couldn't find " <> path
  }
}

pub fn result_as_string(result: Result(something, HotboxError)) {
  case result {
    Ok(something) -> string.inspect(something)
    Error(err) -> error_as_string(err)
  }
}

pub fn results_as_string(results: List(Result(something, HotboxError))) {
  list.fold(
    results,
    "",
    fn(accumulator: String, result: Result(something, HotboxError)) {
      accumulator <> "\n" <> result_as_string(result)
    },
  )
}
