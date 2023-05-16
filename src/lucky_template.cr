require "./lucky_template/*"

module LuckyTemplate
  extend self

  def create_folder(name : String, & : Folder ->) : Folder
    folder = Folder.new(name)
    yield folder
    folder
  end

  def create_folder(name : String) : Folder
    create_folder(name) { }
  end

  # Writes folder to disk at path
  def write!(location : Path, folder : Folder) : Nil
    path = location.expand
    Dir.mkdir_p(path)
    folder.write_to_disk!(path)
  end

  # Writes folder from path to disk at path dirname
  def write!(location : Path, & : Folder ->) : Nil
    path = location.expand
    dirname = Path.new(path.dirname)
    Dir.mkdir_p(dirname)
    folder = Folder.new(path.basename)
    yield folder
    folder.write_to_disk!(dirname)
  end
end
