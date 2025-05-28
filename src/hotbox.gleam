import hotbox/ramdisk

pub fn main() -> Nil {
  echo ramdisk.create_ramdisk("darwin", 10.0, "TEST")
  Nil
}
