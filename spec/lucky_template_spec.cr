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
          expect_raises(LuckyTemplate::Error) do
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
        expect_raises(LuckyTemplate::Error) do
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
      folder = LuckyTemplate.write!(Path["."]) do |dir|
        expect_raises(LuckyTemplate::Error) do
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

    it "raises if folder is locked" do
      folder = LuckyTemplate.write!(Path["."]) do |dir|
        expect_raises(LuckyTemplate::Error) do
          LuckyTemplate.validate?(Path["."], dir)
        end
      end
    end
  end

  describe "Folder" do
    describe "#add_file" do
      pending "WIP"
    end

    describe "#add_folder" do
      pending "WIP"
    end

    describe "#insert_folder" do
      pending "WIP"
    end

    describe "#locked?" do
      pending "WIP"
    end

    describe "#empty?" do
      pending "WIP"
    end
  end
end
