require "./spec_helper"

describe LuckyTemplate do
  around_each do |example|
    with_tempfile("tmp") do |tmp|
      Dir.mkdir_p(tmp)
      Dir.cd(tmp) do
        example.run
      end
    end
  end

  describe ".create_folder" do
    context "without block" do
      it "returns a folder" do
        LuckyTemplate.create_folder.should be_a(LuckyTemplate::Folder)
      end

      it "returned folder is not locked" do
        LuckyTemplate.create_folder.locked?.should be_false
      end
    end

    context "with block" do
      it "yields a folder and returns the folder" do
        returned_folder = LuckyTemplate.create_folder do |folder|
          folder.should be_a(LuckyTemplate::Folder)
        end
        returned_folder.should be_a(LuckyTemplate::Folder)
      end

      it "yielded folder is locked, but returned folder is not locked" do
        returned_folder = LuckyTemplate.create_folder do |folder|
          folder.locked?.should be_true
        end
        returned_folder.locked?.should be_false
      end
    end
  end

  describe ".write!" do
    context "without block" do
      it "writes folder to disk" do
        folder = LuckyTemplate.create_folder
        LuckyTemplate.write!(Path["."], folder)
      end

      it "writes folder with file to disk" do
        folder = LuckyTemplate.create_folder do |dir|
          dir.add_file(".keep")
        end
        LuckyTemplate.write!(Path["."], folder)
      end

      it "raises if folder is locked" do
        LuckyTemplate.create_folder do |folder|
          expect_raises(LuckyTemplate::Error, "folder is locked") do
            LuckyTemplate.write!(Path["."], folder)
          end
        end
      end

      it "raises if location is not an existing folder" do
        folder = LuckyTemplate.create_folder do |dir|
          dir.add_file(".keep")
        end
        File.touch(Path["./folder"])
        expect_raises(File::AlreadyExistsError) do
          LuckyTemplate.write!(Path["./folder"], folder)
        end
      end
    end

    context "with block" do
      it "writes folder to disk" do
        LuckyTemplate.write!(Path["."]) { }
      end
    end
  end

  describe ".snapshot" do
    it "returns a snapshot" do
      folder = LuckyTemplate.create_folder
      LuckyTemplate.snapshot(folder).should be_a(LuckyTemplate::Snapshot)
    end

    it "raises if folder is locked" do
      LuckyTemplate.create_folder do |folder|
        expect_raises(LuckyTemplate::Error, "folder is locked") do
          LuckyTemplate.snapshot(folder)
        end
      end
    end

    it "returns same snapshot if no changes are made to folder" do
      folder = LuckyTemplate.create_folder do |dir|
        dir.add_file(".keep")
      end
      snap1 = LuckyTemplate.snapshot(folder)
      snap2 = LuckyTemplate.snapshot(folder)
      snap2.should eq(snap1)
    end

    it "returns different snapshot if changes are made to folder" do
      folder = LuckyTemplate.create_folder do |dir|
        dir.add_file(".keep")
      end
      snap1 = LuckyTemplate.snapshot(folder)
      folder.add_file("README.md")
      snap2 = LuckyTemplate.snapshot(folder)
      snap2.should_not eq(snap1)
    end

    it "returns snapshot with POSIX paths as keys" do
      folder = LuckyTemplate.create_folder do |dir|
        dir.add_folder("parent", "child", "grandchild")
      end
      snapshot = LuckyTemplate.snapshot(folder)
      snapshot.keys.should contain("parent")
      snapshot.keys.should contain("parent/child")
      snapshot.keys.should contain("parent/child/grandchild")
    end
  end

  describe ".validate!" do
    it "returns true if folder is valid" do
      folder = LuckyTemplate.write!(Path["."]) do |dir|
        dir.add_file(".keep")
      end
      LuckyTemplate.validate!(Path["."], folder).should be_true
    end

    it "raises if a file or folder does not exist" do
      folder = LuckyTemplate.write!(Path["."]) do |dir|
        dir.add_file(".keep")
      end
      File.delete(Path["./.keep"])
      expect_raises(File::NotFoundError) do
        LuckyTemplate.validate!(Path["."], folder)
      end
    end

    it "raises if folder is locked" do
      LuckyTemplate.write!(Path["."]) do |dir|
        expect_raises(LuckyTemplate::Error, "folder is locked") do
          LuckyTemplate.validate!(Path["."], dir)
        end
      end
    end
  end

  describe ".validate?" do
    it "returns true if folder is valid" do
      folder = LuckyTemplate.write!(Path["."]) do |dir|
        dir.add_file(".keep")
      end
      LuckyTemplate.validate?(Path["."], folder).should be_true
    end

    it "returns false if folder is not valid" do
      folder = LuckyTemplate.write!(Path["."]) do |dir|
        dir.add_file(".keep")
      end
      File.delete(Path["./.keep"])
      LuckyTemplate.validate?(Path["."], folder).should be_false
    end
  end

  describe "Folder" do
    describe "#add_file" do
      context "with name" do
        it "adds file with string content" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file("hello.txt", "hello world with string")
          end
          File.read(Path["./hello.txt"]).should eq("hello world with string")
        end

        it "adds file with interpolated string content" do
          LuckyTemplate.write!(Path["."]) do |folder|
            name = "John"
            folder.add_file("hello.txt", "Hello #{name}")
          end
          File.read(Path["./hello.txt"]).should eq("Hello John")
        end

        it "adds file with string content using heredoc" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file("hello.txt", <<-TEXT)
            hello world with heredoc
            TEXT
          end
          File.read(Path["./hello.txt"]).should eq("hello world with heredoc")
        end

        it "adds file with interpolated string content using heredoc" do
          LuckyTemplate.write!(Path["."]) do |folder|
            name = "Jane"
            folder.add_file("hello.txt", <<-TEXT)
            Hello #{name}
            TEXT
          end
          File.read(Path["./hello.txt"]).should eq("Hello Jane")
        end

        it "adds file with no content" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file("hello.txt")
          end
          File.size(Path["./hello.txt"]).should eq(0)
        end

        it "adds file with block" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file("hello.txt") do |io|
              io << "hello world with block"
            end
          end
          File.read(Path["./hello.txt"]).should eq("hello world with block")
        end

        it "adds file with proc" do
          LuckyTemplate.write!(Path["."]) do |folder|
            proc = LuckyTemplate::FileIO.new { |io| io << "hello world with proc" }
            folder.add_file("hello.txt", &proc)
          end
          File.read(Path["./hello.txt"]).should eq("hello world with proc")
        end

        it "adds file with class that implements Fileable" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file("hello.txt", HelloWorldClass.new)
          end
          File.read(Path["./hello.txt"]).should eq("hello world with class")
        end

        it "adds file with struct that implements Fileable" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file("hello.txt", HelloWorldStruct.new)
          end
          File.read(Path["./hello.txt"]).should eq("hello world with struct")
        end

        it "adds file when name is a POSIX path" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file("./hello.txt")
          end
          File.size(Path["./hello.txt"]).should eq(0)
        end

        it "adds nested file when name is a POSIX path" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file("./a/b/c/hello.txt")
          end
          File.size(Path["./a/b/c/hello.txt"]).should eq(0)
        end
      end

      context "with path" do
        it "adds file with string content" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file(Path["hello.txt"], "hello world with string")
          end
          File.read(Path["./hello.txt"]).should eq("hello world with string")
        end

        it "adds file with interpolated string content" do
          LuckyTemplate.write!(Path["."]) do |folder|
            name = "John"
            folder.add_file(Path["hello.txt"], "Hello #{name}")
          end
          File.read(Path["./hello.txt"]).should eq("Hello John")
        end

        it "adds file with string content using heredoc" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file(Path["hello.txt"], <<-TEXT)
            hello world with heredoc
            TEXT
          end
          File.read(Path["./hello.txt"]).should eq("hello world with heredoc")
        end

        it "adds file with interpolated string content using heredoc" do
          LuckyTemplate.write!(Path["."]) do |folder|
            name = "Jane"
            folder.add_file(Path["hello.txt"], <<-TEXT)
            Hello #{name}
            TEXT
          end
          File.read(Path["./hello.txt"]).should eq("Hello Jane")
        end

        it "adds file with no content" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file(Path["hello.txt"])
          end
          File.size(Path["./hello.txt"]).should eq(0)
        end

        it "adds file with block" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file(Path["hello.txt"]) do |io|
              io << "hello world with block"
            end
          end
          File.read(Path["./hello.txt"]).should eq("hello world with block")
        end

        it "adds file with proc" do
          LuckyTemplate.write!(Path["."]) do |folder|
            proc = LuckyTemplate::FileIO.new { |io| io << "hello world with proc" }
            folder.add_file(Path["hello.txt"], &proc)
          end
          File.read(Path["./hello.txt"]).should eq("hello world with proc")
        end

        it "adds file with class that implements Fileable" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file(Path["hello.txt"], HelloWorldClass.new)
          end
          File.read(Path["./hello.txt"]).should eq("hello world with class")
        end

        it "adds file with struct that implements Fileable" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file(Path["hello.txt"], HelloWorldStruct.new)
          end
          File.read(Path["./hello.txt"]).should eq("hello world with struct")
        end

        it "adds nested file" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file(Path["a/b/c/hello.txt"])
          end
          File.size(Path["./a/b/c/hello.txt"]).should eq(0)
        end

        it "adds file removing '..' prefix" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file(Path["../hello.txt"], "..")
          end
          File.read(Path["./hello.txt"]).should eq("..")
        end

        it "adds file removing '.' prefix" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file(Path["./hello.txt"], ".")
          end
          File.read(Path["./hello.txt"]).should eq(".")
        end

        it "adds file removing '/' prefix" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file(Path["/hello.txt"], "/")
          end
          File.read(Path["./hello.txt"]).should eq("/")
        end

        it "adds file removing '~' prefix" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file(Path["~/hello.txt"], "~")
          end
          File.read(Path["./hello.txt"]).should eq("~")
        end

        it "adds file removing trailing slash" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file(Path["~/hello/"], "trailing slash")
          end
          File.read(Path["./hello"]).should eq("trailing slash")
        end

        it "adds file normalizing nested paths" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file(Path["../a/b/../bb/c.txt"], "normalize paths")
          end
          File.read(Path["./a/bb/c.txt"]).should eq("normalize paths")
        end

        it "adds nested files under same folder" do
          folder = LuckyTemplate.create_folder do |dir|
            dir.add_file(Path["./a/.keep"])
            dir.add_file(Path["./a/hello.txt"])
          end
          snapshot = LuckyTemplate.snapshot(folder)
          snapshot.keys.should contain("a/.keep")
          snapshot.keys.should contain("a/hello.txt")
        end

        it "raises if empty string" do
          LuckyTemplate.write!(Path["."]) do |folder|
            expect_raises(LuckyTemplate::Error, "invalid path") do
              folder.add_file(Path[""])
            end
          end
        end

        it "raises if empty path" do
          LuckyTemplate.write!(Path["."]) do |folder|
            expect_raises(LuckyTemplate::Error, "invalid path") do
              folder.add_file(Path.new)
            end
          end
        end

        it "raises if multiple '..' parts" do
          LuckyTemplate.write!(Path["."]) do |folder|
            expect_raises(LuckyTemplate::Error, "invalid folder names") do
              folder.add_file(Path["../../hello.txt"])
            end
          end
        end
      end

      context "with permissions" do
        it "adds file" do
          filename = "hello.bash"
          file_perms = {{ flag?(:windows) ? 0o666_i16 : 0o755_i16 }}
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file(filename, <<-BASH, file_perms)
            #!/usr/bin/env bash
            echo Hello World
            BASH
          end
          File.read(Path[filename]).should eq(<<-BASH)
          #!/usr/bin/env bash
          echo Hello World
          BASH
          File.info(Path[filename]).permissions.value.should eq(file_perms)
        end

        it "adds file with block" do
          filename = "hello.bash"
          file_perms = {{ flag?(:windows) ? 0o666_i16 : 0o755_i16 }}
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file(filename, file_perms) do |io|
              io << "#!/usr/bin/env bash"
              io << '\n'
              io << "echo Hello World"
            end
          end
          File.read(Path[filename]).should eq(String.build { |io|
            io << "#!/usr/bin/env bash"
            io << '\n'
            io << "echo Hello World"
          })
          File.info(Path[filename]).permissions.value.should eq(file_perms)
        end

        it "adds empty file" do
          filename = "hello.bash"
          file_perms = {{ flag?(:windows) ? 0o666_i16 : 0o755_i16 }}
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file(filename, file_perms)
          end
          File.size(Path[filename]).should eq(0)
          File.info(Path[filename]).permissions.value.should eq(file_perms)
        end

        it "adds file from Int16#to_s" do
          filename = "hello.bash"
          file_perms = {{ flag?(:windows) ? 0o666_i16 : 0o755_i16 }}
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_file(filename, file_perms.to_s, file_perms)
          end
          File.read(Path[filename]).should eq(file_perms.to_s)
          File.info(Path[filename]).permissions.value.should eq(file_perms)
        end
      end
    end

    describe "#add_folder" do
      context "with block" do
        it "adds nested folders as array" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_folder(["a", "b", "c"]) do |c|
              c.add_file("hello.txt")
            end
          end
          File.size(Path["./a/b/c/hello.txt"]).should eq(0)
        end

        it "adds nested folders as path" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_folder(Path["a/b/c"]) do |c|
              c.add_file("hello.txt")
            end
          end
          File.size(Path["./a/b/c/hello.txt"]).should eq(0)
        end

        it "adds nested folders as splat" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_folder("a", "b", "c") do |c|
              c.add_file("hello.txt")
            end
          end
          File.size(Path["./a/b/c/hello.txt"]).should eq(0)
        end

        it "raises if empty string" do
          LuckyTemplate.write!(Path["."]) do |folder|
            expect_raises(LuckyTemplate::Error, "invalid folder names") do
              folder.add_folder("") do |dir|
                dir.add_file(".keep")
              end
            end
          end
        end

        it "raises if multiple empty strings" do
          LuckyTemplate.write!(Path["."]) do |folder|
            expect_raises(LuckyTemplate::Error, "invalid folder names") do
              folder.add_folder("", "") do |dir|
                dir.add_file(".keep")
              end
            end
          end
        end
      end

      context "without block" do
        it "adds nested folders as array" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_folder(["a", "b", "c"])
          end
          Dir.exists?(Path["./a/b/c"]).should be_true
        end

        it "adds nested folders as path" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_folder(Path["a/b/c"])
          end
          Dir.exists?(Path["./a/b/c"]).should be_true
        end

        it "adds nested folders as splat" do
          LuckyTemplate.write!(Path["."]) do |folder|
            folder.add_folder("a", "b", "c")
          end
          Dir.exists?(Path["./a/b/c"]).should be_true
        end

        it "raises if empty string" do
          LuckyTemplate.write!(Path["."]) do |folder|
            expect_raises(LuckyTemplate::Error, "invalid folder names") do
              folder.add_folder("")
            end
          end
        end

        it "raises if multiple empty strings" do
          LuckyTemplate.write!(Path["."]) do |folder|
            expect_raises(LuckyTemplate::Error, "invalid folder names") do
              folder.add_folder("", "")
            end
          end
        end

        it "raises if empty array" do
          LuckyTemplate.write!(Path["."]) do |folder|
            expect_raises(LuckyTemplate::Error, "invalid folder names") do
              folders = [] of String
              folder.add_folder(folders)
            end
          end
        end
      end
    end

    describe "#insert_folder" do
      it "raises if folder is itself" do
        LuckyTemplate.create_folder do |folder|
          expect_raises(LuckyTemplate::Error, "folder equal to itself") do
            folder.insert_folder("folder", folder)
          end
        end
      end

      it "raises if folder is locked" do
        LuckyTemplate.create_folder do |parent|
          parent.add_folder("child") do |child|
            expect_raises(LuckyTemplate::Error, "locked folder") do
              child.insert_folder("parent", parent)
            end
          end
        end
      end

      it "raises if folder is locked by adding child folder to parent again" do
        LuckyTemplate.create_folder do |parent|
          parent.add_folder("child") do |child|
            expect_raises(LuckyTemplate::Error, "locked folder") do
              parent.insert_folder("child2", child)
            end
          end
        end
      end
    end

    describe "#locked?" do
      it "returns true if locked" do
        LuckyTemplate.create_folder do |folder|
          folder.locked?.should be_true
        end
      end

      it "returns false if not locked" do
        folder = LuckyTemplate.create_folder
        folder.locked?.should be_false
      end
    end

    describe "#empty?" do
      it "returns true on empty folder" do
        folder = LuckyTemplate.create_folder
        folder.empty?.should be_true
      end

      it "returns false on modified folder" do
        LuckyTemplate.create_folder do |folder|
          folder.add_file(".keep")
          folder.empty?.should be_false
        end
      end
    end
  end

  context "example" do
    it "creates basic repository" do
      project_name = "example"
      folder = LuckyTemplate.write!(Path["."]) do |dir|
        dir.add_file("README.md", "# #{project_name}\n")

        dir.add_file(Path["./src/.keep"])

        dir.add_file(Path["./src/#{project_name}.cr"], <<-CRYSTAL)
        class #{project_name.camelcase}
          def run
            puts "Hello World!"
          end
        end
        #{project_name.camelcase}.new.run\n
        CRYSTAL

        dir.add_folder("spec") do |spec|
          spec.add_file("spec_helper.cr", <<-CRYSTAL)
          require "../src/#{project_name}"\n
          CRYSTAL

          spec.add_file("#{project_name}_spec.cr", <<-CRYSTAL)
          require "./spec_helper"

          describe #{project_name.camelcase} do
            it "works" do
              true.should be_false
            end
          end\n
          CRYSTAL
        end
      end
      folder.should be_valid_at(Path["."])
    end

    it "uses ECR as template" do
      template = EcrTemplate.new
      folder = LuckyTemplate.write!(Path["."]) do |dir|
        dir.add_file("template.txt", template)
      end
      folder.should be_valid_at(Path["."])
      File.read(Path["./template.txt"]).should contain(template.expected_content)
    end

    it "uses envsubst as external template" do
      pending!("envsubst not found in PATH") unless Process.find_executable("envsubst")

      external_process = ExternalProcessExample.new
      folder = LuckyTemplate.write!(Path["."]) do |dir|
        dir.add_file("external_process.txt", external_process)
      end
      folder.should be_valid_at(Path["."])
      File.read(Path["./external_process.txt"]).should contain(external_process.expected_content)
    end
  end
end
