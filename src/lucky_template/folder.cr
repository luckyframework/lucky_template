module LuckyTemplate
  class Folder
    alias Files = File | Folder

    getter name : String
    @files = [] of Files

    def initialize(@name : String)
      raise "Invalid folder name" if @name.empty?
    end

    def add_file(name : String, file : FileType) : Nil
      add_file(File.new(name, file))
    end

    def add_file(file : File) : Nil
      @files << file
    end

    def add_folder(name : String) : Nil
      add_folder(name) { }
    end

    def add_folder(name : String, & : Folder ->) : Nil
      folder = Folder.new(name)
      yield folder
      @files << folder
    end

    protected def files
      @files
    end

    protected def write_to_disk!(path : Path) : Nil
      write_folder_to_disk!(path, self)
    end

    protected def write_file_to_disk!(path : Path, file : File) : Nil
      ::File.open(path.join(file.name), "w") do |io|
        file.to_s(io)
      end
    end

    protected def write_folder_to_disk!(path : Path, folder : Folder) : Nil
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
  end
end
