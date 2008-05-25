require File.dirname(__FILE__) + '/spec_helper.rb'
require 'flog'

describe 'flog command' do
  def run_command
    eval File.read(File.join(File.dirname(__FILE__), *%w[.. bin flog]))
  rescue SystemExit
  end
  
  describe 'when no command-line arguments are specified' do
    before :all do
      path = File.join(File.dirname(__FILE__), *%w[.. bin])
      ENV['PATH'] = [path, ENV['PATH']].join(':')
    end
  
    before :each do
      Object.send(:remove_const, :ARGV)
      ARGV = []
    end  
  
    before :each do
      @flog = stub('Flog', :flog_files => true, :report => true)
      Flog.stubs(:new).returns(@flog)
    end
  
    it 'should run' do
      lambda { run_command('blah') }.should_not raise_error(Errno::ENOENT)
    end
  end
end