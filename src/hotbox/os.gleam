import gleam/float
import gleam/int
import gleam/string
import hotbox/result.{
  type HotboxError, EUnreachable, OSError, ShelloutError, UnknownOSError,
  UnsupportedError,
}
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
            Error(#(code, text)) -> Error(ShelloutError(code, text))
          }
        }
      }
    Error(#(code, text)) -> Error(ShelloutError(code, text))
  }
}

pub fn get_available_memory(
  operating_system: String,
) -> Result(Int, HotboxError) {
  case operating_system {
    "darwin" -> darwin_get_available_memory()
    "windows" -> windows_get_available_memory()
    "linux" -> linux_get_available_memory()
    _ -> Error(UnknownOSError)
  }
}

fn darwin_get_available_memory() {
  let result =
    shellout.command(run: "memory_pressure", with: [], in: ".", opt: [])
  case result {
    Ok(output) -> {
      case string.split_once(string.drop_start(output, 15), " (") {
        Ok(#(ram_string, rest)) -> {
          case string.split_once(rest, "System-wide memory free percentage:") {
            Ok(#(_, chance_string)) ->
              case
                int.parse(ram_string),
                float.parse(
                  "0." <> string.drop_end(string.trim(chance_string), 1),
                )
              {
                Ok(ram), Ok(string) ->
                  Ok(float.round(int.to_float(ram) *. string))
                _, _ -> Error(EUnreachable)
              }
            _ -> Error(EUnreachable)
          }
        }
        _ -> Error(EUnreachable)
      }
    }
    Error(#(code, text)) -> Error(ShelloutError(code, text))
  }
}

fn linux_get_available_memory() {
  Error(UnsupportedError)
}

fn windows_get_available_memory() -> Result(Int, HotboxError) {
  let result =
    shellout.command(
      run: "powershell",
      with: [
        "-Command", "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory",
      ],
      in: ".",
      opt: [],
    )
  case result {
    Ok(output) ->
      case int.parse(output) {
        Ok(memory) -> Ok(memory)
        Error(_) -> Error(EUnreachable)
      }
    Error(#(code, text)) -> Error(ShelloutError(code, text))
  }
}
