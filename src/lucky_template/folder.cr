module LuckyTemplate
  class Folder
    alias Files = File | Folder

    @files = {} of String => Files
    @locked = false

    # Adds a new `File` to the folder with static *content*
    #
    # Examples:
    #
    # ```
    # add_file("hello.txt", "hello world")
    # ```
    #
    # ```
    # add_file("hello.txt", <<-TEXT)
    # hello world
    # TEXT
    # ```
    def add_file(name : String, content : String) : self
      add_file(name, File.new(content))
    end

    # Adds a new `File` to the folder with `Fileable` interface
    #
    # Example:
    #
    # ```
    # class Hello
    #   include LuckyTemplate::Fileable
    # end
    #
    # add_file("hello.txt", Hello.new)
    # ```
    def add_file(name : String, klass : Fileable) : self
      add_file(name, File.new(klass))
    end

    # Adds a new `File` to the folder yielding an `IO`
    #
    # Example:
    #
    # ```
    # add_file("hello.txt") do |io|
    #   ECR.embed("hello.ecr", io)
    # end
    # ```
    def add_file(name : String, &block : FileProc) : self
      add_file(name, File.new(block))
    end

    # Adds a new empty `File` to the folder
    #
    # Example:
    #
    # ```
    # add_file("hello.txt")
    # ```
    def add_file(name : String) : self
      add_file(name, File.new(nil))
    end

    # Adds a `File` to the folder
    def add_file(name : String, file : File) : self
      @files[name] = file
      self
    end

    # Adds nested folders, yielding the last one
    #
    # Example:
    #
    # ```
    # add_folder("a", "b", "c") do |folder| # folder == "c"
    #   folder.add_file("hello.txt")
    # end
    # ```
    #
    # Produces these folder paths:
    #
    # ```text
    # a
    # a/b
    # a/b/c
    # a/b/c/hello.txt
    # ```
    def add_folder(*names : String, & : Folder ->) : self
      prev : Folder? = nil
      names.each_with_index do |name, index|
        current_folder = Folder.new
        if index == names.size - 1
          current_folder.lock do
            yield current_folder
          end
        end
        if prev_folder = prev
          prev_folder.insert_folder(name, current_folder)
        else
          insert_folder(name, current_folder)
        end
        prev = current_folder
      end
      self
    end

    # Adds nested empty folders
    #
    # Example:
    #
    # ```
    # add_folder("a", "b", "c", "d")
    # ```
    #
    # Produces these folder paths:
    #
    # ```text
    # a
    # a/b
    # a/b/c
    # a/b/c/d
    # ```
    def add_folder(*names : String) : self
      add_folder(*names) { }
    end

    # Insert an existing folder
    #
    # Raises `LuckyTemplate::Error` if one of the following are true:
    #   - existing folder is equal to itself
    #   - existing folder is locked
    #
    # Example:
    #
    # ```
    # another_folder = LuckyTemplate::Folder.new
    # LuckyTemplate.create_folder do |folder|
    #   folder.insert_folder(another_folder)
    # end
    # ```
    def insert_folder(name : String, folder : Folder) : self
      if folder == self
        raise Error.new("Cannot add Folder equal to itself")
      elsif folder.locked?
        raise Error.new("Cannot add Folder that is locked")
      end
      @files[name] = folder
      self
    end

    # To be used as a safe-guard to protect against circular references
    protected def lock(&) : Nil
      @locked = true
      yield
    ensure
      @locked = false
    end

    # Checks if folder is _locked_
    def locked? : Bool
      @locked
    end

    protected def files
      @files
    end
  end
end
