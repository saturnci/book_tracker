require "rails_helper"
load Rails.root.join(".saturnci/jobs/entrypoint/run").to_s

describe ".saturnci/jobs/entrypoint/run" do
  let!(:io) { StringIO.new }
  let!(:error_io) { StringIO.new }
  let!(:client) { double("client") }

  let!(:test_suite_run) do
    double("test_suite_run", url: "https://example.com/tsr/1", wait_for_completion: nil, status: "Passed")
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("BRANCH_NAME").and_return("main")
    allow(ENV).to receive(:[]).with("COMMIT_HASH").and_return("abc123")
    allow(ENV).to receive(:[]).with("COMMIT_MESSAGE").and_return("commit message")
    allow(ENV).to receive(:[]).with("AUTHOR_NAME").and_return("author name")

    stub_const("SaturnCI::VERSION", "test")
    stub_const("SaturnCI::TestSuiteRun", double("SaturnCI::TestSuiteRun", create: test_suite_run))
    stub_const("SaturnCI::JobRun", double("SaturnCI::JobRun", create: nil))
  end

  context "when BRANCH_NAME is set" do
    it "prints the branch name to the given io" do
      run(io, error_io, "push", client)
      expect(io.string).to include("Branch name: main")
    end
  end

  context "when BRANCH_NAME is not set" do
    before do
      allow(ENV).to receive(:[]).with("BRANCH_NAME").and_return(nil)
    end

    it "prints a graceful error to the given error_io" do
      run(io, error_io, "push", client)
      expect(error_io.string).to eq("BRANCH_NAME env var is required\n")
    end

    it "returns exit status 1" do
      expect(run(io, error_io, "push", client)).to eq(1)
    end
  end

  context "when COMMIT_HASH is not set" do
    before do
      allow(ENV).to receive(:[]).with("COMMIT_HASH").and_return(nil)
    end

    it "prints a graceful error to the given error_io" do
      run(io, error_io, "push", client)
      expect(error_io.string).to eq("COMMIT_HASH env var is required\n")
    end
  end

  context "when the github event is a push" do
    it "creates a test suite run" do
      expect(SaturnCI::TestSuiteRun).to receive(:create)
      run(io, error_io, "push", client)
    end
  end

  context "when the github event is not a push" do
    it "does not create a test suite run" do
      expect(SaturnCI::TestSuiteRun).not_to receive(:create)
      run(io, error_io, "check_suite", client)
    end
  end

  context "when the push is a branch deletion" do
    before do
      allow(ENV).to receive(:[]).with("DELETED").and_return("true")
    end

    it "does not create a test suite run" do
      expect(SaturnCI::TestSuiteRun).not_to receive(:create)
      run(io, error_io, "push", client)
    end
  end

  context "when the test suite run passes" do
    it "creates a deploy job run" do
      expect(SaturnCI::JobRun).to receive(:create).with(hash_including(job_name: "deploy"))
      run(io, error_io, "push", client)
    end

    it "names the deploy job run after the commit message" do
      allow(ENV).to receive(:[]).with("COMMIT_MESSAGE").and_return("Add foo feature")
      expect(SaturnCI::JobRun).to receive(:create).with(hash_including(name: "Add foo feature"))
      run(io, error_io, "push", client)
    end
  end

  context "when the test suite run does not pass" do
    before do
      allow(test_suite_run).to receive(:status).and_return("Failed")
    end

    it "does not create a deploy job run" do
      expect(SaturnCI::JobRun).not_to receive(:create)
      run(io, error_io, "push", client)
    end
  end

  context "when the branch is not main" do
    before do
      allow(ENV).to receive(:[]).with("BRANCH_NAME").and_return("feature-branch")
    end

    it "does not create a deploy job run" do
      expect(SaturnCI::JobRun).not_to receive(:create)
      run(io, error_io, "push", client)
    end
  end
end
