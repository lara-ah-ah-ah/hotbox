import hotbox/result.{type HotboxError, FileError}
import simplifile

pub fn detect_file_size(of path: String) -> Result(Int, HotboxError) {
  case simplifile.file_info(path) {
    Error(err) -> Error(FileError(err, path))
    Ok(info) -> Ok(info.size)
  }
}
