module LuckyTemplate
  class Folder
    alias Files = File | Folder

    getter name : String
    @files = [] of Files
    @in_use = false

    def initialize(@name : String)
      if @name.empty?
        raise Error.new("Folder name must not be empty")
      end
    end

    def add_file(name : String, content : String) : Nil
      add_file(File.new(name, content))
    end

    def add_file(name : String, klass : Fileable) : Nil
      add_file(File.new(name, klass))
    end

    def add_file(name : String, &block : FileProc) : Nil
      add_file(File.new(name, block))
    end

    def add_file(name : String) : Nil
      add_file(File.new(name, nil))
    end

    def add_file(file : File) : Nil
      @files << file
    end

    def add_folder(*names : String) : Nil
      add_folder(*name) { }
    end

    def add_folder(new_folder : Folder) : Nil
      if new_folder == self
        raise Error.new("Folder cannot add itself")
      elsif @in_use
        raise Error.new("Parent folder already in-use")
      end

      @files << new_folder
    end

    def add_folder(*names : String, & : Folder ->) : Nil
      prev : Folder? = nil
      names.each_with_index do |name, index|
        folder = Folder.new(name)
        if index == names.size - 1
          folder.in_use do
            yield folder
          end
        end
        if prev_folder = prev
          prev_folder.add_folder(folder)
        else
          @files << folder
        end
        prev = folder
      end
    end

    # Used as a safe-guard to protect against circular references
    protected def in_use(&)
      @in_use = true
      yield
    ensure
      @in_use = false
    end

    protected def files : Array(Files)
      @files
    end

    # Writes the folder to disk at the given path
    protected def write_to_disk!(path : Path) : Nil
      write_folder_to_disk!(path, self)
    end

    private def write_file_to_disk!(path : Path, file : File) : Nil
      ::File.open(path.join(file.name), "w") do |io|
        file.to_s(io)
      end
    end

    private def write_folder_to_disk!(path : Path, folder : Folder) : Nil
      new_path = path.join(folder.name)
      Dir.mkdir_p(new_path)
      folder.files.each do |file|
        case file
        in File
          write_file_to_disk!(new_path, file)
        in Folder
          write_folder_to_disk!(new_path, file)
        end
      end
    end

    # Returns `true` if the folder is _valid_ at the given path
    #
    # _valid_ - Files and folder exist within the given path
    #
    # Raises `::File::NotFoundError` if either a file or folder does not exist
    protected def validate!(path : Path) : Bool
      validate_folder!(path, self)
      true
    end

    # Returns a `Bool` if the folder is _valid_ at the given path
    #
    # _valid_ - Files and folder exist within the given path
    protected def validate?(path : Path) : Bool
      validate!(path)
    rescue
      false
    end

    private def validate_file!(path : Path, file : File) : Nil
      ::File.size(path.join(file.name))
    end

    private def validate_folder!(path : Path, folder : Folder) : Nil
      new_path = path.join(folder.name)
      Dir.open(new_path) { }
      folder.files.each do |file|
        case file
        in File
          validate_file!(new_path, file)
        in Folder
          validate_folder!(new_path, file)
        end
      end
    end

    alias Snapshot = Hash(String, FileSystemType)

    protected def snapshot_files : Snapshot
      Snapshot.new.tap do |snapshot|
        snapshot_folder(Path.new, self, snapshot)
      end
    end

    private def snapshot_folder(path : Path, folder : Folder, snapshot : Snapshot) : Nil
      new_path = path / folder.name
      snapshot[new_path.to_s] = FileSystemType::Folder
      folder.files.each do |file|
        case file
        in File
          snapshot[(new_path / file.name).to_s] = FileSystemType::File
        in Folder
          snapshot_folder(new_path, file, snapshot)
        end
      end
    end
  end

  enum FileSystemType
    File
    Folder
  end
end
