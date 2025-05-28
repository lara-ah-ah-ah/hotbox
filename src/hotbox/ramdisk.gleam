import filepath
import gleam/float
import gleam/string
import hotbox/result.{
  type HotboxError, FileError, MissingFileError, ShelloutError, UnknownOSError,
  UnsupportedError,
}
import shellout
import simplifile

pub fn create_ramdisk(
  for operating_system: String,
  of size: Float,
  at path: String,
) -> Result(String, HotboxError) {
  case operating_system {
    "linux" -> create_linux_ramdisk(of: size, at: path)
    "darwin" -> create_darwin_ramdisk(of: size, at: path)
    "windows" -> create_windows_ramdisk(of: size, at: path)
    _ -> Error(UnknownOSError)
  }
}

fn create_linux_ramdisk(
  of _: Float,
  at _: String,
) -> Result(String, HotboxError) {
  Error(UnsupportedError)
}

fn create_darwin_ramdisk(
  of size: Float,
  at path: String,
) -> Result(String, HotboxError) {
  case
    shellout.command(
      run: "hdiutil",
      with: [
        "attach",
        "-nomount",
        "ram://" <> string.inspect(float.round(size *. 2048.0)) <> ")",
      ],
      in: ".",
      opt: [],
    )
  {
    Error(#(code, text)) -> Error(ShelloutError(code, text))
    Ok(disk) ->
      case detect_copy_label("/Volumes", path, 0) {
        Ok(label) ->
          case
            shellout.command(
              run: "diskutil",
              with: ["apfs", "create", string.trim(disk), path],
              in: ".",
              opt: [],
            )
          {
            Error(#(code, text)) -> Error(ShelloutError(code, text))
            Ok(_) -> {
              let file_to_write =
                "/Volumes/"
                <> make_apfs_label(path)
                <> label
                <> "/.metadata_never_index"
              case simplifile.write(file_to_write, "") {
                Ok(_) -> Ok(filepath.directory_name(file_to_write))
                Error(err) -> Error(FileError(err, file_to_write))
              }
            }
          }
        err -> err
      }
  }
}

fn create_windows_ramdisk(
  of _: Float,
  at _: String,
) -> Result(String, HotboxError) {
  Error(UnsupportedError)
}

fn detect_copy_label(
  in path: String,
  of name: String,
  current count: Int,
) -> Result(String, HotboxError) {
  let count_string = case count {
    0 -> ""
    _ -> " " <> string.inspect(count)
  }
  case simplifile.is_directory(path) {
    Ok(True) ->
      case
        simplifile.is_directory(filepath.join(
          path,
          make_apfs_label(name) <> count_string,
        ))
      {
        Ok(False) -> Ok(count_string)
        _ -> detect_copy_label(path, name, count + 1)
      }
    Error(err) -> Error(FileError(err, path))
    Ok(False) -> Error(MissingFileError(path))
  }
}

fn make_apfs_label(from string: String) -> String {
  string
  |> string.replace("/", ":")
}
