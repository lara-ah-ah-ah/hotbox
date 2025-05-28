import gleam/string
import hotbox/result.{type HotboxError, OSError}
import shellout

pub fn detect_os_label() -> Result(String, HotboxError) {
  // Try Unix-style first
  let uname_result = shellout.command("uname", ["-s"], ".", [])

  case uname_result {
    Ok(output) ->
      case
        string.contains(does: output, contain: "Darwin"),
        string.contains(does: output, contain: "Linux")
      {
        True, False -> Ok("darwin")
        False, True -> Ok("linux")
        _, _ -> {
          // Fall back to Windows command
          let win_result = shellout.command("cmd", ["/C", "ver"], ".", [])

          case win_result {
            Ok(_) -> Ok("windows")
            Error(_) -> Error(OSError)
          }
        }
      }
    Error(_) -> Error(OSError)
  }
}
